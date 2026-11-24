# Lab n°1 


## 1. Créer les VM avec Vagrant
 
> Toujours lancer Vagrant **sans sudo**, depuis `ubuntu-env/`, avec l'utilisateur qui possède la clé SSH
> (sinon le `Vagrantfile` cherche la clé dans `/root/.ssh/`).
 
```bash
cd ~/devops-ansible/ubuntu-env
vagrant up                       # crée et provisionne les 4 VM (long la première fois)
vagrant status                   # les 4 VM doivent être "running"
```
 
Le provisioning de chaque VM :
1. garantit la config réseau `eth1` (netplan) avec l'IP fixe ;
2. ajoute la clé publique de l'hôte dans `authorized_keys` (sans doublon) ;
3. synchronise l'horloge ;
4. installe `python3`, `python3-apt` et `curl` (requis par Ansible).

---
 
## 2. Tester Ansible
 
```bash
cd ~/devops-ansible/ubuntu-env   # ansible.cfg est lu depuis le dossier courant
ping -c 2 192.168.56.10          # 1. réseau
ssh vagrant@192.168.56.10 hostname   # 2. SSH manuel → "monitoring"
ansible all -m ping              # 3. Ansible → 4 x "pong"
```
 
Autres commandes :
 
```bash
ansible-inventory --graph                    # arbre des groupes
ansible k8s_servers -m ping                  # un groupe
ansible all -a "uptime"                      # commande ad hoc
ansible all -m ping -vvv                     # mode verbeux pour diagnostiquer
```
 
---

