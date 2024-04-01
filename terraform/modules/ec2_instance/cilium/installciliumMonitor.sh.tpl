# ---------------------------------------------------------------------------

CILIUM_CLI_VERSION=${cilium_version}
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$${CILIUM_CLI_VERSION}/cilium-linux-$${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-$${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-$${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-$${CLI_ARCH}.tar.gz{,.sha256sum}



cilium install --set ipam.operator.clusterPoolIPv4PodCIDRList=172.16.0.0/12,\
 k8sServicePort=6443 \
   --set operator.prometheus.enabled=true \
   --set hubble.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
   --set clustermesh.useAPIServer=true \
   --set clustermesh.apiserver.metrics.enabled=true \
   --set clustermesh.apiserver.metrics.kvstoremesh.enabled=true \
   --set clustermesh.apiserver.metrics.etcd.enabled=true