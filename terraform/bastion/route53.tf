# Route 53 호스팅 존 데이터 소스
data "aws_route53_zone" "allcle_zone" {
    name = "allcle.net." # 호스팅 영역 이름 (마침표 포함)
}

# www.allcle.net과 www.pre.allcle.net의 레코드 리소스를 import하기
# resource "null_resource" "terraform_import" {
#     provisioner "local-exec" {
#         command = <<EOT
#             terraform import aws_route53_record.www_allcle ${data.aws_route53_zone.allcle_zone.zone_id}_www.allcle.net_A
#             terraform import aws_route53_record.pre_allcle ${data.aws_route53_zone.allcle_zone.zone_id}_www.pre.allcle.net_A
#         EOT
#     }
#     depends_on = [ aws_route53_record.www_allcle, aws_route53_record.pre_allcle ]
# }

resource "aws_route53_health_check" "seoul_health_check" {
    fqdn              = "www.allcle.net"  # 서울 리전 ALB의 FQDN
    type              = "HTTPS"
    port              = 443
    resource_path     = "/*"
    request_interval  = 30
    failure_threshold = 2
}

resource "aws_route53_health_check" "seoul_health_check_pre" {
    fqdn              = "www.pre.allcle.net"  # 서울 리전 ALB의 FQDN
    type              = "HTTPS"
    port              = 443
    resource_path     = "/*"
    request_interval  = 30
    failure_threshold = 2
}


# www.allcle.net 레코드에 오하이오 리전 ALB를 장애 조치 Secondary로 추가하기
resource "aws_route53_record" "www_allcle_failover" {
  zone_id = data.aws_route53_zone.allcle_zone.zone_id  # 서울 리전 Route 53 호스팅 존 ID
  name     = "www.allcle.net"
  type     = "A"

  alias {
    name                   = data.aws_lb.allcle_alb_ohio.dns_name  # 오하이오 리전 ALB의 DNS 이름 (미리 설정)
    zone_id                = data.aws_lb.allcle_alb_ohio.zone_id   # 오하이오 리전 ALB의 호스팅 존 ID (미리 설정)
    evaluate_target_health = false  # 대체 레코드의 경우 비활성화
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "allcle_net_failover"
}

#---------------------------------------------------------------------------------------------------------


# www.pre.allcle.net 레코드에 오하이오 리전 ALB를 장애 조치 Secondary로 추가하기
resource "aws_route53_record" "pre_allcle_failover" {
  zone_id = data.aws_route53_zone.allcle_zone.zone_id  # 서울 리전 Route 53 호스팅 존 ID
  name     = "www.pre.allcle.net"
  type     = "A"

  alias {
    name                   = data.aws_lb.allcle_alb_ohio.dns_name  # 오하이오 리전 ALB의 DNS 이름 (미리 설정)
    zone_id                = data.aws_lb.allcle_alb_ohio.zone_id   # 오하이오 리전 ALB의 호스팅 존 ID (미리 설정)
    evaluate_target_health = false  # 대체 레코드의 경우 비활성화
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "pre_allcle_net_failover"

  depends_on = [ data.aws_lb.allcle_alb_ohio ]
}

# 생성되어있는 k8s ingress 데이터 가져오기
data "kubernetes_ingress_v1" "allcle_ingress" {
  metadata {
    name = "allcle-ingress"
    namespace = "default"
  }
  depends_on = [ kubernetes_ingress_v1.allcle_ingress ]
}

locals {
  alb_dns_name = data.kubernetes_ingress_v1.allcle_ingress.status[0].load_balancer[0].ingress[0].hostname

  # ALB DNS 이름을 '.'으로 분리하여 마지막 부분을 제거합니다.
  base_dns_parts = split(".", local.alb_dns_name)
  base_dns_name = local.base_dns_parts[0]

  # 최종 ALB 이름을 정의합니다.
  alb_name_parts = split("-", local.base_dns_name)
  ohio_alb_name = join("-", slice(local.alb_name_parts, 0, 4))
  
}

# 생성되어있는 Ohio Region ALB 데이터 가져오기
data "aws_lb" "allcle_alb_ohio" {
  name = local.ohio_alb_name
  depends_on = [ data.kubernetes_ingress_v1.allcle_ingress ]
}

output "ohio_alb_zone_id" {
  value = data.aws_lb.allcle_alb_ohio.zone_id
}

