#!/usr/bin/env python3
"""
This script is meant to run as a sidecar-container on a jibri pod.
It updates the following pod metadata based on its status :
- the pod deletion cost annotation
- the status label

For more information on Pod deletion cost, see:
https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost
"""

import json
import logging
import os
import time
from ssl import create_default_context
from urllib import request

# Time to wait between each jibri status check
from urllib.error import HTTPError, URLError

update_period_seconds = os.getenv("UPDATE_PERIOD_SECONDS", 5)

# -- Jibri
# URL to jibri Health API
jibri_health_api = os.getenv(
    "JIBRI_HEALTH_API", "http://127.0.0.1:2222/jibri/api/v1.0/health"
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

STATUS_BUSY = "BUSY"
STATUS_IDLE = "IDLE"
STATUS_UNKNOWN = "UNKNOWN"


def get_jibri_status():
    """Call Jibri's Health API and return its busy status (BUSY, IDLE or UNKNOWN)."""
    response = request.urlopen(jibri_health_api)
    if response.getcode() != 200:
        raise HTTPError(jibri_health_api, response.getcode(), "Unexpected response code", {}, None)
    return json.load(response).get("status", {}).get("busyStatus", STATUS_UNKNOWN)


def update_pod_metadata(pod_deletion_cost, status):
    """
    Call Kubernetes API to update the status label and the pod deletion
    cost annotation.
    """
    json_patch = json.dumps({
        "metadata": {
            "annotations": {
                "controller.kubernetes.io/pod-deletion-cost": str(pod_deletion_cost)
            },
            "labels": {
                "status": status
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
        raise HTTPError(jibri_health_api, response.getcode(), "Unexpected response code", headers, None)


def get_pod_deletion_cost(status):
    """
    Given a jibri status, this function returns an integer value representing the cost of
    deleting this pod. Pods with lower deletion cost are preferred to be deleted before
    pods with higher deletion cost.
    """
    if status == STATUS_BUSY:
        return 10000
    return 0


# Initialize logger
logging.basicConfig(
    format="[%(asctime)s][%(levelname)s] %(message)s", level=logging.INFO
)

# This variable will contain jibri's status
jibri_status = STATUS_UNKNOWN

while True:
    try:
        new_jibri_status = get_jibri_status()
    except (URLError, HTTPError):
        logging.exception("Unable to get the jibri status")
        new_jibri_status = STATUS_UNKNOWN

    if new_jibri_status != jibri_status:
        logging.info("Jibri's status changed to : %s", new_jibri_status)
        deletion_cost = get_pod_deletion_cost(new_jibri_status)
        try:
            status_label = new_jibri_status.lower()
            update_pod_metadata(deletion_cost, status_label)
            logging.info("pod-deletion-cost annotation updated to %s", deletion_cost)
            logging.info("status label updated to %s", status_label)
            jibri_status = new_jibri_status
        except (FileNotFoundError, HTTPError, URLError):
            logging.exception("Unable to update pod metadata")
    time.sleep(update_period_seconds)
