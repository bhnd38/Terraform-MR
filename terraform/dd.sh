aws configure

# tfenv로 Terraform 설치
sudo yum install -y git
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
tfenv install <Version>
tfenv use <installed_version>
tfenv list

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml



# eksctl 설치

curl -s --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
aws eks update-kubeconfig --region ap-northeast-2 --name allcle-eks-cluster


# aws cli 최신 버전 설치 방법
sudo yum remove awscli -y
sudo yum install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
alias aws=/usr/local/bin/aws
aws eks update-kubeconfig --region ap-northeast-2 --name allcle-eks-cluster

# 클러스터 통신 상태 확인
# aws eks describe-cluster --name allcle-eks-cluster --query "cluster.resourcesVpcConfig"

# 클러스터에 적용된 보안 그룹에서 트래픽 허용

# aws-auth ConfigMap에 mapUsers 추가
kubectl edit configmap aws-auth -n kube-system

# apiVersion: v1
# data:
#   mapRoles: |
#     - groups:
#       - system:bootstrappers
#       - system:nodes
#       rolearn: arn:aws:iam::590183736410:role/allcle-eks-ng-eks-node-group-20240829030016161200000006
#       username: system:node:{{EC2PrivateDNSName}}
#   mapUsers: |
#     - userarn: arn:aws:iam::590183736410:user/reca6_7
#       username: reca6_7
#       groups:
#         - system:masters
#     - userarn: arn:aws:iam::590183736410:user/reca6_8
#       username: reca6_8
#       groups:
#         - system:masters
#     - userarn: arn:aws:iam::590183736410:user/reca6_9
#       username: reca6_9
#       groups:
#         - system:masters
# kind: ConfigMap
# metadata:
#   creationTimestamp: "2024-08-29T03:09:38Z"
#   name: aws-auth
#   namespace: kube-system
#   resourceVersion: "1039"
#   uid: 9d6e1d6d-c639-42eb-b1c1-c19e5c0d8857


allcle-service 생성
테스트용 nginx pod 띄울 deployment 생성

트래픽 라우팅 순서
ALB -> Ingress -> Service -> Pod
