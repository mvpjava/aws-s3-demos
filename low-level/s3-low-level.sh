#!/bin/bash

BUCKET_NAME="demo-low-level-$RANDOM"
KEY_NAME="hello.txt"
LOCAL_FILE="/tmp/$KEY_NAME"
REGION="eu-west-2"               
KMS_KEY_ID="alias/aws/s3"        # Replace with your own KMS key if needed

touch $LOCAL_FILE

# Prepare file content
echo "Hello from low-level API" > "$LOCAL_FILE"

# Note: Do not use us-east-1 as a Region with LocationConstraint (causes known error)
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning on the bucket (cannot be done with high-level s3 high-level api commands)
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled


# Upload file with custom metadata, storage class, and encryption
# These cannot be done with the high-level `aws s3 cp` command:
# - Custom metadata
# - Explicit storage class (e.g., STANDARD_IA)
# - Server-side encryption with KMS key
# - enable versioning
aws s3api put-object \
  --bucket "$BUCKET_NAME" \
  --key "$KEY_NAME" \
  --body "$LOCAL_FILE" \
  --metadata "owner=devteam,env=prod" \
  --storage-class STANDARD \
  --server-side-encryption aws:kms \
  --ssekms-key-id "$KMS_KEY_ID"

# Retrieve and display object metadata (no direct equivalent in high-level CLI)
aws s3api head-object \
  --bucket "$BUCKET_NAME" \
  --key "$KEY_NAME"

# Upload a file twice to create versions
echo "Version 1" > /tmp/versioned.txt
aws s3 cp /tmp/versioned.txt s3://$BUCKET_NAME/versioned.txt
echo "Version 2" > /tmp/versioned.txt
aws s3 cp /tmp/versioned.txt s3://$BUCKET_NAME/versioned.txt

# List object versions (low-level only, no high-level equivalent)
echo "Listing versions:"
aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json

###################################################
# Prompt user to continue before deleting versions#
###################################################
read -p "Press Enter to delete all versions in the bucket '$BUCKET_NAME' and proceed with bucket deletion..."

# Delete all versions explicitly 
# you cannot list/delete a specific version of an object using the aws s3 CLI commands, only s3api
echo "Deleting all versions..."
VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json)

# Example visual of VERSIONS JSON output:
#[
#  {
#    "Key": "file1.txt",
#    "VersionId": "3HL4kqtJlcpXroDTDmjVBH40Nrjfkd"
#  },
#  {
#    "Key": "file2.txt",
#    "VersionId": "pJz2z.BuRz6fNs9kSLwLXKMZmhMuS1X"
#  },
#  {
#    "Key": "file1.txt",
#    "VersionId": "axcd34kqtJlcpXroDTxyzBH40Nrj1111"
#  }
#]

# The filter .[] means take each element of the JSON array separately
# The -c flag tells jq to output each element as a compact JSON object on one line (instead of pretty-printed multi-line)
# Using example above, you get ...
# {"Key":"file1.txt","VersionId":"3HL4kqtJlcpXroDTDmjVBH40Nrjfkd"}
# {"Key":"file2.txt","VersionId":"pJz2z.BuRz6fNs9kSLwLXKMZmhMuS1X"}
# {"Key":"file2.txt","VersionId":"axcd34kqtJlcpXroDTxyzBH40Nrj1111"}
for row in $(echo "${VERSIONS}" | jq -c '.[]'); do
  KEY=$(echo "$row" | jq -r '.Key')
  VERSION_ID=$(echo "$row" | jq -r '.VersionId')
  aws s3api delete-object --bucket "$BUCKET_NAME" --key "$KEY" --version-id "$VERSION_ID"
done

# Now delete the bucket (after all versions removed)
aws s3api delete-bucket --bucket "$BUCKET_NAME"

# Cleanup local file
rm /tmp/versioned.txt
rm $LOCAL_FILE
