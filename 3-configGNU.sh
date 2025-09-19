#!/bin/bash

echo """
##############################################################
##############################################################
######                                                  ######
######  Instalação do Sistema Operacional GNU para URT  ######
######               Unidade do Reator Triga            ######
######                                                  ######
######          Distribuição: Debian 13 (Trixie)        ######
######                                                  ######
######         Autor: Thalles Oliveira Campagnani       ######
######                                                  ######
##############################################################
##############################################################
######                                                  ######
######                     PARTE 3:                     ######
######              Configuração do sistema             ######
######                em ambiente chroot                ######
######                                                  ######
##############################################################
##############################################################


"""
read -p "Pressione enter para iniciar... "

# Garante que o script pare se algum comando falhar
set -e

# Atualizar lista de pacotes e instalar ferramentas essenciais
echo "{[( Atualizando APT e instalando pacotes de configuração )]}"
apt-get update
apt-get install -y locales sudo console-setup network-manager openssh-client openssh-server grub-efi

# Configurar fuso horário
#echo "{[( Configurando fuso horário )]}"
#ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
#hwclock --systohc

# Locales e mapa do teclado
echo "{[( Configurando locales e mapa do teclado )]}"
# O padrão Debian para o teclado do console é /etc/default/keyboard
echo 'XKBMODEL="pc105"' > /etc/default/keyboard
echo 'XKBLAYOUT="br"' >> /etc/default/keyboard
echo 'XKBVARIANT="abnt2"' >> /etc/default/keyboard
echo 'XKBOPTIONS=""' >> /etc/default/keyboard
echo 'BACKSPACE="guess"' >> /etc/default/keyboard

echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
# O padrão Debian para o locale é /etc/default/locale
echo "LANG=pt_BR.UTF-8" > /etc/default/locale

# Hostname
echo "{[( Configurando Hostname )]}"
echo "DT32674CDTN" > /etc/hostname
echo """
127.0.0.1   localhost
::1         localhost
127.0.1.1   DT32674CDTN.localdomain DT32674CDTN
""" > /etc/hosts

# Ativando serviço do NetworkManager e SSH
echo "{[( Ativando serviço do NetworkManager e SSH )]}"
systemctl enable NetworkManager.service
systemctl enable ssh.service

# Senha do root
echo "{[( Criando senha para root )]}"
passwd

# Criando usuário trigauser
TRIGAUSER=trigauser
echo "{[( Criando usuário $TRIGAUSER e definindo senha )]}"
useradd -m -s /bin/bash $TRIGAUSER
passwd $TRIGAUSER

while true; do
    # Criando usuários para manutenção
    read -p "Digite o nome do usuário para manutenção (sudo) ou deixe em branco para não criar: " ADDUSER

    # Verificar se o campo está vazio
    if [[ -z $ADDUSER ]]; then
        break
    fi

    # Criar usuário e definir senha
    echo "{[( Criando usuário $ADDUSER e definindo senha )]}"
    # No Debian, o grupo para permissões de sudo é 'sudo'
    useradd -m -s /bin/bash $ADDUSER
    usermod -aG sudo $ADDUSER
    passwd $ADDUSER
    echo "Usuário $ADDUSER criado com sucesso e adicionado ao grupo sudo."

    echo "{[( Você pode adicionar mais usuários para manutenção se quiser )]}"
done

# GRUB
echo "{[( Instalando GRUB na UEFI )]}"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Debian
grub-mkconfig -o /boot/grub/grub.cfg

exit
