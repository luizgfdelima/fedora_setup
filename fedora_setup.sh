#!/usr/bin/env bash
#
# ==============================================================================
# Título:        fedora_setup.sh
# Descrição:     Setup de pós instalação para os sistemas Fedora Linux.
# Conteúdo:		 Instalação de programas básicos para meu uso;
#				 Upgrade do sistema e de firmware;
#				 
# Autor:         luizgfdelima@gmail.com
# Versão:        1
# Como usar:     sudo ./fedora_setup.sh
# Testado em:	 GNU bash, versão 5.3.9(1)-release (x86_64-redhat-linux-gnu)
# ==============================================================================
#
#
# CORES ==============================================================================

SEM_FORMAT="\033[0m"
VERDE="\033[38;5;10m"
FUNDO_VERMELHO="\033[48;5;9m"
NEGRITO="\033[1m"

# VARIAVEIS ==============================================================================

RPM_FREE="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
RPM_NON_FREE="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
DIRETORIO_APPIMAGES="./downloaded_appimages"
REPOSITORIOS_EXTRAS=(
	https://repo.vivaldi.com/archive/vivaldi-fedora.repo
)
PROGRAMAS_DNF=(
	fuse-libs
	make
	git
	chromium
	vivaldi
	steam
	code
	qbittorrent
	syncthing
	goverlay
	mangohud
	pavucontrol
	obs
	haruna
	btop
	btrfs-assistant
	distrobox
	docker
	docker-compose
	podman
	podman-compose
	micro
	yazi
	bat
	tealdeer
	klassy
	fastfetch
	@virtualization
)
PROGRAMAS_FLATPAK=(
	it.mijorus.gearlever
	org.localsend.localsend_app
	com.vysp3r.ProtonPlus
	com.bitwarden.desktop
	com.ranfdev.DistroShelf
	com.github.tchx84.Flatseal
	com.github.Matoking.protontricks
	
)
APPIMAGES=(
	https://github.com/obsidianmd/obsidian-releases/releases/download/v1.13.4/Obsidian-1.13.4.AppImage
	https://github.com/ElyPrismLauncher/Launcher/releases/download/11.0.3/PineconeMC-Linux-x86_64.AppImage
)

# TESTES E REQUISITOS ==============================================================================

set -uo pipefail

if (( $EUID != 0 )); then
	exec sudo "$0" "$@"
fi

if [[ -d ./fedora_setup-stdout.log && ./fedora_setup-stderr.log ]]; then
	sudo -u "$SUDO_USER" -- touch ./fedora_setup-stdout.log ./fedora_setup-stderr.log
fi

echo -e "Verificando conexão com a Internet..."
if ! ping -c 4 "google.com" -q >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log; then
	echo -e  "${NEGRITO}${FUNDO_VERMELHO}Erro! A conexão com a Internet está indisponível ou foi interrompida.${SEM_FORMAT}" 2>> ./fedora_setup-stderr.log
	exit 1
else
	echo -e "${NEGRITO}${VERDE}Conexão com a Internet estabelecida.${SEM_FORMAT}"
fi

# ATUALIZACAO DE FIRMWARE ==============================================================================

atualizar_firmware () {
	echo -e "Procurando por atualizações de firmware..."
	fwupdmgr refresh --force >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	fwupdmgr get-devices >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	fwupdmgr get-updates >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	fwupdmgr update -y >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	
	if ! [[ $? = 0 ]]; then
		echo -e "${NEGRITO}${FUNDO_VERMELHO}Não foi possivel atualizar o firmware.${SEM_FORMAT}"
	else
		echo -e "${NEGRITO}${VERDE}Firmware atualizado${SEM_FORMAT}. Se houverem atualizações pendentes de firmware elas serão aplicadas após o encerramento do script."
	fi
}

# ATUALIZACAO DO SISTEMA ==============================================================================

atualizar_sistema () {
	echo -e "Atualizando pacotes do sistema..."
	dnf update -y --refresh >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	echo -e "${NEGRITO}${VERDE}Sistema atualizado${SEM_FORMAT}. Se houverem ações pendentes elas serão aplicadas após o encerramento do script."
}

# GROUP CORE ==============================================================================

instalar_group_core () {
	echo -e "Fazendo a instalação dos pacotes Core do sistema..."
	dnf4 group install -y core >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	dnf group upgrade -y core >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	echo -e "${VERDE}Instalação dos pacotes Core bem sucedida.${SEM_FORMAT}"
}

# RPM FUSION ==============================================================================

instalar_rpm_fusion () {
	echo -e "Instalando repositórios RPM Fusion..."
	if ! ls /etc/yum.repos.d/ | grep -q "rpmfusion-*"; then
		dnf install -y "$RPM_FREE" "$RPM_NON_FREE" >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
		echo -e "${VERDE}Os repositórios RPM Fusion foram instalados.${SEM_FORMAT}"
	elif ls /etc/yum.repos.d/ | grep -q "rpmfusion-*"; then
		echo -e "Os repositórios RPM Fusion já foram instalados."
	else
		echo -e "${NEGRITO}${FUNDO_VERMELHO}Não foi possível instalar os repositórios RPM Fusion.${SEM_FORMAT}"
	fi
}

# FLATPAK ==============================================================================

configurar_flatpaks () {
	echo -e "Configurando e instalando Flatpak e Flathub..."
	if ! dnf list --installed | grep -q flatpak; then
		dnf install -y flatpak >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
		flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
		echo -e "${VERDE}Flatpak e Flathub foram configurados.${SEM_FORMAT}"
	elif ! flatpak remotes | grep flathub; then
		flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
		echo -e "Flatpak já está instalado. ${VERDE}Flathub foi adicionada.${SEM_FORMAT}"
	else
		echo -e "Flatpak e Flathub já foram configurados."
	fi
}

# REPOSITORIOS EXTRAS ==============================================================================

repositorios_extras () {
	echo -e "Adicionando repositórios extras..."
	for repo in ${REPOSITORIOS_EXTRAS[@]}; do
		dnf config-manager addrepo --from-repofile=$repo
		echo -e "O repositório ${NEGRITO}${VERDE}$repo${SEM_FORMAT} foi adicionado."
		if [[ $? -eq 1 ]]; then
			echo -e "O repositório ${NEGRITO}$repo${SEM_FORMAT} já está adicionado."
		fi
	done
}

# CODECS ==============================================================================

instalar_codecs () {
	echo -e "Instalando codecs multimídia..."
	dnf4 group install -y multimedia >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	dnf swap 'ffmpeg-free' 'ffmpeg' -y --allowerasing >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	dnf group install -y sound-and-video >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
	echo -e "${VERDE}Os codecs multimídia foram instalados.${SEM_FORMAT}"
}

# DNF A INSTALAR ==============================================================================

instalar_programas_dnf () {
	echo -e "Instalando programas através do DNF:"
	for pacote in ${PROGRAMAS_DNF[@]}; do
		if ! dnf list --installed | grep -q $pacote; then
			echo -e "Instalando o pacote ${NEGRITO}\"$pacote\"${SEM_FORMAT}..."
			dnf install -y $pacote >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
			echo -e "${NEGRITO}${VERDE}$pacote${SEM_FORMAT} instalado."
		else
			echo -e "O pacote ${NEGRITO}$pacote${SEM_FORMAT} já está instalado."
		fi
	done
}

# FLATPAK A INSTALAR ==============================================================================

instalar_programas_flatpak () {
	echo -e "Instalando programas através do Flatpak:"
	for pacote in ${PROGRAMAS_FLATPAK[@]}; do
		if ! flatpak list | grep -q $pacote; then
			echo -e "Instalando o pacote ${NEGRITO}\"$pacote\"${SEM_FORMAT}..."
			flatpak install -y flathub $pacote >> ./fedora_setup-stdout.log 2>> ./fedora_setup-stderr.log
			echo -e "${NEGRITO}${VERDE}$pacote${SEM_FORMAT} instalado."
		else
			echo -e "O pacote ${NEGRITO}$pacote${SEM_FORMAT} já está instalado."
		fi
	done
}

# BAIXAR APPIMAGES ==============================================================================

baixar_appimages () {
	echo -e "Baixando arquivos AppImage:"
	if [[ ! -d "$DIRETORIO_APPIMAGES" ]]; then
		sudo -u "$SUDO_USER" -- mkdir "$DIRETORIO_APPIMAGES" && cd "$DIRETORIO_APPIMAGES"
	elif [[ -d "$DIRETORIO_APPIMAGES" ]]; then
		cd "$DIRETORIO_APPIMAGES"
	fi

	for url in ${APPIMAGES[@]}; do
		echo -e "Baixando arquivo de \"$url\""
		sudo -u "$SUDO_USER" -- curl -w "%{filename_effective}\n" -LO $url >> ../fedora_setup-stdout.log 2>> ../fedora_setup-stderr.log
	done

	chmod +x *

	cd ..

	echo -e "Arquivos salvos em ${NEGRITO}$DIRETORIO_APPIMAGES${SEM_FORMAT}."
}

# EXECUCAO ==============================================================================

echo -e "${NEGRITO}Iniciando setup pós instalação:${SEM_FORMAT}"
atualizar_firmware
instalar_group_core
atualizar_sistema
instalar_codecs
instalar_rpm_fusion
configurar_flatpaks
repositorios_extras
instalar_programas_dnf
instalar_programas_flatpak
baixar_appimages
shutdown -r +1 &> /dev/null
echo -e "O sistema irá ${NEGRITO}reiniciar${SEM_FORMAT} em ${NEGRITO}1 minuto${SEM_FORMAT}. Para cancelar digite ${NEGRITO}\"sudo shutdown -c\"${SEM_FORMAT}."
