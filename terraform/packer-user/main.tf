############################################
# Packer IAM user (least-privilege-ish)
# For: amazon-ebs builder creating AMIs
############################################




resource "aws_iam_user" "packer" {
  name = var.name
  path = "/cicd/"
  tags = module.this.tags
}




