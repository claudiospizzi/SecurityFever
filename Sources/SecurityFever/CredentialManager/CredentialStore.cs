using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text;

namespace SecurityFever.CredentialManager
{
    public static class CredentialStore
    {
        public static CredentialEntry GetCredential(String targetName, CredentialType type)
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

        public static IEnumerable<CredentialEntry> GetCredentials(String targetName = null, CredentialType? type = null, CredentialPersist? persist = null, String username = null)
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

        public static Boolean ExistCredential(string targetName, CredentialType type)
        {
            IList<CredentialEntry> credentials = GetCredentials(targetName, type).ToList();

            return credentials.Count > 0;
        }

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

        public static void RemoveCredential(string targetName, CredentialType type)
        {
            if (!NativeMethods.CredDelete(targetName, (NativeMethods.CredentialType)type, 0))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
    }
}
