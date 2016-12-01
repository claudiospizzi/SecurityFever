using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security;
using System.Text.RegularExpressions;

namespace SecurityFever.CredentialManager
{
    public class CredentialEntry
    {
        internal CredentialEntry(NativeMethods.Credential nativeCredential, NativeMethods.CredentialEnumerateFlags flags)
        {
            Namespace   = string.Empty;
            Attribute   = string.Empty;
            TargetName  = nativeCredential.TargetName ?? string.Empty;
            TargetAlias = nativeCredential.TargetAlias ?? string.Empty;
            Comment     = nativeCredential.Comment ?? string.Empty;
            Type        = (CredentialType) nativeCredential.Type;
            Persist     = (CredentialPersist) nativeCredential.Persist;
            Username    = nativeCredential.UserName ?? string.Empty;
            Password    = CredentialHelper.IntPtrToSecureString(nativeCredential.CredentialBlob, nativeCredential.CredentialBlobSize);

            if (flags == NativeMethods.CredentialEnumerateFlags.AllCredentials)
            {
                Match match = Regex.Match(TargetName, "(.*?):(.*?)=(.*)");
                
                if (match.Success)
                {
                    if (match.Groups.Count >= 2)
                    {
                        Namespace = match.Groups[1].Value;
                    }

                    if (match.Groups.Count >= 3)
                    {
                        Attribute = match.Groups[2].Value;
                    }

                    if (match.Groups.Count >= 4)
                    {
                        TargetName = match.Groups[3].Value;
                    }
                }
            }

            if (!string.IsNullOrEmpty(Username))
            {
                Credential = new PSCredential(Username, Password);
            }
            else
            {
                Credential = new PSCredential(TargetName, Password);
            }
        }

        public string Namespace
        {
            private set;
            get;
        }

        public string Attribute
        {
            private set;
            get;
        }

        public string TargetAlias
        {
            private set;
            get;
        }

        public string TargetName
        {
            private set;
            get;
        }

        public string Comment
        {
            private set;
            get;
        }

        public CredentialType Type
        {
            private set;
            get;
        }

        public CredentialPersist Persist
        {
            private set;
            get;
        }

        public string Username
        {
            private set;
            get;
        }

        public SecureString Password
        {
            private set;
            get;
        }

        public PSCredential Credential
        {
            private set;
            get;
        }
    }
}
