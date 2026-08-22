# Private RDS foundation

This Terraform layer creates the first AWS database for DeployBoard in `ap-south-1`. RDS is private and cannot be reached directly from the internet. A small EC2 instance with no inbound rules provides temporary AWS Systems Manager port forwarding until EKS exists.

## Expected cost

Prices change; check the AWS Pricing Calculator before applying. The main billable resources are:

- One `db.t4g.micro` RDS instance and 20 GiB gp3 storage
- One `t3.micro` EC2 bridge and 8 GiB gp3 root volume
- One public IPv4 address while the bridge is running
- One Secrets Manager secret
- Backup storage beyond the free automated-backup allocation

There is no NAT gateway in this layer. Stop the SSM bridge when it is not needed. RDS continues billing until destroyed.

## 1. Secure the AWS account

Do not create access keys for the root user.

1. Sign in to the AWS console as root.
2. Enable root MFA.
3. Create a monthly AWS Budget and billing alert.
4. Open IAM Identity Center and enable it.
5. Create your non-root user.
6. Create an `AdministratorAccess` permission set for this learning account.
7. Assign the user and permission set to the AWS account.

Use the administrator permission only while bootstrapping. Later exercises should replace it with narrower Terraform and deployment roles.

## 2. Configure AWS CLI with SSO

From a local terminal:

```bash
aws configure sso --profile navin-devops
```

Enter the IAM Identity Center start URL and SSO region shown in the console, choose the AWS account and administrator role, and set default region `ap-south-1` and output `json`.

Authenticate and verify the non-root role:

```bash
aws sso login --profile navin-devops
export AWS_PROFILE=navin-devops
export AWS_REGION=ap-south-1
aws sts get-caller-identity
```

The ARN should be an assumed SSO role, not `arn:aws:iam::<account>:root`.

## 3. Review local inputs

```bash
cd /home/chandranavinn/Desktop/APPS/App1/config-repo/terraform/rds-foundation
cp terraform.tfvars.example terraform.tfvars
```

The real `terraform.tfvars` is ignored by Git. For the first dev database, the example defaults are sufficient. Do not put passwords in it: RDS creates and rotates the master password through Secrets Manager.

## 4. Initialize and plan

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=rds.tfplan
terraform show rds.tfplan
```

Review the plan carefully. It should include one VPC, four subnets, one internet gateway, route/security resources, one RDS instance, one IAM instance profile, and one EC2 bridge. It must show `publicly_accessible = false` for RDS.

The current layer uses local Terraform state because AWS is not bootstrapped yet. Before adding EKS or collaborating, move state to an encrypted, versioned S3 backend with locking. Never commit local state because it contains sensitive infrastructure metadata.

## 5. Apply deliberately

Only after reviewing the plan and expected cost:

```bash
terraform apply rds.tfplan
```

RDS creation usually takes several minutes. Record the non-secret outputs:

```bash
terraform output
```

Do not paste secret values into chat, shell history, source files, Terraform variables, or Git.

## 6. Install the Session Manager plugin

Check whether it is available:

```bash
session-manager-plugin --version
```

If the command is missing, install the AWS Session Manager plugin using the official AWS package for your Linux distribution. The AWS CLI invokes it when the tunnel starts.

## 7. Start the private database tunnel

Load Terraform outputs:

```bash
export RDS_HOST=$(terraform output -raw rds_endpoint)
export BRIDGE_ID=$(terraform output -raw ssm_bridge_instance_id)
export SECRET_ARN=$(terraform output -raw master_secret_arn)
```

Wait until the bridge is registered with SSM:

```bash
aws ssm describe-instance-information \
  --profile navin-devops \
  --region ap-south-1 \
  --filters "Key=InstanceIds,Values=$BRIDGE_ID"
```

Start a local port-forwarding session and keep this terminal open:

```bash
aws ssm start-session \
  --profile navin-devops \
  --region ap-south-1 \
  --target "$BRIDGE_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$RDS_HOST\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"15432\"]}"
```

The tunnel exposes private RDS only at `127.0.0.1:15432` on your machine. The RDS security group does not accept public internet traffic.

## 8. Retrieve credentials without printing them

In a second terminal, authenticate and load the JSON secret:

```bash
export AWS_PROFILE=navin-devops
export AWS_REGION=ap-south-1
cd /home/chandranavinn/Desktop/APPS/App1/config-repo/terraform/rds-foundation
export SECRET_ARN=$(terraform output -raw master_secret_arn)
export RDS_SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --query SecretString \
  --output text)
```

Use `jq` to place credentials in environment variables without echoing them:

```bash
export PGUSER=$(jq -r '.username' <<<"$RDS_SECRET_JSON")
export PGPASSWORD=$(jq -r '.password' <<<"$RDS_SECRET_JSON")
unset RDS_SECRET_JSON
export PGHOST=127.0.0.1
export PGPORT=15432
export PGDATABASE=deployboard_dev
```

Avoid command-line password arguments because they may appear in process listings or shell history.

## 9. Test PostgreSQL and run migrations

Install the PostgreSQL client locally if `psql` is unavailable, then verify TLS through the tunnel:

```bash
psql "sslmode=require" -c 'select current_database(), current_user, version();'
```

Run the DeployBoard migration from another terminal while the tunnel remains open:

```bash
cd /home/chandranavinn/Desktop/APPS/App1/app-cluster1
source .venv/bin/activate
export DATABASE_URL="postgresql+psycopg://${PGUSER}:${PGPASSWORD}@127.0.0.1:15432/deployboard_dev?sslmode=require"
cd backend
alembic upgrade head
python -m app.seed
alembic current
```

Because special characters in a password must be URL-encoded, the eventual EKS secret will be generated programmatically rather than manually concatenated. For this first local test, prefer `psql` verification; if the generated password contains URL-reserved characters, use a short helper or SQLAlchemy URL object instead of printing or editing the password.

## 10. Stop costs when idle

The bridge is needed only for administrative tunnels. Stop it after closing the SSM session:

```bash
aws ec2 stop-instances \
  --profile navin-devops \
  --region ap-south-1 \
  --instance-ids "$(terraform output -raw ssm_bridge_instance_id)"
```

Start it before the next tunnel:

```bash
aws ec2 start-instances \
  --profile navin-devops \
  --region ap-south-1 \
  --instance-ids "$(terraform output -raw ssm_bridge_instance_id)"
```

RDS cannot be stopped indefinitely; AWS automatically restarts a stopped RDS instance after its service limit. Destroy the learning layer when it is no longer needed.

## 11. Destroy the layer

The first lab uses `deletion_protection = false` and skips the final snapshot for easy teardown. Preserve important data manually before destroying.

```bash
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

Confirm in AWS Resource Explorer or the console that RDS, EC2, EBS, the public IPv4 address, Secrets Manager secret, VPC resources, and security groups are gone.

## Later EKS connection

The SSM tunnel is only for local administration. EKS pods will connect directly inside the VPC. External Secrets Operator will copy environment-specific connection data from Secrets Manager into Kubernetes Secrets, and the backend Deployment will consume `DATABASE_URL` with `secretKeyRef`. RDS security groups will then allow port `5432` from the EKS application security group.