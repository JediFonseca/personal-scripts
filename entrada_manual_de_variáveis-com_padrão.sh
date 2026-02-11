#!/bin/bash

# Código para adicionar valores à variáveis de forma interativa durante a execução do script.
# Se o usuário não informar nenhum valor, o script utilizará as variáveis padrão pré estabelecidas.

#################################################
### ENTRADA DE DADOS E DEFINIÇÃO DE VARIÁVEIS ###
#################################################

# Valor padrão caso o usuário não digite nada.
LOCAL_PADRAO="/mnt/Músicas/Minhas Músicas/"
REMOTE_PADRAO="gdrive"
ID_PADRAO="1WaU8_MxTIr3Y9O3ie43NzbfTXi6fKWLo"

# Entrada de dados interativa.
echo "--- Entrada de Dados (Campos Obrigatórios) ---"
read -p "Caminho da pasta local: " LOCAL
read -p "Nome do remoto no rclone: " REMOTE
read -p "ID da pasta no GDrive: " ID

# Checa se as variáveis utilizadas serão as padrões ou as personalizadas e as informa ao usuário.
if [ -z "$LOCAL" ]; then
    LOCAL=$LOCAL_PADRAO
    echo "O remoto escolhido foi o padrão: $LOCAL"
else
    echo "O remoto \"$LOCAL\" foi selecionado."
fi

if [ -z "$REMOTE" ]; then
    REMOTE=$REMOTE_PADRAO
    echo "O remoto escolhido foi o padrão: $REMOTE"
else
    echo "O remoto \"$REMOTE\" foi selecionado."
fi

if [ -z "$ID" ]; then
    ID=$ID_PADRAO
    echo "O remoto escolhido foi o padrão: $ID"
else
    echo "O remoto \"$ID\" foi selecionado."
fi
