data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "ssm_bridge" {
  name = "${local.name}-ssm-bridge"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_bridge" {
  role       = aws_iam_role.ssm_bridge.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_bridge" {
  name = "${local.name}-ssm-bridge"
  role = aws_iam_role.ssm_bridge.name
}

resource "aws_instance" "ssm_bridge" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.ssm_bridge_instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.ssm_bridge.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_bridge.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = { Name = "${local.name}-ssm-bridge" }
}
