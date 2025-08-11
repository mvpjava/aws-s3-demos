#!/bin/sh

BUCKET_NAME="demo-high-level-$RANDOM"
KEY_NAME="hello.txt"
LOCAL_FILE="/tmp/$KEY_NAME"

touch $LOCAL_FILE

# Prepare file
echo "Hello from high-level API" > "$LOCAL_FILE"

# Create bucket
aws s3 mb "s3://$BUCKET_NAME"

# Upload file (simple, no metadata or storage class control)
aws s3 cp "$LOCAL_FILE" "s3://$BUCKET_NAME/$KEY_NAME"

# Show result
echo "Listing bucket contents ..."
aws s3 ls "s3://$BUCKET_NAME/"

read -p "Press Enter key to delete bucket with all objects"

# Cleanup all objects in bucket then bucket itself
aws s3 rb "s3://$BUCKET_NAME" --force
rm "$LOCAL_FILE"
