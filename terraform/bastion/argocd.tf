data "kubernetes_service" "argocd_server" {
    metadata {
        name = "argocd-server"
        namespace = "argocd"
    }
}

# argocd 초기 admin 비밀번호 출력
resource "null_resource" "login_argocd_server" {
    provisioner "local-exec" {
        command = <<EOT
            ARGOCD_SERVER=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
            ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
            argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure
        EOT
    }
    depends_on = [ data.kubernetes_service.argocd_server ]
}


# argocd의 allcle-eks-us 애플리케이션과 연동
resource "kubernetes_manifest" "argocd_app_sync_allcle" {
    manifest = {
        apiVersion = "argoproj.io/v1alpha1"
        kind = "Application"
        metadata = {
            name = "allcle-sync"
            namespace = data.kubernetes_service.argocd_server.metadata[0].namespace
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
    depends_on = [ null_resource.login_argocd_server ]
}


# argocd의 allcle-eks-pre-us 애플리케이션과 연동
resource "kubernetes_manifest" "argocd_app_sync_allcle_pre" {
    manifest = {
        apiVersion = "argoproj.io/v1alpha1"
        kind = "Application"
        metadata = {
            name = "allcle-pre-sync"
            namespace = data.kubernetes_service.argocd_server.metadata[0].namespace
        }
        spec = {
            project = "default"
            source = {
                repoURL = "https://github.com/flaskgosu/allcle-eks-pre-us.git"
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
    depends_on = [ null_resource.login_argocd_server ]
}