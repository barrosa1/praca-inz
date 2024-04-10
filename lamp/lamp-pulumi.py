import pulumi
from pulumi_vsphere import virtual_machine

config = pulumi.Config()

datacenter = config.require("datacenter")
datastore = config.require("datastore")
network = config.require("network")
resource_pool = config.require("resource_pool")

vm = virtual_machine.VirtualMachine("vm",
    resource_pool_id=resource_pool,
    datastore_id=datastore,
    num_cpus=2,
    memory=1024,
    guest_id="other3xLinux64Guest",
    disks=[virtual_machine.VirtualMachineDiskArgs(
        label="disk0",
        size=20,
    )],
    network_interfaces=[virtual_machine.VirtualMachineNetworkInterfaceArgs(
        network_id=network,
    )],
    clone=virtual_machine.VirtualMachineCloneArgs(
        template_uuid="your_template_uuid",
    ),
)