#!/bin/bash
#=======================================
# Author: welittonjr
# Data: 14-04-2022
# Descrição: Script de Funções Lambda
#========================================

# importando funções de helpers
source helpers.sh

function create_event_sourcing_map() {
    if [ -z "$1" ]; then
        echo 'Function name must be informed'
        exit 1
    else
        if [ -z "$2" ]; then
            echo 'Queue name must be informed'
            exit 1
        else
            if [ $RUNNING_IN_CONTAINER ]; then
                HOST=localstack
            else
                HOST=0.0.0.0
            fi
            REGION=us-east-1
            echo "aws --endpoint-url=http://$HOST:4566 lambda create-event-source-mapping \
                    --function-name arn:aws:lambda:$REGION:000000000000:function:$1 \
                    --event-source-arn arn:aws:sqs:$REGION:000000000000:$2"

            aws --endpoint-url=http://$HOST:4566 lambda create-event-source-mapping \
                --function-name arn:aws:lambda:$REGION:000000000000:function:$1 \
                --event-source-arn arn:aws:sqs:$REGION:000000000000:$2

            #--event-source-arn arn:aws:sqs:elasticmq:000000000000:$2
        fi
    fi
}

function create_func_from_s3() {
    debug=false
    parent_folder="../"
    current_path=$(pwd)/
    current_path_basename=$(basename $(pwd))
    current_file_full_path=$0
    # echo $current_filepath
    current_file_name=$(basename -- "$0")
    # echo $current_filename
    if [ $current_file_full_path = $current_file_name ] || [ $current_file_full_path = "./$current_file_name" ]; then
        current_file_full_path="./${current_file_full_path}"
        current_file_path="./"
    else
        current_file_path="${current_file_full_path/$current_file_name/''}"
    fi

    current_file_path_basename=$(basename -- "$current_file_path")

    if [ -z "$current_file_path_basename" ] || [ $current_file_path = "./" ]; then
        #  echo 'aq'
        current_parent_folder="../"
    else
        #  echo 'naq'
        current_file_path_basename=$current_file_path_basename/
        current_parent_folder="${current_file_path/$current_file_path_basename/''}"
    fi

    if [ debug ]; then
        echo '----------------------------------------'
        echo "$0 - Script variables"
        echo '----------------------------------------'
        echo "current_path: $current_path"
        echo "current_path_basename: $current_path_basename"
        echo "current_file_full_path: $current_file_full_path"
        echo "current_file_name: $current_file_name"
        echo "current_file_path: $current_file_path"
        echo "current_parent_folder: $current_parent_folder"
        echo '----------------------------------------'
    fi

    if [ -z "$1" ]; then
        echo 'Function name must be informed'
        exit 1
    else

        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        HANDLER=$2
        REGION=us-east-1
        if [ -z "$2" ]; then
            HANDLER="app.index"
        fi

        if [ ! -z "$3" ]; then
            FUNCTION_PATH=$1
            FUNCTION_NAME=$2
            HANDLER=$3
        fi

        echo '----------------------------------------'
        echo "$0 - Checking lambda function path"
        echo '----------------------------------------'
        if test "${current_path_basename}" = "${FUNCTION_PATH}"; then
            echo 'current folder is the same of the function'
            FUNCTION_PATH=$current_path
        else
            echo 'current folder is not the same of the function'
            FUNCTION_PATH="${current_parent_folder/scripts\/localstack\//''}"
        fi

        read -p "Press enter to continue..."

        echo '----------------------------------------'
        echo "$0 - Checking previous installation"
        echo '----------------------------------------'
        # zip full code
        if test -f ${FUNCTION_PATH}lambda-full.zip; then
            echo 'Removing old zip file...'
            rm ${FUNCTION_PATH}lambda-full.zip
        else
            echo 'There is no previous installation'
        fi

        read -p "Press enter to continue..."

        echo '----------------------------------------'
        echo "$0 - Script Function variables"
        echo '----------------------------------------'
        echo "Function name: $FUNCTION_NAME"
        echo "Function path: $FUNCTION_PATH"
        echo "Function handler: $HANDLER"
        echo '----------------------------------------'

        echo '----------------------------------------'
        echo "$0 - Zipping lambda data from ${FUNCTION_PATH}"
        echo '----------------------------------------'
        LAST_PWD=$(pwd)
        cd ${FUNCTION_PATH}
        zip -q -r ./lambda-full.zip ./ -x '*.git*' -x "./zip.sh*" -x "./venv/*" -x "./.idea/*" -x "./lambda-full.zip"
        echo "zip file created in ${FUNCTION_PATH}lambda-full.zip"
        cd ${LAST_PWD}

        read -p "Press enter to continue..."

        echo '----------------------------------------'
        echo "$0 - Preparing bucket operations"
        echo '----------------------------------------'
        echo 'Try to list'
        echo "aws --endpoint-url=http://$HOST:4566 s3api list-objects --bucket test > /dev/null 2>&1"
        aws --endpoint-url=http://$HOST:4566 s3api list-objects --bucket test >/dev/null 2>&1

        if [ $? -ne 0 ]; then
            echo 'Create the bucket'
            echo "aws --endpoint-url=http://$HOST:4566 s3 mb s3://test"
            aws --endpoint-url=http://$HOST:4566 s3 mb s3://test
        fi

        echo '----------------------------------------'
        echo "$0 - Copy lambda zip file to S3"
        echo '----------------------------------------'
        echo "aws --endpoint-url=http://$HOST:4566 s3 cp ${FUNCTION_PATH}lambda-full.zip s3://test"
        aws --endpoint-url=http://$HOST:4566 s3 cp ${FUNCTION_PATH}lambda-full.zip s3://test

        read -p "Press enter to continue..."

        echo '----------------------------------------'
        echo "$0 - Check if the lambda function exits"
        echo '----------------------------------------'
        echo "aws --endpoint-url=http://$HOST:4566 lambda get-function --function-name $FUNCTION_NAME --region $REGION > /dev/null 2>&1"
        aws --endpoint-url=http://$HOST:4566 lambda get-function --function-name $FUNCTION_NAME --region $REGION >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo 'Delete the last lambda'
            echo "aws --endpoint-url=http://$HOST:4566 lambda delete-function --function-name $FUNCTION_NAME --region $REGION"
            aws --endpoint-url=http://$HOST:4566 lambda delete-function --function-name $FUNCTION_NAME --region $REGION
        fi

        echo '----------------------------------------'
        echo "$0 - Creating the environment variables"
        echo '----------------------------------------'

        if test -d ${FUNCTION_PATH}.chalice; then
            ENVIRONMENT_VARIABLES=$(jq '.stages.dev.environment_variables' ${FUNCTION_PATH}.chalice/config.json -c)
        else
            ENVIRONMENT_VARIABLES=$(python3 ${FUNCTION_PATH}scripts/tools/python/env-to-json.py ${FUNCTION_PATH}env/development.env)
        fi

        echo "ENVIRONMENT_VARIABLES: ${ENVIRONMENT_VARIABLES}"
        #  echo "{\"Variables\": $ENVIRONMENT_VARIABLES }"
        #  echo {"Variables": $ENVIRONMENT_VARIABLES} > environment.json

        read -p "Press enter to continue..."

        echo '----------------------------------------'
        echo "$0 - Creating the lambda function"
        echo '----------------------------------------'
        echo "aws --endpoint-url=http://$HOST:4566 lambda create-function \
   --function-name arn:aws:lambda:$REGION:000000000000:function:$FUNCTION_NAME \
   --runtime python3.6 --handler $HANDLER --memory-size 128 \
   --code S3Bucket=test,S3Key=lambda-full.zip --role arn:aws:iam:awslocal \
   --environment \"{\"Variables\": $ENVIRONMENT_VARIABLES}\""

        aws --endpoint-url=http://$HOST:4566 lambda create-function \
            --function-name arn:aws:lambda:$REGION:000000000000:function:$FUNCTION_NAME \
            --runtime python3.6 --handler $HANDLER --memory-size 128 \
            --code S3Bucket=test,S3Key=lambda-full.zip --role arn:aws:iam:awslocal \
            --environment "{\"Variables\": $ENVIRONMENT_VARIABLES }"
        #--environment Variables="{ENVIRONMENT_NAME=development}"
        # --environment file://environment.json

    fi
}

function create_func_from_vendor() {
    if [ -z "$1" ]; then
        echo 'Function path must be informed'
        exit 1
    else
        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        LAYER_NAME=$2
        LAYER_DESCRIPTION=$3

        #  if [ ! -z "$3" ]; then
        #    FUNCTION_PATH=$1
        #    FUNCTION_NAME=$2
        #    HANDLER=$3
        #  fi

        if [ -z "$LAYER_NAME" ]; then
            LAYER_NAME="$FUNCTION_PATH-layer"
        fi
        if [ -z "$LAYER_DESCRIPTION" ]; then
            LAYER_DESCRIPTION="$FUNCTION_PATH-layer"
        fi

        echo "Function name: $FUNCTION_NAME"
        echo "Function path: $FUNCTION_PATH"
        echo "Layer name: $LAYER_NAME"
        echo "Layer description: $LAYER_DESCRIPTION"

        # zip only code
        cd ./$FUNCTION_PATH
        python3 -m pip install -r requirements-vendor.txt -t ./layer
        zip ../layer.zip -r ./layer
        rm -Rf ./layer
        cd ../

        echo "aws --endpoint-url=http://$HOST:4566 lambda publish-layer-version --layer-name $LAYER_NAME \
                --description $LAYER_DESCRIPTION --zip-file fileb://layer.zip --compatible-runtimes \"python3.6\" \"python3.8\""

        aws --endpoint-url=http://$HOST:4566 lambda publish-layer-version --layer-name $LAYER_NAME \
            --description $LAYER_DESCRIPTION --zip-file fileb://layer.zip --compatible-runtimes "python3.6" "python3.8"

        echo "aws --endpoint-url=http://$HOST:4566 lambda update-function-configuration \
                --layers arn:aws:lambda:us-east-1:000000000000:layer:$LAYER_NAME:1 --function-name $FUNCTION_NAME"

        aws --endpoint-url=http://$HOST:4566 lambda update-function-configuration \
            --layers arn:aws:lambda:us-east-1:000000000000:layer:$LAYER_NAME:1 --function-name $FUNCTION_NAME

    fi
}

function create_layer() {
    if [ -z "$1" ]; then
        echo 'Function path must be informed'
        exit 1
    else
        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        LAYER_NAME=$2
        LAYER_DESCRIPTION=$3

        if [ -z "$LAYER_NAME" ]; then
            LAYER_NAME="$FUNCTION_PATH-layer"
        fi
        if [ -z "$LAYER_DESCRIPTION" ]; then
            LAYER_DESCRIPTION="$FUNCTION_PATH-layer"
        fi

        if test -f "$FUNCTION_PATH/requirements-layers.txt"; then
            input="$FUNCTION_PATH/requirements-layers.txt"
            while IFS= read -r arn; do
                echo "current arn: $arn"
                echo "aws --endpoint-url=http://$HOST:4566 lambda update-function-configuration \
     --layers $arn --function-name $FUNCTION_NAME"

                aws --endpoint-url=http://$HOST:4566 lambda update-function-configuration \
                    --layers $arn --function-name $FUNCTION_NAME
            done <"$input"
        fi
    fi
}

function invoke_func_api() {
    if [ -z "$1" ]; then
        echo 'Function name must be informed'
        exit 1
    else

        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        if test -d ./$FUNCTION_PATH; then
            PAYLOAD=./$FUNCTION_PATH/samples/localstack/api_request_sample.json
        else
            PAYLOAD=./samples/localstack/api_request_sample.json
        fi

        echo "Function name: $FUNCTION_NAME"
        echo "Function path: $FUNCTION_PATH"
        echo "Function ARN arn:aws:lambda:us-east-1:000000000000:$FUNCTION_NAME"

        echo "aws --endpoint-url=http://$HOST:4566 lambda invoke \
  --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
  --invocation-type RequestResponse \
  --payload file://$PAYLOAD ./output/response.json \
  --log-type Tail --query 'LogResult' --output text |  base64 -d"

        if ! test -d ./output; then
            echo 'creating dir ./output'
            mkdir ./output
        fi

        aws --endpoint-url=http://$HOST:4566 lambda invoke \
            --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
            --invocation-type RequestResponse \
            --payload file://$PAYLOAD ./output/response.json \
            --log-type Tail --query 'LogResult' --output text | base64 -d

        echo "\nResponse"
        echo 'cat ./output/response.json'
        cat ./output/response.json

    #  echo $PAYLOAD
    #  cat $PAYLOAD
    fi
}

function invoke_function() {
    if [ -z "$1" ]; then
        echo 'Function name must be informed'
        exit 1
    else

        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        PAYLOAD=$2

        if [ -z "$2" ]; then
            PAYLOAD='{ "key": "value" }'
        fi

        echo "Function name: $FUNCTION_NAME"
        echo "Function path: $FUNCTION_PATH"
        echo "Function ARN arn:aws:lambda:us-east-1:000000000000:$FUNCTION_NAME"

        echo "aws --endpoint-url=http://$HOST:4566 lambda invoke \
                --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
                --payload $PAYLOAD ./output/response.json \
                --log-type Tail --query 'LogResult' --output text |  base64 -d"

        if ! test -d ./output; then
            echo 'creating dir ./output'
            mkdir ./output
        fi

        aws --endpoint-url=http://$HOST:4566 lambda invoke \
            --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
            --payload "$PAYLOAD" ./output/response.json \
            --log-type Tail --query 'LogResult' --output text | base64 -d

    fi
}

function invoke_func_sqs() {
    if [ -z "$1" ]; then
        echo 'Function name must be informed'
        exit 1
    else

        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localstack
        else
            HOST=0.0.0.0
        fi
        FUNCTION_PATH=$1
        FUNCTION_NAME=$1
        if test -d ./$FUNCTION_PATH; then
            PAYLOAD=./$FUNCTION_PATH/samples/localstack/sqs_sample.json
        else
            PAYLOAD=./samples/localstack/sqs_sample.json
        fi

        echo "Function name: $FUNCTION_NAME"
        echo "Function path: $FUNCTION_PATH"
        echo "Function ARN arn:aws:lambda:us-east-1:000000000000:$FUNCTION_NAME"

        echo "aws --endpoint-url=http://$HOST:4566 lambda invoke \
  --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
  --invocation-type RequestResponse \
  --payload file://$PAYLOAD ./output/response.json \
  --log-type Tail --query 'LogResult' --output text |  base64 -d"

        if ! test -d ./output; then
            echo 'creating dir ./output'
            mkdir ./output
        fi

        aws --endpoint-url=http://$HOST:4566 lambda invoke \
            --function-name arn:aws:lambda:us-east-1:000000000000:function:$FUNCTION_NAME \
            --invocation-type RequestResponse \
            --payload file://$PAYLOAD ./output/response.json \
            --log-type Tail --query 'LogResult' --output text | base64 -d

        echo "\nResponse"
        echo 'cat ./output/response.json'
        cat ./output/response.json

    #  echo $PAYLOAD
    #  cat $PAYLOAD
    fi
}

function list_functions() {
    if [ $RUNNING_IN_CONTAINER ]; then
        HOST=localstack
    else
        HOST=0.0.0.0
    fi
    aws --endpoint-url=http://$HOST:4566 lambda list-functions --master-region us-east-1
    aws --endpoint-url=http://localhost:4566 lambda list-functions --master-region us-east-2
}

clear

# função que verifica se o container está em execução
container_is_running

msgc -bar
msgc -title "Lambda"
msgc -bar
menu=(
    "Create Event Sourcing Map"
    "Create Function From S3"
    "Create Function From Vendor"
    "Create Layer"
    "Invoke Function  API"
    "Invoke Function"
    "Invoke Function SQS"
    "List Functions"
)
mount_menu "menu"
msgc -bar
selection=$(options_menu 8)
case ${selection} in
    1) list_functions ;;
    2) list_functions ;;
    3) list_functions ;;
    4) list_functions ;;
    6) list_functions ;;
    7) list_functions ;;
    8) list_functions ;;
    0) exit 0 ;;
esac
