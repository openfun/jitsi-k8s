#!/usr/bin/env bash

#set -eo pipefail

function assert_env_selected()
{
  if [[ -z "${JITSI_K8S_ENV}" ]]; then
    echo "You must choose an environment by running the bin/activate command"
    exit 10
  fi
}
