#!/usr/bin/env bash
# =============================================================================
#  Lab DevOps - Multipass
#  3 VMs : ansible (contrôleur), k8s (Kubernetes), monitoring (Prometheus/Grafana)
#
#  Usage :
#    ./lab.sh up        # crée (ou démarre) les VMs + configure SSH + inventaire Ansible
#    ./lab.sh status    # affiche l'état et les IPs
#    ./lab.sh stop      # arrête les VMs
#    ./lab.sh start     # redémarre les VMs déjà créées
#    ./lab.sh destroy   # supprime définitivement les VMs
# =============================================================================
set -euo pipefail

IMAGE="24.04"   # Ubuntu LTS

# nom      cpus  mémoire  disque
VMS=(
  "ansible     1   2G   10G"
  "k8s         2   4G   25G"
  "monitoring  2   2G   15G"
)

log() { printf '\033[1;34m[lab]\033[0m %s\n' "$*"; }

vm_exists() { multipass info "$1" &>/dev/null; }
vm_ip()     { multipass exec "$1" -- hostname -I | awk '{print $1}'; }

create_vms() {
  for spec in "${VMS[@]}"; do
    read -r name cpus mem disk <<<"$spec"
    if vm_exists "$name"; then
      log "$name existe déjà → démarrage"
      multipass start "$name"
    else
      log "Création de $name ($cpus CPU, $mem RAM, $disk disque)"
      multipass launch "$IMAGE" --name "$name" --cpus "$cpus" --memory "$mem" --disk "$disk"
    fi
  done
}

setup_ansible() {
  log "Installation d'Ansible sur la VM ansible"
  multipass exec ansible -- bash -c '
    if ! command -v ansible >/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y -qq software-properties-common
      sudo add-apt-repository -y --update ppa:ansible/ansible
      sudo apt-get install -y -qq ansible
    fi
    [ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q
  '

  log "Distribution de la clé SSH de ansible vers k8s et monitoring"
  local pubkey
  pubkey=$(multipass exec ansible -- cat .ssh/id_ed25519.pub)
  for target in k8s monitoring; do
    multipass exec "$target" -- bash -c "
      grep -qF '$pubkey' ~/.ssh/authorized_keys || echo '$pubkey' >> ~/.ssh/authorized_keys
    "
  done

  log "Génération de l'inventaire Ansible"
  local k8s_ip mon_ip
  k8s_ip=$(vm_ip k8s)
  mon_ip=$(vm_ip monitoring)

  multipass exec ansible -- bash -c "mkdir -p ~/lab && cat > ~/lab/inventory.ini <<EOF
[kubernetes]
k8s ansible_host=$k8s_ip

[monitoring]
monitoring ansible_host=$mon_ip

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
EOF
cat > ~/lab/ansible.cfg <<EOF
[defaults]
inventory = ./inventory.ini
host_key_checking = False
EOF"

  log "Test de connectivité Ansible"
  multipass exec ansible -- bash -c 'cd ~/lab && ansible all -m ping'
}

status() {
  multipass list | grep -E '^(Name|ansible|k8s|monitoring)\b' || true
}

case "${1:-}" in
  up)
    create_vms
    setup_ansible
    echo
    status
    echo
    log "Lab prêt ! Connecte-toi au contrôleur : multipass shell ansible  (puis cd ~/lab)"
    ;;
  start)   multipass start ansible k8s monitoring; status ;;
  stop)    multipass stop ansible k8s monitoring ;;
  status)  status ;;
  destroy)
    read -rp "Supprimer définitivement ansible, k8s et monitoring ? [o/N] " ok
    [[ "$ok" =~ ^[oOyY]$ ]] && multipass delete ansible k8s monitoring && multipass purge
    ;;
  *) sed -n '2,14p' "$0"; exit 1 ;;
esac