resource "random_string" "this" {
  length            = 8
  upper             = false
  special           = false
  numeric           = false
}

resource "random_password" "password" {
  length            = 16
  special           = true
  override_special  = "!#$%&*()-_=+[]{}<>:?"
}