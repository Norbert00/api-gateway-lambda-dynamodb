variable "m_principals" {
  type = map(object({
    identifiers = set(string)
    type        = string
  }))
}

variable "m_description" {
  type = string
}

variable "m_force_detach_policies" {
  type = bool
}

variable "m_managed_policy_arns" {
  type = list(string)
}

variable "m_name" {
  type    = string
  default = "api-dynamodb"
}

variable "m_path" {
  type    = string
  default = "/"
  validation {
    condition     = startswith(var.m_path, "/")
    error_message = "Path must starts with /"
  }
}
