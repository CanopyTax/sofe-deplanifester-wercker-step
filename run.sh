#!/bin/bash
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

mkdir -p ~/.aws/
echo -e "[default]\nregion=$WERCKER_DEPLOY_SOFE_SERVICE_S3_REGION\naws_access_key_id = $WERCKER_DEPLOY_SOFE_SERVICE_S3_ACCESS_KEY\naws_secret_access_key = $WERCKER_DEPLOY_SOFE_SERVICE_S3_SECRET_KEY\n" > ~/.aws/config
aws s3 sync "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR" "s3://$WERCKER_DEPLOY_SOFE_SERVICE_S3_LOCATION"

DSS_VERSION=$(ls "/pipeline/source/$WERCKER_DEPLOY_SOFE_SERVICE_UPLOAD_DIR/")
DSS_STATUSCODE=$(curl --silent --output /dev/stderr --write-out "%{http_code}" -d "{ \"service\":\"$WERCKER_DEPLOY_SOFE_SERVICE_SOFE_SERVICE_NAME\",\"url\":\"https://$WERCKER_DEPLOY_SOFE_SERVICE_S3_LOCATION/$DSS_VERSION/$WERCKER_DEPLOY_SOFE_SERVICE_MAIN_FILE\" }" -X PATCH "$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_URL/services?env=$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_ENV" -H "Accept: application/json" -k -H "Content-Type: application/json" -u "$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_USERNAME:$WERCKER_DEPLOY_SOFE_SERVICE_DEPLANIFESTER_PASSWORD")

if test $STATUSCODE -ne 200; then
    exit 1;
fi
