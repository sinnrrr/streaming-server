#!/bin/sh

# Entry point to mount s3fs filesystem before exec'ing command.

# Fail on all script errors
set -e

[ "${DEBUG:-false}" = 'true' ] && {
	set -x

	S3FS_DEBUG='-o dbglevel=dbg -o curldbg -f'
}

# If no command specified, print error
[ "$1" = "" ] && set -- "$@" bash -c 'echo "Error: Please specify a command to run."; exit 128'

# Configuration checks
if [ "$S3_BUCKET_NAME" = "" ]; then
	echo "Error: S3_BUCKET_NAME is not specified"
	exit 128
fi

if [ ! -f "$S3_AUTHFILE" ] && [ "$ACCESS_KEY_ID" = "" ]; then
	echo "Error: ACCESS_KEY_ID not specified, or $S3_AUTHFILE not provided"
	exit 128
fi

if [ ! -f "$S3_AUTHFILE" ] && [ "$SECRET_ACCESS_KEY" = "" ]; then
	echo "Error: SECRET_ACCESS_KEY not specified, or $S3_AUTHFILE not provided"
	exit 128
fi

# Write auth file if it does not exist
if [ ! -f "$S3_AUTHFILE" ]; then
	echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY" >"$S3_AUTHFILE"
	chmod 600 "$S3_AUTHFILE"
fi

echo "==> Mounting S3 Filesystem $S3_MOUNTPOINT"
mkdir -p "$S3_MOUNTPOINT"

# s3fs mount command
s3fs "$S3_BUCKET_NAME" "$S3_MOUNTPOINT" \
	-o "allow_other" \
	-o "passwd_file=$S3_AUTHFILE" \
	-o "url=$S3_URL" \
	-o "endpoint=$S3_REGION" \
	$S3FS_DEBUG $S3FS_ARGS

# see https://github.com/efriandika/streaming-server/issues/3
sleep 5

envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" </etc/nginx/nginx.conf.template >/etc/nginx/nginx.conf &&
	nginx
