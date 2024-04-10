provider "vsphere" {
  user           = "user"
  password       = "password"
  vsphere_server = "vsphere_server"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "resource_pool"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "network"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "debian-web-app-vm"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    size  = 20
  }
}