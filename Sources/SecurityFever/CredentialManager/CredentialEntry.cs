using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using System.Threading.Tasks;

namespace SecurityFever.CredentialManager
{
    public class CredentialEntry
    {
        internal CredentialEntry(NativeMethods.Credential nativeCredential)
        {
            TargetAlias = nativeCredential.TargetAlias;
            TargetName  = nativeCredential.TargetName;
            Comment     = nativeCredential.Comment;
            Type        = (CredentialType) nativeCredential.Type;
            Persist     = (CredentialPersist) nativeCredential.Persist;
            Username    = nativeCredential.UserName;
            Password    = IntPtrToSecureString(nativeCredential.CredentialBlob, nativeCredential.CredentialBlobSize); 
            Credential  = new PSCredential(Username, Password);
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

        private SecureString IntPtrToSecureString(IntPtr pointer, uint size)
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
