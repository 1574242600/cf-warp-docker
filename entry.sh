#!/usr/bin/env bash

set -e

DEFAULT_GATEWAY_NETWORK_CARD_NAME=`route  | grep default  | awk '{print $8}' | head -1`
DEFAULT_ROUTE_IP=`ifconfig $DEFAULT_GATEWAY_NETWORK_CARD_NAME | grep "inet " | awk '{print $2}' | sed "s/addr://"`

#-4|-6
runwgcf() {
  trap '_downwgcf' ERR TERM INT
  systemctl start warp-svc

  WARP_PATH="/var/lib/cloudflare-warp"




  if [ ! -e "$WARP_PATH/reg.json" ]; then
    echo "y" | warp-cli register
    warp-cli set-mode warp
  else 
    echo "y" | warp-cli rotate-keys
  fi 


  case $1 in
    "-4")
        [[ $(warp-cli get-excluded-routes) =~ "0.0.0.0/0" ]] && warp-cli remove-excluded-route 0.0.0.0/0
        warp-cli add-excluded-route 0::/0
        ;;
    "-6")
        [[ $(warp-cli get-excluded-routes) =~ "0::/0" ]] && warp-cli remove-excluded-route 0::/0
        warp-cli add-excluded-route 0.0.0.0/0
        ;;
  esac

  warp-cli connect && ip rule add from $DEFAULT_ROUTE_IP lookup main
  
  echo 
  case $1 in
    "-4")
      _checkV4
      ;;
    "-6")
      _checkV6
      ;;
    *)
      echo "ipv4: "
      _checkV4
      echo 
      echo "ipv6: "
      _checkV6
      ;;
  esac


  echo 
  echo "OK, cf-warp is up."
  
  sleep infinity & wait
}


_downwgcf() {
  echo
  echo "clean up"
  if ! warp-cli disconnect; then
    echo "error down"
  fi
  ip rule delete from $DEFAULT_ROUTE_IP lookup main
  echo "clean up done"
  exit 0
}




_checkV4() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2  https://www.cloudflare.com/cdn-cgi/trace/; do
    warp-cli disconnect
    echo "Sleep 2 and retry again."
    sleep 2
    warp-cli connect
  done
}

_checkV6() {
  echo "Checking network status, please wait...."
  while ! curl --max-time 2 -6 https://www.cloudflare.com/cdn-cgi/trace/; do
    warp-cli disconnect
    echo "Sleep 2 and retry again."
    sleep 2
    warp-cli connect
  done
}



if [ -z "$@" ] || [[ "$1" = -* ]]; then
  runwgcf "$@"
else
  exec "$@"
fi