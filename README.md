# DeployBoard config repository

This repository is the GitOps source of truth for Terraform, Helm, and Argo CD. The first infrastructure layer provisions the private PostgreSQL foundation used by Cluster 1 dev, and the DeployBoard chart securely connects the application to it.

## Current infrastructure

`terraform/rds-foundation` creates:

- A two-AZ VPC
- Two public management subnets and two private database subnets
- A private, encrypted PostgreSQL RDS instance
- An AWS-managed Secrets Manager master password
- A no-ingress EC2 bridge for SSM port forwarding
- Security groups allowing PostgreSQL only from the bridge

The foundation is applied in `ap-south-1`, the schema is migrated and seeded, and the SSM bridge is stopped when it is not needed. RDS remains billable while running. Follow `terraform/rds-foundation/README.md` for administration and cost controls.

## Application deployment

`apps/deployboard` contains the reusable Helm chart. `environments/cluster1-dev/values.yaml` contains only non-secret environment configuration and the Secrets Manager ARN; it never contains the secret value.

The chart requires EKS, External Secrets Operator, an IRSA-backed `ClusterSecretStore`, ECR images, and RDS network access before Argo CD can sync it. See `apps/deployboard/README.md` for the exact contract and validation commands.

Local Docker Compose continues to use its local PostgreSQL container. The RDS configuration applies only to the Kubernetes deployment.

## GitHub Actions

`.github/workflows/validate.yaml` runs on every push and pull request. It lints and renders the Cluster 1 dev Helm release and validates Terraform formatting and configuration.

The application workflow updates only `environments/cluster1-dev/values.yaml`, setting both image tags to the same immutable Git SHA. The config workflow never needs AWS or database credentials.
