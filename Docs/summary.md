## Terraform EKS Stack Summary

### 1. Root Module
- **providers.tf**
  - Configures `aws` provider (region/profile from variables).
  - Declares `kubernetes` provider using `aws eks get-token` exec auth against the created cluster.
  - Declares `helm` provider (using same credentials/context as `kubernetes`).
- **main.tf**
  - `module "vpc"` – creates networking (VPC, subnets, IGW, NAT, routes).
  - `module "cluster"` – creates EKS control plane in that VPC.
  - `module "nodes"` – creates managed node group in private subnets.
  - `module "alb_controller"` – creates ALB controller with IAM and Kubernetes resources.
- **variables.tf / terraform.tfvars**
  - Global settings for environment (env, app_name, region, profile), VPC CIDRs, EKS version and endpoint access, node group sizes/types, and ALB controller version.

### 2. Network Module (`modules/data-plane/network`)
- **main-vpc.tf**
  - `aws_vpc.this` – main VPC (`cluster-network` CIDR) with DNS support.
  - `aws_subnet.eni_subnets` – small ENI subnets for control-plane ENIs.
  - `aws_subnet.private_subnets` – private subnets for worker nodes.
  - `aws_subnet.public_subnets` – public subnets for ingress/NAT.
  - `aws_subnet.database_subnets` – database subnets.
  - `aws_internet_gateway.this` – IGW attached to the VPC.
  - `aws_route_table.public_rt` + `aws_route_table_association.public_rt_assoc` – public routing to IGW.
  - Conditional `aws_eip.nat_eip` and `aws_nat_gateway.this` – NAT gateway for private/db subnets when enabled.
  - `aws_route_table.private_rt` + `aws_route_table_association.private_rt_assoc` and `database_rt_assoc` – private/db routing through NAT.
- **local.tf**
  - Locals for naming and tagging (VPC name, common tags).
- **output.tf**
  - Exposes `vpc_id`, subnet IDs (eni, private, public, database), and route table IDs for root/module consumers.

### 3. Control Plane Module (`modules/control-plane`)
- **locals.tf**
  - `local.cluster_name` – `eks-{region_tag}-{env}-{app_name}`.
  - Common tags for cluster resources.
- **iam.tf**
  - `aws_iam_role.cluster_role` – IAM role assumed by EKS control plane.
  - `aws_iam_role_policy_attachment.amazon_eks_cluster_policy` – attaches `AmazonEKSClusterPolicy`.
- **eks.tf**
  - `aws_security_group.additional_security_group` – optional extra SG for control-plane ENIs.
  - `aws_eks_cluster.this` – EKS cluster:
    - Version from `var.cluster_version`.
    - ENIs in `var.eni_subnet_ids`.
    - Endpoint access flags (`endpoint_private_access` / `endpoint_public_access`).
    - Access config (`authentication_mode`, `bootstrap_cluster_creator_admin_permissions`).
  - EKS addons:
    - `aws_eks_addon.vpc_cni_addon` – VPC CNI with prefix delegation.
    - `aws_eks_addon.eks_kube_proxy_addon` – kube-proxy.
    - `aws_eks_addon.coredns_addon` – CoreDNS with a pinned version.
- **output.tf**
  - Outputs `cluster_name`, `cluster_security_group_id`, and `cluster_object` to the root module.
- **variables.tf**
  - Cluster metadata (`env`, `app_name`, `region`, `region_tag`).
  - EKS settings (version, ENI subnets, VPC ID, endpoint flags, auth mode, bootstrap flag).

### 4. Nodes Module (`modules/data-plane/nodes`)
- **variables.tf**
  - Metadata passed from root: `env`, `app_name`, `region`, `region_tag`.
  - Cluster wiring: `cluster_name`, `cluster_security_group_id`, `subnet_ids`.
  - Node config: `nodes_instance_types`, `capacity_type`, `desired_size`, `min_size`, `max_size`, `max_unavailable`, `label`, disk/AMI knobs.
- **locals.tf**
  - Common tags (`env`, `app_name`, `Terraform`).
- **worker-iam.tf**
  - `aws_iam_role.worker_nodes_role` – IAM role for worker nodes.
  - Policy attachments:
    - `AmazonEKSWorkerNodePolicy`
    - `AmazonEKS_CNI_Policy`
    - `AmazonEC2ContainerRegistryReadOnly`
    - `AmazonSSMManagedInstanceCore`
    - `AmazonS3FullAccess`
    - `SecretsManagerReadWrite`
- **launch-tamplate.tf**
  - `aws_launch_template.launch_template` – launch template for worker nodes:
    - `name_prefix = "${var.cluster_name}-launch-template-"`.
    - 50GB EBS volume, EBS-optimized, IMDSv2 required, no public IPs.
- **worker-node.tf**
  - `aws_eks_node_group.nodes` – managed node group:
    - Binds to `var.cluster_name` and `worker_nodes_role`.
    - Uses `subnet_ids` (private subnets).
    - Scaling config from `desired_size`, `min_size`, `max_size`.
    - Update config `max_unavailable`.
    - Node labels and tags (including Name = `{cluster}-worker-node`).
- **node-sq.tf**
  - `aws_security_group_rule.https_port` – egress rule on HTTPS (443) for cluster SG, allowing outbound internet access via VPC routing.

### 5. ALB Controller Module (`modules/alb-controller`)
- **variables.tf**
  - Module inputs: cluster name, OIDC issuer URL, cluster object, VPC ID, region, version, metadata.
- **locals.tf**
  - Common tags for ALB controller resources.
- **iam.tf**
  - `data.tls_certificate.oidc` and `aws_iam_openid_connect_provider.eks` – OIDC provider for IRSA.
  - `aws_iam_role.alb_controller` – IAM role for AWS Load Balancer Controller.
  - `aws_iam_policy.alb_controller` – policy granting ALB/NLB, SG, WAF, Shield, and related permissions.
  - `aws_iam_role_policy_attachment.alb_controller` – attaches the policy to the role.
- **kubernetes.tf**
  - `kubernetes_service_account.alb_controller` – ServiceAccount annotated with the IAM role ARN (IRSA).
  - `helm_release.aws_load_balancer_controller` – Helm release deploying `aws-load-balancer-controller` with:
    - Cluster name, region, VPC ID.
    - Pre-created ServiceAccount.
- **output.tf**
  - Outputs `alb_controller_role_arn`, `oidc_provider_arn`, and `alb_controller_service_account_name`.

### 6. Validation Status
- `terraform validate` (run from project root) currently **passes with no errors**, meaning:
  - No duplicate variable names within a module.
  - All referenced variables and modules are defined.
  - Provider blocks and resource syntax are valid for Terraform v1.5.7 and the pinned provider versions.


