#!/usr/bin/python3
"""
This script is meant to model the behavior of the JVB nodepool on the cluster
under the influence of the HPA.
You may modify the constant values of the problem in the first section of the
script to simulate your infrastructure and needs.
"""

import dotenv
import math
import matplotlib.pyplot as plt
import numpy as np
import os

# Load env variables
dotenv.load_dotenv("env.d/simulation")

# Ratio of target utilization of pods as stated in `resource.target.averageUtilization`
# ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-resource-metrics
TARGET = float(os.getenv("TARGET", "0.75"))

# Stabilization windows as stated in `behavior.scaleUp/scaleDown.stabilizationWindowSeconds`
# ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#stabilization-window
STABILIZATION_WINDOW_SECONDS_UP = int(os.getenv("STABILIZATION_WINDOW_SECONDS_UP", "0"))
STABILIZATION_WINDOW_SECONDS_DOWN = int(os.getenv("STABILIZATION_WINDOW_SECONDS_DOWN", "60"))

# Period between two HPA calls (default is 15)
# ref: https://predictive-horizontal-pod-autoscaler.readthedocs.io/en/latest/user-guide/sync-period/
HPA_SYNC_PERIOD = int(os.getenv("HPA_SYNC_PERIOD", "15"))

# Initial number of pods
INITIAL_REPLICAS = int(os.getenv("INITIAL_REPLICAS", "10"))

# Minimum number of pods for the replicaset
HPA_MIN_REPLICA = int(os.getenv("HPA_MIN_REPLICA", "1"))

# Maximum number of pods for the replicaset (= 0 to disable)
HPA_MAX_REPLICA = int(os.getenv("HPA_MAX_REPLICA", "0"))

# Readiness delay for new pods on new nodes
# This includes time for nodes to be created and ready
# as well as time for pods to become ready
READINESS_DELAY = int(os.getenv("READINESS_DELAY", "240"))

# Deletion delay for pods
# At the beginning of this deletion delay, pod is not taken into account in the HPA
DELETION_DELAY = int(os.getenv("DELETION_DELAY", "20"))

# Duration of the simulation (in seconds)
SIMULATION_DURATION = int(os.getenv("SIMULATION_DURATION", "3600"))

# Pricing interval and charge per instance
# The `PRICING_CHARGE_PER_INTERVAL` is charged even though the instance does not exist during the whole interval
PRICING_INTERVAL = int(os.getenv("PRICING_INTERVAL", "3600"))
PRICING_AMOUNT_PER_INTERVAL = float(os.getenv("PRICING_AMOUNT_PER_INTERVAL", "0.084"))

### LOAD MODELS ###
# Model function of participant load to apply
# All return values are in equivalent-pod unit

# Initial load
LOAD_INITIAL_VALUE = float(os.getenv("LOAD_INITIAL_VALUE", "7.5"))

# Linear model
LOAD_LINEAR_SLOPE = float(os.getenv("LOAD_LINEAR_SLOPE", "0.015"))
def LINEAR_LOAD_MODEL(t):
    return LOAD_INITIAL_VALUE + LOAD_LINEAR_SLOPE * t

# Sinusoidal model
LOAD_SINUSOIDAL_AMPLITUDE = int(os.getenv("LOAD_SINUSOIDAL_AMPLITUDE", "3"))
LOAD_SINUSOIDAL_PERIOD = int(os.getenv("LOAD_SINUSOIDAL_PERIOD", "1800"))
def SINUSOIDAL_LOAD_MODEL(t):
    return LOAD_INITIAL_VALUE + LOAD_SINUSOIDAL_AMPLITUDE * math.sin(2 * math.pi / LOAD_SINUSOIDAL_PERIOD * t)

# Load model to use
LOAD_MODEL = LINEAR_LOAD_MODEL
if os.getenv("LOAD_MODEL", "LINEAR_LOAD_MODEL") == "SINUSOIDAL_LOAD_MODEL":
    LOAD_MODEL = SINUSOIDAL_LOAD_MODEL


#####################################################################################################


# Temporal list
t = np.linspace(0, SIMULATION_DURATION, SIMULATION_DURATION)

# Oldest time to consider when initializing for stabilization windows
max_past_time = max(STABILIZATION_WINDOW_SECONDS_UP, STABILIZATION_WINDOW_SECONDS_DOWN)

# Maximum delay to consider when initializing number of scheduled pods
max_delay = max(READINESS_DELAY, DELETION_DELAY)

# Lists of instance creation times
# The `best` one corresponds to the case FIFO
# The `worst` one corresponds to the case FILO
best_creation_times = [0 for i in range(INITIAL_REPLICAS)]
worst_creation_times = [0 for i in range(INITIAL_REPLICAS)]

# Total pricing that corresponds to the previous cases
best_pricing = INITIAL_REPLICAS * PRICING_AMOUNT_PER_INTERVAL
worst_pricing = INITIAL_REPLICAS * PRICING_AMOUNT_PER_INTERVAL

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
    usage.append((load_real[-1] / replicas_real[-1]))

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
    
    # Update lists of instance creation times
    if pods_scheduled[-1] > 0:
        # If the number of replicas increases, directly add the pricing
        best_pricing += pods_scheduled[-1] * PRICING_AMOUNT_PER_INTERVAL
        worst_pricing += pods_scheduled[-1] * PRICING_AMOUNT_PER_INTERVAL
        for p in range(pods_scheduled[-1]):
            best_creation_times.append(i)
            worst_creation_times.append(i)
    elif pods_scheduled[-1] < 0:
        for p in range(-pods_scheduled[-1]):
            best_creation_times.pop(-1)
            worst_creation_times.pop(0)
    
    # Increase the pricings with old instances that have existed durint one more `PRICING_INTERVAL`
    for j in range(len(best_creation_times)):
        if best_creation_times[j] != 0 and best_creation_times[j] % PRICING_INTERVAL == 0:
            print(best_pricing)
            best_pricing += PRICING_AMOUNT_PER_INTERVAL
        if worst_creation_times[j] != 0 and worst_creation_times[j] % PRICING_INTERVAL == 0:
            worst_pricing += PRICING_AMOUNT_PER_INTERVAL


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
add_plots([usage*100], "Usage of the cluster", "Proportion", [2, 0])
add_plots([overload], "Overload (= deterioration of quality)","Load lost", [2, 1])

# Display pricings
print(
f"""
Estimated pricing:
  * best case: {math.ceil(worst_pricing * 100) / 100} €
  * worst case: {math.ceil(best_pricing * 100) / 100} €
""")

# Display plots
print("Launching the graph window...")
plt.show()
