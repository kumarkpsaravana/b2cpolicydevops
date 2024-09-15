#!/bin/bash

# Check for mandatory parameters
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <ClientID> <ClientSecret> <Tenant> <PolicyId> <PathToFile>"
    exit 1
fi

# Assign parameters to variables
ClientID=$1
ClientSecret=$2
Tenant=$3
PolicyId=$4
PathToFile=$5

# Get an access token from Microsoft Identity platform (Azure AD)
token_response=$(curl -s -X POST \
  -d "grant_type=client_credentials" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "client_id=$ClientID" \
  -d "client_secret=$ClientSecret" \
  https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token)

# Extract access token from the response
access_token=$(echo $token_response | jq -r '.access_token')

if [ "$access_token" == "null" ]; then
  echo "Failed to get access token. Check your client ID, client secret, and tenant."
  exit 1
fi

echo "Access token retrieved successfully."

# Upload the custom policy to Azure AD B2C using Microsoft Graph API
graphuri="https://graph.microsoft.com/beta/trustframework/policies/$PolicyId/\$value"

# Send PUT request to upload the policy file
response=$(curl -s -w "%{http_code}" -o /dev/null -X PUT "$graphuri" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/xml" \
  --data-binary @"$PathToFile")

# Check the response status code
if [ "$response" -eq 200 ]; then
  echo "Policy $PolicyId uploaded successfully."
else
  echo "Failed to upload policy. HTTP Status Code: $response"
  exit 1
fi

exit 0
