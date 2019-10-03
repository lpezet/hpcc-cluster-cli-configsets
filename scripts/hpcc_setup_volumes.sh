#!/bin/bash

source /opt/hpcc-cluster/functions

run() {
 log info "Setting up volumes..."
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
   if [ ! -z "$raidDeviceName" ]; then
    continue
   fi
   prepare_device $deviceName $deviceType $fsType "" $encrypt
   if [ -z "$mount" ]; then
    continue
   fi
   prepare_mount $mount $mapsTo
   mount_device $deviceName $deviceType $mount   
  done
  
  if [ -f /opt/hpcc-cluster/raids.maps ]; then
   source /opt/hpcc-cluster/raids.maps
   raidsMappingsLength=${#raidsMappings[@]}
   log info "Found $raidsMappingsLength raid entries..."
   for (( i=0; i < $raidsMappingsLength; i+=7 )); do
    raidDeviceName=${raidsMappings[$i]}
    raidLevel=${raidsMappings[$i+1]}
    raidName=${raidsMappings[$i+2]}
    encrypt=${raidsMappings[$i+3]}
    mount=${raidsMappings[$i+4]}
    mapsTo=${raidsMappings[$i+5]}
    fsType=${raidsMappings[$i+6]}
    declare -a raidDevices
    for (( j=0; j < $volumesMappingsLength; j+=7 )); do
     volumeDeviceName=${volumesMappings[$j]}
     volumeRaidDeviceName=${volumesMappings[$j+5]}
     if [ "${raidDeviceName}" = "${volumeRaidDeviceName}" ]; then
      raidDevices+=($volumeDeviceName)
     fi
    done
    if [ ${#raidDevices[@]} -eq 0 ]; then
     log warn "No devices found for array ${raidDeviceName}. Skipping."
     continue
    fi
    allRaidDevices="${raidDevices[@]}"
    log info "Working on raid $raidDeviceName (name=$raidName) with ${#raidDevices[@]} devices: [$allRaidDevices]..."
    prepare_raid $raidDeviceName $raidLevel $raidName ${#raidDevices[@]} "${allRaidDevices}"
    prepare_device $raidDeviceName "raid" $fsType $raidName
    prepare_mount $mount $mapsTo
    mount_device $raidDeviceName "raid" $mount $raidName
   done
   if [ $raidsMappingsLength -gt 0 ]; then
    mdadm --detail --scan | sudo tee -a /etc/mdadm.conf
    #echo "MAILADDR it@archwayha.com" >> /etc/mdadm.conf
    log warn "Updating initramfs..."
    dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
   fi
  fi
 fi
 
 mount -a
 ensure_hpcc_permissions
 
}

run
exit 0