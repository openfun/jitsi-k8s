#!/usr/bin/python3
"""
This script is meant to model the behavior of the JVB nodepool on the cluster
under the influence of the HPA.
You may modify the constant values of the problem in the first section of the
script to simulate your infrastructure and needs.
"""

import math
import matplotlib.pyplot as plt
import numpy as np


# Ratio of target utilization of pods as stated in `resource.target.averageUtilization`
# ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-resource-metrics
TARGET = 0.7

# Stabilization windows as stated in `behavior.scaleUp/scaleDown.stabilizationWindowSeconds`
# ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#stabilization-window
STABILIZATION_WINDOW_SECONDS_UP = 0
STABILIZATION_WINDOW_SECONDS_DOWN = 300

# Period between two HPA calls (default is 15)
# ref: https://predictive-horizontal-pod-autoscaler.readthedocs.io/en/latest/user-guide/sync-period/
HPA_SYNC_PERIOD = 15

# Initial number of pods
INITIAL_REPLICAS = 5

# Minimum number of pods for the replicaset
HPA_MIN_REPLICA = 0

# Maximum number of pods for the replicaset (= 0 to disable)
HPA_MAX_REPLICA = 0

# Readiness delay for new pods on new nodes
# This includes time for nodes to be created and ready
# as well as time for pods to become ready
READINESS_DELAY = 240

# Deletion delay for pods
# At the beginning of this deletion delay, pod is not taken into account in the HPA
DELETION_DELAY = 20

# Duration of the simulation (in seconds)
SIMULATION_DURATION = 4000

### LOAD MODELS ###
# Model function of participant load to apply
# All return values are in equivalent-pod unit

# Initial load
LOAD_INITIAL_VALUE = 10

# Linear model
LOAD_LINEAR_SLOPE = 0.0167
def LINEAR_LOAD_MODEL(t):
    return LOAD_INITIAL_VALUE + LOAD_LINEAR_SLOPE * t

# Sinusoidal model
LOAD_SINUSOIDAL_AMPLITUDE = 3
LOAD_SINUSOIDAL_PERIOD = 1800
def SINUSOIDAL_LOAD_MODEL(t):
    return LOAD_INITIAL_VALUE + LOAD_SINUSOIDAL_AMPLITUDE * math.sin(2 * math.pi / LOAD_SINUSOIDAL_PERIOD * t)

# Load model to use
LOAD_MODEL = SINUSOIDAL_LOAD_MODEL


#####################################################################################################


# Temporal list
t = np.linspace(0, SIMULATION_DURATION, SIMULATION_DURATION)

# Oldest time to consider when initializing for stabilization windows
max_past_time = max(STABILIZATION_WINDOW_SECONDS_UP, STABILIZATION_WINDOW_SECONDS_DOWN)

# Maximum delay to consider when initializing number of scheduled pods
max_delay = max(READINESS_DELAY, DELETION_DELAY)

# Initialization of treatment lists
# In each list L, L[-i] constitutes the value of L at t-i+1 seconds
# Some lists may be initialized with a lot of elements so please always consider last nth elements
# when dealing with those list (and not nth element directly)

# Load applied according to the load model
load = []

# Real load applied (it cannot apply more load than the resources it has)
load_real = []

# Number of active pods
replicas_real = [INITIAL_REPLICAS]

# Number of active pods + number of scheduled pods
replicas_total = [INITIAL_REPLICAS]

# Total instant number of pods computed with the HPA algorithm
replicas_instant_calc = [INITIAL_REPLICAS for j in range(max_past_time)]

# Number of pod that are scheduled
pods_scheduled = [0 for i in range(max_delay)]

# Load dropped by the cluster because there are not enough resources
overload = []

# Real usage of pods in the cluster
usage = []


for i in range(len(t)):
    # Compute instant loads
    load.append(LOAD_MODEL(t[i]))
    load_real.append(min(load[-1], replicas_real[-1]))

    # Compute overload & instant usage
    overload.append(load[-1] - load_real[-1])
    usage.append((load_real[-1] / replicas_real[-1])*100)

    # Make HPA computations only if it a multiple of `HPA_SYNC_PERIOD`
    if i % HPA_SYNC_PERIOD == 0:
        # Compute the instant number of replicas according to HPA algorithm
        # ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#algorithm-details
        new_replicas_instant = max(math.ceil(load_real[-1] / TARGET), HPA_MIN_REPLICA)
        if HPA_MAX_REPLICA != 0:
            new_replicas_instant = min(new_replicas_instant, HPA_MAX_REPLICA)
        replicas_instant_calc.append(new_replicas_instant)

        # Select if a scale up or scale down should be done
        # Scale up and down are only triggered if all values in the stabilization window are in the same direction
        # ref: https://github.com/kubernetes/enhancements/tree/master/keps/sig-autoscaling/853-configurable-hpa-scale-velocity#introducing-stabilizationwindowseconds-option
        if replicas_instant_calc[-1] > replicas_total[-1]:
            # Indexes of metrics that correspond to a HPA computation (every `HPA_SYNC_PERIOD` period)
            hpa_computation_indexes = range(0, STABILIZATION_WINDOW_SECONDS_UP + 1, HPA_SYNC_PERIOD)

            # Values that should be taken into account (in the stabilization window)
            replicas_computation_window = [replicas_instant_calc[-1 - j] for j in hpa_computation_indexes]

            # We take the lowest of the values (as requested by the stabilization window algorithm)
            selected_number_of_replicas = min(replicas_computation_window)

            # We ensure this value is greater than the total number of pods
            selected_number_of_pods_to_add = max(selected_number_of_replicas - replicas_total[-1], 0)

            # Add to the `pods_scheduled` list
            pods_scheduled.append(selected_number_of_pods_to_add)

        elif replicas_instant_calc[-1] < replicas_total[-1]:
            # Indexes of metrics that correspond to a HPA computation (every `HPA_SYNC_PERIOD` period)
            hpa_computation_indexes = range(0, STABILIZATION_WINDOW_SECONDS_DOWN + 1, HPA_SYNC_PERIOD)

            # Values that should be taken into account (in the stabilization window)
            replicas_computation_window = [replicas_instant_calc[-1 - j] for j in hpa_computation_indexes]

            # We take the greatest of the values (as requested by the stabilization window algorithm)
            selected_number_of_replicas = max(replicas_computation_window)

            # We ensure this value is smaller than the total number of pods
            selected_number_of_pods_to_add = min(selected_number_of_replicas - replicas_total[-1], 0)

            # Add to the `pods_scheduled` list
            pods_scheduled.append(selected_number_of_pods_to_add)

        else:
            pods_scheduled.append(0)

    # Otherwise, add artificial values for graphing purposes
    else:
        replicas_instant_calc.append(replicas_instant_calc[-1])
        pods_scheduled.append(0)

    # Computes new number of total replicas
    replicas_total.append(replicas_total[-1] + pods_scheduled[-1])

    # Computes new number of real replicas
    replicas_real.append(replicas_real[-1])
    if pods_scheduled[-READINESS_DELAY - 1] > 0:
        replicas_real[-1] += pods_scheduled[-READINESS_DELAY - 1]
    if pods_scheduled[-DELETION_DELAY - 1] < 0:
        replicas_real[-1] += pods_scheduled[-DELETION_DELAY - 1]


_, axis = plt.subplots(3, 2, constrained_layout=True)
colors = ['red', 'blue', 'green', 'purple']

def add_plots(treatement_lists, title, y_label, plot_id, labels = []):
    axis[plot_id[0], plot_id[1]].set_title(title)
    for i in range(len(treatement_lists)):
        axis[plot_id[0], plot_id[1]].plot(t,treatement_lists[i][-SIMULATION_DURATION:], colors[i])
    if labels:
        axis[plot_id[0], plot_id[1]].legend(labels)
    axis[plot_id[0], plot_id[1]].set_ylabel(y_label)    


add_plots([load, load_real], "Load as number of equivalent pods", "Pods", [0, 0], ["Applied load", "Load handled by cluster"])
add_plots([replicas_instant_calc], "Instant number of pods needed for load", "Pods", [0, 1])
add_plots([pods_scheduled], "Number of new pods scheduled", "Pods", [1, 0])
add_plots([replicas_real, replicas_total], "Pods on the cluster", "Pods", [1, 1], ["Pods in ready state", "Pods asked for by hpa"])
add_plots([usage*100], "Usage of the cluster", "Percentage", [2, 0])
add_plots([overload], "Overload (= deterioration of quality)","Load lost", [2, 1])

# Display plots
print("Launching the graph window...")
plt.show()
