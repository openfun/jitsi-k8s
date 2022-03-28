# Script that computes needs in jvb pods based on load

Script `jvb.py` enables users to see load on cluster, HPA reaction, and possible deterioriation of quality, based on a function of user load.

Many parameters come into account, whether HPA or cluster parameters.
User load should be the base of the analysis: this script is made to see cluster reaction to a specific load, so that we can adapt values (like number of initial pods or stabilizationWindow) for a more appropriate reaction.

## User load variables

The function of user load represents how many users are connected to jitsi at a given time. To simplify computations, the function's unit is in equivalent pods needed.

For example, with Scaleway GP1-XS instances, we have identified that approximatively 100 participants in the JVB correspond to a 100% CPU usage. One JVB's capacity is thus 100 participants. If you want to see the response of the cluster to a regularly increasing load of 2 participant per second, with 10 initial participants, you will use this function: 
```
0.10 + 0.02 * t
```

As a linear load is already implemented in the script, this corresponds to:

```
LOAD_INITIAL_VALUE = 0.10
LOAD_LINEAR_SLOPE = 0.02
LOAD_MODEL = LINEAR_MODEL
```

Of course, if you have more specific resources, it is recommended to create your own load functions, and variable `LOAD_MODEL` should be equal to the name of your model's function.

`SIMULATION_DURATION` should also be set to the experiment's length, in seconds.

## Cluster settings

The variable `READINESS_DELAY` describes the time it takes for a new JVB to go from "its creation is triggered by hpa" to "ready". This should be set to an average of time that you have observed, as it is quite specific to instances, cloud provider and scaling strategies.
On Scaleway, with GP1-XS and with one JVB per instance, we observe an average of 4 minutes to have a new pod ready.

`DELETION_DELAY` refers to time needed between the moment the pod has been scaled down by HPA, and the moment it is deleted. During that time, it handles load, but is not taken into account in HPA average CPU usage.

## HPA settings

First of all, we use here an HPA that scales based on CPU utilization. The variable `TARGET` thus refers to the average target utilization.

`HPA_SYNC_PERIOD` refers to time between HPA calls.

`STABILIZATION_WINDOW_SECONDS_UP` and `STABILIZATION_WINDOW_SECONDS_DOWN` refer to the time during which HPA observes the cluster before choosing to scale up or down depending on the various informations it received during that time period.
For exemple, if it is equal to 0, it will scale as soon as it sees the need for it. If set to 30 and `HPA_SYNC_PERIOD` is 15, it will look at the two last calls, and decide scaling up or down.

`INITIAL_REPLICAS` refers to the replicas present on the cluster at the beginning of the test. For example, it can be equal to the minimal number of replicas of the HPA if the test is considered to start when cluster is at 'rest' state, or can be greater if considering that the HPA has already scaled beforehand.

`HPA_MIN_REPLICA` refers to the minimal number of pods that the HPA accepts. 

`HPA_MAX_REPLICA` refers to maximal number of pods that the HPA accepts. This is useful to see for example if a load will induce stress on the cluster and deterioration of quality if the number of JVBs cannot exceed a maximum value. If your aim is to see how many JVBs you need for a specific load, without being limited to a maximum number, this variable can be set to 0.

## Approximations

Keep in mind that this script only provides an approximation of cluster reaction to load. It is less exact with unregular loads and rapidly changing loads. More precisely, it does not take into account:
- Exact behavior of JVBs in "graceful shutdown state", where a part of the load is inside JVBs that are not taken into account in the HPA, but this load is fixed or decreasing from the moment the JVB goes into shutdown state. `DELETION_DELAY` tries to immitate this, but load will be spread evenly on JVBs, and not decreading in pods in shutdown states.
- Empty instances in the JVB pool, which show up when JVBs scale down and pods shuts down, but the period between the moment the instance is unneeded and the moment the instance is removed has not passed yet.
- The fact that load is not the same on all JVBs. The behaviour of this script is the same as when there are a lot of very small conferences: load is spread evenly. However, if you are interested in bigger conferences, it will be uneven, and pods that will be deleted will have a lot less participants on them.
