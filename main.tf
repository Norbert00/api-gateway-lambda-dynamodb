
terraform {
  backend "s3" {
    bucket = "tf-remote-state-v02"
    key    = "remote-state/terraform.tfstate"
    region = "eu-central-1"
  }
}


#*  dynamodb table
resource "aws_dynamodb_table" "books-dynamodb-table" {
  name           = "Books"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "BookId"

  attribute {
    name = "BookId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name        = "dynamodb-table-books"
    Environment = "production"
  }
}

#* 
