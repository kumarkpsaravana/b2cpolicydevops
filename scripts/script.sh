#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 10 ]; then
    echo "Usage: $0 <Environment> <Path> <App1B2CExtensionClientId> <App1B2CExtensionObjectId> <App2B2CExtensionClientId> <App2B2CExtensionObjectId> <B2CExtAppId> <B2CExtAppObjectId> <IdentityExperienceFrameworkAppId> <ProxyIdentityExperienceFrameworkAppId> }}"
    exit 1
fi

# Assign parameters
Environment=$1
Path=$2
App1B2CExtensionClientId=$3
App1B2CExtensionObjectId=$4
App2B2CExtensionClientId=$5
App2B2CExtensionObjectId=$6
B2CExtAppId=$7
B2CExtAppObjectId=$8
IdentityExperienceFrameworkAppId=$9
ProxyIdentityExperienceFrameworkAppId=$10

# Ensure jq is installed for JSON parsing
if ! [ -x "$(command -v jq)" ]; then
    echo 'Error: jq is not installed.' >&2
    exit 1
fi

echo $App1B2CExtensionClientId

# Read application settings from appsettings.json
if ! [ -f $Path/"appsettings.json" ]; then
    echo "appsettings.json not found!"
    exit 1
fi

# Read appsettings.json and extract the environment-specific settings
applicationSettings=$(cat $Path/appsettings.json)
environmentSettings=$(echo "$applicationSettings" | jq --arg env "al" '.Environments[] | select(.Name == $env)')
if [ -z "$environmentSettings" ]; then
    echo "No settings found for environment $Environment"
    exit 1
fi

policySettings=$(echo "$environmentSettings" | jq -r '.PolicySettings')

policySettings=$(echo "$policySettings" | jq --arg newProxyIdentityExperienceFrameworkAppId "$ProxyIdentityExperienceFrameworkAppId" \
--arg newProxyIdentityExperienceFrameworkAppId "$IdentityExperienceFrameworkAppId" \
--arg newApp1B2CExtensionObjectId "$App1B2CExtensionObjectId" \
--arg newApp1B2CExtensionObjectId "$App1B2CExtensionObjectId" \
--arg newApp2B2CExtensionObjectId "$App2B2CExtensionObjectId" \
--arg newApp2B2CExtensionClientId "$App2B2CExtensionClientId" \
--arg newB2CExtAppObjectIdd "$B2CExtAppObjectId" \
--arg newB2CExtAppId "$B2CExtAppId" \
'.ProxyIdentityExperienceFrameworkAppId = $newProxyIdentityExperienceFrameworkAppId
| .IdentityExperienceFrameworkAppId = $newIdentityExperienceFrameworkAppId
| .App1B2CExtensionObjectId = $newApp1B2CExtensionObjectId
| .App1B2CExtensionClientId = $newApp1B2CExtensionObjectId
| .App2B2CExtensionObjectId = $newApp2B2CExtensionObjectId
| .App2B2CExtensionClientId = $newApp2B2CExtensionClientId
| .B2CExtAppObjectId = "$newB2CExtAppObjectId
| .B2CExtAppId = $newB2CExtAppId')

echo $policySettings

mkdir -p $Environment

find "$Path" -maxdepth 1 -type f -name "*.xml" -exec cp {} $Environment/ \;

for PathToFile in "$Environment"/*; do
  if [ -f "$PathToFile" ]; then  # Check if it is a file
    echo "Processing XML file: $PathToFile"
    # Replace placeholders with environment settings
    tenant=$(echo "$environmentSettings" | jq -r '.Tenant')
    sed -i "s/{Settings:Tenant}/$tenant/g" $PathToFile

    echo "$policySettings" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    value=$(printf '%s\n' "$value" | sed 's/[\/&]/\\&/g')
        sed -i "s/{Settings:$key}/$value/g" $PathToFile
    done
  fi
done
exit 0
