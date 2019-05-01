#!/usr/bin/env bash

## TODO:  accept salt version as an arg (include py2 vs py3 options or force a legacy script to exist?)

set -e
set -u

readonly MASTER_CONFIG='file_roots:,  base:,    - /srv/salt,    - /srv/formulas,    - /srv/salt/roles,pillar_roots:,  base:,    - /srv/pillar,  dev:,    - /srv/pillar/dev,  production:,    - /srv/pillar/production'



function install_salt_repo_ubuntu() {
  ## TODO:  grab ubuntu version to make multi-version
  wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | apt-key add -
  if [ -f /etc/apt/sources.list.d/saltstack.list]; then
    echo "repo already added"
  else
    echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2017.7 xenial main" > /etc/apt/sources.list.d/saltstack.list
  fi
}

function install_salt_repo_rhel() {
  yum install -y wget
  cd /tmp
  wget https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm
  rpm -i /tmp/salt-repo-2017.7-1.el7.noarch.rpm
  yum clean all
}

function install_salt_master() {
  install_salt_repo_rhel
  yum install salt-master salt-minion -y
  echo -e "$MASTER_CONFIG" | tr ',' '\n' > /etc/salt/master
  for service in salt-master salt-minion; do
    systemctl enable $service.service
    systemctl start $service.service
  done
}

function install_salt_minion() {
  local master=$1
  if [[ $(uname -a) =~ 'Ubuntu' ]]; then
    install_salt_repo_ubuntu
    apt update
    apt install -y salt-minion
  else
    install_salt_repo_rhel
    yum install salt-minion -y
  fi
  echo "master: $master" > /etc/salt/minion.d/master.conf
  systemctl enable salt-minion.service
  systemctl start salt-minion.service
  systemctl restart salt-minion.service
}


main() {
  if [[ $1 == 'master' ]]; then
    install_salt_master
    tmp=$(mktemp -d)
    yum install -y python-pip
    pip install blobxfer
    #
    cd $tmp
    #blobxfer --download mystorageacct container0 mylocalfile.txt --saskey <really_long_key>
    blobxfer --download $2 $3 $4 --saskey $5
    tar xzf *tgz
    mv -f /srv "/srv.$(date +%s)"
    mv dist /srv
    chown -R root: /srv
    systemctl restart salt-master
  else
    install_salt_minion $2
  fi
}
main $@
