#!/bin/bash

# Path to the private key
PRIVATE_KEY="/home/david/git/k8-for-dummies/terraform/dev/blah.pem"

# Path to the original public key
ORIGINAL_PUBLIC_KEY="/home/david/git/k8-for-dummies/terraform/dev/blah_public.pem"

# Extract the public key from the private key
openssl rsa -in "$PRIVATE_KEY" -pubout -out /tmp/extracted_public_key.pem
cat /tmp/extracted_public_key.pem
# Compare the extracted public key with the original public key
if diff /tmp/extracted_public_key.pem "$ORIGINAL_PUBLIC_KEY" > /dev/null; then
    echo "The private key matches the public key."
else
    echo "The private key does NOT match the public key."
fi

# Clean up
rm /tmp/extracted_public_key.pem
