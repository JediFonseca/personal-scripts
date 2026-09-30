#!/bin/bash

#--------------------------------------------------------------------------
# Script de pós instalação para o Pop!_OS 24.04 LTS -----------------------
# Autor: Jedielson da Fonseca----------------------------------------------
#--------------------------------------------------------------------------

#------------------
# --- VARIÁVEIS ---
#------------------

# Paleta de cores
colorblue='\033[0;36m'  # Ciano - para títulos.
colorgreen='\033[0;32m' # Verde - para mensagens de sucesso.
coloryellow='\033[1;33m'   # Amarelo - para avisos.
colorred='\033[0;31m' # Erros
nocolor='\033[0m' # Reseta a cor para o padrão do terminal.

install_tailscale="curl -fsSL https://tailscale.com/install.sh | sh"

# --------------------------------------------------------------------------------------------------------

gamesdata="/mnt/Instalações/"
arquivo="/mnt/Backup/"

documents_source="$HOME/.mnt/NAS/mnt/dados/Documentos"
downloads_source="/mnt/Backup/Downloads"
images_source="$HOME/.mnt/NAS/mnt/dados/Imagens"
music_source="$HOME/.mnt/NAS/mnt/dados/Músicas"
videos_source="$HOME/.mnt/NAS/mnt/dados/Vídeos"
documents_link="$HOME/Documentos/Documentos NAS"
downloads_link="$HOME/Downloads/Arquivo"
images_link="$HOME/Imagens/Imagens NAS"
music_link="$HOME/Músicas/Músicas NAS"
videos_link="$HOME/Vídeos/Vídeos NAS"

#----------------------
# --- LISTAS/ARRAYS ---
#----------------------

declare -A apt_packages=(
    ["tree"]="Tree"
    ["mangohud"]="MangoHud"
    ["gamemode"]="GameMode"
    ["pipewire-audio-client-libraries"]="Pipewire Libraries"
    ["ratbagd"]="Ratbagd"
    ["piper"]="Piper"
    ["curl"]="Curl"
    ["openssh-server"]="OpenSSH Server"
    ["rclone"]="RClone"
    ["ffmpeg"]="ffmpeg"
    ["gparted"]="GParted"
    ["smartmontools"]="smartmontools"
    ["linux-tools-common"]="Linux Tools Common"
    ["lm-sensors"]="LM Sensors"
    ["steam"]="Steam"
    ["git"]="Git"
    ["wget"]="Wget"
    ["curl"]="Curl"
    ["gcc"]="gcc"
    ["make"]="make"
    ["perl"]="perl"
    ["linux-tools-generic"]="linux-tools-generic"
    ["linux-cloud-tools-generic"]="linux-cloud-tools-generic"
	["sshfs"]="sshfs"
	["members"]="members"
)

declare -A flatpak_packages=(
    ["com.usebottles.bottles"]="Bottles"
    ["com.github.finefindus.eyedropper"]="Eyedropper"
    ["top.akizip.akizip"]="Akizip"
    ["com.vysp3r.ProtonPlus"]="Proton Plus"
    ["com.protonvpn.www"]="Proton VPN"
    ["org.gimp.GIMP"]="GIMP"
    ["org.upscayl.Upscayl"]="Upscayl"
    ["com.github.unrud.VideoDownloader"]="Video Downloader"
    ["org.qbittorrent.qBittorrent"]="qBittorrent"
    ["org.hydrogenmusic.Hydrogen"]="Hydrogen Drum Machine"
    ["io.gitlab.librewolf-community"]="LibreWolf"
    ["org.bunkus.mkvtoolnix-gui"]="MKVToolNix GUI"
    ["org.gnome.gitlab.somas.Apostrophe"]="Apostrophe"
    ["org.audacityteam.Audacity"]="Audacity"
    ["com.bitwarden.desktop"]="Bitwarden"
    ["org.videolan.VLC"]="VLC"
    ["org.soundconverter.SoundConverter"]="Sound Converter"
	["io.ente.auth"]="Ente Auth"
)

declare -A deb_downloads=(
    ["https://data.nephobox.com/issue/terabox/Linux/1.49.5/TeraBox_1.49.5_amd64.deb"]="TeraBox"
    ["https://download.virtualbox.org/virtualbox/7.2.20/virtualbox-7.2_7.2.20-175154~Ubuntu~noble_amd64.deb"]="VirtualBox"
    ["https://cdn.fastly.steamstatic.com/client/installer/steam.deb"]="Steam"
    ["https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.22.3/Heroic-2.22.3-linux-amd64.deb"]="Heroic Games Launcher"
	["https://github.com/clementine-player/Clementine/releases/download/1.4.1-252-gca58aae07/clementine_1.4.1-252-gca58aae07.noble_amd64.deb"]="Clementine"
)

declare -A appimage_downloads=(
    ["https://github.com/kem-a/AppManager/releases/download/v3.8.0/AppManager-3.8.0-anylinux-x86_64.AppImage"]="AppManager"
	["https://github.com/jeffvli/feishin/releases/download/v1.17.0/Feishin-linux-x86_64.AppImage"]="Feishin"
	["https://objects.joplinusercontent.com/v3.7.18/Joplin-3.7.18.AppImage?source=JoplinWebsite&type=New"]="Joplin"
	["https://github.com/jely2002/youtube-dl-gui/releases/download/app-v3.2.1/Open.Video.Downloader_3.2.1_amd64.AppImage"]="Open Video Downloader"
)

declare -A remove_packages=(
	["firefox"]="Mozilla Firefox"
	["qsynth"]="QSynth"
	["popsicle"]="Popsicle"
	["simple-scan"]="Simple Scan"
	["thunderbird"]="Thunderbird"
	["system-config-printer"]="Impressoras"
)

flatpak_filesystems=(
	"--filesystem=${gamesdata}:rw"
	"--filesystem=${arquivo}:rw"
	"--filesystem=${documents_link}:rw"
	"--filesystem=${images_link}:rw"
	"--filesystem=${music_link}:rw"
	"--filesystem=${videos_link}:rw"
)

#----------------
# --- FUNÇÕES ---
#----------------

# --------------------------------------------------------------------------------------------------------

sudo_alive () {
sudo -v
while true; do sudo -v; sleep 60; done &
sudo_pid=$!
trap 'kill "$sudo_pid"; sudo -k' EXIT
}

# --------------------------------------------------------------------------------------------------------

basic_dependencies () {
command -v apt &>/dev/null || exit 1
command -v mkdir &>/dev/null || exit 3
command -v ping &>/dev/null || exit 4
}

# --------------------------------------------------------------------------------------------------------

internet_connection () {
clear

echo -e "${coloryellow}\nVerificando a conexão com a internet...\n${nocolor}"

ping -c 5 -W 3 1.1.1.1
if [ "$?" -eq "0" ];
then
      echo -e "${colorgreen}\nConexão com a internet funcionando normalmente. Aguarde...${nocolor}"
      sleep 5
else
     echo -e "${colorred}\nERRO: Seu sistema não está conectado à internet.${nocolor}"
     exit 6
fi
}

# --------------------------------------------------------------------------------------------------------

starting_message () {

clear

echo -e "

${coloryellow}SCRIPT DE PÓS-INSTALAÇÃO DO POPOS 24.04${nocolor}

${colorred}AVISO:${nocolor} Cheque todas as variáveis e listas antes de rodar o script.

${colorblue}Flags disponíveis:${nocolor}

--dependencies - Instala e configura as dependências do script.
--apt		   - Instala os pacotes com o apt.
--flatpak 	   - Instala os flatpaks.
--debd		   - Baixa os .deb.
--debi		   - Instala os .deb.
--appimagesd   - Baixa os AppImages.
--remove	   - Remove os pacotes indesejados.
--flatpak-per  - Ajusta as permissões dos flatpaks.
--mylinks	   - Cria os meus links simbólicos/atalhos.
--tailscale	   - Instala o Tailscale.
--gov		   - Define o CPU Governor para Performance.
"

echo -e -n "${coloryellow}\nPressione ENTER para iniciar a execução do script ou CTRL+C para cancelar.${nocolor}"
read -r
echo

}

# --------------------------------------------------------------------------------------------------------

dependencies_installation () {

echo -e "${coloryellow}Instalando o \"flatpak\" e adicionando o repositório \"Flathub\"...${nocolor}"
sudo apt update
sudo apt install flatpak -y
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${coloryellow}Fase de instalação de dependências finalizada.${nocolor}"
}

# --------------------------------------------------------------------------------------------------------

apt_installation () {
echo -e "${coloryellow}Iniciando instalação dos pacotes \"apt\".${nocolor}"
echo
sudo apt update
sudo apt install --reinstall -y "${!apt_packages[@]}"
echo
echo -e "${coloryellow}Instalando o \"Brave Origin\"...${nocolor}"
curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh
echo

echo -e "${coloryellow}Instalando o \"Swiss Army Knife\"...${nocolor}"
wget -qO- --header="Authorization: token github_pat_11ALNQCSQ0UTtt77kCpfQy_BX2GPLWQrXc3LCiGQIWwicBPK0U4snRzBBywE\
osSgNLRC7QC2FOrprgvUdr" "https://raw.githubusercontent.com/JediFonseca/swiss-army-knife/main/sak-install" | bash

echo
echo -e "${coloryellow}Instalando o \"PCData\"...${nocolor}"
wget -qO- "https://raw.githubusercontent.com/JediFonseca/pcdata/refs/heads/main/pcdata-install" | sudo bash

echo -e "${coloryellow}Executando a limpeza pós instalação...${nocolor}"
echo
sudo apt autoremove -y
sudo apt autoclean -y
}

# --------------------------------------------------------------------------------------------------------

flatpak_installation () {
echo -e "${coloryellow}Iniciando a instalação dos pacotes flatpak${nocolor}"
echo
flatpak install --system -y flathub "${!flatpak_packages[@]}"
}

# --------------------------------------------------------------------------------------------------------

install_tailscale () {
echo -e "${coloryellow}Iniciando a instalação do Tailscale.${nocolor}"
echo
curl -fsSL https://tailscale.com/install.sh | sh

sudo systemctl status tailscaled.service --no-pager

echo
echo -e "${colorblue}Verifique, acima, o estado do 'tailscaled.service'.${nocolor}"
echo -e -n "${coloryellow}Pressione ENTER para continuar a execução do script ou CTRL+C para cancelar.${nocolor}"
read -r
echo
}

# --------------------------------------------------------------------------------------------------------

deb_downloads_list () {
echo -e "${coloryellow}Iniciando o download dos pacotes .deb...${nocolor}"
echo
mkdir -p "$HOME/Downloads/DEBs"
for url in "${!deb_downloads[@]}"; do
    wget --show-progress -P "$HOME/Downloads/DEBs" "$url"
done
}

# --------------------------------------------------------------------------------------------------------

remove_packages_list () {
echo -e "${coloryellow}Desinstalando os pacotes indesejados.${nocolor}"
echo
sudo apt remove -y "${!remove_packages[@]}"
sudo apt autoremove -y
sudo apt autoclean -y
}

# --------------------------------------------------------------------------------------------------------

deb_installation () {
echo -e "${coloryellow}Iniciando a instalação dos pacotes .deb.${nocolor}"
echo
sudo apt install -y "$HOME/Downloads/DEBs/"*.deb
}

# --------------------------------------------------------------------------------------------------------

appimages_downloads_list () {
echo -e "${coloryellow}Iniciando o download dos pacotes .appimage...${nocolor}"
echo
mkdir -p "$HOME/Downloads/AppImages"
for url2 in "${!appimage_downloads[@]}"; do
    wget --show-progress -P "$HOME/Downloads/AppImages" "$url2"
done

chmod +x "$HOME/Downloads/AppImages/"*.AppImage
}

# --------------------------------------------------------------------------------------------------------

cpu_governor () {
clear

echo -e "${coloryellow}Verificando o modo de energia atual da sua CPU...${nocolor}"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cpupower frequency-info
echo -e "${coloryellow}Verifique, acima, o modo de energia atual da sua CPU.${nocolor}"
echo -e -n "${coloryellow}Pressione ENTER para ativar o modo \"performance\" ou CTRL+C para cancelar.${nocolor}"
read

sudo cpupower frequency-set -g performance

cat <<EOF | sudo tee /etc/systemd/system/cpupower-performance.service > /dev/null
[Unit]
Description=CPU Performance Governor
After=cpupower.service

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cpupower-performance.service
sudo systemctl start cpupower-performance.service

echo -e "${coloryellow}Verificando o modo de energia ativo para a sua CPU...${nocolor}"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cpupower frequency-info
}

# --------------------------------------------------------------------------------------------------------

mylinks () {
echo
echo -e "${coloryellow}Criando links simbólicos para as pastas do usuário...${nocolor}"
echo
ln -sfn "$documents_source" "$documents_link"
ln -sfn "$images_source" "$images_link"
ln -sfn "$music_source" "$music_link"
ln -sfn "$videos_source" "$videos_link"
ln -sfn "$downloads_source" "$downloads_link"

}

# --------------------------------------------------------------------------------------------------------

flatpak_permissions () {

sudo flatpak override --system "${flatpak_filesystems[@]}"

sudo flatpak override --system --show | sed -e '/^\[Context\]$/d' -e 's/^filesystems=/Filesystems:\n\n/' -e 's/;/\n/g'

echo -e -n "${coloryellow}Verifique, acima, a lista de diretórios nos quais os flatpaks poderão ler e escrever.${nocolor}"
read -r
echo

}

# --------------------------------------------------------------------------------------------------------

lembretes () {
echo -e "${colorblue}Lembretes:${nocolor}"
echo
echo "- Configurar o Tailscale;"
echo "- Colar os scripts na pasta '~/.local/bin/'."
echo "- Para auto-montar partições exFAT, utilize os argumentos: ',uid=1000,gid=1000,umask=000'"
echo "- Configurar o rclone."
}

#-------------------------------------
# --- Início da execução do script ---
#-------------------------------------

if [[ $# -eq 0 ]]; then

    starting_message
	basic_dependencies
    internet_connection
    sudo_alive
    dependencies_installation
    apt_installation
    flatpak_installation
    deb_downloads_list
    deb_installation
	eval "$install_tailscale"
	appimages_downloads_list
    remove_packages_list
    mylinks
    flatpak_permissions
    cpu_governor
    lembretes
    echo
    echo -e "${colorgreen}Script finalizado! Recomenda-se reiniciar o sistema.${nocolor}"

else

    for arg in "$@"; do
        case "$arg" in
            --dependencies) dependencies_installation ;;
			--appimagesd)	appimages_downloads_list ;;
            --apt)          apt_installation ;;
            --flatpak)      flatpak_installation ;;
            --debd)         deb_downloads_list ;;
            --debi)         deb_installation ;;
            --remove)        remove_packages_list ;;
            --flatpak-per)  flatpak_permissions ;;
            --mylinks)      mylinks ;;
            --gov)          cpu_governor ;;
			--tailscale)	eval "$install_tailscale" ;;
            *)
                echo -e "${colorred}Opção inválida: $arg${nocolor}"
                exit 7
                ;;
        esac
    done

fi
