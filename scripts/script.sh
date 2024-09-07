#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <Environment> <Path>"
    exit 1
fi

# Assign parameters
Environment=$1
Path=$2

# Ensure jq is installed for JSON parsing
if ! [ -x "$(command -v jq)" ]; then
    echo 'Error: jq is not installed.' >&2
    exit 1
fi

echo "Listing files in /path/to/directory:"
ls b2cpolicies -a


# Read application settings from appsettings.json
if ! [ -f $Path/"appsettings.json" ]; then
    echo "appsettings.json not found!"
    exit 1
fi

# Read appsettings.json and extract the environment-specific settings
applicationSettings=$(cat $Path/appsettings.json)
environmentSettings=$(echo "$applicationSettings" | jq --arg env "motodigi" '.Environments[] | select(.Name == $env)')
if [ -z "$environmentSettings" ]; then
    echo "No settings found for environment $Environment"
    exit 1
fi

policySettings=$(echo "$environmentSettings" | jq -r '.PolicySettings')

policySettings=$(echo "$policySettings" | jq '.ProxyIdentityExperienceFrameworkAppId = "Jane Smith" 
| .IdentityExperienceFrameworkAppId = "demo 1"
| .App1B2CExtensionObjectId = "demo 1"
| .App1B2CExtensionClientId = "demo 2"
| .App2B2CExtensionObjectId = "demo 3"
| .App2B2CExtensionClientId = "demo 4"
| .B2CExtAppObjectId = "demo 5"
| .B2CExtAppId = "demo 2333"
')

echo $policySettings

mkdir -p $Environment

cp -r "$Path" "$Environment/"
find "$Path" -maxdepth 1 -type f -name "*.xml" -exec cp {} $Environment/ \;

for PathToFile in "$Environment"/*; do
echo $PathToFile
  if [ -f "$PathToFile" ]; then  # Check if it is a file
    echo "Processing XML file: $file"
    # Replace placeholders with environment settings
    tenant=$(echo "$environmentSettings" | jq -r '.Tenant')
    sed -i '' "s/{Settings:Tenant}/$tenant/g" $PathToFile

    echo "$policySettings" | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do
    value=$(printf '%s\n' "$value" | sed 's/[\/&]/\\&/g')
        sed -i '' "s/{Settings:$key}/$value/g" $PathToFile
    done
  fi
done
exit 0
