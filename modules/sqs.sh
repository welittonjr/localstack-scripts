#!/bin/bash
#=======================================
# Author: welittonjr
# Data: 14-04-2022
# Descrição: Script de Funções para SQS
#========================================

# importando funções de helpers
source helpers.sh

# função para criar queue
function create_queue() {
    msgc -yel2 "[Create Queue] >> Informed queue name: "
    read queue
    if [ -z "$queue" ]; then
        tput cuu1 && tput dl1
        msgc -red2 "Queue name must be informed!"
        sleep 1
        create_queue
    else
        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localhost
        else
            msgc -red2 "You need to start the container!"
            exit 0
        fi
        msgc -gre "aws --endpoint-url=http://$HOST:4566 sqs create-queue --queue-name $queue"
        aws --endpoint-url=http://$HOST:4566 sqs create-queue --queue-name $queue
    fi
}

# função para excluir queue
function delete_queue() {
    msgc -yel2 "[Delete Queue] >> Informed queue name: "
    read queue
    if [ -z "$queue" ]; then
        tput cuu1 && tput dl1
        msgc -red2 'Queue name must be informed!'
        sleep 1
        delete_queue
    else
        if [ $RUNNING_IN_CONTAINER ]; then
            HOST=localhost
        else
            msgc -red2 "You need to start the container!"
            exit 0
        fi
        echo "aws --endpoint-url=http://$HOST:4566 sqs get-queue-url --queue-name $1"
        aws --endpoint-url=http://$HOST:4566 sqs get-queue-url --queue-name $1
        if [ $? -eq 0 ]; then
            echo "aws --endpoint-url=http://$HOST:4566 sqs delete-queue --queue-url http://$HOST:4566/000000000000/$1"
            aws --endpoint-url=http://$HOST:4566 sqs delete-queue --queue-url http://$HOST:4566/000000000000/$1
            if [ $? -eq 0 ]; then
                echo "Queue deleted"
            else
                echo "Queue not deleted"
                exit 1
            fi
        else
            echo "Queue doesn't exists"
            exit 1
        fi
    fi
}

# função para listar queue
function list_queue() {
    echo $RUNNING_IN_CONTAINER
    if [ $RUNNING_IN_CONTAINER ]; then
        HOST=localhost
    else
       exit 0
    fi
    msgc -gre "aws --endpoint-url=http://$HOST:4566 sqs list-queues"
    aws --endpoint-url=http://$HOST:4566 sqs list-queues
}

# função para receber mensagem
function receive_message() {
    if [ $RUNNING_IN_CONTAINER ]; then
        HOST=localhost
    else
        msgc -red2 "You need to start the container!"
        exit 0
    fi

    QUEUE=$1
    if [ -z "$QUEUE" ]; then
        QUEUE='http://$HOST:4566/000000000000/test-queue'
    else
        QUEUE=$(basename -- $QUEUE)
        QUEUE="http://$HOST:4566/000000000000/${QUEUE}"
    fi
    echo "aws --endpoint-url=http://$HOST:4566 sqs receive-message --queue-url $QUEUE"
    aws --endpoint-url=http://$HOST:4566 sqs receive-message --queue-url $QUEUE

    if [ ! $? -eq 0 ]; then
        QUEUE="http://$HOST:4566/000000000000/$QUEUE"
        echo "aws --endpoint-url=http://$HOST:4566 sqs receive-message --queue-url $QUEUE"
        aws --endpoint-url=http://$HOST:4566 sqs receive-message --queue-url $QUEUE
    fi
}

clear

# função que verifica se o container está em execução
container_is_running

msgc -bar
msgc -title "SQS"
msgc -bar
menu=(
    "Create Queue"
    "Delete Queue"
    "List Queue"
    "Receive Message"
)
mount_menu "menu"
msgc -bar
selection=$(options_menu 4)
case ${selection} in
    1) create_queue ;;
    2) ./modules/cloudwatch.sh ;;
    3) list_queue ;;
    4) ./modules/s3.sh ;;
    0) exit 0 ;;
esac
