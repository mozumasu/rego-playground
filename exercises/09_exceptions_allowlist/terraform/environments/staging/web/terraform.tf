terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app-staging-web"
    }
  }
}
