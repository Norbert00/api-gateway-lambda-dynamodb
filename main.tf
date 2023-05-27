
terraform {
  backend "s3" {
    bucket = "tf-remote-state-v02"
    key    = "remote-state/terraform.tfstate"
    region = "eu-central-1"
  }
}


#*  dynamodb table
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "books"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "bookid"

  attribute {
    name = "bookid"
    type = "S"
  }
}

# #*  api gateway
resource "aws_api_gateway_rest_api" "books_api" {
  api_key_source = "HEADER"

  disable_execute_api_endpoint = false
  minimum_compression_size     = -1
  name                         = "books-api"
  put_rest_api_mode            = "overwrite"

  lifecycle {
    create_before_destroy = false
  }


  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}

resource "aws_api_gateway_resource" "books_path" {
  rest_api_id = aws_api_gateway_rest_api.books_api.id
  parent_id   = aws_api_gateway_rest_api.books_api.root_resource_id
  path_part   = "books"
}


locals {
  http_methods = {
    "GET"    = "GET"
    "POST"   = "POST"
    "PUT"    = "PUT"
    "DELETE" = "DELETE"
  }
}


resource "aws_api_gateway_method" "api_mehtods" {
  for_each         = local.http_methods
  api_key_required = false
  authorization    = "NONE"
  http_method      = each.key
  resource_id      = aws_api_gateway_resource.books_path.id
  rest_api_id      = aws_api_gateway_rest_api.books_api.id
}

resource "aws_api_gateway_integration" "integration" {
  for_each                = local.http_methods
  rest_api_id             = aws_api_gateway_rest_api.books_api.id
  resource_id             = aws_api_gateway_resource.books_path.id
  http_method             = aws_api_gateway_method.api_mehtods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}


resource "aws_api_gateway_stage" "api_stage" {
  cache_cluster_enabled = false
  deployment_id         = aws_api_gateway_deployment.api_deployment.id
  rest_api_id           = aws_api_gateway_rest_api.books_api.id
  stage_name            = "dev"
  xray_tracing_enabled  = false

  depends_on = [aws_api_gateway_deployment.api_deployment]

}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.books_api.id

  depends_on = [aws_api_gateway_method.api_mehtods, aws_api_gateway_integration.integration]

  lifecycle {
    create_before_destroy = false
  }
}

#* cloudwatch
module "cloudwatch_logs" {
  source              = "./modules/cloudwatch"
  m_name              = "/aws/lambda/tf-lambda_api_gateway_dynamodb"
  m_retention_in_days = 14
}


#*  policy 
data "aws_caller_identity" "account_id" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "policy" {
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
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.account_id.id}:log-group:${module.cloudwatch_logs.cloudwatch_name}:*"]
  }
}



resource "aws_iam_policy" "lambda_policy" {
  name   = "dynamodb_crud"
  path   = "/"
  policy = data.aws_iam_policy_document.policy.json
}

#*  policy attachment
resource "aws_iam_role_policy_attachment" "policy_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.iam_role.name

  depends_on = [aws_iam_role.iam_role, aws_iam_policy.lambda_policy]
}

#*  role 
resource "aws_iam_role" "iam_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Allows Lambda functions to call AWS services on your behalf."
  force_detach_policies = false
  managed_policy_arns   = ["${aws_iam_policy.lambda_policy.arn}"]
  name                  = "api-dynamodb"
  path                  = "/"
}


#*  lambda
resource "aws_lambda_function" "lambda" {
  function_name = "tf-lambda_api_gateway_dynamodb"
  handler       = "api-lambda.lambda_handler"
  memory_size   = 128
  role          = "arn:aws:iam::${data.aws_caller_identity.account_id.id}:role/api-dynamodb"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda.output_path
  publish       = true

  lifecycle {
    ignore_changes = [filename, ]
  }

  source_code_hash = data.archive_file.lambda.output_base64sha256
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "api-lambda.py"
  output_path = "./outputs/api-lambda.zip"
}


resource "aws_lambda_permission" "allow_api_gateway" {
  for_each      = local.http_methods
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.books_api.execution_arn}/*/${aws_api_gateway_method.api_mehtods[each.key].http_method}/books"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = "${module.cloudwatch_logs.cloudwatch_arn}:*"
}

