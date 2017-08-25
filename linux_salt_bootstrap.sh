#!/usr/bin/env bash


set -e
set -u

readonly MASTER_CONFIG='file_roots:,  base:,    - /srv/salt,    - /srv/formulas,    - /srv/salt/roles,pillar_roots:,  base:,    - /srv/pillar,  dev:,    - /srv/pillar/dev,  production:,    - /srv/pillar/production'


function bootstrap_salt_master() {
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
}

function install_salt_repo() {
  rpm --import https://repo.saltstack.com/yum/redhat/7/x86_64/archive/2016.3.1/SALTSTACK-GPG-KEY.pub
  local repofile='/etc/yum.repos.d/saltstack.repo'
  echo '[saltstack-repo]' > $repofile
  echo 'name=SaltStack repo for RHEL/CentOS $releasever' >> $repofile
  echo 'baseurl=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/archive/2016.3.1' >> $repofile
  echo 'enabled=1'  >> $repofile
  echo 'gpgcheck=1' >> $repofile
  echo 'gpgkey=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/archive/2016.3.1/$releaseverSALTSTACK-GPG-KEY.pub' >> $repofile
  yum clean all
}

function install_salt_master() {
  install_salt_repo
  yum install salt-master salt-minion -y
  echo -e "$MASTER_CONFIG" | tr ',' '\n' > /etc/salt/master
  for service in salt-master salt-minion; do
    systemctl enable $service.service
    systemctl start $service.service
  done
  bootstrap_salt_master $2 $3 $4 $5
}

function install_salt_minion() {
  local master=$1
  install_salt_repo
  yum install salt-minion -y
  echo "master: $master" > /etc/salt/minion
  systemctl enable salt-minion.service
  systemctl start salt-minion.service
}


main() {
  if [[ $1 == 'master' ]]; then
     install_salt_master $2 $3 $4 $5
  else
     install_salt_minion $2
  fi
}
main $@
