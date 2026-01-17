# Packer Windows Server 2022 AMI Builder

This repository provides infrastructure automation for building custom Windows Server 2022 AMIs using HashiCorp Packer, with proper IAM permissions managed through Terraform and automated CI/CD via GitHub Actions.

## Overview

This project combines three key components:

1. **Terraform Module** - Creates an IAM user with least-privilege permissions for Packer AMI builds
2. **Packer Templates** - Defines Windows Server 2022 AMI build configuration
3. **GitHub Actions Workflow** - Automates the AMI build process

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── packer.yml              # GitHub Actions workflow for AMI builds
├── ami/
│   └── win2022.pkr.hcl            # Packer template (production)
├── terraform/
│   └── packer-user/               # Terraform module for IAM user
│       ├── context.tf             # CloudPosse naming/tagging conventions
│       ├── iam.tf                 # IAM policies and user configuration
│       ├── main.tf                # Main IAM user resource
│       ├── providers.tf           # AWS provider configuration
│       ├── variables.tf           # Input variables
│       └── example/
│           └── main.tf            # Usage example
└── win2022.pkr.hcl                # Packer template (development/testing)
```

## Components

### 1. Terraform IAM Module (`terraform/packer-user/`)

Creates a dedicated IAM user for Packer with the following permissions:

**Read-Only Permissions:**
- EC2 resource descriptions (AMIs, instances, VPCs, subnets, security groups, etc.)
- Account and region information

**Management Permissions:**
- EC2 instance lifecycle (run, start, stop, terminate)
- Temporary key pair creation/deletion
- Temporary security group management
- AMI creation and registration
- EBS snapshot and volume management
- Resource tagging
- Windows password data retrieval

**Optional Permissions:**
- IAM PassRole (for instance profiles, if needed)

**Features:**
- Uses CloudPosse `terraform-null-label` for consistent naming and tagging
- Follows least-privilege security principles
- Supports custom IAM instance profile roles via `packer_instance_role_arn` variable

**Usage Example:**
```hcl
module "packer_user" {
  source      = "../"
  name        = "packer-ami-builder"
  namespace   = "demo"
  tenant      = "example"
  environment = "dev"
  stage       = "test"
  region      = "us-west-2"
}
```

### 2. Packer Templates

**Location:** `ami/win2022.pkr.hcl` (production) and `win2022.pkr.hcl` (development)

**Configuration:**
- **Base AMI:** Latest official Windows Server 2022 Full Base from Amazon
- **Instance Type:** t2.micro
- **Communicator:** WinRM (port 5985)
- **Region:** Configurable via variable (default: us-east-1)
- **Networking:** Requires VPC ID and Subnet ID

**Provisioning Steps:**
1. Displays hello message via PowerShell
2. Creates `C:\Temp` directory
3. Writes test file to `C:\Temp\hello.txt`
4. Verifies file content

**Output:**
- AMI named `win2022-hello-{timestamp}`
- Tagged with Tool=Packer and Environment=dev

### 3. GitHub Actions Workflow

**Trigger Conditions:**
- Manual dispatch (`workflow_dispatch`)
- Push to `main` branch affecting `ami/**` or workflow file

**Workflow Steps:**
1. Checkout repository
2. Install latest Packer
3. Initialize Packer plugins
4. Build AMI using Packer template

**Required Secrets:**
- `AWS_ACCESS_KEY_ID` - AWS access key for Packer IAM user
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for Packer IAM user
- `AWS_DEFAULT_REGION` - Target AWS region
- `AWS_VPC_ID` - VPC ID for build instance
- `AWS_SUBNET_ID` - Subnet ID for build instance


## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 0.13.0
- Packer >= 1.0.0
- GitHub repository with secrets configured (for CI/CD)

## Getting Started

### 1. Deploy IAM User with Terraform

```bash
cd terraform/packer-user/example
terraform init
terraform plan
terraform apply
```

Create access keys for the IAM user and store them securely.

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository:
- AWS credentials for the Packer IAM user
- AWS region, VPC ID, and Subnet ID
- AMI template filename

### 3. Run Packer Locally (Optional)

```bash
# Initialize Packer plugins
packer init win2022.pkr.hcl

# Validate template
packer validate \
  -var "region=us-east-1" \
  -var "vpc_id=vpc-xxxxx" \
  -var "subnet_id=subnet-xxxxx" \
  win2022.pkr.hcl

# Build AMI
packer build \
  -var "region=us-east-1" \
  -var "vpc_id=vpc-xxxxx" \
  -var "subnet_id=subnet-xxxxx" \
  win2022.pkr.hcl
```

### 4. Trigger GitHub Actions Build

Either push changes to the `ami/` directory or manually trigger the workflow from the Actions tab.

## Security Considerations

- The Packer IAM user follows least-privilege principles
- WinRM uses HTTP (port 5985) inside the VPC with temporary security groups
- Build instances are short-lived and terminated after AMI creation
- Credentials should be rotated regularly
- Consider using HTTPS WinRM (port 5986) for production builds

## Customization

### Extending the Packer Template

Modify `ami/win2022.pkr.hcl` to:
- Install additional software
- Apply Windows updates
- Configure settings
- Run sysprep for production AMIs

### Adjusting IAM Permissions

Edit `terraform/packer-user/iam.tf` to add or remove permissions based on your Packer template requirements.

## Git History

Recent commits:
- `1e11183` - IAM Permissions Gaps
- `4f64278` - win2022 hcl
- `6aa0699` - update packer.yml
- `eb8d8d1` - feat/packer-user
- `632c461` - Init

## License

This project is provided as-is for educational and demonstration purposes.

## Contributing

Contributions are welcome. Please ensure that:
- IAM permissions follow least-privilege principles
- Packer templates are tested before committing
- Documentation is updated for any changes
