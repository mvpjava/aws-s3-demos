#!/bin/bash
set -e  # exit on error

# Step 1: Create nested directory structure
 mkdir -p dir1/dir2/dir3

# # Step 2: Create empty test files in each directory
touch dir1/file1 dir1/file2 dir1/file3
touch dir1/dir2/file1 dir1/dir2/file2 dir1/dir2/file3
touch dir1/dir2/dir3/file1 dir1/dir2/dir3/file2 dir1/dir2/dir3/file3

echo "Local directory structure with files created."

# Step 3: Create S3 bucket with random suffix
RAND_STR=$(date +%s%N | sha256sum | head -c 8)
BUCKET_NAME="s3-sync-demo-${RAND_STR}"

aws s3 mb "s3://${BUCKET_NAME}"
echo "Created bucket: ${BUCKET_NAME}"

# Step 4: Sync local directory to S3 bucket
aws s3 sync dir1 "s3://${BUCKET_NAME}"

echo "Local files synced to bucket: ${BUCKET_NAME}"

# Step 5: List all objects recursively in S3
echo "Listing all objects in S3 bucket:"
aws s3 ls "s3://${BUCKET_NAME}" --recursive

# Step 6: Prompt user to delete the bucket recursively
read -p "Press Enter to delete the bucket '${BUCKET_NAME}' recursively..."

aws s3 rb "s3://${BUCKET_NAME}" --force
echo "Bucket ${BUCKET_NAME} deleted."

rm -fr dir1
