#!/bin/bash

# Generate a private key
openssl genrsa -out private.key 2048

# Create a certificate signing request (CSR)
openssl req -new -key private.key -out csr.pem -subj "/CN=yourdomain.com"

# Self-sign the CSR to generate the certificate
openssl x509 -req -days 365 -in csr.pem -signkey private.key -out certificate.crt

# Convert the certificate and private key to PKCS#12 format
openssl pkcs12 -export -out certificate.pfx -inkey private.key -in certificate.crt

# Clean up temporary files
rm csr.pem
