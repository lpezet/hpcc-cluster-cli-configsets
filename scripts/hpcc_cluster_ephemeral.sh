#!/bin/bash
#
# /etc/init.d/hpcc_cluster_ephemeral
#
# chkconfig: 2345 95 05
# description: Setup ephemeral volumes for HPCC Node
#
# processname: hpcc_cluster_ephemeral

source /opt/hpcc-cluster/functions

run() {
 log info "Setting up ephemeral volumes..."
 if [ -f /opt/hpcc-cluster/volumes.maps ]; then
  source /opt/hpcc-cluster/volumes.maps
  volumesMappingsLength=${#volumesMappings[@]}
  log info "Found $volumesMappingsLength volume entries..."
  for (( i=0; i < $volumesMappingsLength; i+=7 )); do
   deviceName=${volumesMappings[$i]}
   deviceType=${volumesMappings[$i+1]}
   encrypt=${volumesMappings[$i+2]}
   mount=${volumesMappings[$i+3]}
   mapsTo=${volumesMappings[$i+4]}
   raidDeviceName=${volumesMappings[$i+5]}
   fsType=${volumesMappings[$i+6]}
   if [ ! -z "$raidDeviceName" -o ! "$deviceType" = "ephemeral" ]; then
    log info "Skipping raid and non ephemeral device [$deviceName]."
    continue
   fi
   log info "Working on ephemeral device [$deviceName]..."
   prepare_device $deviceName $deviceType $fsType "" $encrypt
   prepare_mount $mount $mapsTo
   mount_device $deviceName $deviceType $mount   
  done
 fi
 mount -a
 ensure_hpcc_permissions
 
}

case "$1" in
    start)
    run
    ;;
    stop)
    echo "No need to stop."
    ;;
    restart)
    run
    ;;
    status)
    echo "Start this script to setup and mount ephemeral devices if not done already."
    ;;
    *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0