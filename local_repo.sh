#!/bin/bash
# local_repo.sh [image] [mount point]

if [ $# -eq 0 ]; then
  echo use: local_repo.sh [image] [mount point]
  echo example: local_repo.sh CentOS-8.2.iso /repos/CentOS82
  exit 1
fi

mkdir -p $2
mount -o loop $1 $2
grep $2 /etc/mtab >> /etc/fstab

# set repo cfg file
repo_cfg="/etc/yum.repos.d/local.repo"
while true; do
    read -p "this is version 8 or later? (y/n)" yn
    case $yn in
        [Yy]* ) 
            echo "[local-repo-baseos]" > $repo_cfg
            echo "name=Local Repository - BaseOS" >> $repo_cfg
            echo "baseurl=file://$2/BaseOS" >> $repo_cfg
            echo "enabled=1" >> $repo_cfg
            echo "gpgcheck=0" >> $repo_cfg

            echo "[local-repo-app]" >> $repo_cfg
            echo "name=Local Repository - AppStream" >> $repo_cfg
            echo "baseurl=file://$2/AppStream" >> $repo_cfg
            echo "enabled=1" >> $repo_cfg
            echo "gpgcheck=0" >> $repo_cfg
            break;;
        [Nn]* ) 
            echo "[local-repo]" >> $repo_cfg
            echo "name=Local Repository" >> $repo_cfg
            echo "baseurl=file://$2" >> $repo_cfg
            echo "enabled=1" >> $repo_cfg
            echo "gpgcheck=0" >> $repo_cfg
            break;;

        * ) echo "please answer yes or no.";;
    esac
done


# check 
echo ---------- check yum ------------
yum repolist | grep local-repo
echo ---------- check fstab ----------
tail /etc/fstab
echo ---------------------------------

exit 0
