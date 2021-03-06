#!/bin/bash -e
# $WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR
# $WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE
# $WERCKER_DEPLOY_SOFE_SERVICE_S3_REGION
# $WERCKER_DEPLOY_SOFE_SERVICE_S3_ACCESS_KEY
# $WERCKER_DEPLOY_SOFE_SERVICE_S3_SECRET_KEY
# $WERCKER_DEPLOY_SOFE_SERVICE_S3_LOCATION
# $WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_ENV
# $WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_URL
# $WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_USERNAME
# $WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_PASSWORD
# $WERCKER_DEPLOY_SOFE_SERVICE_SOFE_SERVICE_NAME
# $WERCKER_DEPLOY_SOFE_SERVICE_DEBUG


DSS_VERSION=$(ls "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/")
mkdir -p ~/.aws/
# Create access key file so we dont mess up any env_vars
echo -e "[default]\nregion=$WERCKER_DEPLOY_SOFE_SERVICE_S3_REGION\naws_access_key_id = $WERCKER_DEPLOY_SOFE_SERVICE_S3_ACCESS_KEY\naws_secret_access_key = $WERCKER_DEPLOY_SOFE_SERVICE_S3_SECRET_KEY\n" > ~/.aws/config


if [ "$WERCKER_DEPLOY_SOFE_SERVICE_DEBUG" == 'true' ]
then
  head "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/$DSS_VERSION/$WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE"
fi

echo "$(file --mime-type -b ./$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/$DSS_VERSION/$WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE)"
if [[ "$(file --mime-type -b ./$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/$DSS_VERSION/$WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE)" =~ 'gzip' ]]
then
echo "already gziped!"
else
# gzip the files in place
find "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/" -type f -exec gzip "{}" \; -exec echo "{}" \; -exec mv "{}.gz" "{}" \;
fi

# Upload all the files
aws s3 sync "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR" "s3://$WERCKER_DEPLOY_SOFE_SERVICE_S3_LOCATION" --content-encoding gzip --cache-control "public, max-age=31556926"

# To get curl to output the response contents but store the http status in a variable, you have to create a file descriptor and redirect curl output to it.
# See http://superuser.com/questions/272265/getting-curl-to-output-http-status-code
exec 3>&1

# Deploy using the deplanifester
request="{ \"service\":\"$WERCKER_DEPLOY_SOFE_SERVICE_SOFE_SERVICE_NAME\",\"url\":\"https://$WERCKER_DEPLOY_SOFE_SERVICE_S3_LOCATION/$DSS_VERSION/$WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE\" }"
patchURL="$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_URL/services?env=$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_ENV"
echo "Patch $patchURL with"
echo "$request"

STATUSCODE=$(curl -w '%{http_code}' -o >(cat >&3) -d "$request" -X PATCH "$patchURL" -H "Accept: application/json" -k -H "Content-Type: application/json" -u "$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_USERNAME:$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_PASSWORD")

echo # New line
echo "Deplanifester status code was ${STATUSCODE}"
echo # New line

if test $STATUSCODE -ne 200;
then
	echo "Failed to deploy sofe service. Deplanifester returned http status ${STATUSCODE}"
	exit 1
else
	echo "Successful deployment of sofe service"
fi
