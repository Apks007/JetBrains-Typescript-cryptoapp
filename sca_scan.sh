#!/bin/bash
set -e
# Get the current directory name
CURRENT_DIR=$(basename "$PWD")
# Create a temporary directory
TEMP_DIR=$(mktemp -d)
# Copy current directory contents to a subdirectory in the temp directory
cp -R . "$TEMP_DIR/$CURRENT_DIR"
# Create ZIP file for SCA Scan
(cd "$TEMP_DIR" && zip -r "../$CURRENT_DIR.zip" "$CURRENT_DIR" -x '*.git*')
# Move the ZIP file to the current directory
mv "$TEMP_DIR/../$CURRENT_DIR.zip" .
# Clean up the temporary directory
rm -rf "$TEMP_DIR"
# Verify the ZIP file exists
if [ ! -f "$CURRENT_DIR.zip" ]; then
    echo "Error: ZIP file not created successfully."
    exit 1
fi
# Perform SCA Scan
RESPONSE=$(curl -X POST \
  -H "Client-ID: 123e4567-e89b-12d3-a456-426614174001" \
  -H "Client-Secret: 7a91d1c9-2583-4ef6-8907-7c974f1d6a0e" \
  -F "projectZipFile=@$CURRENT_DIR.zip" \
  -F "applicationId=674066843da24ef64598ca8b" \
  -F "scanName=typescript-cryptoapp-SCA Scan from TeamCity" \
  -F "language=typescript" \
  https://appsecops-api.intruceptlabs.com/api/v1/integrations/sca-scans)
# Use Python to parse and display JSON
python3 - <<EOF
import json
import sys
def print_table(data):
    if not data:
        print("No vulnerability data available.")
        return
    
    # Assuming data is a list of dictionaries
    keys = data[0].keys()
    
    # Print header
    for key in keys:
        print(f"{key:<20}", end="")
    print()
    print("-" * (20 * len(keys)))
    
    # Print rows
    for row in data:
        for key in keys:
            print(f"{str(row.get(key, '')):<20}", end="")
        print()
try:
    data = json.loads('''$RESPONSE''')
    print("SCA Scan Results:")
    print(f"Can Proceed: {data.get('canProceed', 'N/A')}")
    
    print("\nVulnerabilities Table:")
    vulns_table = data.get('vulnsTable')
    if isinstance(vulns_table, str):
        # If vulnsTable is a string, try to parse it as JSON
        try:
            vulns_table = json.loads(vulns_table)
        except json.JSONDecodeError:
            print("Error: Unable to parse vulnerabilities table.")
            vulns_table = None
    
    if vulns_table:
        print_table(vulns_table)
    else:
        print("No vulnerabilities table found or table is empty.")
    
    if data.get('canProceed') == False:
        print("\nCritical vulnerabilities found. Please review the scan results.")
    else:
        print("\nNo critical vulnerabilities detected.")
except json.JSONDecodeError:
    print("Error: Invalid JSON response")
    print("Raw response:", '''$RESPONSE''')
except Exception as e:
    print(f"Error: {str(e)}")
    print("Raw response:", '''$RESPONSE''')
EOF
# Clean up
rm "$CURRENT_DIR.zip"
# Always exit with 0 to not fail the build
exit 0
