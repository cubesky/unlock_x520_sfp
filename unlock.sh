#!/bin/bash
intf=$1
if [ -z $intf ]; then
  echo "Interface $intf not set."
  exit 3
fi

if [ -f "/sys/class/net/$intf/device/device" ];then
  vdr_id=$(cat /sys/class/net/$intf/device/vendor)
  dev_id=$(cat /sys/class/net/$intf/device/device)
  if [[ $vdr_id == "0x8086" ]]; then
     echo "Check failed: Interface $intf not Intel X520 Card (VDR $vdr_id)"
     exit 3
  fi
  if [[ $dev_id == "0x154d" || $dev_id == "0x10fb" ]]; then
    val=$(ethtool -e $intf offset 0x58 length 1 | tail -n 1 | cut -d : -f 2 | xargs)
    val_bin=$(echo "obase=10; ibase=16; ${val^^}" | bc)
    val_def=$((val_bin & 1))
    if [ $val_def -eq 1 ]; then
      echo "Card is unlocked."
      exit 0
    else
      echo "Unlocking..."
      new_val_dec=$((val_bin | 1))
      new_val=$(echo "obase=16; ibase=10; ${new_val_dec^^}" | bc | awk '{print tolower($0)}')
      magic="$dev_id8086"
      ethtool -E $intf magic $magic offset 0x58 value 0x$new_val length 1
      echo "Reboot the machine for changes to take effect..."
    fi
  else
    echo "Check failed: Interface $intf not Intel X520 Card (DEV $dev_id)"
    exit 3
  fi
else
  echo "Interface $intf can not read."
  exit 3
fi
