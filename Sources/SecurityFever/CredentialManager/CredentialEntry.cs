using System;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security;

namespace SecurityFever.CredentialManager
{
    public class CredentialEntry
    {
        internal CredentialEntry(NativeMethods.Credential nativeCredential)
        {
            TargetAlias = nativeCredential.TargetAlias ?? string.Empty;
            TargetName  = nativeCredential.TargetName ?? string.Empty;
            Comment     = nativeCredential.Comment ?? string.Empty;

            Type        = (CredentialType) nativeCredential.Type;
            Persist     = (CredentialPersist) nativeCredential.Persist;

            Username    = nativeCredential.UserName ?? string.Empty;
            Password    = IntPtrToSecureString(nativeCredential.CredentialBlob, nativeCredential.CredentialBlobSize);

            if (!string.IsNullOrEmpty(Username))
            {
                Credential = new PSCredential(Username, Password);
            }
            else
            {
                Credential = new PSCredential(TargetName, Password);
            }
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

        private static SecureString IntPtrToSecureString(IntPtr pointer, uint size)
        {
            SecureString secure = new SecureString();

            if (size > 0)
            {
                string plain = Marshal.PtrToStringUni(pointer, (int)size / 2);

                if (!string.IsNullOrEmpty(plain))
                {
                    foreach (var c in plain)
                    {
                        secure.AppendChar(c);
                    }
                }
            }

            secure.MakeReadOnly();

            return secure;
        }
    }
}
