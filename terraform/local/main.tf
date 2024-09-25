terraform {
  backend "s3" {
    bucket = "allcle-tf-multi-backend"
    key = "terraform/terraform.tfstate"
  }
}


# us-east-2 리전 프로바이더
provider "aws" {
  region = var.region
}

# us-east-1(ohio) 리전 프로바이더(cloudfront 인증서용)
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "allcle_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ALLCLE-VPC"
  }
}

# Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.allcle_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.allcle_vpc.id
  cidr_block              = var.public_subnet_c_cidr
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-c"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.allcle_vpc.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "${var.region}a"
  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.allcle_vpc.id
  cidr_block        = var.private_subnet_c_cidr
  availability_zone = "${var.region}c"
  tags = {
    Name = "private-c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.allcle_vpc.id
  tags = {
    Name = "ALLCLE-IGW"
  }
}

# Elastic IP 생성
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "NAT-EIP-A"
  }
}

resource "aws_eip" "nat_eip_c" {
  domain = "vpc"
  tags = {
    Name = "NAT-EIP-C"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "${var.nat_gateway_name}-A"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw_c" {
  allocation_id = aws_eip.nat_eip_c.id
  subnet_id     = aws_subnet.public_c.id
  tags = {
    Name = "${var.nat_gateway_name}-C"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Route Tables 생성
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.allcle_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.allcle_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }
  tags = {
    Name = "Private-RT-A"
  }
}

resource "aws_route_table" "private_rt_c" {
  vpc_id = aws_vpc.allcle_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_c.id
  }
  tags = {
    Name = "Private-RT-C"
  }
}

# Route Tables 연결
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_rt_c.id
}

# Security Groups 생성
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.allcle_vpc.id
  name   = "Bastion-SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 실제 운영 환경에서는 특정 IP 범위로 제한해야 합니다.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion-SG"
  }
}

#-------------------------------------------------------------------------------------------

## Bastion에 필요한 IAM Instance Profile용 Role 생성

# # IAM 역할 생성
# resource "aws_iam_role" "bastion_role" {
#   name               = "BastionRole"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [

#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }


# 모든 권한을 포함하는 IAM 정책
# resource "aws_iam_policy" "bastion_full_access" {
#   name        = "BastionFullAccessPolicy"
#   description = "Full access to EKS, S3, EventBridge, IAM, DynamoDB, Lambda, SQS, and CloudWatch Logs"
  
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:*",
#           "eks:*",
#           "s3:*",
#           "events:*",
#           "iam:*",
#           "acm:*",
#           "dynamodb:*",
#           "lambda:*",
#           "sqs:*",
#           "logs:*",  # CloudWatch Logs 관련 권한 추가
#           "sts:GetCallerIdentity"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# # IAM 역할에 정책 붙이기
# resource "aws_iam_role_policy_attachment" "attach_bastion_policy" {
#   role       = aws_iam_role.bastion_role.name
#   policy_arn = aws_iam_policy.bastion_full_access.arn
# }

# # IAM Instance Profile 생성
# resource "aws_iam_instance_profile" "bastion_instance_profile" {
#   name = "BastionHostInstanceProfile"
#   role = aws_iam_role.bastion_role.name
#   depends_on = [ aws_iam_role.bastion_role ]
# }

# Bastion 인스턴스 생성
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.public_key_pair
  # iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name

  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]
  tags = {
    Name = "bastion"
  }
  # depends_on = [ aws_iam_instance_profile.bastion_instance_profile ]
}


# AMI AL2023 데이터 소스
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name = "name"
    values = ["al2023-ami-*"] # Amazon Linux 2023 이름 패턴
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}


# ALB 보안 그룹
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.allcle_vpc.id
  name   = "ALB-SG"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.30"
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    
  }

  vpc_id     = aws_vpc.allcle_vpc.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_c.id, aws_subnet.private_a.id, aws_subnet.private_c.id]

  eks_managed_node_groups = {
    allcle_eks_ng = {
      name           = var.node_group_name
      instance_types = [var.instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      # vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]
      subnet_ids = [ aws_subnet.private_a.id, aws_subnet.private_c.id ]
    }
  }

  tags = {
    Environment = "ALLCLE"
  }
}


# EKS 클러스터 보안 그룹에 인바운드 룰 추가
resource "aws_security_group_rule" "eks_from_bastion" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  security_group_id = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.bastion_sg.id

  description = "Allow all TCP traffic from Bastion to EKS cluster"
}

# eks 모듈로 생성된 보안 그룹 데이터 불러오기
data "aws_security_group" "eks_nodes_sg" {
  id = module.eks.node_security_group_id
}

# 자동생성된 노드 보안 그룹에 규칙 추가하기
resource "aws_security_group_rule" "custom_ingress" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.eks_nodes_sg.id
}

#-----------------------------------------------------------------------

# EKS ALB Controller IAM Role 생성
resource "aws_iam_role" "alb_controller_role" {
    name               = "us-alb-controller-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
                Federated = module.eks.oidc_provider_arn
            }
        }
        ]
    })
    depends_on = [ module.eks ]
    tags = {
        Name = "ALBIngressControllerRoleUS"
    }
}

# ALB Controller IAM Policy 생성
resource "aws_iam_policy" "alb_ingress_controller_policy" {
    name        = "USAWSLoadBalancerControllerIAMPolicy"
    path        = "/"
    description = "Policy for AWS Load Balancer Controller"
    
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = "iam:CreateServiceLinkedRole"
            Resource = "*"
            Condition = {
            StringEquals = {
                "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeCoipPools",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTags"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "waf-regional:GetWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:GetSubscriptionState",
            "shield:DescribeProtection",
            "shield:CreateProtection",
            "shield:DeleteProtection"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:CreateSecurityGroup"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:CreateTags"
            ]
            Resource = "arn:aws:ec2:*:*:security-group/*"
            Condition = {
            StringEquals = {
                "ec2:CreateAction" = "CreateSecurityGroup"
            }
            Null = {
                "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:CreateTags",
            "ec2:DeleteTags"
            ]
            Resource = "arn:aws:ec2:*:*:security-group/*"
            Condition = {
            Null = {
                "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
                "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup"
            ]
            Resource = "*"
            Condition = {
            Null = {
                "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup"
            ]
            Resource = "*"
            Condition = {
            Null = {
                "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
            ]
            Resource = [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ]
            Condition = {
            Null = {
                "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
                "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
            ]
            Resource = [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DeleteTargetGroup"
            ]
            Resource = "*"
            Condition = {
            Null = {
                "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
            }
            }
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
            ]
            Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            Effect = "Allow"
            Action = [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule"
            ]
            Resource = "*"
        }
        ]
    })
}



# # IAM Role에 alb 정책 연결
resource "aws_iam_role_policy_attachment" "alb_ingress_controller_attach" {
    policy_arn = aws_iam_policy.alb_ingress_controller_policy.arn
    role       = aws_iam_role.alb_controller_role.name
}

#--------------------------------------------------------------------------

# HELM 차트로 ALB Controller 생성
# resource "helm_release" "alb_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"

#   values = [
#     yamlencode({
#       clusterName  = var.eks_cluster_name
#       serviceAccount = {
# 	create = true
#         name = "aws-load-balancer-controller"
#         annotations = {
#           "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
#         }
#       }
#       service = {
#         loadBalancer = {
#           advancedConfig = {
#             loadBalancer = {
#               security_groups = [aws_security_group.alb_sg.id]
#             }
#           }
#         }
#       }
#     })
#   ]
#   depends_on = [ aws_security_group.alb_sg, aws_iam_role.alb_controller_role ]
# }