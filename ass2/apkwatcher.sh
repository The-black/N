#!/bin/bash
#
# APK Watcher - notify when an APK is updated
#

# Initialize environment
WORKDIR=`dirname "$0"`
. ${WORKDIR}/apkwatcher.conf

die(){
  echo $1
  echo -e "Subject: Problem with apkwatcher\n\n$1" | $SENDMAIl_COMMAND $MAINTAINER_EMAIL
  exit 1
}

warn(){
  echo $1
  echo -e "Subject: Warning in apkwatcher\n\n$1" | $SENDMAIl_COMMAND $MAINTAINER_EMAIL
}

# Loop through APKs
for apk in `cd "$CONF_DIR" ; ls` ; do
  . "${CONF_DIR}/$apk"                                          # Load specific APK config
  case "$FEED_SOURCE" in
    apkmirror)
    currVersion=`$CURL $APKMIRROR_CURL_FLAGS ${APKMIRROR_MAIN_URL}/${APK_AUTHOR}/${APK_NAME}/ 2>/dev/null | grep "/apk/${APK_AUTHOR}/${APK_NAME}/" | grep fontBlack | head -1 | sed 's~^.* ~~g' | sed 's~<.*$~~'`
    [ -z "$currVersion" ] && die "Failed to get version for $apk apk"
    if [ "$currVersion" != "$APK_VERSION" ] ; then              # New version detected
      releasePage=`$CURL $APKMIRROR_CURL_FLAGS ${APKMIRROR_MAIN_URL}/${APK_AUTHOR}/${APK_NAME}/${APK_NAME}-${currVersion//./-}-release/ 2>/dev/null`
      releaseNotes=`echo "$releasePage" | grep releaseNotes | head -1 | sed 's~^.*releaseNotes" content="~~' | sed 's~" />.*$~~'` 
      [ -z "$releaseNotes" ] && warn "Release notes empty for $apk version $currVersion"
      datePublished=`echo "$releasePage" | grep datePublished | awk '{print $2}' | tr -d '",'`
      [ -z "$datePublished" ] && warn "datePublished empty for $apk version $currVersion"
      dateModified=`echo "$releasePage" | grep dateModified | awk '{print $2}' | tr -d '",'`
      [ -z "$dateModified" ] && warn "dateModified empty for $apk version $currVersion"
      echo -e "Subject: New APK release: $apk version ${currVersion}\n\nAPK name: ${APK_NAME}\nAPK author: ${APK_AUTHOR}\nPrevious version: ${APK_VERSION}\nNew version: ${currVersion}\nPublish date: ${datePublished}\nModify date: ${dateModified}\n\nRelease notes:\n${releaseNotes}\n"  | $SENDMAIl_COMMAND $WATCHER_EMAIL
      echo "${APK_NAME},${APK_AUTHOR},${APK_VERSION},${currVersion},${datePublished},${dateModified}" >> $ACTIVITY_LOG
      sed -i "s~^APK_VERSION.*$~APK_VERSION=\"${currVersion}\"~" "${CONF_DIR}/$apk"
    fi
    ;;
    *)
      die "Unknown feed source in $apk apk"
    ;;
  esac                 
done
