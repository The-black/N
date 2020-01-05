#!/bin/bash -e
#
# APK Watcher installer 
# 
# All params should be set in apkwatcher.cof prior to running the installer.
# The installer should be run by a user with sudo permissions
#

die(){
  echo $1
  echo -e "Subject: Problem with apkwatcher\n\n$1" | $SENDMAIl_COMMAND $MAINTAINER_EMAIL
  exit 1
}

WORKDIR=`dirname "$0"`
cd $WORKDIR
. ./apkwatcher.conf
[ -z "$APKWATCHER_DIR" ] && die "Configuration file not found in current dir"

sudo mkdir -p ${CONF_DIR}
sudo cp apkwatcher.sh apkwatcher.conf "${APKWATCHER_DIR}/"
sudo cp apkwatcher.d/* "${CONF_DIR}/"
sudo chown -R $APKWATCHER_USER $APKWATCHER_DIR

echo "# Settings for apkwatcher" | sudo tee  /etc/cron.d/apkwatcher  > /dev/null
echo "42 */2 * * * $APKWATCHER_USER ${APKWATCHER_DIR}/apkwatcher.sh" | sudo tee -a /etc/cron.d/apkwatcher  > /dev/null
echo "# Done with apkwatcher settings" | sudo tee -a /etc/cron.d/apkwatcher  > /dev/null

echo "Done, apkwatcher installed at ${APKWATCHER_DIR}"

