terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app_production_api"
    }
  }
}
