resource "aws_security_group" "ssm_bridge" {
  name_prefix = "${local.name}-ssm-bridge-"
  description = "No-ingress bridge for SSM port forwarding"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Outbound access for SSM and private RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-ssm-bridge" }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "database" {
  name_prefix = "${local.name}-postgres-"
  description = "PostgreSQL access from approved application clients"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from SSM bridge"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_bridge.id]
  }

  egress {
    description = "Allow response traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-postgres" }

  lifecycle { create_before_destroy = true }
}
