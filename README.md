# Ambiente Ansible com Vagrant

Ambiente de laboratório para praticar automação com Ansible em máquinas
Rocky Linux 9 executadas pelo Vagrant.

## Topologia

| Máquina | Função | IP privado | Portas encaminhadas |
|---|---|---|---|
| `control-node` | Nó de controle com Ansible | `192.168.1.2` | - |
| `app01` | Servidor de aplicação | `192.168.1.3` | `8080 -> 80` |
| `db01` | Servidor de banco de dados | `192.168.1.4` | `3308 -> 3308` |

O projeto usa a box `generic/rocky9` e o provider `vmware_desktop`.

## Pré-requisitos

Instale no computador host:

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads);
- VMware Workstation ou VMware Fusion;
- plugin do Vagrant para VMware:

```powershell
vagrant plugin install vagrant-vmware-desktop
```

No Windows, execute os comandos abaixo no PowerShell. Os comandos iniciados
por `vagrant ssh` ou executados depois dele são comandos Linux dentro da VM.

## Obtendo o projeto

```powershell
git clone https://github.com/lucasrochaexe/ansible-devops.git
cd "ansible-devops"
```

## Criando as máquinas

Cada diretório é um projeto Vagrant independente. Suba primeiro o banco e o
nó de controle:

```powershell
cd "db01"
vagrant up --provider=vmware_desktop

cd "..\control-node"
vagrant up --provider=vmware_desktop
```

Opcionalmente, suba também o servidor de aplicação:

```powershell
cd "..\app01"
vagrant up --provider=vmware_desktop
```

O primeiro `vagrant up` pode demorar porque a box e os pacotes precisam ser
baixados. Os scripts `provision.sh` instalam dependências e configuram os
nomes dos hosts no arquivo `/etc/hosts`.

## Verificando o estado das VMs

Em cada diretório de máquina:

```powershell
vagrant status
```

Para acessar uma VM:

```powershell
cd "control-node"
vagrant ssh
```

Para sair da VM:

```bash
exit
```

## Configurando a chave SSH do Ansible

O inventário usa a chave privada em:

```text
/home/vagrant/.ssh/db01_key
```

A chave deve ser a chave privada gerada pelo Vagrant para a VM `db01`.
Execute os passos a seguir no PowerShell.

### 1. Copie a chave privada para a pasta compartilhada do control-node

```powershell
Copy-Item `
  ".\db01\.vagrant\machines\default\vmware_desktop\private_key" `
  ".\control-node\db01_key" `
  -Force
```

### 2. Instale a chave dentro do control-node

```powershell
cd "control-node"
vagrant ssh
```

Dentro da VM:

```bash
mkdir -p /home/vagrant/.ssh
cp /vagrant/db01_key /home/vagrant/.ssh/db01_key
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/db01_key
ssh-keygen -y -f /home/vagrant/.ssh/db01_key > /vagrant/db01_key.pub
exit
```

### 3. Autorize a chave no db01

No PowerShell, a pasta compartilhada do `db01` é diferente da pasta
compartilhada do `control-node`. Por isso, copie a chave pública:

```powershell
Copy-Item `
  ".\db01_key.pub" `
  "..\db01\db01_key.pub" `
  -Force

cd "..\db01"
```

Adicione a chave ao usuário `vagrant`:

```powershell
vagrant ssh -c "sudo sh -c 'cat /vagrant/db01_key.pub >> /home/vagrant/.ssh/authorized_keys'; sudo chown -R vagrant:vagrant /home/vagrant/.ssh; sudo chmod 700 /home/vagrant/.ssh; sudo chmod 600 /home/vagrant/.ssh/authorized_keys; sudo restorecon -RFv /home/vagrant/.ssh"
```

### 4. Teste o acesso SSH

```powershell
cd "..\control-node"
vagrant ssh
```

Dentro do `control-node`:

```bash
ssh -o IdentitiesOnly=yes \
  -i /home/vagrant/.ssh/db01_key \
  vagrant@192.168.1.4
```

Se o login funcionar, saia do `db01`:

```bash
exit
```

## Executando o Ansible

Dentro do `control-node`, o projeto está disponível em `/vagrant`:

```bash
cd /vagrant/ansible
```

Confira o inventário:

```bash
cat inventory/hosts.ini
```

O host `db01` deve estar configurado com IP, usuário e chave:

```ini
[dbs]
db01 ansible_host=192.168.1.4 ansible_user=vagrant ansible_private_key_file=/home/vagrant/.ssh/db01_key
```

Valide a configuração:

```bash
ansible-inventory --host db01
```

Teste a conectividade:

```bash
ansible db01 -m ping
```

O resultado esperado é:

```text
db01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Execute o playbook em modo de verificação:

```bash
ansible-playbook playbooks/db.yaml --check
```

Para aplicar as alterações de verdade, remova o `--check`:

```bash
ansible-playbook playbooks/db.yaml
```

O playbook configura o `db01` usando as roles:

- `configuracao-default-so`;
- `configuracao-mariadb`.

## Comandos úteis do Vagrant

Executar novamente o provisionamento:

```powershell
vagrant provision
```

Parar uma VM:

```powershell
vagrant halt
```

Reiniciar uma VM:

```powershell
vagrant reload
```

Destruir uma VM específica:

```powershell
vagrant destroy -f
```

Depois de destruí-la, recrie-a com:

```powershell
vagrant up --provider=vmware_desktop
```

## Solução de problemas

### `Permission denied (publickey)`

Confirme, dentro do `control-node`, se a chave existe:

```bash
ls -l /home/vagrant/.ssh/db01_key
chmod 600 /home/vagrant/.ssh/db01_key
```

Teste o SSH diretamente:

```bash
ssh -o IdentitiesOnly=yes \
  -i /home/vagrant/.ssh/db01_key \
  vagrant@192.168.1.4
```

Confirme também se o inventário aponta para a mesma chave:

```bash
ansible-inventory --host db01
```

### `nano: command not found`

O `nano` não vem necessariamente instalado na box. Para editar arquivos,
use `vi` ou escreva o arquivo com um heredoc:

```bash
cat > inventory/hosts.ini <<'EOF'
[apps]
app01

[dbs]
db01 ansible_host=192.168.1.4 ansible_user=vagrant ansible_private_key_file=/home/vagrant/.ssh/db01_key
EOF
```

### A rede privada não responde

Verifique se as VMs estão ligadas e se os endereços estão configurados:

```bash
ping -c 3 192.168.1.4
```

Dentro das VMs, confira as interfaces:

```bash
ip addr
ip route
```

Os endereços esperados são `192.168.1.2` para o `control-node` e
`192.168.1.4` para o `db01`.

## Segurança

Os arquivos gerados pelo Vagrant e as chaves privadas locais são ignorados
pelo [`.gitignore`](./.gitignore). Nunca remova essas regras nem publique uma
chave privada no repositório.
