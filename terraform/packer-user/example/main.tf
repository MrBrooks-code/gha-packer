

module "packer_user" {
  source      = "../"
  name        = "packer-ami-builder"
  namespace   = "demo"
  tenant      = "example"
  environment = "dev"
  stage       = "test"
  region      = "us-west-2"
}