#!/bin/bash
cat << 'EOF'
  __  __     __         __     _  ______ ___  ___
 / / / /__  / /__  ____/ /__  | |/_/ __/|_  |/ _ \
/ /_/ / _ \/ / _ \/ __/  '_/ _>  </__ \/ __// // /
\____/_//_/_/\___/\__/_/\_\ /_/|_/____/____/\___/

Powered by 网络世界小白 & LiYin
EOF

intf=$1
echo "Checking for interface $intf..."
if [ -z $intf ]; then
  echo "Interface $intf not set."
  exit 3
fi

if ! [ -x "$(command -v ethtool)" ]; then
  echo 'Error: ethtool is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v xargs)" ]; then
  echo 'Error: xargs is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v cut)" ]; then
  echo 'Error: cut is not installed.' >&2
  exit 1
fi

if [ -f "/sys/class/net/$intf/device/device" ];then
  vdr_id=$(cat /sys/class/net/$intf/device/vendor | xargs)
  dev_id=$(cat /sys/class/net/$intf/device/device | xargs)
  if ! [[ "$vdr_id" == "0x8086" ]]; then
     echo "Check failed: Interface $intf not Intel X520 Card (VDR $vdr_id)"
     exit 3
  fi
  if [[ "$dev_id" == "0x154d" || "$dev_id" == "0x10fb" ]]; then
    val=$(ethtool -e $intf offset 0x58 length 1 | tail -n 1 | cut -d : -f 2 | xargs)
    val_bin=$((16#$val))
    val_def=$((val_bin & 1))
    if [ $val_def -eq 1 ]; then
      echo "Card is unlocked."
      exit 0
    else
      echo "Unlocking..."
      new_val_dec=$((val_bin | 1))
      new_val=$(printf '%x\n' $new_val_dec)
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
