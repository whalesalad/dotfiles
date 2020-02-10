#!/usr/bin/env bash

mkdir -p ~/.ssh
wget https://github.com/whalesalad.keys -O ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 644 ~/.ssh/authorized_keys

# debian
su
apt install sudo
adduser michael sudo
# end debian

sudo apt install git vim htop

git config --global user.email "michael@whalesalad.com"
git config --global user.name "Michael Whalen"

# Stress Testing
stress --cpu $(nproc) --io 4 --vm 2 --vm-bytes 128M --timeout 10s
stress --cpu  --timeout 900

stress --hdd $(nproc) --hdd-bytes 100G --timeout 900


# vim https://github.com/amix/vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

sudo apt update
sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce

sudo apt install nfs-common
sudo mkdir -p /valhalla/{Videos,Movies}
sudo chown -R michael:staff /valhalla
sudo chmod -R 755 /valhalla

sudo mount valhalla.ws.internal:/volume4/Movies /valhalla/Movies/
sudo mount valhalla.ws.internal:/volume4/Videos /valhalla/Videos/

# rpi pass
VqiCbVss
