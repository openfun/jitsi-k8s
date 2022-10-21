#!/usr/bin/env python3
"""
This script is meant to run as a sidecar-container on a jvb pod.
It updates the pod deletion cost annotation based on the number of
participants on the JVB.

For more information on Pod deletion cost, see:
https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost
"""

import json
import logging
import os
import time
import signal
from ssl import create_default_context
import sys
from urllib import request

# Time to wait between each jvb status check
from urllib.error import HTTPError, URLError

update_period_seconds = os.getenv("UPDATE_PERIOD_SECONDS", 60)

# -- JVB
# URL to colibri API
# https://github.com/jitsi/jitsi-videobridge/blob/master/doc/rest-colibri.md
colibri_api = os.getenv(
    "COLIBRI_API", "http://127.0.0.1:8080/colibri/stats"
)

# -- Kubernetes
# URL to reach Kubernetes' API
k8s_api = os.getenv("K8S_API", "https://kubernetes.default.svc")
# Path to ServiceAccount token
service_account_directory = os.getenv(
    "K8S_SA_DIRECTORY", "/var/run/secrets/kubernetes.io/serviceaccount"
)

# Reference the internal certificate authority (CA)
cacert = f"{service_account_directory}/ca.crt"

# Service account Bearer token
bearer = open(f"{service_account_directory}/token", "r").read()

# Current pod namespace
namespace = open(f"{service_account_directory}/namespace", "r").read()
pod_name = os.getenv("HOSTNAME")

# Exit gracefully if SIGTERM signal is sent
def sigterm_handler(_signo, _stack_frame):
    """Exit gracefully."""
    sys.exit(0)
signal.signal(signal.SIGTERM, sigterm_handler)


def get_colibri_stats():
    """Call Colibri API and return stats."""
    response = request.urlopen(colibri_api)
    if response.getcode() != 200:
        raise HTTPError(colibri_api, response.getcode(), "Unexpected response code", {}, None)
    return json.load(response)


def update_pod_metadata(pod_deletion_cost):
    """
    Call Kubernetes API to update the status label and the pod deletion
    cost annotation.
    """
    json_patch = json.dumps({
        "metadata": {
            "annotations": {
                "controller.kubernetes.io/pod-deletion-cost": str(pod_deletion_cost)
            }
        }
    })
    url = f"{k8s_api}/api/v1/namespaces/{namespace}/pods/{pod_name}"
    headers = {
        "Authorization": f"Bearer {bearer}",
        "Content-Type": "application/merge-patch+json",
        "Accept": "application/json",
    }
    ssl_context = create_default_context()
    ssl_context.load_verify_locations(cacert)
    patch_request = request.Request(
        url, data=json_patch.encode(), headers=headers, method="PATCH"
    )
    response = request.urlopen(patch_request, context=ssl_context)
    if response.getcode() != 200:
        raise HTTPError(colibri_api, response.getcode(), "Unexpected response code", headers, None)


def get_pod_deletion_cost(stats):
    """
    Given colibri stats, this function returns the number of participants on this JVB, 
    which represents the cost of deleting this pod. Pods with lower deletion cost are 
    preferred to be deleted before pods with higher deletion cost.
    """
    total_participants = stats.get("participants", 0)
    external_participants = stats.get("octo_endpoints", 0)

    return total_participants - external_participants


# Initialize logger
logging.basicConfig(
    format="[%(asctime)s][%(levelname)s] %(message)s", level=logging.INFO
)

# This variable will contain the pod deletion cost
pod_deletion_cost = None

while True:
    try:
        colibri_stats = get_colibri_stats()
        new_pod_deletion_cost = get_pod_deletion_cost(colibri_stats)
    except (URLError, HTTPError):
        logging.exception("Unable to get colibri stats")
        new_pod_deletion_cost = pod_deletion_cost

    if new_pod_deletion_cost != pod_deletion_cost:
        try:
            update_pod_metadata(new_pod_deletion_cost)
            logging.info("pod-deletion-cost annotation updated to %s", new_pod_deletion_cost)
            pod_deletion_cost = new_pod_deletion_cost
        except (FileNotFoundError, HTTPError, URLError):
            logging.exception("Unable to update pod metadata")
    time.sleep(update_period_seconds)
