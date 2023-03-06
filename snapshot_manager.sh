#!/usr/bin/env bash

usage() {
cat << EOF
  Usage: [Arg]...
  
  Arguments:
    -c, --create DOMAIN NAME DISK        Create snapshot
    -r, --restore DOMAIN NAME DISK      Restore to created snapshot
    -d, --delete DOMAIN NAME DISK        Delete snapshot
EOF
}

create() {
  local domain=${1}
  local name=${2}
  local disk=${3}
  
  echo "INFO: Creating snapshot..."
  virsh snapshot-create-as ${domain} --name ${name} --disk-only
  echo "INFO: Snapshot created"
}

restore() {
  local domain=${1}
  local name=${2}
  local disk=${3}

  echo "INFO: Finding pooldir..."
  pooldir=$(virsh pool-dumpxml default | grep -Po "(?<=path\>)[^<]+")
  cd $pooldir
  echo "INFO: Finding snapshot files..."
  backingfile=$(qemu-img info $domain.$name -U | grep -Po 'backing file:\s\K(.*)')
  echo "INFO: Stopping vm..."
  virsh destory $domain
  
  echo "INFO: Restoring to snapshot..."
  virt-xml $domain --edit target=$disk --disk path=$backingfile --update
}

delete() {
  local domain=${1}
  local name=${2}
  local disk=${3}
  pooldir=$(virsh pool-dumpxml default | grep -Po "(?<=path\>)[^<]+")

  echo "INFO: Deleting snapshot..."
  virsh snapshot-delete --metadata $domain $name
  sudo rm $pooldir/$domain.$name
}

if [ $# -gt 0 ]; then
  while (( $# > 0 ))
  do
    case $1 in
      -h | --help)
        usage
        ;;
      -c | --create)
        create $2 $3 $4
        ;;
      -r | --restore)
        restore $2 $3 $4
        ;;
      -d | --delete)
        delete $2 $3 $4
    esac
    shift
  done
else
  usage
fi
