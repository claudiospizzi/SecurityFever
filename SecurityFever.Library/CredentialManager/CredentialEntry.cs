using System.Management.Automation;
using System.Security;
using System.Text.RegularExpressions;

namespace SecurityFever.CredentialManager
{
    /// <summary>
    /// Class representing an entry in the credential manager.
    /// </summary>
    public class CredentialEntry
    {
        /// <summary>
        /// Create a new CredentialEntry object.
        /// </summary>
        /// <param name="nativeCredential">The native credential object.</param>
        /// <param name="flags">Credential object flags.</param>
        internal CredentialEntry(NativeMethods.Credential nativeCredential, NativeMethods.CredentialEnumerateFlags flags)
        {
            // Initialize default properties
            Namespace   = string.Empty;
            Type        = (CredentialType)nativeCredential.Type;
            Persist     = (CredentialPersist)nativeCredential.Persist;
            TargetName  = nativeCredential.TargetName ?? string.Empty;
            Username    = nativeCredential.UserName ?? string.Empty;
            Password    = CredentialHelper.IntPtrToSecureString(nativeCredential.CredentialBlob, nativeCredential.CredentialBlobSize);
            Comment     = nativeCredential.Comment ?? string.Empty;
            Attribute   = string.Empty;
            TargetAlias = nativeCredential.TargetAlias ?? string.Empty;
            
            // Extract namespace, attribute and target name
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

            // Use the username if provided or fallback to the target name
            if (!string.IsNullOrEmpty(Username))
            {
                Credential = new PSCredential(Username, Password);
            }
            else
            {
                Credential = new PSCredential(TargetName, Password);
            }
        }

        /// <summary>
        /// Entry namespace like Domain, LegacyGeneric, MicrosoftAccount, WindowsLive, etc.
        /// </summary>
        public string Namespace
        {
            private set;
            get;
        }

        /// <summary>
        /// Type of the entry.
        /// </summary>
        public CredentialType Type
        {
            private set;
            get;
        }

        /// <summary>
        /// Definition where it will persist the entry.
        /// </summary>
        public CredentialPersist Persist
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry target name, used to display in the credential manager.
        /// </summary>
        public string TargetName
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry username.
        /// </summary>
        public string Username
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry password.
        /// </summary>
        public SecureString Password
        {
            private set;
            get;
        }

        /// <summary>
        /// PowerShell credential object.
        /// </summary>
        public PSCredential Credential
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry comment.
        /// </summary>
        public string Comment
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry attribute.
        /// </summary>
        public string Attribute
        {
            private set;
            get;
        }

        /// <summary>
        /// Entry alias.
        /// </summary>
        public string TargetAlias
        {
            private set;
            get;
        }
    }
}
