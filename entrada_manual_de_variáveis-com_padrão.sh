#!/bin/bash

# Código para adicionar valores à variáveis de forma interativa durante a execução do script.
# Se o usuário não informar nenhum valor, o script utilizará as variáveis padrão pré estabelecidas.

# Definição de cores.
BLUE='\033[0;36m'  # Ciano.
YELLOW='\033[1;33m'   # Amarelo.
RED='\033[0;31m' # Vermelho.
NOCOLOR='\033[0m' # Reseta a cor para o padrão do terminal.

#################################################
### ENTRADA DE DADOS E DEFINIÇÃO DE VARIÁVEIS ###
#################################################

# Valor padrão caso o usuário não digite nada.
LOCAL_PADRAO="/mnt/Músicas/Minhas Músicas/"
REMOTE_PADRAO="gdrive"
ID_PADRAO="1WaU8_MxTIr3Y9O3ie43NzbfTXi6fKWLo"

# Entrada de dados interativa.
echo "${RED}--- Entrada de Dados (Campos Obrigatórios) ---${NOCOLOR}"
read -p "${YELLOW}Caminho da pasta local: ${NOCOLOR}" LOCAL
read -p "${YELLOW}Nome do remoto no rclone: ${NOCOLOR}" REMOTE
read -p "${YELLOW}ID da pasta no GDrive: ${NOCOLOR}" ID

# Checa se as variáveis utilizadas serão as padrões ou as personalizadas e as informa ao usuário.
if [ -z "$LOCAL" ]; then
    LOCAL=$LOCAL_PADRAO
    echo "${YELLOW}O remoto escolhido foi o padrão: $LOCAL${NOCOLOR}"
else
    echo "${YELLOW}O remoto \"$LOCAL\" foi selecionado.${NOCOLOR}"
fi

if [ -z "$REMOTE" ]; then
    REMOTE=$REMOTE_PADRAO
    echo "${YELLOW}O remoto escolhido foi o padrão: $REMOTE${NOCOLOR}"
else
    echo "${YELLOW}O remoto \"$REMOTE\" foi selecionado.${NOCOLOR}"
fi

if [ -z "$ID" ]; then
    ID=$ID_PADRAO
    echo "${YELLOW}O remoto escolhido foi o padrão: $ID${NOCOLOR}"
else
    echo "${YELLOW}O remoto \"$ID\" foi selecionado.${NOCOLOR}"
fi
