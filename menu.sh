#!/bin/bash
#=======================================
# Author: Github@welittonjr
# Data: 14-04-2022
# Descrição: Script de Funções LocalStack
#========================================

# importando funções de helpers
source helpers.sh

clear
msgc -bar
msgc -title "LOCALSTACK"
msgc -bar
menu=(
    "Functions SQS"
    "Functions CloudWatch"
    "Functions Lambda"
    "Functions S3"
)
mount_menu "menu"
msgc -bar
selection=$(options_menu 4)
case ${selection} in
    1) ./modules/sqs.sh ;;
    2) ./modules/cloudwatch.sh ;;
    3) ./modules/lambda.sh ;;
    4) ./modules/s3.sh ;;
    0) exit 0 ;;
esac