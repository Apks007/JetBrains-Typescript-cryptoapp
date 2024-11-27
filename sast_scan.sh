#!/bin/bash
set -e
# Create ZIP file for SAST Scan
zip -r project.zip . -x '*.git*'
# Perform SAST Scan
RESPONSE=$(curl -X POST \
  -H "Client-ID: 123e4567-e89b-12d3-a456-426614174001" \
  -H "Client-Secret: 7a91d1c9-2583-4ef6-8907-7c974f1d6a0e" \
  -F "projectZipFile=@project.zip" \
  -F "applicationId=674066843da24ef64598ca8b" \
  -F "scanName=typescript-cryptoapp-SAST Scan from TeamCity" \
  -F "language=typescript" \
  https://appsecops-api.intruceptlabs.com/api/v1/integrations/sast-scans)
# Use Python to parse and display JSON
python3 - <<EOF
import json
import sys
try:
    data = json.loads('''$RESPONSE''')
    print("SAST Scan Results:")
    print(f"Can Proceed: {data.get('canProceed', 'N/A')}")
    print("\nVulnerabilities Table:")
    vulns_table = data.get('vulnsTable', 'No vulnerabilities table found')
    print(json.dumps(vulns_table, indent=2))
    
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
rm project.zip
# Always exit with 0 to not fail the build
exit 0
