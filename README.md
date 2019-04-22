# K8s Jumpbox Deployment on Azure using Ansible

Ansible is an open-source tool that automates cloud provisioning, configuration management, and application deployments. Using Ansible you can provision virtual machines, containers, network, and complete cloud infrastructures. In addition, Ansible allows you to automate the deployment and configuration of resources in your environment.

Ansible includes a suite of [Ansible modules](http://docs.ansible.com/ansible/latest/modules_by_category.html) that can be executed directly on remote hosts or via playbooks. Users can also create their own modules. Modules can be used to control system resources - such as services, packages, or files - or execute system commands.

For interacting with Azure services, Ansible includes a suite of Ansible cloud modules that provides the tools to easily create and orchestrate your infrastructure on Azure.

## Getting Started

These instructions will get you a K8s Jumpbox up and running on your Azure Subscription. See deployment for notes on how to deploy.

### Prerequisites

* Azure subscription - If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio).
* Create a [Linux Virtual Machine](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal) which will act as a Ansible Master VM.
* Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)& [Azure Modules](https://docs.ansible.com/ansible/latest/scenario_guides/guide_azure.html) on newly created Linux VM.
* Create a [Service Principle](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) on Azure using Azure Cli and make note of App ID & Secret 

### Installing
##### Step 1: Login to the Linux VM with username and password
##### Step 2: Check the version of Ansible
```
      $ sudo ansible --version
```
##### Step 3: Generate SSH keys and copy the content of id_rsa.pub key
```
     $sudo ssh-keygen
      
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:z6zTVQ/PJYt2o96DrVYClmfcqBG8Pdb8nzqY2m2HjeY ansible@ansiblevm
The key's randomart image is:
+---[RSA 2048]----+
|         .       |
|          o      |
|           * =   |
|          * O B .|
|        S. B + O.|
|         +. = = =|
|         .+ooB+.o|
|        ..oo=Bo+.|
|        .o.+*E=. |
+----[SHA256]-----+
```
##### Step 4: Use Ansible environment variables

configure your Ansible credentials by exporting them as environment variables.

In a terminal or Bash window, enter the following commands:

```
$ export AZURE_SUBSCRIPTION_ID=<your-subscription_id>
$ export AZURE_CLIENT_ID=<security-principal-appid>
$ export AZURE_SECRET=<security-principal-password>
$ export AZURE_TENANT=<security-principal-tenant>

```

##### Step 5: Create the k8jumpbox.yaml file
```
   $ sudo vi k8jumpbox.yaml
   
# Description
# ===========
# This playbook create an Azure VM with public IP, and open 22 port for SSH, and add ssh public key to the VM.
# This playbook create an Azure VM with public IP
# Change variables below to customize your VM deployment

- name: Create Azure VM
  hosts: localhost
  connection: local
  vars:
    resource_group: shaikansible
    vm_name: testvm5
    location: eastus
    ssh_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrNmk6HL28K3PKMag1HSjE31cGRjjQgEQYlbjco/Vpf6lib1A3OWdmlIJ74zIih/MUPaviDyV3XjgAGs29LdN6lyUCA7qTjEMD/x9vUetPl80Ye30nrCDP8YEhMtw9CyNJvAFSbayvSyWN8lWu7YZ3VhhVvR8efjGkOp3H0cAc28iBCGVVXw9ZO0spQVjqbTkM2QhAvqucfulfH8m/Qe5YjeaNSwRSQ5WeJtK99rxCeO0qt/imGXP6NVFizPjZbdDwp9AgCevxA6keTzVZU5Y9bRIrzLuMqisSqVMMxYbzjXcmzai6rPO5/yGbso2Pl/wtIeCis0xlW5N1IcosSeRZ"
  tasks:
  - name: Create a resource group
    azure_rm_resourcegroup:
        name: "{{ resource_group }}"
        location: "{{ location }}"
  - name: Create virtual network
    azure_rm_virtualnetwork:
      resource_group: "{{ resource_group }}"
      name: "{{ vm_name }}"
      address_prefixes: "10.0.0.0/16"
  - name: Add subnet
    azure_rm_subnet:
      resource_group: "{{ resource_group }}"
      name: "{{ vm_name }}"
      address_prefix: "10.0.1.0/24"
      virtual_network: "{{ vm_name }}"
  - name: Create public IP address
    azure_rm_publicipaddress:
      resource_group: "{{ resource_group }}"
      allocation_method: Static
      name: "{{ vm_name }}"
  - name: Create Network Security Group that allows SSH
    azure_rm_securitygroup:
      resource_group: "{{ resource_group }}"
      name: "{{ vm_name }}"
      rules:
        - name: SSH
          protocol: Tcp
          destination_port_range: 22
          access: Allow
          priority: 1001
          direction: Inbound
  - name: Create virtual network inteface card
    azure_rm_networkinterface:
      resource_group: "{{ resource_group }}"
      name: "{{ vm_name }}"
      virtual_network: "{{ vm_name }}"
      subnet: "{{ vm_name }}"
      public_ip_name: "{{ vm_name }}"
      security_group: "{{ vm_name }}"
  - name: Create VM
    azure_rm_virtualmachine:
      resource_group: "{{ resource_group }}"
      name: "{{ vm_name }}"
      vm_size: Standard_DS1_v2
      admin_username: ansible
      ssh_password_enabled: false
      ssh_public_keys:
        - path: /home/ansible/.ssh/authorized_keys
          key_data: "{{ ssh_key }}"
      network_interfaces: "{{ vm_name }}"
      image:
        offer: CentOS
        publisher: OpenLogic
        sku: '7.5'
        version: latest
  - name: Create VM Extension
    azure_rm_virtualmachine_extension:
      name: myvmextension
      location: eastus
      resource_group: shaikansible
      virtual_machine_name: testvm5
      publisher: Microsoft.Azure.Extensions
      virtual_machine_extension_type: CustomScript
      type_handler_version: 2.0
      settings:
        fileUris:
        - 'https://clistoragesiva.blob.core.windows.net/jumpbox/jumpserver_pkgs.sh'
        commandToExecute: "bash jumpserver_pkgs.sh"
      state: present
```
##### Step 6: Create a bash script file to install the required packages and Make this script globally available

```
      $ vi packages.sh
      
#!/bin/bash
#" This Script will install the following packages on centos 7 "
# - Docker
# - AzureCLI
# - Visual Studio Code
# - Helm
# - Kubectl
# - git
# - VNC
#Author : SNP Technologies
#Date   : 12-April-2019

#Installation of Docker
curl -fsSL https://get.docker.com/ | sh
sudo systemctl start docker
echo "Docker Installation Completed"
sleep 30
echo "Azure CLI installatio starting"
sleep 10

#Installation of AzureCLI

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install azure-cli -y
sleep 30
echo "Azure CLI installation Completed"
echo "Starting Visual Studio Code Installation"
sleep 10
 
#Installation of Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo touch /etc/yum.repos.d/vscode.repo
sudo chmod 777 /etc/yum.repos.d/vscode.repo
sudo cat > /etc/yum.repos.d/vscode.repo <<-EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo yum install code -y
sudo chmod 644 /etc/yum.repos.d/vscode.repo

sleep 30
echo "Visual Studio Code Installation Completed"
echo "Starting Helm Installation"
sleep 10

#Installation of Helm
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.13.1-linux-amd64.tar.gz
sudo tar -zxvf helm-v2.13.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

sleep 30
echo "Helm Installation Completed"
echo "Starting Kubectl installation"
sleep 10

#Installation of Kubectl
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo touch /etc/yum.repos.d/kubernetes.repo
sudo chmod 777 /etc/yum.repos.d/kubernetes.repo
sudo cat > /etc/yum.repos.d/kubernetes.repo <<-EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y  kubectl
sudo chmod 644 /etc/yum.repos.d/kubernetes.repo

sleep 30
echo "Kubectl installation completed"
echo "Starting GIT installation"
sleep 10

#Installation of GIT
sudo yum install git -y
sleep 10
echo " GIT installation completed"
sleep 10

#installation of VNC Server
sudo yum groupinstall -y "GNOME Desktop"
sudo yum install tigervnc-server -y
sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver_ansible@:1.service
#sudo cp /lib/systemd/system/vncserver@.service  /etc/systemd/system/vncserver@:1.service
sudo sed -i 's/<USER>/ansible/g' /etc/systemd/system/vncserver_ansible@:1.service
sudo cat /etc/systemd/system/vncserver_ansible@:1.service<<-EOF
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=ansible

# Clean any existing files in /tmp/.X11-unix environment
ExecStartPre=-/usr/bin/vncserver -kill %i
ExecStart=/sbin/runuser -l ansible -c "/usr/bin/vncserver %i -geometry 800x800"
PIDFile=/home/ansible/.vnc/%H%i.pid
ExecStop=-/usr/bin/vncserver -kill %i

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start vncserver_ansible@:1.service
sudo systemctl enable vncserver_ansible@:1.service
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=vnc-server
sudo firewall-cmd --permanent --add-port=5901/tcp
sudo firewall-cmd --reload

sleep 10
echo " We have installed Docker,AzureCLI,Visual Studio Code,Helm,GIT & VNC"
sleep 30
#End of the Script
```
##### Step 7: Run the Playbook 
```
       $ ansible-playbook k8jumpbox.yaml
```
The results of running the ansible command should look similar to the following output:

```
PLAY [Create Azure VM] *************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************
ok: [localhost]

TASK [Create a resource group] *****************************************************************************************************************************************
ok: [localhost]

TASK [Create virtual network] ******************************************************************************************************************************************
changed: [localhost]

TASK [Add subnet] ******************************************************************************************************************************************************
changed: [localhost]

TASK [Create public IP address] ****************************************************************************************************************************************
changed: [localhost]

TASK [Create Network Security Group that allows SSH] *******************************************************************************************************************
changed: [localhost]

TASK [Create virtual network inteface card] ****************************************************************************************************************************
[DEPRECATION WARNING]: Setting ip_configuration flatten is deprecated and will be removed. Using ip_configurations list to define the ip configuration. This feature
will be removed in version 2.9. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
changed: [localhost]

TASK [Create VM] *******************************************************************************************************************************************************
changed: [localhost]

TASK [Create VM Extension] *********************************************************************************************************************************************
changed: [localhost]

PLAY RECAP *************************************************************************************************************************************************************
localhost                  : ok=9    changed=7    unreachable=0    failed=0
```

we have successfully deployed K8s Jumpbox on Azure 

##### Step 8: Test the Deployment with fallowing commands
```
      $ ssh ansible@<IP Address of VM>
      $ sudo git --help       ## To check the GIT Installation 
      $ sudo az login         ## To check the Azure Cli Installation
      $ sudo docker --help    ## To check the Docker Installation
      $ sudo code             ## To check the VScode Installation
      $ sudo kubectl          ## To check the Kubectl Installation
      $ sudo helm --version   ## To check the Helm Installation
      $ sudo vncviewer        ## To check the VNCServer installation
```




