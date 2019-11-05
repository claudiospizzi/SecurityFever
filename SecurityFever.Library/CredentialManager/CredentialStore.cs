using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text;

namespace SecurityFever.CredentialManager
{
    /// <summary>
    /// Class providing methods to interact with the credential manager. This
    /// is a wrapper to unmanaged code.
    /// </summary>
    public static class CredentialStore
    {
        /// <summary>
        /// Get a credential entry based on name and type. If no or multiple
        /// credentials were found, an exception is thrown.
        /// </summary>
        /// <param name="targetName">Credential entry name.</param>
        /// <param name="type">Credential entry type.</param>
        /// <returns>The credential entry.</returns>
        public static CredentialEntry GetCredential(string targetName, CredentialType type)
        {
            IList<CredentialEntry> credentials = GetCredentials(targetName, type).ToList();

            if (credentials.Count == 1)
            {
                return credentials[0];
            }
            else if (credentials.Count < 1)
            {
                throw new Win32Exception("Credentials not found!");
            }
            else
            {
                throw new Win32Exception("No unique credential found!");
            }
        }

        /// <summary>
        /// Get all credential entries matching the specified parameters.
        /// </summary>
        /// <param name="targetName">Optional entry name.</param>
        /// <param name="type">Optional entry type.</param>
        /// <param name="persist">Optional entry persist.</param>
        /// <param name="username">Optional entry username.</param>
        /// <returns>List of al matching credential entries.</returns>
        public static IEnumerable<CredentialEntry> GetCredentials(string targetName = null, CredentialType? type = null, CredentialPersist? persist = null, string username = null)
        {
            IList<CredentialEntry> credentials = new List<CredentialEntry>();

            int count;
            IntPtr credentialArrayPtr;

            NativeMethods.CredentialEnumerateFlags flags = NativeMethods.CredentialEnumerateFlags.None;
            if (Environment.OSVersion.Version.Major >= 6)
            {
                flags = NativeMethods.CredentialEnumerateFlags.AllCredentials;
            }

            if (NativeMethods.CredEnumerate(null, flags, out count, out credentialArrayPtr))
            {
                for (int i = 0; i < count; i += 1)
                {
                    int offset = i * Marshal.SizeOf(typeof(IntPtr));

                    IntPtr credentialPtr = Marshal.ReadIntPtr(credentialArrayPtr, offset);

                    if (credentialPtr != IntPtr.Zero)
                    {
                        NativeMethods.Credential nativeCredential = Marshal.PtrToStructure<NativeMethods.Credential>(credentialPtr);

                        CredentialEntry credential = new CredentialEntry(nativeCredential, flags);

                        if ((string.IsNullOrEmpty(targetName) || credential.TargetName == targetName) &&
                            (!type.HasValue || credential.Type == type.Value) &&
                            (!persist.HasValue || credential.Persist == persist.Value) &&
                            (string.IsNullOrEmpty(username) || credential.Credential.UserName == username))
                        {
                            credentials.Add(credential);
                        }
                    }
                }
            }
            else
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            return credentials;
        }

        /// <summary>
        /// Check if the credential identified by name and type exists.
        /// </summary>
        /// <param name="targetName">Credential entry name.</param>
        /// <param name="type">Credential entry type.</param>
        /// <returns>If the entry exists, return true, else false.</returns>
        public static bool ExistCredential(string targetName, CredentialType type)
        {
            IList<CredentialEntry> credentials = GetCredentials(targetName, type).ToList();

            return credentials.Count > 0;
        }

        /// <summary>
        /// Create a new credential entry objects.
        /// </summary>
        /// <param name="targetName">Credential entry name.</param>
        /// <param name="type">Credential entry type.</param>
        /// <param name="persist">Credential entry persist.</param>
        /// <param name="credential">Credential object.</param>
        /// <returns>Returns the new created entry.</returns>
        public static CredentialEntry CreateCredential(string targetName, CredentialType type, CredentialPersist persist, PSCredential credential)
        {
            NativeMethods.Credential nativeCredential = new NativeMethods.Credential()
            {
                TargetName         = targetName,
                Type               = (NativeMethods.CredentialType)type,
                Persist            = (NativeMethods.CredentialPersist)persist,
                AttributeCount     = 0,
                UserName           = credential.UserName,
                CredentialBlob     = Marshal.StringToCoTaskMemUni(credential.GetNetworkCredential().Password),
                CredentialBlobSize = (uint)Encoding.Unicode.GetByteCount(credential.GetNetworkCredential().Password)
            };

            try
            {
                if (NativeMethods.CredWrite(ref nativeCredential, 0))
                {
                    return GetCredential(targetName, type);
                }
                else
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
            }
            finally
            {
                if (nativeCredential.CredentialBlob != IntPtr.Zero)
                {
                    Marshal.FreeCoTaskMem(nativeCredential.CredentialBlob);
                }
            }
        }

        /// <summary>
        /// Remove an existing credential entry.
        /// </summary>
        /// <param name="targetName">Credential entry name.</param>
        /// <param name="type">Credential entry type.</param>
        public static void RemoveCredential(string targetName, CredentialType type)
        {
            if (!NativeMethods.CredDelete(targetName, (NativeMethods.CredentialType)type, 0))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
    }
}
