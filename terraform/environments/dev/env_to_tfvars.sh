#!/bin/bash

# Path to your .env file
ENV_FILE="../../../.env"
TFVARS_FILE="terraform.tfvars"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Clear or create terraform.tfvars
> "$TFVARS_FILE"

# Convert .env to terraform.tfvars format
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
        continue
    fi

    # Split the line into key and value
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)

    # Convert environment variable names to terraform variable names
    case "$key" in
        "DOMAIN_NAME")
            echo "domain_name = \"$value\"" >> "$TFVARS_FILE"
            ;;
        "SUBDOMAIN")
            echo "subdomain = \"$value\"" >> "$TFVARS_FILE"
            ;;
        "GENERIC_TIMEZONE")
            echo "timezone = \"$value\"" >> "$TFVARS_FILE"
            ;;
        "SSL_EMAIL")
            echo "ssl_email = \"$value\"" >> "$TFVARS_FILE"
            ;;
    esac
done < "$ENV_FILE"

echo "Successfully created $TFVARS_FILE from $ENV_FILE"