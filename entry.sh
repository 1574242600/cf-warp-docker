#!/usr/bin/env bash
set -e

#我学艺不精，不知道为什么别名无效，希望有大佬指点一下
# alias warp-cli='warp-cli --accept-tos'

DEFAULT_GATEWAY_NETWORK_CARD_NAME=`route  | grep default  | awk '{print $8}' | head -1`
DEFAULT_ROUTE_IP=`ifconfig $DEFAULT_GATEWAY_NETWORK_CARD_NAME | grep "inet " | awk '{print $2}' | sed "s/addr://"`

#-4|-6
runwgcf() {
  trap '_downWarp' ERR TERM INT
  systemctl start warp-svc

  WARP_PATH="/var/lib/cloudflare-warp"

  if [ ! -e "$WARP_PATH/reg.json" ]; then
    warp-cli --accept-tos register
    warp-cli --accept-tos set-mode warp
    warp-cli --accept-tos enable-always-on
  else 
    warp-cli --accept-tos rotate-keys
  fi 


  case $1 in
    "-4")
        [[ $(warp-cli --accept-tos get-excluded-routes) =~ "0.0.0.0/0" ]] && warp-cli --accept-tos remove-excluded-route 0.0.0.0/0
        warp-cli --accept-tos add-excluded-route ::/0
        ;;
    "-6")
        [[ $(warp-cli --accept-tos get-excluded-routes) =~ "::/0" ]] && warp-cli --accept-tos remove-excluded-route ::/0
        warp-cli --accept-tos add-excluded-route 0.0.0.0/0
        ;;
      *) 
        warp-cli --accept-tos remove-excluded-route 0.0.0.0/0
        warp-cli --accept-tos remove-excluded-route ::/0
  esac

  ip rule add from $DEFAULT_ROUTE_IP lookup main prio 0
  connectWarp
  
  echo 
  case $1 in
    "-4")
      _checkV4 || _downWarp 1
      ;;
    "-6")
      _checkV6 || _downWarp 1
      ;;
    *)
      (_checkV4 && echo && _checkV6) || _downWarp 1
      ;;
  esac


  echo 
  echo "OK, cf-warp is up."
  
  sleep infinity & wait
}


_downWarp() {
  echo
  echo "clean up"

  if ! warp-cli --accept-tos disconnect; then
    echo "error down"
  fi

  ip rule delete from $DEFAULT_ROUTE_IP lookup main

  echo "clean up done"
  exit $1;
}

_checkV4() {
  _check 4
}

_checkV6() {
  _check 6
}

_check() {
  echo "Checking ipv$1 network status, please wait...."; echo;

  errorCount=0;
  while ! curl -s$1 --max-time 2  https://www.cloudflare.com/cdn-cgi/trace/; do
    if [[ $errorCount = 3 ]]; then return 1; fi;
    
    warp-cli --accept-tos disconnect;

    echo "Sleep 3 and retry again. count: $((errorCount + 1))/3";
    sleep 3;
    
    connectWarp;
    let errorCount++;
  done
}

connectWarp() {
  warp-cli --accept-tos connect;
  sleep 3;
}

if [ -z "$@" ] || [[ "$1" = -* ]]; then
  runwgcf "$@"
else
  exec "$@"
fi
