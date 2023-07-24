# Certificate Demo Files

The password for all certificates is: `Passw0rd`.

## Root CA

* **ca.cer**
  * Certificates: CN=Lab Root CA 1
  * Format: X.509/DER

* **ca.pem**
  * Certificates: CN=Lab Root CA 1
  * Format: X.509/PEM

* **ca.p7b**
  * Certificates: CN=Lab Root CA 1
  * Format: PKCS#7

* **ca-des.pfx**
  * Certificates: CN=Lab Root CA 1
  * Format: PKCS#12
  * Protection: TripleDES-SHA1 with Password

* **ca-aes.pfx**
  * Certificates: CN=Lab Root CA 1
  * Format: PKCS#12
  * Protection: AES256-SHA256 with Password

## Issued Cert

* **cert.cer**
  * Certificates: CN=server.lab.local
  * Format: X.509/DER

* **cert.pem**
  * Certificates: CN=server.lab.local
  * Format: X.509/PEM

* **cert-single.p7b**
  * Certificates: CN=server.lab.local
  * Format: PKCS#7

* **cert-chain.p7b**
  * Certificates: CN=server.lab.local & CN=Lab Root CA 1
  * Format: PKCS#7

* **cert-single-des.pfx**
  * Certificates: CN=server.lab.local
  * Format: PKCS#12
  * Protection: TripleDES-SHA1 with Password

* **cert-single-aes.pfx**
  * Certificates: CN=server.lab.local
  * Format: PKCS#12
  * Protection: AES256-SHA256 with Password

* **cert-chain-des.pfx**
  * Certificates: CN=server.lab.local & CN=Lab Root CA 1
  * Format: PKCS#12
  * Protection: TripleDES-SHA1 with Password

* **cert-chain-aes.pfx**
  * Certificates: CN=server.lab.local & CN=Lab Root CA 1
  * Format: PKCS#12
  * Protection: AES256-SHA256 with Password
