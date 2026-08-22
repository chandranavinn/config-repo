# DeployBoard Helm chart

This chart deploys the Cluster 1 frontend and backend and connects the backend to private Amazon RDS without storing database credentials in Git.

## Database flow

1. External Secrets Operator reads `username` and `password` from the AWS-managed RDS secret.
2. The `ExternalSecret` combines those credentials with the non-secret RDS endpoint and database name.
3. It creates the `deployboard-database` Kubernetes Secret with a URL-encoded `url` key.
4. The Argo CD migration hook runs `alembic upgrade head` with that URL.
5. Backend pods receive the same URL as `DATABASE_URL`.

The application never receives AWS credentials and no database password is committed to this repository.

## Cluster prerequisites

- EKS worker nodes or pods can route to the private RDS subnets.
- The RDS security group allows TCP `5432` from the EKS application security group.
- External Secrets Operator is installed in Cluster 1.
- A `ClusterSecretStore` named `aws-secrets-manager` uses IRSA and may read only the configured secret ARN.
- The backend and frontend images exist in ECR with the immutable tags in the environment values.
- Argo CD deploys the chart into the target namespace with automated sync enabled.

The existing RDS master secret is used for this first dev milestone. Before production, create separate least-privilege application and migration roles with independently managed secrets.

## Validate

From the `config-repo` root:

```bash
helm lint apps/deployboard \
  -f environments/cluster1-dev/values.yaml

helm template deployboard apps/deployboard \
  --namespace deployboard-dev \
  -f environments/cluster1-dev/values.yaml
```

The `replace-with-git-sha` image tags are intentional placeholders. CI will replace them with the Git commit SHA after pushing both images to ECR.
