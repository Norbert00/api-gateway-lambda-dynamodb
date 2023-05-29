#*  policy 
data "aws_caller_identity" "account_id" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid = "VisualEditor0"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
    ]

    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.account_id.id}:table/books"
    ]
  }

  statement {
    actions = [
      "dynamodb:ListGlobalTables",
      "dynamodb:ListTables",
    ]
    resources = ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.account_id.id}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.account_id.id}:log-group:/aws/lambda/tf-lambda_api_gateway_dynamodb:*"]
  }
}

resource "aws_iam_policy" "policy" {
  name   = var.m_name
  path   = var.m_path
  policy = data.aws_iam_policy_document.policy_document.json
}


resource "aws_iam_role_policy_attachment" "policy_attach" {
  policy_arn = var.m_policy_arn
  role       = var.m_role
  depends_on = [aws_iam_policy.policy]
}
