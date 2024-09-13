# us-east-2 리전 프로바이더
provider "aws" {
  region = var.region
}

# us-east-1(ohio) 리전 프로바이더(cloudfront 인증서용)
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
  # depends_on = [ module.eks ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
  # depends_on = [ module.eks ]
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  #config_path = "~/.kube/config"
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
  
}

provider "helm" {
  kubernetes{
    host = data.aws_eks_cluster.cluster.endpoint
    #config_path = "~/.kube/config"
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.cluster.token
  }
  
}

#VPC data
data "aws_vpc" "allcle_vpc" {
  filter {
    name = "tag:Name"
    values = ["ALLCLE-VPC"]
  }
}

# Subnet data
data "aws_subnet" "public_a" {
  filter {
    name = "tag:Name"
    values = ["public-a"]
  }
}

data "aws_subnet" "public_c" {
  filter {
    name = "tag:Name"
    values = ["public-c"]
  }
}

data "aws_subnet" "private_a" {
  filter {
    name = "tag:Name"
    values = ["private-a"]
  }
}

data "aws_subnet" "private_c" {
  filter {
    name = "tag:Name"
    values = ["private-c"]
  }
}

# Bastion 보안 그룹 데이터 불러오기
data "aws_security_group" "bastion_sg" {
  filter {
    name = "tag:Name"
    values = [ "Bastion-SG" ]
  }
}

# ALB 보안 그룹 데이터 불러오기
data "aws_security_group" "alb_sg" {
  filter {
    name = "tag:Name"
    values = [ "ALB-SG" ]
  }
}


# # ALB 보안 그룹
# resource "aws_security_group" "alb_sg" {
#   vpc_id = data.aws_vpc.allcle_vpc.id
#   name   = "ALB-SG"

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ALB-SG"
#   }
# }


# AMI AL2023 데이터 소스
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name = "name"
    values = ["al2023-ami-*"] # Amazon Linux 2023 이름 패턴
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Cloudfront용 ACM 인증서 데이터 소스
data "aws_acm_certificate" "cloudfront" {
  provider = aws.virginia
  domain = "www.allcle.net"
  statuses = ["ISSUED"]
}

# ALB용 ACM 인증서 데이터 소스
data "aws_acm_certificate" "issued" {
  domain = "allcle.net"
  statuses = ["ISSUED"]
}



# EKS Cluster 생성
# module "eks" {
#   source          = "terraform-aws-modules/eks/aws"
#   version         = "~> 20.0"
#   cluster_name    = var.eks_cluster_name
#   cluster_version = "1.30"
#   enable_cluster_creator_admin_permissions = true
#   cluster_endpoint_public_access = true
#   cluster_endpoint_private_access = true

#   cluster_addons = {
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
    
#   }

#   vpc_id     = data.aws_vpc.allcle_vpc.id
#   subnet_ids = [data.aws_subnet.public_a.id, data.aws_subnet.public_c.id, data.aws_subnet.private_a.id, data.aws_subnet.private_c.id]

#   eks_managed_node_groups = {
#     allcle_eks_ng = {
#       name           = var.node_group_name
#       instance_types = [var.instance_type]
#       ami_type       = "AL2023_x86_64_STANDARD"
#       key_name       = var.eks_key_pair

#       min_size     = 2
#       max_size     = 4
#       desired_size = 2

#       # vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]
#       subnet_ids = [data.aws_subnet.private_a.id, data.aws_subnet.private_c.id]
#     }
#   }

#   tags = {
#     Environment = "ALLCLE"
#   }
# }

# EKS 클러스터 보안 그룹에 인바운드 룰 추가
# resource "aws_security_group_rule" "eks_from_bastion" {
#   type = "ingress"
#   from_port = 0
#   to_port = 65535
#   protocol = "tcp"
#   security_group_id = module.eks.cluster_security_group_id
#   source_security_group_id = data.aws_security_group.bastion_sg.id

#   description = "Allow all TCP traffic from Bastion to EKS cluster"
# }

# eks 모듈로 생성된 보안 그룹 데이터 불러오기
# data "aws_security_group" "eks_nodes_sg" {
#   id = module.eks.node_security_group_id
# }

# 자동생성된 노드 보안 그룹에 규칙 추가하기
# resource "aws_security_group_rule" "custom_ingress" {
#   type = "ingress"
#   from_port = 443
#   to_port = 443
#   protocol = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]
#   security_group_id = data.aws_security_group.eks_nodes_sg.id
# }


# EKS ALB Controller IAM Role 생성
# resource "aws_iam_role" "alb_controller_role" {
#   name               = "alb-controller-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = module.eks.oidc_provider_arn
#         }
#       }
#     ]
#   })

#   tags = {
#     Name = "ALBIngressControllerRole"
#   }
# }

# ALB Controller IAM Policy 생성
# resource "aws_iam_policy" "alb_ingress_controller_policy" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   path        = "/"
#   description = "Policy for AWS Load Balancer Controller"
  
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = "iam:CreateServiceLinkedRole"
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeAccountAttributes",
#           "ec2:DescribeAddresses",
#           "ec2:DescribeAvailabilityZones",
#           "ec2:DescribeInternetGateways",
#           "ec2:DescribeVpcs",
#           "ec2:DescribeVpcPeeringConnections",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeInstances",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeTags",
#           "ec2:GetCoipPoolUsage",
#           "ec2:DescribeCoipPools",
#           "elasticloadbalancing:DescribeLoadBalancers",
#           "elasticloadbalancing:DescribeLoadBalancerAttributes",
#           "elasticloadbalancing:DescribeListeners",
#           "elasticloadbalancing:DescribeListenerCertificates",
#           "elasticloadbalancing:DescribeSSLPolicies",
#           "elasticloadbalancing:DescribeRules",
#           "elasticloadbalancing:DescribeTargetGroups",
#           "elasticloadbalancing:DescribeTargetGroupAttributes",
#           "elasticloadbalancing:DescribeTargetHealth",
#           "elasticloadbalancing:DescribeTags"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "cognito-idp:DescribeUserPoolClient",
#           "acm:ListCertificates",
#           "acm:DescribeCertificate",
#           "iam:ListServerCertificates",
#           "iam:GetServerCertificate",
#           "waf-regional:GetWebACL",
#           "waf-regional:GetWebACLForResource",
#           "waf-regional:AssociateWebACL",
#           "waf-regional:DisassociateWebACL",
#           "wafv2:GetWebACL",
#           "wafv2:GetWebACLForResource",
#           "wafv2:AssociateWebACL",
#           "wafv2:DisassociateWebACL",
#           "shield:GetSubscriptionState",
#           "shield:DescribeProtection",
#           "shield:CreateProtection",
#           "shield:DeleteProtection"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateSecurityGroup"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateTags"
#         ]
#         Resource = "arn:aws:ec2:*:*:security-group/*"
#         Condition = {
#           StringEquals = {
#             "ec2:CreateAction" = "CreateSecurityGroup"
#           }
#           Null = {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateTags",
#           "ec2:DeleteTags"
#         ]
#         Resource = "arn:aws:ec2:*:*:security-group/*"
#         Condition = {
#           Null = {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress",
#           "ec2:DeleteSecurityGroup"
#         ]
#         Resource = "*"
#         Condition = {
#           Null = {
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:CreateLoadBalancer",
#           "elasticloadbalancing:CreateTargetGroup"
#         ]
#         Resource = "*"
#         Condition = {
#           Null = {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:CreateListener",
#           "elasticloadbalancing:DeleteListener",
#           "elasticloadbalancing:CreateRule",
#           "elasticloadbalancing:DeleteRule"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#         ]
#         Resource = [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#         ]
#         Condition = {
#           Null = {
#             "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:AddTags",
#           "elasticloadbalancing:RemoveTags"
#         ]
#         Resource = [
#           "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#           "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#           "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:ModifyLoadBalancerAttributes",
#           "elasticloadbalancing:SetIpAddressType",
#           "elasticloadbalancing:SetSecurityGroups",
#           "elasticloadbalancing:SetSubnets",
#           "elasticloadbalancing:DeleteLoadBalancer",
#           "elasticloadbalancing:ModifyTargetGroup",
#           "elasticloadbalancing:ModifyTargetGroupAttributes",
#           "elasticloadbalancing:DeleteTargetGroup"
#         ]
#         Resource = "*"
#         Condition = {
#           Null = {
#             "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
#           }
#         }
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:RegisterTargets",
#           "elasticloadbalancing:DeregisterTargets"
#         ]
#         Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:SetWebAcl",
#           "elasticloadbalancing:ModifyListener",
#           "elasticloadbalancing:AddListenerCertificates",
#           "elasticloadbalancing:RemoveListenerCertificates",
#           "elasticloadbalancing:ModifyRule"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }



# IAM Role에 alb 정책 연결
# resource "aws_iam_role_policy_attachment" "alb_ingress_controller_attach" {
#   policy_arn = aws_iam_policy.alb_ingress_controller_policy.arn
#   role       = aws_iam_role.alb_controller_role.name
# }


# alb controller 역할 데이터 불러오기
data "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"
}


# HELM 차트로 alb controller 배포
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName  = var.eks_cluster_name
      serviceAccount = {
	create = true
        name = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = data.aws_iam_role.alb_controller_role.arn
        }
      }
      service = {
        loadBalancer = {
          advancedConfig = {
            loadBalancer = {
              security_groups = [aws_security_group.alb_sg.id]
            }
          }
        }
      }
    })
  ]
}


resource "kubernetes_ingress_v1" "allcle-ingress" {
  metadata {
    name = var.eks_ingress_name
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/subnets" = "${data.aws_subnet.public_a.id},${data.aws_subnet.public_c.id}"
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = data.aws_acm_certificate.issued.arn
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      host = "www.allcle.net"
      http {
        path {
          path = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "nginx-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [ helm_release.alb_controller ]  
}

# ALB 데이터 가져오기
data "aws_lb" "alb" {
  name = a
}