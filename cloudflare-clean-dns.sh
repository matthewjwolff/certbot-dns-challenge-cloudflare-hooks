#!/bin/bash

source "/run/secrets/cloudflare_dns"

CHALLENGE_PREFIX="_acme-challenge"
CHALLENGE_DOMAIN="${CHALLENGE_PREFIX}.${CERTBOT_DOMAIN}"
PARENT_DOMAIN=$(sed 's/.*\.\(.*\..*\)/\1/' <<< "${CERTBOT_DOMAIN}")

CLOUDFLARE_ZONE=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=${PARENT_DOMAIN}" \
     -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
     -H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
     -H "Content-Type: application/json" -s | jq -r '.result[0].id')

echo "DOMAIN: ${CHALLENGE_DOMAIN}"
echo "ZONE: ${CLOUDFLARE_ZONE}"

records=($(curl -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records?type=TXT&name=${CHALLENGE_DOMAIN}&page=1&per_page=100" \
     -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
     -H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
     -H "Content-Type: application/json" -s | jq -r ".result[].id"))

echo "${records}"

for record in "${records[@]}"; do
    echo "clean: $record"
    curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records/${record}" \
    	-H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
    	-H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
    	-H "Content-Type: application/json" -s | jq -r "[.success, .errors[].message] | @csv"
done
