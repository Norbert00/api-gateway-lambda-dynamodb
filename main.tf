
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
  #arn                   = "arn:aws:apigateway:eu-central-1::/restapis/ixgf79heae/stages/dev"    know after deployment
  cache_cluster_enabled = false
  deployment_id         = "zefn9o"
  #execution_arn         = "arn:aws:execute-api:eu-central-1:109028672636:ixgf79heae/dev" know after deployment
  #id                    = "ags-ixgf79heae-dev" know after deployment
  #invoke_url            = "https://ixgf79heae.execute-api.eu-central-1.amazonaws.com/dev" know after deployment
  rest_api_id          = "ixgf79heae"
  stage_name           = "dev"
  xray_tracing_enabled = false
}

resource "aws_api_gateway_method" "api_method" {
  api_key_required = false
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = "ymmokh"
  rest_api_id      = "ixgf79heae"
}


#* policy 
resource "aws_iam_policy" "lambda_policy" {
  name = "dynamodb_crud"
  path = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "dynamodb:BatchGetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:GetItem",
            "dynamodb:Scan",
            "dynamodb:Query",
            "dynamodb:UpdateItem",
          ]
          Effect   = "Allow"
          Resource = "arn:aws:dynamodb:eu-central-1:109028672636:table/books"
          Sid      = "VisualEditor0"
        },
        {
          Action = [
            "dynamodb:ListGlobalTables",
            "dynamodb:ListTables",
          ]
          Effect   = "Allow"
          Resource = "*"
          Sid      = "VisualEditor1"
        },
      ]
      Version = "2012-10-17"
    }
  )
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
  name = "api-dynamodby"
  path = "/"


}


#* lambda
# resource "aws_lambda_function" "api-lambda" {
#   #   architectures                  = [
#   #     "x86_64",
#   # ]
#   # arn                            = "arn:aws:lambda:eu-central-1:109028672636:function:api-lambda"
#   function_name = "api-lambda"
#   handler       = "lambda_function.lambda_handler"
#   #id                             = "api-lambda"
#   # invoke_arn                     = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:109028672636:function:api-lambda/invocations"
#   #last_modified                  = "2023-04-26T15:31:04.000+0000"
#   #layers                         = []
#   #memory_size                    = 128
#   package_type = "Zip"
#   #qualified_arn                  = "arn:aws:lambda:eu-central-1:109028672636:function:api-lambda:$LATEST"
#   #qualified_invoke_arn           = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:109028672636:function:api-lambda:$LATEST/invocations"
#   #reserved_concurrent_executions = -1
#   role    = "arn:aws:iam::109028672636:role/api-dynamodby"
#   runtime = "python3.9"
#   # skip_destroy                   = false
#   # source_code_hash               = "1+WDoEvg2pSKt/mCAv7i1XVBX57/GZvQpyI9JoxDBqc="
#   # source_code_size               = 283
#   # tags                           = {}
#   # tags_all                       = {}
#   # timeout                        = 3
#   # version                        = "$LATEST"

#   # ephemeral_storage {
#   #     size = 512
#   # }

#   # tracing_config {
#   #     mode = "PassThrough"
#   # }
# }
#* lambda trigger
# resource "aws_lambda_permission" "lambda_permission" {
#   action        = "lambda:InvokeFunction"
#   function_name = "api-lambda"
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.books_api.execution_arn}/*"
# }



# data "aws_iam_policy_document" "lambda_policy" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:DescribeContributorInsights",
#       "dynamodb:RestoreTableToPointInTime",
#       "dynamodb:UpdateGlobalTable",
#       "dynamodb:DeleteTable",
#       "dynamodb:UpdateTableReplicaAutoScaling",
#       "dynamodb:DescribeTable",
#       "dynamodb:PartiQLInsert",
#       "dynamodb:GetItem",
#       "dynamodb:DescribeContinuousBackups",
#       "dynamodb:DescribeExport",
#       "dynamodb:ListImports",
#       "dynamodb:EnableKinesisStreamingDestination",
#       "dynamodb:BatchGetItem",
#       "dynamodb:DisableKinesisStreamingDestination",
#       "dynamodb:UpdateTimeToLive",
#       "dynamodb:BatchWriteItem",
#       "dynamodb:PutItem",
#       "dynamodb:PartiQLUpdate",
#       "dynamodb:Scan",
#       "dynamodb:StartAwsBackupJob",
#       "dynamodb:UpdateItem",
#       "dynamodb:UpdateGlobalTableSettings",
#       "dynamodb:CreateTable",
#       "dynamodb:RestoreTableFromAwsBackup",
#       "dynamodb:GetShardIterator",
#       "dynamodb:DescribeReservedCapacity",
#       "dynamodb:ExportTableToPointInTime",
#       "dynamodb:DescribeEndpoints",
#       "dynamodb:DescribeBackup",
#       "dynamodb:UpdateTable",
#       "dynamodb:GetRecords",
#       "dynamodb:DescribeTableReplicaAutoScaling",
#       "dynamodb:DescribeImport",
#       "dynamodb:ListTables",
#       "dynamodb:DeleteItem",
#       "dynamodb:PurchaseReservedCapacityOfferings",
#       "dynamodb:CreateTableReplica",
#       "dynamodb:ListTagsOfResource",
#       "dynamodb:UpdateContributorInsights",
#       "dynamodb:CreateBackup",
#       "dynamodb:UpdateContinuousBackups",
#       "dynamodb:DescribeReservedCapacityOfferings",
#       "dynamodb:PartiQLSelect",
#       "dynamodb:UpdateGlobalTableVersion",
#       "dynamodb:CreateGlobalTable",
#       "dynamodb:DescribeKinesisStreamingDestination",
#       "dynamodb:DescribeLimitsresource "aws_lambda_function" "api-lambda" {
#   #   architectures                  = [
#   #     "x86_64",
#   # ]
#   # arn                            = "arn:aws:lambda:eu-central-1:109028672636:function:api-lambda"
#   function_name = "api-lambda"
#   handler       = "lambda_function.lambda_handler"
#   #id                             = "api-lambda"
#   # invoke_arn                     = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:109028672636:function:api-lambda/invocations"
#   #last_modified                  = "2023-04-26T15:31:04.000+0000"
#   #layers                         = []
#   #memory_size                    = 128
#   package_type = "Zip"
#   #qualified_arn                  = "arn:aws:lambda:eu-central-1:109028672636:function:api-lambda:$LATEST"
#   #qualified_invoke_arn           = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:109028672636:function:api-lambda:$LATEST/invocations"
#   #reserved_concurrent_executions = -1
#   role    = "arn:aws:iam::109028672636:role/api-dynamodby"
#   runtime = "python3.9"
#   # skip_destroy                   = false
#   # source_code_hash               = "1+WDoEvg2pSKt/mCAv7i1XVBX57/GZvQpyI9JoxDBqc="
#   # source_code_size               = 283
#   # tags                           = {}
#   # tags_all                       = {}
#   # timeout                        = 3
#   # version                        = "$LATEST"

#   # ephemeral_storage {
#   #     size = 512
#   # }

#   # tracing_config {
#   #     mode = "PassThrough"
#   # }Item",
#       "dynamodb:ListBackups",
#       "dynamodb:Query",
#       "dynamodb:DescribeStream",
#       "dynamodb:DeleteTableReplica",
#       "dynamodb:DescribeTimeToLive",
#       "dynamodb:ListStreams",
#       "dynamodb:ListContributorInsights",
#       "dynamodb:DescribeGlobalTableSettings",
#       "dynamodb:ListGlobalTables",
#       "dynamodb:DescribeGlobalTable",
#       "dynamodb:RestoreTableFromBackup",
#       "dynamodb:DeleteBackup",
#       "dynamodb:PartiQLDelete"
#     ]
#     resources = ["arn:aws:apigateway:eu-central-1::/restapis/ixgf79heae/stages/dev"]
#   }
# }


# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }


# resource "aws_iam_role" "api" {
#   name               = "api-dynamodby"
#   path               = "/"
#   assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
# }
