#!/bin/sh

# DSM Config
__USERNAME__="$(echo ${@} | cut -d' ' -f1)"
__PASSWORD__="$(echo ${@} | cut -d' ' -f2)"
__HOSTNAME__="$(echo ${@} | cut -d' ' -f3)"
__MYIP__="$(echo ${@}  | cut -d' ' -f4)"

# log location
__LOGFILE__="/var/log/cloudflareddns.log"

# CloudFlare Config
__RECTYPE__="A"
__RECID__="fa9a2ebe560459d99dada1d55fab4b7a"
__ZONE_ID__="bc7eab81c6191707f7b8abb9c1715e8e"
__TTL__="1"
__PROXY__="false"
# example: http://127.0.0.1:1080
__ADDR_PROXY__=""
__EXTERNEL_CMD__=""


log() {
    __LOGTIME__=$(date +"%b %e %T")
    if [ "${#}" -lt 1 ]; then
        false
    else
        __LOGMSG__="${1}"
    fi
    if [ "${#}" -lt 2 ]; then
        __LOGPRIO__=7
    else
        __LOGPRIO__=${2}
    fi

    logger -p ${__LOGPRIO__} -t "$(basename ${0})" "${__LOGMSG__}"
    echo "${__LOGTIME__} $(basename ${0}) (${__LOGPRIO__}): ${__LOGMSG__}" >> ${__LOGFILE__}
}


__URL__="https://api.cloudflare.com/client/v4/zones/${__ZONE_ID__}/dns_records/${__RECID__}"


if [ ! -z "$__ADDR_PROXY__" -a -z "$(curl  -sS "$__ADDR_PROXY__")" ];then
      __EXTERNEL_CMD__="-x $__ADDR_PROXY__"
      log "proxy server already set."
    else
      log "proxy server not set yet."
fi

# Update DNS record:
log "Updating with ${__MYIP__}..."
__RESPONSE__=$(curl -s -X PUT "${__URL__}" \
     -H "X-Auth-Email: ${__USERNAME__}" \
     -H "X-Auth-Key: ${__PASSWORD__}" \
     ${__EXTERNEL_CMD__} \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"${__RECTYPE__}\",\"name\":\"${__HOSTNAME__}\",\"content\":\"${__MYIP__}\",\"ttl\":${__TTL__},\"proxied\":${__PROXY__}}")

# Strip the result element from response json
__RESULT__=$(echo ${__RESPONSE__} | grep -Po '"success":\K.*?[^\\],')
echo ${__RESPONSE__}
case ${__RESULT__} in
    'true,')
        __STATUS__='good'
        true
        ;;
    *)
        __STATUS__="${__RESULT__}"
        log "__RESPONSE__=${__RESPONSE__}"
        false
        ;;
esac
log "Status: ${__STATUS__}"

printf "%s" "${__STATUS__}"
