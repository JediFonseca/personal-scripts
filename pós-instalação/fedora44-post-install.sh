#!/bin/bash

#------------------------------------------------------------------------------
# Script de pós instalação para o Fedora Workstation 44 -----------------------
# Autor: Jedielson da Fonseca--------------------------------------------------
#------------------------------------------------------------------------------

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

declare -A dnf_packages=(
    ["mangohud"]="MangoHud"
    ["openssh-server"]="OpenSSH Server"
    ["rclone"]="RClone"
    ["ffmpeg"]="ffmpeg"
    ["gparted"]="GParted"
    ["lm_sensors"]="LM Sensors"
    ["steam"]="Steam"
    ["gnome-tweak-tool"]="GNOME Tweaks"
    ["seahorse"]="Senhas e Chaves"
    ["libayatana-appindicator-gtk3"]="Biblioteca requerida pelo Ente Auth"
    ["kernel-devel"]="kernel-devel"
    ["kernel-headers"]="kernel-headers"
    ["gcc"]="gcc"
    ["make"]="make"
    ["perl"]="perl"
    ["adw-gtk3-theme"]="Libadwaita Theme for Legacy Apps"
    ["git"]="Git"
    ["curl"]="curl"
    ["wget"]="Wget"
	["sshfs"]="sshfs"
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
    ["org.audacityteam.Audacity"]="Audacity"
    ["org.videolan.VLC"]="VLC"
    ["org.soundconverter.SoundConverter"]="Sound Converter"
    ["net.nokyan.Resources"]="Recursos"
    ["com.mattjakeman.ExtensionManager"]="GNOME Extension Manager"
    ["page.codeberg.libre_menu_editor.LibreMenuEditor"]="Menu Editor"
    ["com.bitwarden.desktop"]="BitWarden"
	["org.gtk.Gtk3theme.Adwaita-dark"]="Adwaita Dark Theme for Flatpaks"
	["io.ente.auth"]="Ente Auth"
)

declare -A rpm_downloads=(
    ["https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.22.1/Heroic-2.22.1-linux-x86_64.rpm"]="Heroic Games Launcher"
    ["https://download.virtualbox.org/virtualbox/7.2.16/VirtualBox-7.2-7.2.16_174877_fedora40-1.x86_64.rpm"]="VirtualBox"
    ["https://data.nephobox.com/issue/terabox/Linux/1.47.0/TeraBox-1.47.0.x86_64.rpm"]="Terabox"
	["https://github.com/clementine-player/Clementine/releases/download/1.4.1-252-gca58aae07/clementine-1.4.1-2.252.gca58aae07.fc44.x86_64.rpm"]="Clementine"
)

declare -A appimage_downloads=(
    ["https://github.com/kem-a/AppManager/releases/download/v3.8.0/AppManager-3.8.0-anylinux-x86_64.AppImage"]="AppManager"
	["https://github.com/jeffvli/feishin/releases/download/v1.17.0/Feishin-linux-x86_64.AppImage"]="Feishin"
	["https://objects.joplinusercontent.com/v3.7.18/Joplin-3.7.18.AppImage?source=JoplinWebsite&type=New"]="Joplin"
	["https://github.com/jely2002/youtube-dl-gui/releases/download/app-v3.2.1/Open.Video.Downloader_3.2.1_amd64.AppImage"]="Open Video Downloader"
)

declare -A remove_packages=(
	["firefox"]="Mozilla Firefox"
	["yelp"]="Help"
	["gnome-clocks"]="GNOME Clocks"
	["gnome-weather"]="GNOME Weather"
	["gnome-contacts"]="GNOME Contacts"
	["gnome-maps"]="GNOME Maps"
	["simple-scan"]="Digitalizador de Documentos"
	["mediawriter"]="Fedora Media Writer"
	["showtime"]="Videos"
	["snapshot"]="Câmera"
	["gnome-characters"]="Caracteres"
	["decibels"]="Reprodutor de áudio"
	["gnome-connections"]="Conexões"
	["gnome-tour"]="Tour"
	["gnome-software"]="GNOME Software"
	["gnome-system-monitor"]="GNOME System Monitor"
	["gnome-boxes"]="GNOME Boxes"
)

flatpak_filesystems=(
	"--filesystem=${arquivo}:rw"
	"--filesystem=${documents_link}:rw"
	"--filesystem=${images_link}:rw"
	"--filesystem=${music_link}:rw"
	"--filesystem=${videos_link}:rw"
	"--filesystem=${gamesdata}:rw"
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
command -v dnf &>/dev/null || exit 1
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
     exit 7
fi
}

# --------------------------------------------------------------------------------------------------------

starting_message () {

clear

echo -e "

${coloryellow}SCRIPT DE PÓS-INSTALAÇÃO DO FEDORA WORKSTATION 44${nocolor}

${colorred}AVISO:${nocolor} Cheque todas as variáveis e listas antes de rodar o script.

${colorblue}Flags disponíveis:${nocolor}

--dependencies - Instala e configura as dependências do script.
--dnf		   - Instala os pacotes com o dnf.
--flatpak 	   - Instala os flatpaks.
--rpmd		   - Baixa os .rpm.
--rpmi		   - Instala os .rpm.
--appimagesd   - Baixa os AppImages.
--remove	   - Remove os pacotes indesejados.
--flatpak-per  - Ajusta as permissões dos flatpaks.
--mylinks	   - Cria os meus links simbólicos/atalhos.
--tailscale	   - Instala o Tailscale.
"

echo -e -n "${coloryellow}\nPressione ENTER para iniciar a execução do script ou CTRL+C para cancelar.${nocolor}"
read -r
echo

}

# --------------------------------------------------------------------------------------------------------

dependencies_installation () {

echo -e "${coloryellow}Habilitando o 'Flathub'...${nocolor}"

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${coloryellow}Instalando e configurando o 'RPM Fusion'...${nocolor}"

sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noar\
ch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

echo -e "${coloryellow}Fase de instalação de dependências finalizada.${nocolor}"
}

# --------------------------------------------------------------------------------------------------------

dnf_installation () {
echo -e "${coloryellow}Iniciando instalação dos pacotes \"dnf\".${nocolor}"
echo
sudo dnf install --allowerasing -y "${!dnf_packages[@]}"

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

echo
echo -e "${coloryellow}Executando a limpeza pós instalação...${nocolor}"
echo
sudo dnf clean all
}

# --------------------------------------------------------------------------------------------------------

flatpak_installation () {
echo -e "${coloryellow}Iniciando a instalação dos pacotes flatpak${nocolor}"
echo
sudo flatpak install --system -y flathub "${!flatpak_packages[@]}"
}

# --------------------------------------------------------------------------------------------------------

rpm_downloads_list () {
echo -e "${coloryellow}Iniciando o download dos pacotes .rpm...${nocolor}"
echo
mkdir -p "$HOME/Downloads/RPMs"
for url1 in "${!rpm_downloads[@]}"; do
    wget --show-progress -P "$HOME/Downloads/RPMs" "$url1"
done
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

remove_packages_list () {
echo -e "${coloryellow}Desinstalando os pacotes indesejados.${nocolor}"
echo
sudo dnf remove -y "${!remove_packages[@]}"
sudo dnf autoremove -y
sudo dnf clean all
}

# --------------------------------------------------------------------------------------------------------

rpm_installation () {
echo -e "${coloryellow}Iniciando a instalação dos pacotes .rpm.${nocolor}"
echo
sudo dnf install -y "$HOME/Downloads/RPMs/"*.rpm
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
echo "- Integrar AppImages;"
echo "- Colar os scripts na pasta '~/.local/bin/'."
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
    dnf_installation
    flatpak_installation
    rpm_downloads_list
    rpm_installation
	eval "$install_tailscale"
	appimages_downloads_list
    remove_packages_list
    mylinks
    flatpak_permissions
    lembretes
    echo
    echo -e "${colorgreen}Script finalizado! Recomenda-se reiniciar o sistema.${nocolor}"

else

    for arg in "$@"; do
        case "$arg" in
            --dependencies) dependencies_installation ;;
			--appimagesd)	appimages_downloads_list ;;
            --dnf)          dnf_installation ;;
            --flatpak)      flatpak_installation ;;
            --rpmd)         rpm_downloads_list ;;
            --rpmi)         rpm_installation ;;
            --remove)       remove_packages_list ;;
            --flatpak-per)  flatpak_permissions ;;
            --mylinks)      mylinks ;;
			--tailscale)	eval "$install_tailscale" ;;
            *)
                echo -e "${colorred}Opção inválida: $arg${nocolor}"
                exit 7
                ;;
        esac
    done

fi
