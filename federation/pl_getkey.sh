#!/bin/bash

source /etc/planetlab/plc_config
export GNUPGHOME=/etc/planetlab/
dir=$PLC_NAME/

mkdir -p "$dir"

gpg -a --export > "$dir$PLC_NAME.gpg"
cp /etc/planetlab/api_ca_ssl.crt "$dir$PLC_NAME.crt"
echo https://$PLC_API_HOST:$PLC_API_PORT/$PLC_API_PATH > "$dir$PLC_NAME.url"

tar -czf "$PLC_NAME.tar.gz" "$dir"