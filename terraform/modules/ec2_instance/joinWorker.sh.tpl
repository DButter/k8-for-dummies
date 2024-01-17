echo $(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."ca_cert_pem"') | base64 -d > /etc/pki/ca-trust/source/anchors/k8_ca.crt
update-ca-trust extract


# Fetch the token from /usr/local/bin/aws Secrets Manager
export TOKEN=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."token"')
export certificateKey=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id ${secret_manager_id} --query SecretString --output text | jq -r '."certificateKey"')
sudo kubeadm join plane.k8.local:6443 --token=$TOKEN --node-name=${node_name} --discovery-token-unsafe-skip-ca-verification --certificate-key=$certificateKey
