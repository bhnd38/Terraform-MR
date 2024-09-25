data "aws_ecr_repository" "nginx_k8s" {
    name = "nginx-k8s"
}

data "aws_ecr_repository" "flask_k8s" {
    name = "flask-k8s"
}

data "aws_ecr_repository" "pre_nginx" {
    name = "pre-nginx"
}

data "aws_ecr_repository" "pre_flask" {
    name = "pre-flask"
}

data "aws_ecr_repository" "home_nginx" {
    name = "home-nginx"
}

data "aws_ecr_repository" "home_flask" {
    name = "home-flask"
}

# argocd 네임스페이스 생성
resource "kubernetes_namespace" "argocd" {
    metadata {
        name = "argocd"
    }
    depends_on = [ helm_release.alb_controller ]
}

# argocd 설치
resource "helm_release" "argocd" {
    name = "argocd"
    repository = "https://argoproj.github.io/argo-helm"
    chart = "argo-cd"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    version = "2.12.3"

    values = [
        file("${var.allcle_eks_us_repo}/values.yaml")
    ]
    # depends_on = [ kubernetes_namespace.argocd ]
}

# argocd 서비스 타입을 LoadBalancer로 변경
resource "kubernetes_service" "argocd_server" {
    metadata {
        name = "argocd-server"
        namespace = kubernetes_namespace.argocd.metadata[0].name
    }

    spec {
        type = "LoadBalancer"

        selector = {
            "app.kubernetes.io/name" = "argocd-server"
        }

        port {
            port = 80
            target_port = 8080
        }

        port {
            port = 443
            target_port = 8080
        }
    }
}

# argocd 초기 admin 비밀번호 출력
resource "null_resource" "get_argocd_admin_password" {
    provisioner "local-exec" {
        command = <<EOT
            kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        EOT
    }
}


# helm 설치 스크립트 다운로드 및 실행
resource "null_resource" "install_helm" {
    provisioner "local-exec" {
        command = <<EOT
            curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
            chmod 700 get_helm.sh
            ./get_helm.sh
        EOT
    }
}

# helm 차트 생성
resource "null_resource" "crate_helm_chart" {
    provisioner "local-exec" {
        command = "helm create allcle-helm"
    }
}

resource "kubernetes_manifest" "argocd_app_sync_allcle" {
    manifest = {
        apiVersion = "argoproj.io/v1alpha1"
        kind = "Application"
        metadata = {
            name = "allcle-sync"
            namespace = kubernetes_namespace.argocd.metadata[0].name
        }
        spec = {
            project = "default"
            source = {
                repoURL = "https://github.com/flaskgosu/allcle-eks-us.git"
                path = "."
                targetRevision = "HEAD"
            }
            destination = {
                server = "https://kubernetes.default.svc"
                namespace = "default"
            }
            syncPolicy = {
                automated = {
                    prune = true # 불필요 리소스 자동 제거
                    selfHeal = true # 클러스터와 Git 상태 자동 동기화
                }
            }
        }
    }
}

# resource "kubernetes_manifest" "argocd_app_sync_allcle_pre" {
#     manifest = {
#         apiVersion = "argoproj.io/v1alpha1"
#         kind = "Application"
#         metadata = {
#             name = "allcle-pre-sync"
#             namespace = kubernetes_namespace.argocd.metadata[0].name
#         }
#         spec = {
#             project = "default"
#             source = {
#                 repoURL = "https://github.com/flaskgosu/allcle-eks-pre-us.git"
#                 path = "."
#                 targetRevision = "HEAD"
#             }
#             destination = {
#                 server = "https://kubernetes.default.svc"
#                 namespace = "default"
#             }
#             syncPolicy = {
#                 automated = {
#                     prune = true # 불필요 리소스 자동 제거
#                     selfHeal = true # 클러스터와 Git 상태 자동 동기화
#                 }
#             }
#         }
#     }
# }