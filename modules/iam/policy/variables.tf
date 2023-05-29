variable "m_name" {
  type = string
}

variable "m_path" {
  type    = string
  default = "/"
  validation {
    condition     = startswith(var.m_path, "/")
    error_message = "Path must starts /"
  }
}

variable "m_policy_arn" {
  type = string
  validation {
    condition     = startswith(var.m_policy_arn, "arn")
    error_message = "Policy arn must start with the word arn"
  }
}

variable "m_role" {
  type = string
}
