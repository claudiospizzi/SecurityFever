namespace SecurityFever.CredentialManager
{
    /// <summary>
    /// Type of credential.
    /// </summary>
    public enum CredentialType
    {
        Generic               = 0x01,
        DomainPassword        = 0x02,
        DomainCertificate     = 0x03,
        DomainVisiblePassword = 0x04,
        GenericCertificate    = 0x05,
        DomainExtended        = 0x06,
        Maximum               = 0x07,
        MaximumEx             = Maximum + 1000
    }
}
