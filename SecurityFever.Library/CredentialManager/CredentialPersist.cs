namespace SecurityFever.CredentialManager
{
    /// <summary>
    /// Type of credential persistence.
    /// </summary>
    public enum CredentialPersist : uint
    {
        Session      = 0x01,
        LocalMachine = 0x02,
        Enterprise   = 0x03
    }
}
