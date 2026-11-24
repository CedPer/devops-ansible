# Lab d'entraînement Ansible


## Liste des LAB 

- [Lab n°1](lab1/README.MD)



## 1. Préparer le serveur Ubuntu 24.04
 
### 1.1 Mise à jour et paquets de base
 
```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y openssh-server git curl wget vim software-properties-common
```
 
### 1.2 Activer le serveur SSH
 
```bash
sudo systemctl enable --now ssh
sudo systemctl status ssh        # doit être "active (running)"
ip -br a                         # repérer l'IP du serveur pour s'y connecter
```
 
### 1.3 Installation Ansible
 
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
```
---

## 2. Clés SSH
 
### 2.1 Créer la clé
 
```bash
ssh-keygen -t ed25519 -C "ansible-hote"      # fichier par défaut : ~/.ssh/id_ed25519
```
 
Le `Vagrantfile` injecte automatiquement `~/.ssh/id_ed25519.pub` (ou à défaut `~/.ssh/id_rsa.pub`)
dans `/home/vagrant/.ssh/authorized_keys` de chaque VM lors du provisioning.
 
> ⚠️ La clé doit exister **avant** le `vagrant up`. Sinon : la créer puis lancer `vagrant provision`.
 
### 2.2 Clé avec passphrase → utiliser ssh-agent
 
Ansible lance SSH en mode non interactif : il **ne peut pas saisir la passphrase**.
Sans agent, le résultat est `Permission denied (publickey,password)` alors que le ping fonctionne.
 
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519        # passphrase demandée une seule fois
ssh-add -l                       # vérifier que la clé est chargée
```
 
Pour ne pas le refaire à chaque session :
 
```bash
# ~/.ssh/config
Host *
    AddKeysToAgent yes
```
 
```bash
# à la fin de ~/.bashrc
if [ -z "$SSH_AUTH_SOCK" ]; then eval "$(ssh-agent -s)" >/dev/null; fi
```

---

## 3. Git
 
### 3.1 Récupérer le dépôt
 
```bash
cd ~
git clone git@github.com:CedPer/devops-ansible.git
cd devops-ansible
```
 
> Dépôt déjà cloné en HTTPS ? Passer en SSH :
> `git remote set-url origin git@github.com:CedPer/devops-ansible.git`
 
### 3.2 Cycle de travail
 
```bash
git pull --rebase                # récupérer les changements distants
git status                       # voir ce qui a changé
git add .                        # ou un fichier précis
git commit -m "Ajout du rôle nginx"
git push
```
 
Commandes utiles :
 
```bash
git log --oneline -10            # historique récent
git diff                         # changements non indexés
git remote -v                    # URL du remote
git ls-files | grep vagrant/     # doit être vide : .vagrant/ ne doit jamais être poussé
```
 
> Un fichier déjà commité reste suivi même s'il est dans `.gitignore`.
> Pour l'en retirer sans le supprimer du disque : `git rm -r --cached <chemin>`.
 
---

## 4. Installer VirtualBox et Vagrant (playbook Ansible)
 
Le playbook s'exécute sur l'hôte lui-même (`localhost`) : VirtualBox depuis les dépôts Ubuntu,
Vagrant depuis le dépôt officiel HashiCorp.
 
```bash
cd ~/devops-ansible/ubuntu-env
ansible-playbook deploy_virtualbox_vagrant.yml -K     # -K : demande le mot de passe sudo
```
 
Vérification :
 
```bash
VBoxManage --version
vagrant --version
```
 
---


