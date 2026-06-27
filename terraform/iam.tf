locals {
  roles = toset(["elasticsearch", "kibana", "apm"])
}

resource "aws_iam_role" "elastic_node" {
  for_each = local.roles

  name = "elastic-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  for_each = local.roles

  role       = aws_iam_role.elastic_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ssm_params" {
  for_each = local.roles

  name = "elastic-${each.key}-ssm-params"
  role = aws_iam_role.elastic_node[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/elastic/*"
    }]
  })
}

resource "aws_iam_instance_profile" "elastic_node" {
  for_each = local.roles

  name = "elastic-${each.key}"
  role = aws_iam_role.elastic_node[each.key].name
}
