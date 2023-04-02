#!/usr/bin/env bash

set -e
set -x

IP=$1

STATUSCODE=$(curl --silent -I http://${IP}:8000/ | head -n 1|cut -d$' ' -f2)
if [[ $STATUSCODE -ne 200 ]]; then
    exit 1
    echo "your deployed web app seems to be down, failing the pipeline and sending out an email"
    # send email
else
    echo "web-app is up"
fi
