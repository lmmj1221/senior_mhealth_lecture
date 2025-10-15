#!/bin/bash
echo "=== Generating Secrets ==="
echo ""
echo "NEXTAUTH_SECRET=$(openssl rand -base64 32)"
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "JWT_SECRET_KEY=$(openssl rand -base64 32)"
echo ""
echo "Copy these values to your .env files!"
