resource "aws_dynamodb_table" "dynamodb-table" {
  name           = var.m_name
  billing_mode   = var.m_billing_mode
  read_capacity  = var.m_read_capacity
  write_capacity = var.m_write_capacity
  hash_key       = var.m_hash_key

  attribute {
    name = var.m_attribute.name
    type = var.m_attribute.type
  }
}
