cobra
=====

 To create an instance use:
 nova boot pickaname --image image_uuid --flavor pickaflavor

# Current Issues:

1. You have to delete the bridge that is created along with your instance after you delete the instance

Before you create an image your bridges will be:

    brctl show
    bridge name	bridge id		STP enabled	interfaces
    br101		8000.12313d047e5c	no		eth0.100
    virbr0		8000.000000000000	yes

After you create an image your bridges will be:

    `brctl show`
     bridge name	bridge id		STP enabled	interfaces
     br100		8000.fe163eece635	no		vnet0
     br101		8000.12313d047e5c	no		eth0.100
     virbr0	        8000.000000000000	yes

When deleting an instance, you the br100 device is not removed, use the following commands to remove it

    `ifconfig br100 down`
    `brctl delbr br100`

2. If you have issues related to AMQP connections, check the rabbitmq server log. If the password is wrong, run unstack.sh and then rerun the devstack.sh.
