# The resulting managed image ID is then referenced directly in the VMSS Terraform/Bicep templates shown earlier (`source_image_id` / `imageReference.id`)
# Every instance that scales out is a byte-for-byte copy, eliminating config drift entirely.

source "azure-arm" "nodeapp" {
  subscription_id  = var.subscription_id
  managed_image_resource_group_name = "rg-images"
  managed_image_name                = "golden-nodeapp-${formatdate("YYYYMMDD", timestamp())}"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"

  location = "australiaeast"
  vm_size  = "Standard_D2s_v5"
}

build {
  sources = ["source.azure-arm.nodeapp"]

  provisioner "shell" {
    scripts = [
      "scripts/install-nodejs.sh",
      "scripts/cis-hardening.sh",
      "scripts/install-ama.sh"
    ]
  }

  # Required de-provisioning step for Azure generalized images
  provisioner "shell" {
    inline = ["sudo waagent -deprovision+user -force"]
  }
}