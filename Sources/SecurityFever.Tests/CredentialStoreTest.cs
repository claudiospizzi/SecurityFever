using Microsoft.VisualStudio.TestTools.UnitTesting;
using SecurityFever.CredentialManager;
using System.Collections.Generic;

namespace SecurityFever.Tests
{
    [TestClass]
    public class CredentialStoreTest
    {
        [TestMethod]
        public void TestGetCredentials()
        {
            IEnumerable<CredentialEntry> credentials = CredentialStore.GetCredentials();
        }
    }
}
