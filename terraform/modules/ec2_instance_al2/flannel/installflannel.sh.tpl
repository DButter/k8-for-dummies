curl -O https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sed -i 's|10.244.0.0/16|${pod_network_cidr}|g' kube-flannel.yml

kubectl apply -f kube-flannel.yml --kubeconfig=/home/ec2-user/.kube/config

