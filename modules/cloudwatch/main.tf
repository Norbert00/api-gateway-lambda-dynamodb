#* cloudwatch
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/tf-lambda_api_gateway_dynamodb"
  retention_in_days = 14
}