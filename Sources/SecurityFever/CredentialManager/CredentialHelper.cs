using System;
using System.Runtime.InteropServices;
using System.Security;

namespace SecurityFever.CredentialManager
{
    public static class CredentialHelper
    {
        public static SecureString IntPtrToSecureString(IntPtr pointer, uint size)
        {
            if (size > 0)
            {
                string plain = Marshal.PtrToStringUni(pointer, (int)size / 2);

                return StringToSecureString(plain);
            }
            else
            {
                return StringToSecureString(string.Empty);
            }
        }

        public static SecureString StringToSecureString(string plain)
        {
            SecureString secure = new SecureString();

            if (!string.IsNullOrEmpty(plain))
            {
                foreach (char c in plain)
                {
                    secure.AppendChar(c);
                }
            }

            secure.MakeReadOnly();

            return secure;
        }
    }
}
