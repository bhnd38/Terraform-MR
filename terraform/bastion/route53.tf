provider "aws" {
    region = "us-east-2"
}

provider "aws" {
    alias = "Seoul"
    region = "ap-northeast-2"  # 서울 리전
}

# Route 53 호스팅 존 데이터 소스
data "aws_route53_zone" "allcle_zone" {
    name = "allcle.net." # 호스팅 영역 이름 (마침표 포함)
}

resource "aws_route53_health_check" "seoul_health_check" {
    fqdn              = "www.allcle.net"  # 서울 리전 ALB의 FQDN
    type              = "HTTPS"
    resource_path     = "/*"
    request_interval  = 30
    failure_threshold = 2
}

data "aws_route53_record" "www_allcle" {
    zone_id = data.aws_route53_zone.allcle_zone.zone_id
    name = "www.allcle.net"
    type = "A"
}

# 생성되어있는 ALB 값 가져오기
data "aws_lb" "allcle_alb" {
    dns_name = local.ohio_alb_dns_name
}

resource "aws_route53_record" "www_allcle_updated" {
    zone_id = data.aws_route53_zone.allcle_zone.zone_id  # 서울 리전 Route 53 호스팅 존 ID
    name     = data.aws_route53_record.www_allcle.name
    type     = "A"

    alias {
        name                   = var.seoul_alb_dns  # 서울 리전 ALB의 DNS 이름
        zone_id                = var.seoul_alb_host_zone_id   # 서울 리전 ALB의 호스팅 존 ID
        evaluate_target_health = true
    }

    failover_routing_policy {
        type = "PRIMARY"
    }

    set_identifier = "allcle_net_primary"
    health_check_id = "${aws_route53_health_check.seoul_health_check.id}"

    lifecycle {
      create_before_destroy = false
    }
}

resource "aws_route53_record" "www_allcle_failover" {
  zone_id = data.aws_route53_zone.allcle_zone  # 서울 리전 Route 53 호스팅 존 ID
  name     = "www.allcle.net"
  type     = "A"

  alias {
    name                   = local.ohio_alb_dns_name  # 오하이오 리전 ALB의 DNS 이름 (미리 설정)
    zone_id                = data.aws_lb.allcle_alb.zone_id   # 오하이오 리전 ALB의 호스팅 존 ID (미리 설정)
    evaluate_target_health = false  # 대체 레코드의 경우 비활성화
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "allcle_net_failover"
}