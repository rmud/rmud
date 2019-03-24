#!/bin/sh
HOSTNAME="$1"
EMAIL="$2"
PASSWORD="$3"
FROM="$4"
TO="$5"

curl -v --url "smtp://$HOSTNAME:587" --ssl-reqd \
  --mail-from "$FROM" --mail-rcpt "$TO" \
  --upload-file - --user "$EMAIL:$PASSWORD" --insecure
