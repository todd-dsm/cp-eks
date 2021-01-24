# Admin Policy
path "*" {
  capabilities = ["list", "read", "update", "create", "delete", "sudo"]
}