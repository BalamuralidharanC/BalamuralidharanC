#!/bin/bash

# Path to the PFX file
PFX_FILE="/path/to/certificate.pfx"

# Passphrase for the PFX file
PASSPHRASE="your_passphrase"

# Extract the certificate chain and private key from the PFX file
openssl pkcs12 -in "$PFX_FILE" -passin "pass:$PASSPHRASE" -nocerts -out private.key -nodes
openssl pkcs12 -in "$PFX_FILE" -passin "pass:$PASSPHRASE" -clcerts -out certificate.crt -nodes
openssl pkcs12 -in "$PFX_FILE" -passin "pass:$PASSPHRASE" -cacerts -out ca.crt -nodes

# Base64 encode the certificate chain and private key
BASE64_CERT=$(base64 -w 0 certificate.crt)
BASE64_KEY=$(base64 -w 0 private.key)
BASE64_CA=$(base64 -w 0 ca.crt)

# Create a Kubernetes secret YAML file
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: your-secret-name
  namespace: your-namespace
type: kubernetes.io/tls
data:
  tls.crt: |
    $BASE64_CERT
  tls.key: |
    $BASE64_KEY
  ca.crt: |
    $BASE64_CA
EOF

# Apply the Kubernetes secret
kubectl apply -f secret.yaml

# Clean up temporary files
rm private.key certificate.crt ca.crt secret.yaml
