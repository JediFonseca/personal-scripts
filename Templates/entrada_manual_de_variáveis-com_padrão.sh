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
echo -e "${RED}--- Entrada de Dados (Campos Obrigatórios) ---${NOCOLOR}"
read -p "Caminho da pasta local: " LOCAL
read -p "Nome do remoto no rclone: " REMOTE
read -p "ID da pasta no GDrive: " ID

# Checa se as variáveis utilizadas serão as padrões ou as personalizadas e as informa ao usuário.
if [ -z "$LOCAL" ]; then
    LOCAL=$LOCAL_PADRAO
    echo -e "O local escolhido foi o padrão: ${YELLOW}$LOCAL${NOCOLOR}."
else
    echo -e "O local ${YELLOW}$LOCAL${NOCOLOR} foi selecionado."
fi

if [ -z "$REMOTE" ]; then
    REMOTE=$REMOTE_PADRAO
    echo -e "O remoto escolhido foi o padrão: ${YELLOW}$REMOTE${NOCOLOR}."
else
    echo -e "O remoto ${YELLOW}$REMOTE${NOCOLOR} foi selecionado."
fi

if [ -z "$ID" ]; then
    ID=$ID_PADRAO
    echo -e "O ID escolhido foi o padrão: ${YELLOW}$ID${NOCOLOR}."
else
    echo -e "O ID ${YELLOW}$ID${NOCOLOR} foi selecionado."
fi
