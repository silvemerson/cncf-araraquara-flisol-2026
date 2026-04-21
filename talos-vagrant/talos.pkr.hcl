packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "talos_version" {
  type    = string
  default = "v1.12.6"
}

variable "schematic_id" {
  type    = string
  default = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
}

locals {
  iso_url      = "https://factory.talos.dev/image/${var.schematic_id}/${var.talos_version}/metal-amd64.iso"
  iso_checksum = "none"
}

source "qemu" "talos" {
  vm_name          = "talos-${var.talos_version}"
  iso_url          = local.iso_url
  iso_checksum     = local.iso_checksum
  disk_size        = "10G"
  memory           = 2048
  cpus             = 2
  headless         = true
  accelerator      = "kvm"
  communicator     = "none"
  shutdown_timeout = "5m"
  shutdown_command = ""

  disk_interface   = "virtio"
  net_device       = "virtio-net"

  boot_wait        = "60s"
  boot_command     = []

  output_directory = "output-talos"
  format           = "qcow2"

  qemuargs = [
    ["-monitor", "unix:/tmp/talos-monitor.sock,server,nowait"]
  ]
}

build {
  sources = ["source.qemu.talos"]

  provisioner "shell-local" {
    inline = ["sleep 30 && echo 'quit' | socat - UNIX-CONNECT:/tmp/talos-monitor.sock || true"]
  }

  post-processor "vagrant" {
    provider_override = "libvirt"
    output            = "talos-${var.talos_version}-libvirt.box"
  }
}