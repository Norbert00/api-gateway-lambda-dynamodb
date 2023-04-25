resource "aws_dynamodb_table_item" "item1" {
  table_name = aws_dynamodb_table.books-dynamodb-table.name
  hash_key   = aws_dynamodb_table.books-dynamodb-table.hash_key

  item = <<ITEM
{
  "BookId": {"S": "001"},
  "BookName": {"S": "Boso ale w ostrogach"},
  "BookPrice": {"N": "50"},
  "BookCurrency": {"S": "PLN"}
}
ITEM
}
