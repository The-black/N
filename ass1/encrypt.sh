#!/bin/bash -e
#
# Encrypt a VM on the local VirtualBox (not exportable)
#
# The settings here are the default for running under Cygwin on a windows host.
# Adjust them for other environments
VAGRANT='vagrant' 
VBOXMANAGE='/cygdrive/c/Progra~1/Oracle/VirtualBox/VBoxManage.exe'
VM='Kiosk'
PASSWORDID='Boot-password'
EXPORTFORMAT='ovf'

die(){
  echo "$1"
  exit 1
}

encrypt_disk(){
  HDD_UUID=`"$VBOXMANAGE" showvminfo $VM | grep 'SATA.*UUID' | sed 's~^.*UUID: ~~' | sed 's~).*$~~'`
  [ -z "$HDD_UUID" ] && die "Cannot find disk for VM ${VM}. Did yu run \"vagrant up\" ?"
  "$VBOXMANAGE" encryptmedium "$HDD_UUID" --newpassword - --newpasswordid $PASSWORDID --cipher "AES-XTS256-PLAIN64" || die "Failed to encrypt disk $HDD_UUID for VM $VM"
}


vagrantStatus=`$VAGRANT status | grep $VM | awk '{print $2}'`
case $vagrantStatus in
  running)
    echo "$VM is up, shutting it down for encryption"
    $VAGRANT halt
    encrypt_disk
    $VAGRANT up
    ;;
  saved|poweroff)
    echo "Encrypting $VM"
    encrypt_disk
    ;;
  not)
    echo "$VM is not created. Starting it up and shutting it down for encryption"
    $VAGRANT up
    $VAGRANT halt
    encrypt_disk
    ;;
  *)
    die "Unrecognised status: $vagrantStatus"
    ;;
esac




