# ---------------------------------------------------------------------------

sudo mkdir --parents /etc/kubernetes/pki
echo $(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."ca_cert_pem"') | base64 -d > /etc/kubernetes/pki/ca.crt
echo $(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."private_key_pem"') | base64 -d > /etc/kubernetes/pki/ca.key
sudo find /etc/kubernetes/pki -type f -exec chmod 600 {} +

echo $(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."ca_cert_pem"') | base64 -d > /etc/pki/ca-trust/source/anchors/k8_ca.crt
update-ca-trust extract


# Fetch the token from /usr/local/bin/aws Secrets Manager
export TOKEN=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."token"')
export certificateKey=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."certificateKey"')


sudo kubeadm init --control-plane-endpoint=plane.k8.local --node-name=${node_name} --token=$TOKEN --cri-socket=unix:///run/containerd/containerd.sock --pod-network-cidr=${pod_network_cidr} --upload-certs --certificate-key=$certificateKey --kubernetes-version=${kubernetes_version}
mkdir -p /home/ec2-user/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config