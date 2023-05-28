#*  role 
resource "aws_iam_role" "iam_role" {
  assume_role_policy    = data.aws_iam_policy_document.data_iam.json
  description           = var.m_description
  force_detach_policies = var.m_force_detach_policies
  managed_policy_arns   = var.m_managed_policy_arns
  name                  = var.m_name
  path                  = var.m_path
}



data "aws_iam_policy_document" "data_iam" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    dynamic "principals" {
      for_each = var.m_principals
      content {
        type        = principals.value.type
        identifiers = principals.value.identifiers
      }
    }
  }
}
