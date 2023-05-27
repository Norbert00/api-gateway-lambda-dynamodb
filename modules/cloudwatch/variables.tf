variable "m_name" {
  type = string
}

variable "m_retention_in_days" {
  type = number
  validation {
    condition = contains([0,
      1,
      3,
      5,
      7,
      14,
      30,
      60,
      90,
      120,
      150,
      180,
      365,
      400,
      545,
      731,
      1096,
      1827,
      2192,
      2557,
      2922,
      3288,
    3653], var.m_retention_in_days)
    error_message = "Expected retention in days to be one of [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653]"

  }
}
