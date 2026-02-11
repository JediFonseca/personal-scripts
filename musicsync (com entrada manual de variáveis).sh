#!/bin/bash

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

###########################################
### CHECAGEM POR PARÂMETROS DE EXECUÇÃO ###
###########################################

# Verifica se o primeiro parâmetro ($1) é --sim
if [ "$1" == "--sim" ]; then
    SIMULAR="--dry-run"
    echo -e "${YELLOW}Esse script irá SIMULAR a sincronização da pasta \"$LOCAL\" com o Google Drive.${NOCOLOR}"
    echo -e "${YELLOW}Nenhum arquivo no GDrive ou no PC será copiado, apagado ou modificado.${NOCOLOR}"
else
    SIMULAR=""
    echo -e "${YELLOW}Esse script irá sincronizar todos os arquivos da pasta \"$LOCAL\" com o Google Drive.${NOCOLOR}"
    echo -e "${RED}Essa operação irá espelhar a pasta do PC no GDrive e não o contrário.${NOCOLOR}"
    echo -e "${RED}Arquivos no GDrive que não estão no PC serão APAGADOS!${NOCOLOR}"
fi

#############################
### FASE DE SINCRONIZAÇÃO ###
#############################

echo -e "${YELLOW}Pressione ENTER para continuar ou CTRL+C para cancelar.${NOCOLOR}"
read

echo -e "${BLUE}Iniciando a sincronização...${NOCOLOR}"

rclone sync "$LOCAL" "$REMOTE,root_folder_id=$ID:" $SIMULAR -P

echo -e "${BLUE}Sincronização finalizada.${NOCOLOR}"

