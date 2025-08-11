#!/bin/sh

#Example Usage: ./rm-all-s3-objs-ver.sh mybucket

YOUR_BUCKET_NAME=$1

# Get the list of objects with versions
 objects=$(aws s3api list-object-versions --bucket $YOUR_BUCKET_NAME --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')
echo $objects

# # Delete the objects
 aws s3api delete-objects --bucket $YOUR_BUCKET_NAME --delete "$objects"

