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



# alb controller 역할 데이터 불러오기
data "aws_iam_role" "alb_controller_role" {
  name = "us-alb-controller-role"
}

data "aws_security_group" "alb_sg" {
  filter {
    name = "tag:Name"
    values = ["ALB-SG"]
  }
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
              security_groups = [data.aws_security_group.alb_sg.id]
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
# data "aws_lb" "alb" {
#   name = a
# }