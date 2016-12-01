using Microsoft.VisualStudio.TestTools.UnitTesting;
using SecurityFever.CredentialManager;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;

namespace SecurityFever.Tests.CredentialManager
{
    [TestClass]
    public class CredentialStoreTest
    {
        [TestMethod]
        public void TestCreateCredential()
        {
            // Arrange
            string expectedNamespace          = "LegacyGeneric";
            string expectedAttribute          = "target";
            string expectedTargetAlias        = string.Empty;
            string expectedTargetName         = "Unit Test Demo";
            CredentialType expectedType       = CredentialType.Generic;
            CredentialPersist expectedPersist = CredentialPersist.LocalMachine;
            string expectedUsername           = "DEMO\\user";
            string expectedPassword           = "MySecurePassword";
            PSCredential expectedCredential   = new PSCredential(expectedUsername, CredentialHelper.StringToSecureString(expectedPassword));

            // Act
            CredentialEntry actualCredentialEntry = CredentialStore.CreateCredential(expectedTargetName, expectedType, expectedPersist, expectedCredential);

            // Assert
            Assert.AreEqual(expectedNamespace, actualCredentialEntry.Namespace);
            Assert.AreEqual(expectedAttribute, actualCredentialEntry.Attribute);
            Assert.AreEqual(expectedTargetAlias, actualCredentialEntry.TargetAlias);
            Assert.AreEqual(expectedTargetName, actualCredentialEntry.TargetName);
            Assert.AreEqual(expectedType, actualCredentialEntry.Type);
            Assert.AreEqual(expectedPersist, actualCredentialEntry.Persist);
            Assert.AreEqual(expectedUsername, actualCredentialEntry.Credential.UserName);
            Assert.AreEqual(expectedPassword, actualCredentialEntry.Credential.GetNetworkCredential().Password);
        }

        [TestMethod]
        public void TestGetCredential()
        {
            // Arrange
            string expectedNamespace = "LegacyGeneric";
            string expectedAttribute = "target";
            string expectedTargetAlias = string.Empty;
            string expectedTargetName = "Unit Test Demo";
            CredentialType expectedType = CredentialType.Generic;
            CredentialPersist expectedPersist = CredentialPersist.LocalMachine;
            string expectedUsername = "DEMO\\user";
            string expectedPassword = "MySecurePassword";
            PSCredential expectedCredential = new PSCredential(expectedUsername, CredentialHelper.StringToSecureString(expectedPassword));

            // Act
            CredentialEntry actualCredentialEntry = CredentialStore.GetCredential(expectedTargetName, expectedType, expectedPersist);

            // Assert
            Assert.AreEqual(expectedNamespace, actualCredentialEntry.Namespace);
            Assert.AreEqual(expectedAttribute, actualCredentialEntry.Attribute);
            Assert.AreEqual(expectedTargetAlias, actualCredentialEntry.TargetAlias);
            Assert.AreEqual(expectedTargetName, actualCredentialEntry.TargetName);
            Assert.AreEqual(expectedType, actualCredentialEntry.Type);
            Assert.AreEqual(expectedPersist, actualCredentialEntry.Persist);
            Assert.AreEqual(expectedUsername, actualCredentialEntry.Credential.UserName);
            Assert.AreEqual(expectedPassword, actualCredentialEntry.Credential.GetNetworkCredential().Password);
        }

        [TestMethod]
        public void TestGetCredentials()
        {
            // Act
            IEnumerable<CredentialEntry> actualCredentialEntries = CredentialStore.GetCredentials();

            // Assert
            Assert.AreNotEqual(actualCredentialEntries.Count(), 0);
        }

        [TestMethod]
        public void TestRemoveCredential()
        {
            // Arrange
            string targetName         = "Unit Test Demo";
            CredentialType type       = CredentialType.Generic;
            CredentialPersist persist = CredentialPersist.LocalMachine;

            // Act
            CredentialStore.RemoveCredential(targetName, type);

            // Assert
            try
            {
                CredentialStore.GetCredential(targetName, type, persist);

                Assert.Fail("The GetCredential() returns the credential which should be deleted!");
            }
            catch
            {
                Assert.IsTrue(true);
            }
        }
    }
}
