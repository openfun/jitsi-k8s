# k8s octo usage with multiple JVBs

## Context

### Application context
Jitsi-meet is an opensource WebRTC application divided in several services which can be hosted separately. The Jitsi VideoBridge (JVB) service is a Selective Forwarding Unit (aka SFU) used for audio and video redistribution among all participants.
​
JVBs are scalable so that conferences and participants can be connected to different JVBs. If Octo is not used, one conference has all its participants in the same JVB, but multiple conferences can be on that JVB. This creates a problem as JVBs have limited resources: once a conference is started on a JVB, it is bound to it. If too many people join the conference, the JVB will be overloaded and experience will be poor.
​
Therefore, it is interesting to explore Octo, which makes it possible for people in the same conference to be on different JVBs.

### Kubernetes context
As we want to have a scalable infrastructure, Jitsi is deployed on a k8s environment. The number of JVB pods is managed by a Horizontal Pod Autoscaler (HPA). Each JVB is hosted on a node and is the only JVB on that node. Clients thus contact the JVB but the node's public IP, and by the default port for JVBs (10000).

---
## Solutions
---
### SingleBridge strategy

SingleBridge strategy on Octo is the same as not having Octo: a conference is bound to a JVB. We still explored this solution to see the limitations.

As seen in [load test of the 18/03/2022](https://github.com/openfun/jitsi-meet-torture-rocket/tree/main/docs/load_tests), when too many conferences are on a single JVB, and too many people join these conferences, a single JVB can easily be overloaded while others do nothing.

However, this creates less stress on the network, as JVBs are only aware of what is happening inside themselves, and not what is happening in other JVBs.

**We discourage this solution**

---
### SplitBridge strategy

SplitBridge strategy, as we discovered later, is mainly made for dev purposes. Indeed, it explicitely tries to put people of the same conference in different JVBs. As such, the load is distributed quite well between JVBs, as seen in [load test of the 18/03/2022](https://github.com/openfun/jitsi-meet-torture-rocket/tree/main/docs/load_tests). However, there is more stress on the network, as all JVBs share all their information to one another.

This removes the limitation of SingleBridge strategy, however it is not ideal.

**This solution is not made for production environments**

---
### RegionBased strategy

RegionBased strategy uses "region" flags on JVBs, that are passed down thanks to the frontend, and puts participants on JVBs depending on their region.

It has many mechanisms which are really interesting:

* (Happy case 1): If there is a non-overloaded bridge in the conference and in the region: use the least loaded of them.
* (Happy case 1A): If there is a non-overloaded bridge in the conference and in the region's group: use the least loaded of them.
* (Happy case 2): If there is a non-overloaded bridge in the region, and the conference has no bridges in the region: use the least loaded bridge in the region.
* (Happy case 2A): If there is a non-overloaded bridge in the region's group, and the conference has no bridges in the region's group: use the least loaded bridge in the region's group.

* (Split case 1): If there is a non-overloaded bridge in the region, the conference has bridges in the region but all are overloaded: Use the least loaded of the bridges in the region.
* (Split case 1A): If there is a non-overloaded bridge in the region's group, the conference has bridges in the region's group but all are overloaded: Use the least loaded of the bridges in the region.

* (Overload case 1): If all bridges in the region's group are overloaded, and the conference has a bridge in the region's group: use the least loaded conference bridge in the region's group.
* (Overload case 2): If all bridges in the region's group are overloaded, and the conference has no bridges in the region's group: use the least loaded bridge in the region's group.

* (No-region-match case 1): If there are no bridges in the region's group, and the conference has a non-overloaded bridge: use the least loaded conference bridge.
* (No-region-match case 2): If there are no bridges in the region's group and allconference bridges are overloaded: use the least loaded bridge.

This solution is interesting when there are multiple cloud-providers/JVB VMs are deployed at different places, etc...

But it is also interesting when there is only one region, which is the solution we implemented by default in this repository.

Indeed, as seen in [load test of the 20/03/2022](https://github.com/openfun/jitsi-meet-torture-rocket/tree/main/docs/load_tests), it does a great job at mixing the advantages of SingleBridge and SplitBridge. One conference is put on one JVB, until this JVB is overwhelmed, in which case it picks another one for new participants. This reduces the stress on the network, while not blocking conferences that are too large.

As such, this is the **solution that we recommend**, even with one region only.

---
### IntraRegionBased strategy

IntraRegionBased strategy wasn't explored as much as other strategies, because the documentation is less complete on it. IntraRegion is like RegionBased, but with only one region. This is why we recommend RegionBased: it makes it possible to also use regions, while not taking away anything we would get from IntraRegionBased.

---
​