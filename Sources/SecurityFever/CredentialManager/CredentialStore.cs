using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace SecurityFever.CredentialManager
{
    public static class CredentialStore
    {
        public static IEnumerable<CredentialEntry> GetCredentials(string filter = null)
        {
            IList<CredentialEntry> credentials = new List<CredentialEntry>();

            // Out-variables for the CredEnumerate function
            int count;
            IntPtr credentialArrayPtr;

            // By default, no flags are used
            NativeMethods.CredentialEnumerateFlags flags = NativeMethods.CredentialEnumerateFlags.None;

            // Check for a filter and set AllCredentials-flag if necessary
            if (string.IsNullOrEmpty(filter) || filter == "*")
            {
                filter = null;

                // Flag is only valid on Vista an later
                if (Environment.OSVersion.Version.Major >= 6)
                {
                    flags = NativeMethods.CredentialEnumerateFlags.AllCredentials;
                }
            }

            if (NativeMethods.CredEnumerate(filter, flags, out count, out credentialArrayPtr))
            {
                for (int i = 0; i < count; i += 1)
                {
                    int offset = i * Marshal.SizeOf(typeof(IntPtr));

                    IntPtr credentialPtr = Marshal.ReadIntPtr(credentialArrayPtr, offset);

                    if (credentialPtr != IntPtr.Zero)
                    {
                        NativeMethods.Credential nativeCredential = Marshal.PtrToStructure<NativeMethods.Credential>(credentialPtr);

                        credentials.Add(new CredentialEntry(nativeCredential));
                    }
                }
            }
            else
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            return credentials;
        }
    }
}
