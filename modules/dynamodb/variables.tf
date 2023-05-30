variable "m_name" {
  type    = string
  default = "books"
}

variable "m_billing_mode" {
  type    = string
  default = "PROVISIONED"
}

variable "m_read_capacity" {
  type    = number
  default = 1
}

variable "m_write_capacity" {
  type    = number
  default = 1
}

variable "m_hash_key" {
  type    = string
  default = "bookid"
}

variable "m_attribute" {
  type = object({
    name = string
    type = string
  })
  default = {
    name = "bookid"
    type = "S"
  }
}
