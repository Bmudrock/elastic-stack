resource "aws_iam_role" "this" {
  name = "elastic-${local.ns}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# Session Manager access for break-glass administration.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The instance reads its TLS material and writes/reads stack credentials
# (passwords, Fleet tokens) under its own namespaced SSM path.
resource "aws_iam_role_policy" "ssm_params" {
  name = "elastic-${local.ns}-ssm-params"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StackParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:*:parameter${local.ssm_root}/*"
      },
      {
        Sid    = "SsmKmsForSecureString"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "elastic-${local.ns}"
  role = aws_iam_role.this.name
}
