#!/usr/bin/env python3
"""
This script is meant to run as a sidecar-container on a jigasi pod.
It updates the following pod metadata based on its status :
- the pod deletion cost annotation
- the status label

It also initiates the graceful shutdown of the jigasi container, in order to stop new connections to the pod.

For more information on Pod deletion cost, see:
https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#pod-deletion-cost
"""

import json
import logging
import os
import time
import websockets
import asyncio
from ssl import create_default_context
from urllib import request

# Time to wait between each jibri status check
from urllib.error import HTTPError, URLError

update_period_seconds = os.getenv("UPDATE_PERIOD_SECONDS", 5)

# URL to jigasi stats API
jigasi_stats_api = os.getenv(
    "JIGASI_STATS_API", "http://127.0.0.1:8788/about/stats"
)

# -- Kubernetes
# URL to reach Kubernetes' API
k8s_api = os.getenv("K8S_API", "https://kubernetes.default.svc")
k8s_ws_api = os.getenv("K8S_WS_API", "wss://kubernetes.default.svc")
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

def get_jigasi_status():
    """Call Jigasi's Stats API and return its status based on the number of conferences (BUSY>=1, IDLE=0 or UNKNOWN)."""
    response = request.urlopen(jigasi_stats_api)
    if response.getcode() != 200:
        raise HTTPError(jigasi_stats_api, response.getcode(), "Unexpected response code", {}, None)
    response = json.load(response).get("conferences", STATUS_UNKNOWN)
    if response != STATUS_UNKNOWN:
        if response == 0:
            response =  STATUS_IDLE
        else :
            response = STATUS_BUSY
    return response


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
        raise HTTPError(jigasi_stats_api, response.getcode(), "Unexpected response code", headers, None)

async def initiate_graceful_shutdown():
    """
    Call Kubernetes API to execute the graceful shutdown command in the Jigasi container,
    and stop further incoming calls from connecting, while waiting for all current connections 
    to end before shutting the process down.
    """
    url = f"{k8s_ws_api}/api/v1/namespaces/{namespace}/pods/{pod_name}/exec?container=jigasi&command=/usr/share/jigasi/graceful_shutdown.sh&command=-p&command=1&stdin=true&stderr=true&stdout=true&tty=true"
    headers = {
        "Authorization": f"Bearer {bearer}",
        "Accept": "*/*",
    }
    ssl_context = create_default_context()
    ssl_context.load_verify_locations(cacert)
    try:
        async with websockets.connect(url, extra_headers=headers, ssl=ssl_context) as websocket:
            logging.info("Graceful shutdown initiated")
    except Exception as e:
        logging.info("Graceful shutdown initiated")

def get_pod_deletion_cost(status):
    """
    Given a jigasi status, this function returns an integer value representing the cost of
    deleting this pod. Pods with lower deletion cost are preferred to be deleted before
    pods with higher deletion cost.
    """
    if status == STATUS_BUSY:
        return 10000
    if status == STATUS_IDLE:
        return 100
    return 10


# Initialize logger
logging.basicConfig(
    format="[%(asctime)s][%(levelname)s] %(message)s", level=logging.INFO
)

# This variable will contain jigasi's status
jigasi_status = STATUS_UNKNOWN

# This variable tracks whether the shutdown command has already been sent
not_shutdown = True

while True:
    try:
        new_jigasi_status = get_jigasi_status()
    except (URLError, HTTPError):
        logging.exception("Unable to get the Jigasi status")
        update_pod_metadata(0, "shutdown")
        logging.info("Pod is shutting down, conference ended")
        break

    if new_jigasi_status != jigasi_status:
        logging.info("Jigasi's status changed to : %s", new_jigasi_status)
        deletion_cost = get_pod_deletion_cost(new_jigasi_status)
        try:
            if new_jigasi_status == "IDLE" and jigasi_status == "BUSY":
                new_jigasi_status == "BUSY"
            status_label = new_jigasi_status.lower()
            update_pod_metadata(deletion_cost, status_label)
            logging.info("pod-deletion-cost annotation updated to %s", deletion_cost)
            logging.info("status label updated to %s", status_label)
            jigasi_status = new_jigasi_status
        except (FileNotFoundError, HTTPError, URLError):
            logging.exception("Unable to update pod metadata")
        if new_jigasi_status == "BUSY" and not_shutdown:
            logging.info("Initiating graceful shutdown")
            asyncio.run(initiate_graceful_shutdown())
            not_shutdown = False
    time.sleep(update_period_seconds)