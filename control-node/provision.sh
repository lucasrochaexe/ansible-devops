#!/usr/bin/env bash
echo "atualizacao de pacotes"
sudo dnf update -y 
echo "epel-release -> Extra packages for entrepise linux"
sudo dnf install -y \
epel-release \ 
git \
vim \
wget \ 
curl \
unzip \
net-tools \
python3
echo "Instalacao do ansible"
sudo dnf install -y ansible
echo "sed -> procurar, alterar em algum arquivo"
echo "-i -> editar"
echo "/d -> deletar"
sudo sed -i '/192.168.1.2 control-node/d' /etc/hosts
sudo sed -i '/192.168.1.3 app01/d' /etc/hosts
sudo sed -i '/192.168.1.4 db01/d' /etc/hosts
sudo sed -i '/127\.0\.1\.1.*control-node/d' /etc/hosts

sudo tee -a /etc/hosts > /dev/null <<EOT
192.168.1.2 control-node
192.168.1.3 app01
192.168.1.4 db01
EOT
grep -E 'control-node|app01|db01' /etc/hosts
python3 --version
ansible --version

