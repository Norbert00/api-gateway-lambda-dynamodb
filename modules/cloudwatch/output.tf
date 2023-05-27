output "cloudwatch_name" {
  value = aws_cloudwatch_log_group.log_group.name
}

output "cloudwatch_arn" {
  value = aws_cloudwatch_log_group.log_group.arn
}
