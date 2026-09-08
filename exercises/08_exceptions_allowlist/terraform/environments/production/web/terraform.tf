# staging の state を掴んだまま移行待ち (exceptions.yaml で期限付きの免除)
terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app-staging-web"
    }
  }
}
