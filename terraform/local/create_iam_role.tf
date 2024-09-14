#EKS ALB Controller IAM Role 생성
resource "aws_iam_role" "alb_controller_role" {
    name               = "alb-controller-role"
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

    tags = {
        Name = "ALBIngressControllerRoleUS"
    }
}
