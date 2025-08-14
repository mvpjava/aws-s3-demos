#!/bin/bash
# Usage: ./assume_role.sh <AWS_ACCOUNT_ID> <ROLE_NAME>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <AWS_ACCOUNT_ID> <ROLE_NAME>"
    exit 1
fi

ACCOUNT_ID=$1
ROLE_NAME=$2
SESSION_NAME="${ROLE_NAME}session"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Assuming role: $ROLE_ARN with session name: $SESSION_NAME"

# Run assume-role once and capture everything in one go
read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN EXPIRATION <<< $(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken,Expiration]" \
  --output text)

# Export the credentials
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "Temporary credentials exported:"
echo "  AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
echo "  AWS_SECRET_ACCESS_KEY=[HIDDEN]"
echo "  AWS_SESSION_TOKEN=[HIDDEN]"
echo "Credentials expire at: $EXPIRATION UTC"

