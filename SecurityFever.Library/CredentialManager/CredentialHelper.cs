using System;
using System.Runtime.InteropServices;
using System.Security;

namespace SecurityFever.CredentialManager
{
    /// <summary>
    /// Helper methods to manage credential manager entries.
    /// </summary>
    public static class CredentialHelper
    {
        /// <summary>
        /// Convert an unmanaged IntPtr to a SecureString object, used for
        /// credentials.
        /// </summary>
        /// <param name="pointer">The credential blob.</param>
        /// <param name="size">The credential blob size.</param>
        /// <returns>The protected credential.</returns>
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

        /// <summary>
        /// Convert a plain string to a SecureString object.
        /// </summary>
        /// <param name="plain">The plain string to protect.</param>
        /// <returns>The protected string.</returns>
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
