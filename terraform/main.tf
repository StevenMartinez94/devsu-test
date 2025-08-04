terraform {
  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = ">= 0.1.32"
    }
  }
}

provider "contabo" {
  oauth2_client_id     = var.oauth2_client_id
  oauth2_client_secret = var.oauth2_client_secret
  oauth2_user          = var.oauth2_user
  oauth2_pass          = var.oauth2_pass
}

# Create instances for Kubernetes nodes
resource "contabo_instance" "k8s_vps" {
  count = 3

  display_name = "k8s_vps-${count.index + 1}"
  product_id   = var.product_id
  region       = var.region
  image_id     = var.image_id
}
