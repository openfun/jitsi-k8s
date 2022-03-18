#!/usr/bin/env python3
"""
This script is meant to run as a init-container on a jvb pod.
It updates the CPU and memory resource limits on the jvb statefulset.
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


def call_kubernetes_api(url, method, data={}):
    """
    Call Kubernetes API.
    """
    headers = {
        "Authorization": f"Bearer {bearer}",
        "Content-Type": "application/merge-patch+json",
        "Accept": "application/json",
    }
    ssl_context = create_default_context()
    ssl_context.load_verify_locations(cacert)
    patch_request = request.Request(
        url, data=data, headers=headers, method=method
    )
    response = request.urlopen(patch_request, context=ssl_context)
    if response.getcode() != 200:
        raise HTTPError(jibri_health_api, response.getcode(), "Unexpected response code", headers, None)

    return json.load(response)


# Initialize logger
logging.basicConfig(
    format="[%(asctime)s][%(levelname)s] %(message)s", level=logging.INFO
)


# Get Node and Statefulset names
pod = call_kubernetes_api(
    f"{k8s_api}/api/v1/namespaces/{namespace}/pods/{pod_name}", 
    "GET"
)
node_name = pod["spec"]["nodeName"]
statefulset_name = pod["metadata"]["ownerReferences"][0]["name"]


# Get allocatable CPU and memory
node_template = call_kubernetes_api(
    f"{k8s_api}/api/v1/nodes/{node_name}", 
    "GET"
)
cpu = node_template["status"]["allocatable"]["cpu"]
memory = node_template["status"]["allocatable"]["memory"]


# Get statefulset spec
statefulset_template = call_kubernetes_api(
    f"{k8s_api}/apis/apps/v1/namespaces/{namespace}/statefulsets/{statefulset_name}", 
    "GET"
)
spec = statefulset_template["spec"]


# Update statefulset spec
# We do not set to the strict maximum allocatable values otherwise 
# it would not ba accepted by Kubernetes
spec["template"]["spec"]["containers"][0]["resources"] = {
    "limits": {
        "cpu": str(int(cpu[:-1]) - 100) + "m",
        "memory": str(int(memory[:-2]) - 2000000) + "Ki"
    }
}
call_kubernetes_api(
    f"{k8s_api}/apis/apps/v1/namespaces/{namespace}/statefulsets/{statefulset_name}",
    "PATCH",
    data=json.dumps({ "spec": spec }).encode()
)
