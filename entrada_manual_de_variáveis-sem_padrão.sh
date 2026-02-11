#!/bin/bash

# Código para adicionar valores à variáveis de forma interativa durante a execução do script.
# Nesse caso, não há variáveis padrão. Assim, o usuário é obrigado a informar os valores das mesmas.
# Se o usuário não informar nenhum valor, o script continuará perguntando pelos mesmos sucessivamente.

#################################################
### ENTRADA DE DADOS E DEFINIÇÃO DE VARIÁVEIS ###
#################################################

# Entrada de dados interativa.
# O loop vai rodar enquanto qualquer uma das variáveis estiver vazia.
while [ -z "$LOCAL" -o -z "$REMOTE" -o -z "$ID" ]; do

    echo "--- Entrada de Dados (Campos Obrigatórios) ---"
    read -p "Caminho da pasta local: " LOCAL
    read -p "Nome do remoto no rclone: " REMOTE
    read -p "ID da pasta no GDrive: " ID

    if [ -z "$LOCAL" -o -z "$REMOTE" -o -z "$ID" ]; then
        echo -e "\nERRO: Todos os campos precisam ser preenchidos!\n"
        # Limpa as variáveis para garantir que o loop pergunte tudo de novo.
        LOCAL=""
        REMOTE=""
        ID=""
    fi
done

# Feedback para o usuário sobre as variáveis que foram definidas.
echo -e "\nVariáveis definidas com sucesso!\n"
echo "Pasta local: $LOCAL."
echo "Nome do remoto no rclone: $REMOTE."
echo "ID da pasta no Google Drive: $ID."
