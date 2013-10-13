#!/bin/bash -x
# Tested with ami-b7b2dcde

# Get the private IP address
CURR_PRIVATE_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
CURR_HOST_NAME=`hostname`
echo "$CURR_PRIVATE_IP $CURR_HOST_NAME" | sudo -A tee -a /etc/hosts
sudo rm -f /etc/yum.repos.d/fedora-updates-testing.repo
sudo yum clean all
sudo yum -y update
sudo yum install -y vconfig
sudo yum install -y bridge-utils
sudo vconfig add eth0 100
sudo brctl addbr br101
sudo brctl addif br101 eth0.100
sudo ip link set eth0.100 up 
sudo ip link set br101 up     
sudo yum install -y git
sudo yum install -y python-pip
sudo pip install -q netaddr
sudo pip install --upgrade prettytable
git clone https://github.com/openstack-dev/devstack.git
cd devstack

# When creating the stack deployment for the first time, 
# you are going to see prompts for multiple passwords. 
# Your results will be stored in the localrc file. 
# If you wish to bypass this, and provide the passwords up front, 
# add in the following lines with your own password to the localrc file
echo ADMIN_PASSWORD=1qaz2wsx > localrc
echo MYSQL_PASSWORD=1qaz2wsx >> localrc
echo RABBIT_PASSWORD=1qaz2wsx >> localrc
echo SERVICE_PASSWORD=1qaz2wsx >> localrc
echo SERVICE_TOKEN=1qaz2wsx >> localrc
echo FIXED_RANGE=192.168.0.0/24 >> localrc
echo FIXED_NETWORK_SIZE=256 >> localrc
echo FLAT_INTERFACE=eth0.100 >> localrc
echo ENABLED_SERVICES+=,tls-proxy >> localrc

## It would also be useful to automatically download and register VM images that Heat can launch.
echo IMAGE_URLS+=",http://fedorapeople.org/groups/heat/prebuilt-jeos-images/F19-x86_64-cfntools.qcow2" >> localrc

source localrc
echo VORBOSE=True >> stackrc
echo LOGFILE=stacklog.txt >> stackrc
source stackrc

# This installs Devstack. It takes a long time (10-15 minutes) 
./stack.sh

# Devstack is now installed. 
# If all is well, you will see the following output : 
#  Horizon is now available at http://IP_ADDRESS/
#  Heat has replaced the default flavors. View by running: nova flavor-list
#  Keystone is serving at http://IP_ADDRESS:5000/v2.0/
#  The password: 1qaz2wsx
#  This is your host ip: IP_ADDRESS

# Now use the user demo to perform some actions : 
source openrc demo demo

# Creates a security group named default and add rules to it : 
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
nova secgroup-list-rules default

# Forces the env to auto assign floating IP addresses to a newly created VMs
# First kills the nova-network
ps -ef | grep -i "nova-network" | grep -v grep | awk '{print $2}' | xargs sudo kill -9
# Enables auto assignments of floating IP addresses to a newly created VMs : 
sudo sed -i -e "s/default_floating_pool = public/&\nauto_assign_floating_ip = True/g" /etc/nova/nova.conf
# Starts the nova-network
cd /opt/stack/nova && /usr/bin/nova-network --config-file /etc/nova/nova.conf || touch "/opt/stack/status/stack/n-net.failure" &


# To create an instance use:
# nova boot pickaname --image image_uuid --flavor pickaflavor

# Before you create an image your `brctl show` will display
#devstack]$ brctl show
#bridge name	bridge id		STP enabled	interfaces
#br101		8000.12313d047e5c	no		eth0.100
#virbr0		8000.000000000000	yes

# After you create an image your `brctl show` will display
# devstack]$ brctl show
# bridge name	bridge id		STP enabled	interfaces
# br100		8000.fe163eece635	no		vnet0
# br101		8000.12313d047e5c	no		eth0.100
# virbr0	8000.000000000000	yes

# When deleting an instance, you the br100 device is not removed, use the following commands to remove it
# ifconfig br100 down
# brctl delbr br100
