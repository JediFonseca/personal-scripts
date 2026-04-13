#!/bin/bash

# Código para adicionar valores à variáveis de forma interativa durante a execução do script.
# Nesse caso, não há variáveis padrão. Assim, o usuário é obrigado a informar os valores das mesmas.
# Se o usuário não informar nenhum valor, o script continuará perguntando pelos mesmos sucessivamente.

# Definição de cores.
GREEN='\033[0;32m' # Verde
BLUE='\033[0;36m'  # Ciano.
YELLOW='\033[1;33m'   # Amarelo.
RED='\033[0;31m' # Vermelho.
NOCOLOR='\033[0m' # Reseta a cor para o padrão do terminal.

#################################################
### ENTRADA DE DADOS E DEFINIÇÃO DE VARIÁVEIS ###
#################################################

# Entrada de dados interativa.
# O loop vai rodar enquanto qualquer uma das variáveis estiver vazia.
while [ -z "$LOCAL" -o -z "$REMOTE" -o -z "$ID" ]; do

    echo -e "${RED}--- Entrada de Dados (Campos Obrigatórios) ---${NOCOLOR}"
    read -p "Caminho da pasta local: " LOCAL
    read -p "Nome do remoto no rclone: " REMOTE
    read -p "ID da pasta no GDrive: " ID

    if [ -z "$LOCAL" -o -z "$REMOTE" -o -z "$ID" ]; then
        echo -e "\n${RED}ERRO: Todos os campos precisam ser preenchidos!${NOCOLOR}\n"
        # Limpa as variáveis para garantir que o loop pergunte tudo de novo.
        LOCAL=""
        REMOTE=""
        ID=""
    fi
done

# Feedback para o usuário sobre as variáveis que foram definidas.
echo -e "\n${GREEN}Variáveis definidas com sucesso!${NOCOLOR}\n"
echo -e "Pasta local:${YELLOW} $LOCAL${NOCOLOR}."
echo -e "Nome do remoto no rclone:${YELLOW} $REMOTE${NOCOLOR}."
echo -e "ID da pasta no Google Drive:${YELLOW} $ID${NOCOLOR}."
