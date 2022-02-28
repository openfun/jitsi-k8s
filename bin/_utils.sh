#!/usr/bin/env bash

#set -eo pipefail

function assert_env_selected()
{
  if [[ -z "${JITSI_K8S_ENV}" ]]; then
    echo "You must choose an environment by running the bin/activate command"
    exit 10
  fi
}

function random_password()
{
  declare -i size=${1:-32}
  head -c 4096 < /dev/urandom | base64 | tr -dc A-Z-a-z-0-9 | head -c"${size}"
}
