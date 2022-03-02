function(request) {
  local statefulset = request.object,
  local labelKey = statefulset.metadata.annotations["service-per-pod-label"],

  // the base port for is collected from the container setup
  // it defaults to 30300
  local basePort = std.parseInt([a for a in [
                          c for c in statefulset.spec.template.spec.containers
                          if c.name == 'jvb'
                        ][0].args + ['30300']
                        if std.startsWith(a, '3') && std.length(a) == 5][0]),

  // create a service for each pod, with a selector on the given label key
  attachments: [
    {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        name: statefulset.metadata.name + "-" + index,
        namespace: statefulset.metadata.namespace,
        labels: {app: "service-per-pod"}
      },
      spec: {
      selector: {
          [labelKey]: statefulset.metadata.name + "-" + index
        },
        type: "NodePort",
        externalTrafficPolicy: "Local",
        ports: [
          {
            "port": basePort + index,
            "protocol": "UDP",
            "targetPort": basePort + index,
            "nodePort": basePort + index
          }
        ]
      }
    }
    for index in std.range(0, statefulset.spec.replicas - 1)
  ]
}