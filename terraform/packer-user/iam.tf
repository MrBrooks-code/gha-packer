data "aws_iam_policy_document" "packer_ami_builder" {
  # Packer Read Rights
  statement {
    sid    = "DescribeReadOnly"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceCreditSpecifications",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }

  # Packer Instance Management Rights
  statement {
    sid    = "RunAndManageBuildInstance"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  # Packer Security Group Management Rights
  statement {
    sid    = "ManageSecurityGroupForWinRMOrSSH"
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress"
    ]
    resources = ["*"]
  }

  # Packer AMI and Snapshot Management Rights
  statement {
    sid    = "CreateImageAndSnapshots"
    effect = "Allow"
    actions = [
      "ec2:CreateImage",
      "ec2:RegisterImage",
      "ec2:DeregisterImage",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:ModifyImageAttribute",
      "ec2:CopyImage"
    ]
    resources = ["*"]
  }

  # Packer Volume Management Rights
  statement {
    sid    = "VolumeLifecycleForBuild"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:ModifyVolumeAttribute"
    ]
    resources = ["*"]
  }

  # Packer Tagging Rights
  statement {
    sid    = "Tagging"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]
  }

  # Helpful for sanity checks in CI
  statement {
    sid       = "CallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  # OPTIONAL: only needed if your Packer builder sets iam_instance_profile (Windows often doesn’t need it,
  # but you might want SSM, domain join, etc.)
  dynamic "statement" {
    for_each = var.packer_instance_role_arn == null ? [] : [var.packer_instance_role_arn]
    content {
      sid       = "AllowPassRoleForInstanceProfile"
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "packer_ami_builder" {
  name   = "PackerAmiBuilderPolicy"
  policy = data.aws_iam_policy_document.packer_ami_builder.json
}

resource "aws_iam_user_policy_attachment" "packer_attach" {
  user       = aws_iam_user.packer.name
  policy_arn = aws_iam_policy.packer_ami_builder.arn
}