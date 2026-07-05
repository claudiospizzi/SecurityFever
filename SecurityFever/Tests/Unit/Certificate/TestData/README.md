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

* **ca-key.pem**
  * Key: CN=Lab Root CA 1
  * Format: PKCS#8
  * Protection: Unencrypted

* **ca-rsa.pem**
  * Key: CN=Lab Root CA 1
  * Format: PKCS#1
  * Protection: Unencrypted

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

* **cert-key.pem**
  * Key: CN=server.lab.local
  * Format: PKCS#8
  * Protection: Unencrypted

* **cert-rsa.pem**
  * Key: CN=server.lab.local
  * Format: PKCS#1
  * Protection: Unencrypted

## Commands

Convert a PKCS#12 (.pfx) to the legacy RSA PKCS#1 as `ca-*-rsa.pem` and the modern PKCS#8 as `ca-*-key.pem` using OpenSSL:

```shell
openssl pkcs12 -passin pass:"Passw0rd" -in ca-aes.pfx -nocerts -out ca-key.pem -nodes
openssl pkcs12 -passin pass:"Passw0rd" -in ca-3des.pfx -nocerts -out ca-key.pem -nodes
openssl rsa -in ca-key.pem -out ca-key.pem
openssl rsa -in ca-key.pem -out ca-rsa.pem -traditional

openssl pkcs12 -passin pass:"Passw0rd" -in cert-single-aes.pfx -nocerts -out cert-key.pem -nodes
openssl pkcs12 -passin pass:"Passw0rd" -in cert-single-3des.pfx -nocerts -out cert-key.pem -nodes
openssl rsa -in cert-key.pem -out cert-key.pem
openssl rsa -in cert-key.pem -out cert-rsa.pem -traditional
```
