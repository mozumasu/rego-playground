terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app-production-api"
    }
  }
}
