
terraform {
  backend "s3" {
    bucket = "tf-remote-state-v02"
    key    = "remote-state/terraform.tfstate"
    region = "eu-central-1"
  }
}


#*  dynamodb table
resource "aws_dynamodb_table" "dynamodb-table" {
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

#*  api gateway
resource "aws_api_gateway_rest_api" "books_api" {
  api_key_source = "HEADER"

  disable_execute_api_endpoint = false
  minimum_compression_size     = -1
  name                         = "books-api"
  put_rest_api_mode            = "overwrite"

  lifecycle {
    create_before_destroy = true
  }


  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }
}


resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.books_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.books_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "api_stage" {
  cache_cluster_enabled = false
  deployment_id         = "zefn9o"
  rest_api_id           = "ixgf79heae"
  stage_name            = "dev"
  xray_tracing_enabled  = false
}

resource "aws_api_gateway_method" "api_method" {
  api_key_required = false
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = "ymmokh"
  rest_api_id      = "ixgf79heae"
}


#* policy 
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
      "arn:aws:dynamodb:eu-central-1:109028672636:table/books"
    ]
  }

  statement {
    actions = [
      "dynamodb:ListGlobalTables",
      "dynamodb:ListTables",
    ]
    resources = ["arn:aws:dynamodb:eu-central-1:109028672636:*"]
  }
}



resource "aws_iam_policy" "lambda_policy" {
  name   = "dynamodb_crud"
  path   = "/"
  policy = data.aws_iam_policy_document.policy.json
}

#* policy attachment
resource "aws_iam_role_policy_attachment" "policy_attach" {
  policy_arn = "arn:aws:iam::109028672636:policy/dynamodb_crud"
  role       = "api-dynamodb"
}

#* role 
resource "aws_iam_role" "tf_iam_role" {
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
  managed_policy_arns = [
    "arn:aws:iam::109028672636:policy/dynamodb_crud",
  ]
  name = "api-dynamodb"
  path = "/"
}


#* lambda
resource "aws_lambda_function" "lambda" {
  function_name = "api-lambda"
  handler       = "lambda_function.lambda_handler"
  memory_size = 128
  role     = "arn:aws:iam::109028672636:role/api-dynamodby"
  runtime  = "python3.9"
  filename = data.archive_file.lambda.output_path
  
  lifecycle {
    ignore_changes = [filename, ]
  }

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "api-lambda.py"
  output_path = "./outputs/api-lambda.zip"
}


resource "aws_lambda_permission" "allow_api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = "arn:aws:lambda:eu-central-1:109028672636:function:api-lambda"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:eu-central-1:109028672636:ixgf79heae/*/GET/books"
}

