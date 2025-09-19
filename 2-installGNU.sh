#!/bin/bash

echo """
##############################################################
##############################################################
######                                                  ######
######  Instalação do Sistema Operacional GNU para URT  ######
######             Unidade do Reator Triga              ######
######                                                  ######
######          Distribuição: Debian 13 (Trixie)        ######
######                                                  ######
######         Autor: Thalles Oliveira Campagnani       ######
######                                                  ######
##############################################################
##############################################################
######                                                  ######
######                     PARTE 2:                     ######
######     Formatação e instalação do sistema base      ######
######                                                  ######
##############################################################
##############################################################


"""
read -p "Pressione enter para iniciar... "

# Garante que o script pare se algum comando falhar
set -e

# Verifica se debootstrap está instalado
if ! command -v debootstrap &> /dev/null; then
    echo "Erro: O comando 'debootstrap' não foi encontrado."
    echo "Por favor, instale o pacote 'debootstrap' no seu sistema atual e tente novamente."
    exit 1
fi

# Path das partições
EFI_PART="/dev/nvme0n1p1"
DEBIAN_PART="/dev/nvme0n1p5"
HOME_PART="/dev/nvme0n1p6"

# Atualizar relógio
echo "{[( Atualizando relógio )]}"
timedatectl

# Configuração das partições
echo "{[( Configuração atual das partições )]}"
fdisk -l

echo """
# Configuração esperada das partições (por este instalador):
    # /dev/nvme0n1p1 - EFI
    # /dev/nvme0n1p2 - MS Reserved
    # /dev/nvme0n1p3 - Windows CDTN
    # /dev/nvme0n1p4 - Arch
    # /dev/nvme0n1p5 - Debian (Será formatada e usada)
    # /dev/nvme0n1p6 - Home (Será formatada e usada)
"""
# Formatar a partição raiz do Debian
read -p "Deseja formatar a partição raiz (${DEBIAN_PART})? [y/N]: " formatar_raiz
if [[ $formatar_raiz == "y" || $formatar_raiz == "Y" ]]; then
    echo "Formatando partição raiz do Debian..."
    mkfs.ext4 ${DEBIAN_PART}
fi

# Formatar a partição home
read -p "Deseja formatar a partição home (${HOME_PART})? [y/N]: " formatar_home
if [[ $formatar_home == "y" || $formatar_home == "Y" ]]; then
    echo "Formatando partição home..."
    mkfs.ext4 ${HOME_PART}
fi

# Montar partições
echo "{[( Montando partições )]}"
mount ${DEBIAN_PART} /mnt
mount --mkdir ${HOME_PART} /mnt/home
mount --mkdir ${EFI_PART} /mnt/boot/efi

# Instalação do sistema base com debootstrap
echo "{[( Instalando sistema base do Debian 13 (Trixie) )]}"
debootstrap --arch=amd64 --components=main,contrib,non-free,non-free-firmware --include=firmware-linux,intel-microcode trixie /mnt http://debian.c3sl.ufpr.br/debian/ #http://deb.debian.org/debian/

# Gerar fstab
echo "{[( Gerando fstab )]}"
# O Debian não tem genfstab, então geramos manualmente com UUIDs para maior robustez
{
    echo "# <file system> <mount point>   <type>  <options>       <dump>  <pass>"
    echo "UUID=$(blkid -s UUID -o value ${DEBIAN_PART}) /               ext4    errors=remount-ro 0       1"
    echo "UUID=$(blkid -s UUID -o value ${HOME_PART})   /home           ext4    defaults        0       2"
    echo "UUID=$(blkid -s UUID -o value ${EFI_PART})    /boot/efi       vfat    umask=0077      0       1"
} > /mnt/etc/fstab

cat /mnt/etc/fstab

# Copiar script para pasta root
echo "{[( Copiando script de configuração para pasta root )]}"
cp 3-configGNU.sh /mnt/root/

# Montar sistemas de arquivos virtuais para o chroot
echo "{[( Preparando o ambiente para chroot )]}"
sudo mount --bind /dev /mnt/dev
sudo mount --bind /dev/pts /mnt/dev/pts
sudo mount -t proc proc /mnt/proc
sudo mount -t sysfs sysfs /mnt/sys

# Fazer chroot e executar script de configuração
echo "{[( Fazendo chroot e executando script de configuração )]}"
chroot /mnt /bin/bash --login -c "/root/3-configDebian.sh"

# Desmontar tudo após a finalização
echo "{[( Desmontando partições )]}"
umount -R /mnt
