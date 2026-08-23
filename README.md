# DeployBoard infrastructure repository

This branch contains the Terraform infrastructure for DeployBoard. It is separate from the Helm deployment branch and must not contain application charts, Kubernetes manifests, or environment values.

## Branch responsibilities

- `terra-form`: AWS networking, RDS, EKS, IAM, security groups, and the SSM bridge.
- `app-cluster1-deploy`: Helm chart and Cluster 1 Kubernetes environment values.
- Argo CD branch: planned GitOps controller and Application definitions.

## Layout

```text
terraform/
└── rds-foundation/
    ├── database.tf
    ├── eks.tf
    ├── network.tf
    ├── security.tf
    ├── ssm_bridge.tf
    ├── variables.tf
    └── outputs.tf
```

## Managed resources

The `terraform/rds-foundation` stack manages the shared development foundation:

- Existing two-AZ VPC and public/database subnets.
- Existing encrypted PostgreSQL RDS instance.
- Existing SSM bridge instance for private database administration.
- EKS cluster `deployboard-dev-cluster` in `ap-south-1`.
- Managed node group `deployboard-dev-nodes` with two `t3.medium` nodes.
- IAM roles and managed policies required by EKS.
- EKS node security group and PostgreSQL access from EKS nodes.

The RDS password remains in AWS Secrets Manager. Terraform outputs the secret ARN and connection metadata; it does not place the password in Git or Kubernetes values files.

## State and duplicate-resource protection

Terraform state is local and ignored by Git for this development setup. The state file must be recovered or imported before running a plan in a new worktree. Never run `terraform apply` from a worktree with an empty state when the VPC or RDS foundation already exists.

Before applying, require a plan with:

```text
0 destroy
```

Do not apply if Terraform proposes replacing the RDS instance, VPC, subnets, or SSM bridge. Review the plan and import the existing AWS resource into the recovered state instead.

## Terraform workflow

From `terraform/rds-foundation`:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -input=false
terraform apply -auto-approve -input=false
```

## CI validation

`.github/workflows/terraform-validate.yaml` validates Terraform changes on pull
requests, pushes to `terra-form`, and manual dispatch. It runs:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false -input=false`
3. `terraform validate`

The workflow intentionally does not run `terraform plan`, `terraform apply`, or
destroy operations. This branch uses a local state file and manages existing
AWS resources, so infrastructure changes must be reviewed and applied manually
from the recovered state in the Terraform worktree.

After applying, verify the cluster and nodes:

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name deployboard-dev-cluster

kubectl get nodes -o wide
```

The expected result is an `ACTIVE` EKS cluster and two `Ready` nodes. Helm deployment is performed separately from the `app-cluster1-deploy` branch after External Secrets Operator and its IRSA-backed `ClusterSecretStore` are configured.

## Cost and safety

RDS and EKS incur AWS charges while running. Stop the SSM bridge when it is not needed, and use the stack README for database administration and cost-control procedures. Do not delete shared infrastructure as part of an application deployment change.
