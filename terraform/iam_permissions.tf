# Add necessary permissions to existing shopease_user

# Attach Glue permissions
resource "aws_iam_user_policy_attachment" "shopease_glue" {
  user       = "shopease_user"
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

# Attach Athena permissions
resource "aws_iam_user_policy_attachment" "shopease_athena" {
  user       = "shopease_user"
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

# Custom policy for IAM role creation (needed for Glue)
resource "aws_iam_policy" "shopease_iam_limited" {
  name        = "ShopEaseIAMLimitedAccess"
  description = "Limited IAM permissions for creating Glue service roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PassRole",
          "iam:GetRole",
          "iam:PutRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::*:role/GlueServiceRole",
          "arn:aws:iam::*:role/*glue*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "shopease_iam_limited" {
  user       = "shopease_user"
  policy_arn = aws_iam_policy.shopease_iam_limited.arn
}
