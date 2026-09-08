# staging からコピーして workspace 名を直し忘れた例 (production の plan が staging の state を掴む)
terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app-staging-web"
    }
  }
}
