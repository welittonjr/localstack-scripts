#!/bin/bash
#=======================================
# Author: welittonjr
# Data: 14-04-2022
# Descrição: Script de Funções para S3
#========================================

# importando funções de helpers
source helpers.sh

# função para listar buckets S3
function list_buckets() {
    if [ $RUNNING_IN_CONTAINER ]; then
        HOST=localstack
    else
        HOST=0.0.0.0
    fi
    echo "aws --endpoint-url=http://$HOST:4566 s3 ls"
    aws --endpoint-url=http://$HOST:4566 s3 ls
}

# função para listar arquivos
function list_files() {
    if [ $RUNNING_IN_CONTAINER ]; then
        HOST=localstack
    else
        HOST=0.0.0.0
    fi

    BUCKET=$1
    if [ -z "$BUCKET" ]; then
        if [ -z "$APP_BUCKET" ]; then
            BUCKET="test-bucket"
        else
            BUCKET=$APP_BUCKET
        fi
    fi
    echo "aws --endpoint-url=http://$HOST:4566 s3 ls s3://$BUCKET"
    aws --endpoint-url=http://$HOST:4566 s3 ls s3://$BUCKET
}

clear

# função que verifica se o container está em execução
container_is_running

msgc -bar
msgc -title "S3"
msgc -bar
menu=(
    "List Buckets"
    "List Files"
)
mount_menu "menu"
msgc -bar
selection=$(options_menu 2)
case ${selection} in
    1) list_buckets ;;
    2) list_files ;;
    0) exit 0 ;;
esac