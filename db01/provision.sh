#!/usr/bin/env bash

echo "=========================="
echo "atualizacao do S.O"
echo "=========================="
sudo dnf update -y

echo "=========================="
echo "Instalacao de dependencias"
echo "=========================="
sudo dnf install -y \
vim \
wget \
curl \
net-tools \
python3 \
git \
unzip

echo "=========================="
echo "Remove duplicacoes de hosts"
echo "=========================="
sudo sed -i '/192.168.1.2 control-node/d' /etc/hosts
sudo sed -i '/192.168.1.3 app01/d' /etc/hosts
sudo sed -i '/192.168.1.4 db01/d' /etc/hosts
sudo sed -i '/127\.0\.1\.1.*db01/d' /etc/hosts

echo "=========================="
echo "Adicionar os hosts"
echo "=========================="
sudo tee -a /etc/hosts > /dev/null <<EOT
192.168.1.2 control-node
192.168.1.3 app01
192.168.1.4 db01
EOT

echo "configuracao de chave publica"
sudo tee -a /home/vagrant/.ssh/authorized_keys > /dev/null <<EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPx9pvSEwaM09oDKIZLR4TOMPtU3/G40HoL77+aoYDi vagrant@control-node
EOT

echo "=========================="
echo "Testes de conectividade"
echo "=========================="

grep -E 'control-node|app01|db01' /etc/hosts
echo "=========================="
echo "Versao Python"
echo "=========================="
python3 --version
