# EKS Cluster Testing Guide

This document provides comprehensive testing procedures for all components deployed by the Terraform EKS stack.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Post-Deployment Verification](#post-deployment-verification)
3. [VPC and Networking Tests](#vpc-and-networking-tests)
4. [EKS Cluster Tests](#eks-cluster-tests)
5. [Node Group Tests](#node-group-tests)
6. [ALB Controller Tests](#alb-controller-tests)
7. [End-to-End ALB Testing](#end-to-end-alb-testing)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Configure AWS Credentials
```bash
# Verify AWS credentials
aws sts get-caller-identity --profile pushpender-credentials

# Set default profile (optional)
export AWS_PROFILE=pushpender-credentials
```

### 2. Get Cluster Information
```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "eks-ap1-prod-EKS-squad-1")
REGION="ap-south-1"

# Or manually set based on your terraform.tfvars
CLUSTER_NAME="eks-ap1-prod-EKS-squad-1"
REGION="ap-south-1"
```

### 3. Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 4. Install Required Tools (if not already installed)
```bash
# kubectl
# AWS CLI v2
# jq (for JSON parsing)
# curl (for testing endpoints)
```

---

## Post-Deployment Verification

### Step 1: Verify Terraform Outputs
```bash
# Get all outputs
terraform output

# Get specific outputs
terraform output cluster_name
terraform output vpc_id
terraform output cluster_security_group_id
```

### Step 2: Verify All Resources Created
```bash
# Check Terraform state
terraform state list

# Expected resources:
# - module.vpc.*
# - module.cluster.*
# - module.nodes.*
# - module.alb_controller.*
```

---

## VPC and Networking Tests

### Test 1: Verify VPC Exists
```bash
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-vpcs \
  --vpc-ids $VPC_ID \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'Vpcs[0].[VpcId,CidrBlock,State]' \
  --output table
```

**Expected Result:**
- VPC ID matches output
- CIDR: `10.0.0.0/16`
- State: `available`

### Test 2: Verify Subnets
```bash
# Get subnet IDs from Terraform
ENI_SUBNETS=$(terraform output -json eni_subnet_ids | jq -r '.[]')
PRIVATE_SUBNETS=$(terraform output -json private_subnet_ids | jq -r '.[]')
PUBLIC_SUBNETS=$(terraform output -json public_subnet_ids | jq -r '.[]')

# Verify ENI subnets
echo "ENI Subnets:"
for subnet in $ENI_SUBNETS; do
  aws ec2 describe-subnets \
    --subnet-ids $subnet \
    --region $REGION \
    --profile pushpender-credentials \
    --query 'Subnets[0].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
    --output table
done

# Verify Private subnets
echo "Private Subnets:"
for subnet in $PRIVATE_SUBNETS; do
  aws ec2 describe-subnets \
    --subnet-ids $subnet \
    --region $REGION \
    --profile pushpender-credentials \
    --query 'Subnets[0].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
    --output table
done

# Verify Public subnets
echo "Public Subnets:"
for subnet in $PUBLIC_SUBNETS; do
  aws ec2 describe-subnets \
    --subnet-ids $subnet \
    --region $REGION \
    --profile pushpender-credentials \
    --query 'Subnets[0].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
    --output table
done
```

**Expected Results:**
- ENI Subnets: `10.0.1.0/28`, `10.0.2.0/28` (MapPublicIpOnLaunch: false)
- Private Subnets: `10.0.3.0/24`, `10.0.4.0/24` (MapPublicIpOnLaunch: false)
- Public Subnets: `10.0.5.0/24`, `10.0.6.0/24` (MapPublicIpOnLaunch: true)

### Test 3: Verify Internet Gateway
```bash
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'InternetGateways[0].[InternetGatewayId,Attachments[0].State]' \
  --output table
```

**Expected Result:** Internet Gateway attached and in `available` state

### Test 4: Verify NAT Gateway (if enabled)
```bash
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table
```

**Expected Result:** NAT Gateway in `available` state (if `enable_nat_gateway = true`)

### Test 5: Verify Route Tables
```bash
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'RouteTables[*].[RouteTableId,Associations[0].SubnetId,Routes[0].GatewayId]' \
  --output table
```

**Expected Results:**
- Public route table with route to Internet Gateway
- Private route table with route to NAT Gateway
- Database route table with route to NAT Gateway

---

## EKS Cluster Tests

### Test 1: Verify Cluster Status
```bash
aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'cluster.[name,status,version,endpoint]' \
  --output table
```

**Expected Result:**
- Status: `ACTIVE`
- Version: `1.31` (or your configured version)
- Endpoint: Valid Kubernetes API endpoint

### Test 2: Verify Cluster Endpoint Access
```bash
aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'cluster.resourcesVpcConfig.[endpointPrivateAccess,endpointPublicAccess]' \
  --output table
```

**Expected Result:** Matches your `terraform.tfvars` settings

### Test 3: Verify EKS Addons
```bash
# List all addons
aws eks list-addons \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials

# Verify specific addons
aws eks describe-addon \
  --cluster-name $CLUSTER_NAME \
  --addon-name vpc-cni \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'addon.[addonName,status,addonVersion]' \
  --output table

aws eks describe-addon \
  --cluster-name $CLUSTER_NAME \
  --addon-name kube-proxy \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'addon.[addonName,status,addonVersion]' \
  --output table

aws eks describe-addon \
  --cluster-name $CLUSTER_NAME \
  --addon-name coredns \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'addon.[addonName,status,addonVersion]' \
  --output table
```

**Expected Results:**
- All addons in `ACTIVE` status
- vpc-cni, kube-proxy, coredns installed

### Test 4: Verify Cluster IAM Role
```bash
CLUSTER_ROLE_ARN=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'cluster.roleArn' \
  --output text)

echo "Cluster Role ARN: $CLUSTER_ROLE_ARN"

aws iam get-role \
  --role-name $(echo $CLUSTER_ROLE_ARN | cut -d'/' -f2) \
  --profile pushpender-credentials \
  --query 'Role.[RoleName,AssumeRolePolicyDocument]' \
  --output json
```

**Expected Result:** Role exists with `AmazonEKSClusterPolicy` attached

### Test 5: Verify kubectl Access
```bash
# Test cluster connection
kubectl cluster-info

# Verify API server accessibility
kubectl get --raw /healthz

# Check cluster version
kubectl version --output=yaml
```

**Expected Result:** Successful connection to cluster

---

## Node Group Tests

### Test 1: Verify Node Group Status
```bash
aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name $(aws eks list-nodegroups \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --profile pushpender-credentials \
    --query 'nodegroups[0]' \
    --output text) \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'nodegroup.[nodegroupName,status,instanceTypes,scalingConfig]' \
  --output json
```

**Expected Result:**
- Status: `ACTIVE`
- Instance types match configuration
- Scaling config matches `terraform.tfvars`

### Test 2: Verify Worker Nodes via kubectl
```bash
# List all nodes
kubectl get nodes -o wide

# Get detailed node information
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, status: .status.conditions, instanceType: .metadata.labels."node.kubernetes.io/instance-type"}'

# Check node labels
kubectl get nodes --show-labels
```

**Expected Results:**
- Nodes in `Ready` state
- Node count matches `desired_size`
- Labels match configuration
- Instance types: `t3.small` (or your configured type)

### Test 3: Verify Node IAM Role
```bash
# Get node IAM role from node annotations
kubectl get nodes -o json | jq -r '.items[0].spec.providerID' | cut -d'/' -f5

# Or from AWS
NODE_GROUP_NAME=$(aws eks list-nodegroups \
  --cluster-name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'nodegroups[0]' \
  --output text)

NODE_ROLE_ARN=$(aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name $NODE_GROUP_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'nodegroup.nodeRole' \
  --output text)

echo "Node Role ARN: $NODE_ROLE_ARN"

aws iam get-role \
  --role-name $(echo $NODE_ROLE_ARN | cut -d'/' -f2) \
  --profile pushpender-credentials \
  --query 'Role.AttachedPolicies[*].PolicyName' \
  --output table
```

**Expected Result:** Role has required policies attached:
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
- AmazonSSMManagedInstanceCore
- AmazonS3FullAccess
- SecretsManagerReadWrite

### Test 4: Verify Node Connectivity
```bash
# Test pod scheduling
kubectl run test-pod --image=busybox --rm -it --restart=Never -- echo "Node connectivity test successful"

# Check node resources
kubectl top nodes
```

**Expected Result:** Pods can be scheduled and run on nodes

---

## ALB Controller Tests

### Test 1: Verify OIDC Provider
```bash
CLUSTER_ARN=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'cluster.arn' \
  --output text)

OIDC_ISSUER=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'cluster.identity.oidc.issuer' \
  --output text | sed 's|https://||')

aws iam list-open-id-connect-providers \
  --profile pushpender-credentials \
  --query "OpenIDConnectProviderList[?contains(Arn, '$OIDC_ISSUER')]" \
  --output table
```

**Expected Result:** OIDC provider exists for the cluster

### Test 2: Verify ALB Controller IAM Role
```bash
# Get role ARN from Terraform output (if available)
# Or find it by name pattern
ALB_ROLE_NAME="${CLUSTER_NAME}-alb-controller-role"

aws iam get-role \
  --role-name $ALB_ROLE_NAME \
  --profile pushpender-credentials \
  --query 'Role.[RoleName,AssumeRolePolicyDocument]' \
  --output json

# Verify policy attachment
aws iam list-attached-role-policies \
  --role-name $ALB_ROLE_NAME \
  --profile pushpender-credentials \
  --output table
```

**Expected Result:** Role exists with trust relationship to OIDC provider

### Test 3: Verify ALB Controller ServiceAccount
```bash
# Check ServiceAccount exists
kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml

# Verify IRSA annotation
kubectl get serviceaccount aws-load-balancer-controller -n kube-system \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

**Expected Result:**
- ServiceAccount exists in `kube-system` namespace
- Has annotation: `eks.amazonaws.com/role-arn` with ALB controller role ARN

### Test 4: Verify ALB Controller Deployment
```bash
# Check Helm release
helm list -n kube-system

# Check deployment status
kubectl get deployment aws-load-balancer-controller -n kube-system

# Check pod status
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check pod logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=50
```

**Expected Results:**
- Deployment in `Ready` state
- Pods running (typically 2 replicas)
- No errors in logs
- Helm release shows `deployed` status

### Test 5: Verify ALB Controller Permissions
```bash
# Check if controller can describe EC2 resources (via pod exec)
POD_NAME=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o jsonpath='{.items[0].metadata.name}')

# Test AWS CLI access from pod
kubectl exec -n kube-system $POD_NAME -- aws sts get-caller-identity

# Test EC2 describe permissions
kubectl exec -n kube-system $POD_NAME -- aws ec2 describe-vpcs --region $REGION --query 'Vpcs[0].VpcId' --output text
```

**Expected Result:** Pod can assume IAM role and access AWS services

---

## End-to-End ALB Testing

### Prerequisites
Before testing ALB, ensure:
1. ALB Controller is running (see ALB Controller Tests)
2. Nodes are in Ready state
3. kubectl is configured

### Test 1: Deploy Test Application

See `test-alb/` directory for sample manifests. Deploy the test application:

```bash
# Navigate to test directory
cd test-alb

# Deploy test application
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# Verify deployment
kubectl get deployment test-app -n default
kubectl get service test-app -n default
kubectl get ingress test-app -n default
```

**Expected Results:**
- Deployment: 2 replicas running
- Service: ClusterIP type, port 80
- Ingress: Address should be populated with ALB DNS name

### Test 2: Verify ALB Creation
```bash
# Get ALB DNS name from Ingress
ALB_DNS=$(kubectl get ingress test-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ALB DNS Name: $ALB_DNS"

# Verify ALB exists in AWS
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --profile pushpender-credentials \
  --query "LoadBalancers[?DNSName=='$ALB_DNS'].LoadBalancerArn" \
  --output text)

echo "ALB ARN: $ALB_ARN"

# Get ALB details
aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'LoadBalancers[0].[LoadBalancerName,State.Code,Scheme,Type]' \
  --output table
```

**Expected Results:**
- ALB in `active` state
- Scheme: `internet-facing` (or `internal` based on annotation)
- Type: `application`

### Test 3: Verify Target Groups
```bash
# Get target group ARNs
TARGET_GROUPS=$(aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'TargetGroups[*].TargetGroupArn' \
  --output text)

for TG_ARN in $TARGET_GROUPS; do
  echo "Target Group: $TG_ARN"
  aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region $REGION \
    --profile pushpender-credentials \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
    --output table
done
```

**Expected Results:**
- Target groups created
- Targets (pods) in `healthy` state
- Targets match pod IPs

### Test 4: Test Application Endpoint
```bash
# Wait for ALB to be fully provisioned (may take 2-5 minutes)
echo "Waiting for ALB to be ready..."
sleep 60

# Get ALB DNS name
ALB_DNS=$(kubectl get ingress test-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test HTTP endpoint
echo "Testing ALB endpoint: http://$ALB_DNS"
curl -v http://$ALB_DNS

# Test with host header (if path-based routing)
curl -v -H "Host: test-app.example.com" http://$ALB_DNS
```

**Expected Results:**
- HTTP 200 response
- Response body shows "Hello from test-app"
- Response includes pod name (for multiple replicas)

### Test 5: Verify Security Groups
```bash
# Get ALB security group
ALB_SG=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'LoadBalancers[0].SecurityGroups[0]' \
  --output text)

echo "ALB Security Group: $ALB_SG"

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids $ALB_SG \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'SecurityGroups[0].[GroupId,IpPermissions]' \
  --output json
```

**Expected Results:**
- Security group allows inbound traffic on port 80/443
- Security group allows outbound traffic to node security group

### Test 6: Test Load Balancing
```bash
# Send multiple requests to verify load balancing
for i in {1..10}; do
  curl -s http://$ALB_DNS | grep -o "Pod: [^<]*" || echo "Request $i"
  sleep 1
done
```

**Expected Results:**
- Requests distributed across multiple pods
- Different pod names in responses (if multiple replicas)

### Test 7: Cleanup Test Resources
```bash
# Delete test resources
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# Verify ALB is deleted (may take a few minutes)
aws elbv2 describe-load-balancers \
  --region $REGION \
  --profile pushpender-credentials \
  --query "LoadBalancers[?DNSName=='$ALB_DNS']" \
  --output table
```

**Expected Result:** ALB and associated resources deleted

---

## Troubleshooting

### Issue: kubectl Connection Fails
```bash
# Re-configure kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile pushpender-credentials

# Check AWS credentials
aws sts get-caller-identity --profile pushpender-credentials

# Verify cluster endpoint access
aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --profile pushpender-credentials
```

### Issue: Nodes Not Joining Cluster
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name <nodegroup-name> \
  --region $REGION \
  --profile pushpender-credentials

# Check node group events
aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name <nodegroup-name> \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'nodegroup.health.issues' \
  --output json

# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table
```

### Issue: ALB Controller Not Creating Load Balancers
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100

# Verify IAM permissions
kubectl exec -n kube-system <alb-controller-pod> -- aws iam get-role --role-name <role-name>

# Check Ingress events
kubectl describe ingress test-app -n default

# Verify subnets are tagged correctly
aws ec2 describe-subnets \
  --subnet-ids <subnet-id> \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'Subnets[0].Tags' \
  --output table
```

### Issue: ALB Created but Targets Unhealthy
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region $REGION \
  --profile pushpender-credentials

# Check security group rules
# ALB security group must allow traffic to node security group
# Node security group must allow traffic from ALB security group

# Check pod status
kubectl get pods -l app=test-app -o wide

# Check service endpoints
kubectl get endpoints test-app
```

### Issue: Cannot Access ALB DNS
```bash
# Verify ALB is active
aws elbv2 describe-load-balancers \
  --load-balancer-arns <alb-arn> \
  --region $REGION \
  --profile pushpender-credentials \
  --query 'LoadBalancers[0].State' \
  --output json

# Check DNS resolution
nslookup <alb-dns-name>

# Check security group allows your IP
# For internet-facing ALB, ensure security group allows 0.0.0.0/0 on port 80/443
```

---

## Test Summary Checklist

Use this checklist to verify all components:

- [ ] VPC created and configured correctly
- [ ] Subnets created in correct AZs with correct CIDRs
- [ ] Internet Gateway attached
- [ ] NAT Gateway created (if enabled)
- [ ] Route tables configured correctly
- [ ] EKS Cluster in ACTIVE state
- [ ] EKS Addons (VPC CNI, kube-proxy, CoreDNS) installed and active
- [ ] kubectl configured and can connect to cluster
- [ ] Node group in ACTIVE state
- [ ] Worker nodes in Ready state
- [ ] Node IAM role has required policies
- [ ] OIDC provider created
- [ ] ALB Controller IAM role created with correct trust policy
- [ ] ALB Controller ServiceAccount exists with IRSA annotation
- [ ] ALB Controller deployment running
- [ ] ALB Controller pods healthy
- [ ] Test application deployed successfully
- [ ] Ingress created and ALB DNS name populated
- [ ] ALB created in AWS
- [ ] Target groups healthy
- [ ] Application accessible via ALB DNS
- [ ] Load balancing working across pods
- [ ] Security groups configured correctly

---

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

---

**Last Updated:** $(date)
**Tested with:** EKS Cluster v1.31, ALB Controller v1.8.0

