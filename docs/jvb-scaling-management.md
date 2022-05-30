# k8s service scaling

## Context

### Application context
Jitsi-meet is an opensource WebRTC application divided in several services which can be hosted separately. The Jitsi VideoBridge (JVB) service is a Selective Forwarding Unit (aka SFU) used for audio and video redistribution among all participants.
​
For scalability purposes, it is possible to create a single Jitsi cluster (or shard) with multiple JVB. In this case, each JVB will receive streams of a part of the participants and will send these streams to other participants. Thus each participant will send audio and video stream to a single JVB and receive multiple audio and video streams from one or several JVB, thanks to Octo.
​
Therefore, each participant must be able to contact each JVB at any time.
​
### Kubernetes context
As we want to have a scalable infrastructure, Jitsi is deployed on a k8s environment. Each JVB is deployed on a pod which must be accessible from outside the cluster. The number of JVB pods is managed by a Horizontal Pod Autoscaler (HPA).
​
This document explains several solutions for the networking issue linked to the variable number of JVB.
​
## Additionnal problem
Kubernetes LoadBalancers does not support mixed loadbalancers (TCP and UDP). (as explained [here](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/), flags have to be used to make it work).
Audio and Video streams are sent over UDP. Despite HTTP/TCP, there is few information we can rely on for loadbalancing.
​
---
## Solutions
---
### clientIP affinity
The first solution considered is to create a single service selecting all JVB pods with clientIP affinity. In this case, each user will send and receive streams from a single JVB and will not be able to talk to other JVB.
​
In this scenario, octo should be disabled so that a conference is hosted on a single JVB.
​
But there is a problem with Network Address Translation (NAT) because as soon as several users are using the same public IP, they can't follow conferences hosted on different JVB.
​
A solution could be to write a custom affinity function, but as the routed traffic is built over UDP, the service should look inside the datagram for information.
​
Therefore, **this solution is considered invalid**.
​
---
### Service per pod at deployment
In this solution we have a different service for each JVB pod. The pods are scaling automatically, but the services are all created beforehand. They either link to an existing pod, or to nothing. The pods are deployed thanks to a statefulSet, so that their names follow the logic "jvb-0", "jvb-1"... The services link the jvb-_n_ to port _30300 + n_. The maximum number of jvb pods (defined in the HPA) should be the number of services that are deployed on the cluster.
​
In this solution we use a statefulset for JVB pods so that the name of the JVB can be predicted. The goal is to create _n_ services selecting up to _n_ JVB pods, the number of JVB can not be greater than the number of JVB services, this maximum number should be the maximum number of pods in the HPA specification. Every service exposes the underlying pod with a nodePort.
​
The nodePort is calculated with the formula _basePort + JvbNumber_ where _basePort_ is a constant and _JvbNumber_ is the number of the JVB in the JVB StatefulSet (using the predictable character of pod names).
​
The uncertainty of this solution is the behavior of a k8s cluster in which a large number of services are present at all times.
​
The ease of implementation of this solution depends on the technologies used to deploy the infrastructure. In our case, we use kustomize and this solution would have drastically increased the size of the built configuration sent with _kubectl_.
​
---
### Service per pod at runtime
This solution relies on the creation of a custom controller which listens to the creation and destruction of JVB pods and creates and destroys services according to which JVB pod is scheduled.
​
Custom controllers are created through custom ressources which can be hard to maintain. GKE created an opensource repository which was then continued in [this repository](https://github.com/metacontroller/metacontroller).
​
The metacontroller is easily deployable with this repository, using either Helm or Kustomize, but the service account linked to metacontroller pods possesses rights over all cluster objects (whether in creation, deletion, patch....), which involves a risk that we decided to mitigate.
​
At first, we chose this solution. However, it added complexity and an external dependency. We chose to keep the solution simple, however this solution is also **considered quite correct**.

---
### Create one pod per node
In this solution, we use a nodePort for the JVB pod to be accessible from outside the cluster. Each JVB should be on a different node as we use the same port (the default one).
​
The autoscaling relies on the cluster autoscaling. As we use Scaleway, the k8s pool will schedule a new node if there is a pod that can not be launched on an existing node. Therefore, the JVB pool autoscaling depends on the cluster autoscaling which is usually configured by the cloud provider.
​
For a simple cluster, this is a very efficient solution:
- as can be seen in [our tests' docs](https://github.com/openfun/jitsi-meet-torture-rocket/tree/main/docs/load_tests), we found that having only one JVB per node was more efficient for resource usage.
- All JVBs have the same size, so it is easy to put resource requests and limits on JVBs.

However, if JVB pool becomes more complex (different sized VMs, different cloud providers...) multiple deployments will have to be created, so that they can have resource requests/limits that are adapted to the underlying VM.

This solution is thus more dependant on the underlying infrastructure, but simpler.
​
**We chose this solution**
​
---