# DeployBoard Configuration Repository

<div align="center">

## Cluster 1 deployment configuration

[![Status](https://img.shields.io/badge/status-production-ready-success)](https://github.com)
[![Helm](https://img.shields.io/badge/helm-v3.21.4-blue)](https://helm.sh)
[![GitOps](https://img.shields.io/badge/gitops-ready-argo%20cd-orange)](https://argo-cd.readthedocs.io)

</div>

<div align="center">

<table>
  <tr>
    <td width="33%"><strong>Deployment</strong><br>Cluster 1</td>
    <td width="33%"><strong>Platform</strong><br>Kubernetes + Helm</td>
    <td width="33%"><strong>Security</strong><br>Secrets via AWS SM</td>
  </tr>
</table>

</div>

This repository holds the deployment configuration for DeployBoard and intentionally stays separate from both the application source code and the Terraform infrastructure layer.

---

## Overview

<div align="center">

| Area | Purpose | Ownership |
| --- | --- | --- |
| Deployment config | Helm chart and runtime manifests | `app-cluster1-deploy` |
| Infrastructure | EKS and AWS foundation | `terra-form` |
| GitOps | Argo CD installation and app sync | Planned separately |

</div>

### Mission

Keep application deployment concerns isolated from infrastructure provisioning so updates stay predictable, reviewable, and safe for Cluster 1.

<div align="center">

<table>
  <tr>
    <td width="50%"><strong>Environment</strong><br>Development cluster</td>
    <td width="50%"><strong>Namespace</strong><br>deployboard-dev</td>
  </tr>
</table>

</div>

---

## Branch ownership

| Branch | Responsibility | Main content |
| --- | --- | --- |
| `app-cluster1-deploy` | Helm and Kubernetes application deployment | `app-cluster1/`, `.github/workflows/helm-validate.yaml` |
| `terra-form` | AWS infrastructure and EKS foundation | `terraform/` |
| Argo CD branch | GitOps installation and Argo CD application definitions | Planned separately |

> Do not add Helm charts, Kubernetes manifests, or environment values to `terra-form`. Do not add Terraform files to `app-cluster1-deploy`.

---

## Deployment dashboard

### Repository structure

```text
app-cluster1/
├── Chart.yaml
├── values.yaml
└── templates/

.github/workflows/
└── helm-validate.yaml
```

### Current deployment scope

The `app-cluster1/values.yaml` file is the single source of truth for the current Cluster 1 development deployment. It contains non-secret image and RDS connection metadata and must never include a database username, password, token, or generated Kubernetes secret.

A future `app2-cluster1/` directory can host another application chart without mixing its resources or values with this deployment configuration.

---

## What the chart deploys

The chart creates separate frontend and backend workloads for DeployBoard:

- Two backend replicas by default, exposed internally on port `8000`
- Two frontend replicas by default, exposed internally on port `80`
- Separate Horizontal Pod Autoscalers for backend and frontend
- Backend readiness and liveness checks
- Frontend readiness and liveness checks
- An optional `HTTPRoute`, disabled until a Gateway API controller and hostname are available
- An optional Ingress configuration for clusters that use an Ingress controller
- An `ExternalSecret` that reads the existing RDS secret from AWS Secrets Manager and creates the Kubernetes secret consumed by the backend

The backend receives `DATABASE_URL` from the generated Kubernetes secret. Database credentials are never committed to Git and are never passed as Helm command-line values.

---

## Prerequisites

Before deploying the chart to Cluster 1, verify the following:

1. The EKS cluster and managed node group are active.
2. The nodes can reach the private RDS endpoint on TCP `5432`.
3. External Secrets Operator is installed.
4. A `ClusterSecretStore` named `aws-secrets-manager` exists and uses IRSA with permission to read the configured Secrets Manager ARN.
5. The Docker Hub backend and frontend images exist with the requested immutable tag.
6. The target namespace, `deployboard-dev`, exists or is created by the deployment tool.

Infrastructure is maintained on the separate `terra-form` branch under `terraform/rds-foundation`. The existing RDS and VPC foundation must be reused; do not create a second database or VPC for the application.

---

## Validation pipeline

### Local Helm validation

Run these commands from the repository root on `app-cluster1-deploy`:

```bash
helm lint app-cluster1

helm template deployboard app-cluster1 \
  --namespace deployboard-dev \
  > /tmp/deployboard-cluster1-dev.yaml
```

To inspect the rendered resources:

```bash
grep '^kind:' /tmp/deployboard-cluster1-dev.yaml
kubectl apply --dry-run=client -f /tmp/deployboard-cluster1-dev.yaml
```

The `replace-with-git-sha` values are placeholders for local validation. The image-delivery workflow updates both image tags in `app-cluster1/values.yaml` to the application commit SHA before deployment.

### CI validation

`.github/workflows/helm-validate.yaml` is the Helm-only check for this branch. It runs on pushes to `app-cluster1-deploy`, pull requests that modify the chart or workflow, and manual dispatch. The workflow:

1. Checks out the repository.
2. Installs Helm `v3.21.4`.
3. Runs `helm lint` against `app-cluster1` and its `values.yaml`.
4. Runs `helm template` with the same chart and namespace.

CI validates manifests only. It does not need AWS credentials, database credentials, a Kubernetes context, or access to the production cluster.

---

## Release flow

1. The application repository builds and publishes the backend and frontend images to Docker Hub.
2. The image-delivery workflow updates `app-cluster1/values.yaml` with the immutable application SHA.
3. Helm CI validates the changed configuration.
4. The future Argo CD branch will consume this branch and synchronize the chart into Cluster 1.

> Keep image tags immutable. Do not use `latest` for a deployment that should be reproducible.

---

## Guardrails

- Separate config from infra.
- Keep secrets outside Git.
- Use immutable image tags.
- Reuse the existing foundation rather than recreating it.
- Keep Helm validation fast, explicit, and CI-safe.
