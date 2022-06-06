#!/bin/bash

#=======================================
# Author: welittonjr
# Data: 14-04-2022
# Descrição: Script de Funções LocalStack
#========================================

# nome do container que será executado o script
readonly CONTAINER_NAME="stack-bash_localstack_1"
# variavel que diz se o container está sendo executado ou não
declare RUNNING_IN_CONTAINER=0

# função de mostrar mensagem colorida
function msgc() {
    COLOR[0]='\033[1;37m' #BRAN='\033[1;37m'
    COLOR[1]='\e[31m'     #VERMELHO='\e[31m'
    COLOR[2]='\e[32m'     #VERDE='\e[32m'
    COLOR[3]='\e[33m'     #AMARELO='\e[33m'
    COLOR[4]='\e[34m'     #AZUL='\e[34m'
    COLOR[5]='\e[91m'     #MAGENTA='\e[35m'
    COLOR[6]='\033[1;97m' #MAG='\033[1;36m'

    BOLD='\e[1m'
    WITHOUTCOLOR='\e[0m'
    case $1 in
    -title) echo -e "\033[1;41m\t\t | SCRIPTS ${2} | \033[1;49m " ;;
    -ne) cor="${COLOR[1]}${BOLD}" && echo -ne "${cor}${2}${WITHOUTCOLOR}" ;;
    -yel) cor="${COLOR[3]}${BOLD}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -yel2) cor="${COLOR[3]}${BOLD}" && echo -ne "${cor}${2}${WITHOUTCOLOR}" ;;
    -red) cor="${COLOR[3]}${BOLD}[!] ${COLOR[1]}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -red2) cor="${COLOR[1]}${BOLD}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -blu) cor="${COLOR[6]}${BOLD}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -gre) cor="${COLOR[2]}${BOLD}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -whi) cor="${COLOR[0]}${BOLD}" && echo -e "${cor}${2}${WITHOUTCOLOR}" ;;
    -whi2) cor="${COLOR[0]}${BOLD}" && echo -ne "${cor}${2}${WITHOUTCOLOR}" ;;
    -bar) cor="${COLOR[1]}————————————————————————————————————————————————————" && echo -e "${WITHOUTCOLOR}${cor}${WITHOUTCOLOR}" ;;
    esac
}

# função de montar menu vertical
function mount_menu() {
    for ((num = 0; num < ${#menu[@]}; num++)); do
        echo -e " $(msgc -gre "[$(($num + 1))]") $(msgc -red2 "=>>") $(msgc -whi "${menu[$num]}")"
        if [ $(($num + 1)) -eq ${#menu[@]} ]; then
            msgc -bar
            echo -e " $(msgc -gre "[0]") $(msgc -red2 "=>>") $(msgc -whi "Exit")"
        fi
    done
}

# função de opção de menu
function options_menu() {
    local selection="null"
    local range
    local qtd_items_menu=$1
    for ((i = 0; i < $qtd_items_menu; i++)); do range[$i]="$i "; done
    while [[ ! $(echo ${range[*]} | grep -w "$selection") ]]; do
        msgc -whi2 " ► Select an option: " >&2
        read selection
        tput cuu1 >&2 && tput dl1 >&2
    done
    echo $selection
}

# função verificar se container está em execução
function container_is_running() {
    CID=$(docker ps -q -f status=running -f name=^/${CONTAINER_NAME}$)
    if [ ! "${CID}" ]; then
        RUNNING_IN_CONTAINER=0
    else
        RUNNING_IN_CONTAINER=1
    fi
}
