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

# Default values
ENABLE_ELASTIC_IP="false"
ENABLE_AUTO_BACKUP="false"
KEY_NAME="n8n-key-pair"
AWS_REGION="ap-southeast-1"

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
        "ENABLE_ELASTIC_IP")
            ENABLE_ELASTIC_IP="$value"
            ;;
        "KEY_NAME")
            KEY_NAME="$value"
            ;;
        "ENABLE_AUTO_BACKUP")
            ENABLE_AUTO_BACKUP="$value"
            ;;
        "AWS_REGION")
            AWS_REGION="$value"
            ;;
    esac
done < "$ENV_FILE"

# Add variables to terraform.tfvars
echo "enable_elastic_ip = $ENABLE_ELASTIC_IP" >> "$TFVARS_FILE"
echo "key_name = \"$KEY_NAME\"" >> "$TFVARS_FILE"
echo "enable_auto_backup = $ENABLE_AUTO_BACKUP" >> "$TFVARS_FILE"
echo "aws_region = \"$AWS_REGION\"" >> "$TFVARS_FILE"

echo "Successfully created $TFVARS_FILE from $ENV_FILE"