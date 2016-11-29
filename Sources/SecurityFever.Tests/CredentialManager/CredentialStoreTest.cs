using Microsoft.VisualStudio.TestTools.UnitTesting;
using SecurityFever.CredentialManager;
using System.Collections.Generic;
using System.Linq;

namespace SecurityFever.Tests.CredentialManager
{
    [TestClass]
    public class CredentialStoreTest
    {
        [TestMethod]
        public void TestCredentialStore()
        {
            IEnumerable<CredentialEntry> credentials = CredentialStore.GetCredentials();

            Assert.AreNotEqual(credentials.ToList<CredentialEntry>().Count, 0);
        }
    }
}
