# 命名規約制定前の workspace。`_` 区切りのまま運用中 (exceptions.yaml で免除)
terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "app_staging_legacy"
    }
  }
}
