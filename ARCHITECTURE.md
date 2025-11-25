# EKS Cluster Infrastructure Overview

This document summarizes what the Terraform project builds and how the
modules fit together. The stack has four major layers: networking,
EKS control plane, worker nodes (data plane), and ALB controller.

## Networking (`modules/data-plane/network`)
- Creates a VPC (`10.0.0.0/16`) with DNS support enabled, fully tagged using environment and application metadata.
- Provisions four subnet tiers (ENI, private, public, database) across one or two Availability Zones depending on `var.multi_az`.
- Attaches an Internet Gateway, builds a public route table with a default route to the IGW, and associates every public subnet.
- Optionally deploys a NAT Gateway (controlled via `var.enable_nat_gateway`), then wires private and database route tables through that NAT for egress.
- Exposes VPC ID, subnet IDs, and route table IDs via outputs for other modules to consume.

## EKS Control Plane (`modules/control-plane`)
- Defines an IAM role for the EKS service (`AmazonEKSClusterPolicy`) and an optional additional security group for ENIs.
- Builds the cluster name as `eks-${region_tag}-${env}-${app}` so each deployment is uniquely identified.
- Creates `aws_eks_cluster.this` with:
  - Configurable Kubernetes version (`var.cluster_version`).
  - Private/public endpoint controls (`var.endpoint_private_access` / `var.endpoint_public_access`).
  - Access configuration using `var.authentication_mode` and optional admin bootstrap flag.
  - ENI placement restricted to the ENI subnets coming from the VPC module.
- Publishes the cluster name and security-group ID for reuse.
- Installs managed addons:
  - `vpc-cni` with prefix delegation enabled and warm prefixes.
  - `kube-proxy` with conflict resolution set to `OVERWRITE`.

## Worker Nodes & Addons (`modules/data-plane/nodes`)
- IAM: creates a worker node role (`${cluster_name}-nodes`) and attaches
  `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, ECR read-only,
  SSM Managed Instance Core, S3 FullAccess, Secrets Manager RW, and the
  custom AWS Load Balancer Controller policy.
- Launch template:
  - Uses `name_prefix = "${var.cluster_name}-launch-template-"` for uniqueness.
  - 50 GB EBS volume, EBS-optimized, IMDSv2 enforced, no public IPs.
  - User-data left optional/commented to avoid conflicting with EKS-managed bootstrap.
- `aws_eks_node_group.nodes`:
  - References the cluster name and worker role.
  - Deploys into the private subnets from the VPC module.
  - Supports SPOT or ON-DEMAND capacity, custom instance types, and min/max/desired scaling configuration.
  - Applies labels and tags so instances inherit environment/app metadata and a readable `Name`.
- Security: configures an egress HTTPS rule (port 443) on the cluster security group so nodes can reach the internet through the NAT/IGW path.

## Inputs & Customization
Key variables surfaced in `variables.tf`:
- Environment metadata (`env`, `app_name`, `application_name`, `region`, `region_tag`, `profile_name`, `role_name`).
- VPC CIDR map, DNS flags, NAT and multi-AZ toggles.
- EKS settings (`cluster_version`, endpoint access flags, authentication/bootstrapping).
- Node group knobs (`nodes_instance_types`, capacity type, scaling sizes, `max_unavailable`, labels).

All metadata flows through modules so tagging is consistent across networking, control plane, and nodes.

## 4. AWS Load Balancer Controller Module (`modules/alb-controller`)

### Purpose
The AWS Load Balancer Controller manages Application Load Balancers (ALB) and Network Load Balancers (NLB) for Kubernetes services and ingresses. This is now a dedicated module for better organization and reusability.

### Components

#### IAM Configuration (`iam.tf`) - IRSA (IAM Roles for Service Accounts)
- **OIDC Provider**: `aws_iam_openid_connect_provider.eks` - Created for the EKS cluster to enable IRSA
- **IAM Role**: `aws_iam_role.alb_controller` - `{cluster-name}-alb-controller-role`
  - Trust relationship with OIDC provider
  - Assumed by the `aws-load-balancer-controller` ServiceAccount
- **IAM Policy**: `aws_iam_policy.alb_controller` - Comprehensive permissions for:
  - EC2 operations (describe resources, manage security groups)
  - ELB operations (create/manage load balancers, target groups, listeners)
  - ACM/WAF/Shield integration
  - Service-linked role creation
- **Policy Attachment**: `aws_iam_role_policy_attachment.alb_controller` - Attaches policy to role

#### Kubernetes Resources (`kubernetes.tf`)
- **ServiceAccount**: `kubernetes_service_account.alb_controller` in `kube-system` namespace
  - Annotated with IAM role ARN for IRSA
- **Helm Release**: `helm_release.aws_load_balancer_controller` - Installs AWS Load Balancer Controller
  - Chart: `aws-load-balancer-controller` from AWS EKS charts repository
  - Version: Configurable via `alb_controller_version` variable (default: 1.8.0)
  - Configuration via `values` argument:
    - Cluster name
    - VPC ID
    - Region
    - Service account (uses pre-created ServiceAccount)

#### Module Files
- **`variables.tf`**: Module input variables (cluster info, VPC, region, version, metadata)
- **`locals.tf`**: Common tags for resources
- **`output.tf`**: Exports ALB controller role ARN, OIDC provider ARN, and ServiceAccount name

### Features
- **Automatic ALB/NLB Creation**: Creates load balancers when Ingress or Service resources are created
- **Target Group Management**: Automatically manages target groups and registers pods
- **Security Group Management**: Creates and manages security groups for load balancers
- **SSL/TLS Support**: Integrates with ACM for certificate management
- **WAF Integration**: Supports AWS WAF for application protection

### Usage
After deployment, you can create Kubernetes Ingress resources with the annotation:
```yaml
annotations:
  kubernetes.io/ingress.class: alb
  alb.ingress.kubernetes.io/scheme: internet-facing  # or internal
  alb.ingress.kubernetes.io/target-type: ip
```

## How to Deploy
1. Configure AWS credentials/profile as described in `README.md`.
2. Review/adjust `terraform.tfvars` for environment-specific values.
3. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. After `apply` completes, use `aws eks update-kubeconfig --name <cluster_name> --region <region>` to connect and verify nodes/addons are healthy.
5. Verify ALB Controller: `kubectl get deployment -n kube-system aws-load-balancer-controller`

This architecture stands up a production-ready, private EKS cluster with
managed networking, IAM, worker nodes, and ALB controller that follow AWS best practices.

