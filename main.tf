
terraform {
  backend "s3" {
    bucket = "tf-remote-state-v02"
    key    = "remote-state/terraform.tfstate"
    region = "eu-central-1"
  }
}


data "aws_caller_identity" "account_id" {}
data "aws_region" "current" {}

#*  dynamodb table
module "dynamodb" {
  source           = "./modules/dynamodb"
  m_name           = "books"
  m_billing_mode   = "PROVISIONED"
  m_read_capacity  = 1
  m_write_capacity = 1
  m_hash_key       = "bookid"
  m_attribute = {
    name = "bookid"
    type = "S"
  }
}


#*  api gateway
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

resource "aws_api_gateway_resource" "book_path" {
  rest_api_id = aws_api_gateway_rest_api.books_api.id
  parent_id   = aws_api_gateway_resource.books_path.id
  path_part   = "book"
}






locals {
  http_methods_books = {
    "GET" = "GET"
  }
  http_methods_book = {
    "GET"    = "GET"
    "POST"   = "POST"
    "PUT"    = "PUT"
    "DELETE" = "DELETE"
  }

  principals = {
    "lambda" = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


resource "aws_api_gateway_method" "api_mehtods_books" {
  for_each         = local.http_methods_books
  api_key_required = false
  authorization    = "NONE"
  http_method      = each.key
  resource_id      = aws_api_gateway_resource.books_path.id
  rest_api_id      = aws_api_gateway_rest_api.books_api.id
}

resource "aws_api_gateway_method" "api_mehtods_book" {
  for_each         = local.http_methods_book
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


#* policy and policy attachment
module "iam_policy" {
  source       = "./modules/iam/policy"
  m_name       = "dynamodb_crud"
  m_path       = "/"
  m_policy_arn = module.iam_policy.policy_arn
  m_role       = module.iam_role.iam_role_name
}


#* role
module "iam_role" {
  source                  = "./modules/iam/role"
  m_principals            = local.principals
  m_description           = "Allows Lambda functions to call AWS services on your behalf."
  m_force_detach_policies = false
  m_managed_policy_arns   = ["${module.iam_policy.policy_arn}"]
  m_name                  = "api-dynamodb"
  m_path                  = "/"
}


#*  lambda
resource "aws_lambda_function" "lambda" {
  function_name = "tf-lambda_api_gateway_dynamodb"
  handler       = "api-lambda.lambda_handler"
  memory_size   = 128
  role          = "arn:aws:iam::${data.aws_caller_identity.account_id.id}:role/${module.iam_role.iam_role_name}"
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


resource "aws_lambda_permission" "allow_api_gateway_books" {
  for_each      = local.http_methods_books
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.books_api.execution_arn}/*/${aws_api_gateway_method.api_mehtods_books[each.key].http_method_books}/books"
}

resource "aws_lambda_permission" "allow_api_gateway_book" {
  for_each      = local.http_methods_book
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.books_api.execution_arn}/*/${aws_api_gateway_method.api_mehtods_book[each.key].http_method_book}/book"
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = "${module.cloudwatch_logs.cloudwatch_arn}:*"
}

