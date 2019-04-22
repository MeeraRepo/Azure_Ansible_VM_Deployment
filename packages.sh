#!/bin/bash
echo $(date) " - Starting testvm Prep Script"

export USERNAME=ansible

# Generate private keys for use by Ansible
echo $(date) " - Generating Private keys for use by Ansible for OpenShift Installation"

runuser -l $SUDOUSER -c "echo \"$PRIVATEKEY\" > ~/.ssh/id_rsa"
runuser -l $SUDOUSER -c "chmod 600 ~/.ssh/id_rsa*"

# Update system to latest packages
echo $(date) " - Update system to latest packages"
yum -y update --exclude=WALinuxAgent
echo $(date) " - System update complete"

# Install base packages and update system to latest packages
echo $(date) " - Install base packages"
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion httpd-tools kexec-tools sos psacct ansible
echo $(date) " - Base package installation complete"

# Installing Azure CLI
# From https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum
echo $(date) " - Installing Azure CLI"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install -y azure-cli
echo $(date) " - Azure CLI installation complete"

echo $(date) " - Script Complete"
