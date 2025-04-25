to allow ssh port 22 on ec2 instance

aws ec2 describe-instances \
  --instance-ids YOUR_INSTANCE_ID \
  --query "Reservations[].Instances[].SecurityGroups[].GroupId" \
  --output text

aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text



aws ec2 authorize-security-group-ingress \
    --group-id sg-0f3966c5891e8ede4 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0  # Allow from any IP (for testing)


aws ec2 get-console-output --instance-id i-03689a644b8a6e140


aws ec2 describe-instances --instance-ids i-03689a644b8a6e14  --query 'Reservations[0].Instances[0].State'






curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
