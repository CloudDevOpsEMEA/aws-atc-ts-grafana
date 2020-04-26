# AWS ATC TS Grafana Demo - Walkthrough

## Intro

This page expects you have read the [README file](./README.md) and walks you step by step to the whole demo

## Preparation

Copy the setup.change.yml and change the values according to your environment

```console
# cp setup.change.yml setup.yml
# vim setup.yml
# cat setup.yml
```

Your `setup.yml` might look like something like this

```yaml
---
## Your personal variables
owner: f5

## AWS variables
aws:
  access_key_id: AKIAIOSFODNN7EXAMPLE
  secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  region: eu-west-1
  availability_zone: eu-west-1a
  environment: grafana-demo
  vs_from_port: 8080
  vs_to_port: 8090

## BIG-IP variables
bigip:
  admin_user: admin
  admin_password: "MySuperSecretPassword123!"
  ec2_instance_type: m5.large
  ami_search_name: "F5 BIGIP-15.* PAYG-Best 200Mbps*"
  ...
```

## Terraform part

Next we are going to spin-up our infrastructure on AWS: 1 BIG-IP VE, 6 web ppplications and one EC2 instance containing Grafana/Graphite/Statsd (using docker containers)

```console
# make deploy_infra

cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/terraform && terraform init -input=false ;
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!

...

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.
data.template_file.ansible_dynamic_inventory_config: Refreshing state...

...

Plan: 56 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: /Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/aws_tfplan.tf

To perform exactly these actions, run the following command to apply:
    terraform apply "/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/aws_tfplan.tf"

cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/terraform && terraform apply -input=false -auto-approve /Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/aws_tfplan.tf ;

...

module.bigip.aws_instance.f5_bigip: Creation complete after 1m9s [id=i-0db97ad627f42c041]

Apply complete! Resources: 56 added, 0 changed, 6 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

bigip_data =
      bigip_private_ips : 10.0.0.130, 10.0.0.142, 10.0.0.155
      bigip_public_ips  : 54.77.149.146, 18.200.115.67, 34.251.149.168
      bigip_public_dns  : ec2-54-77-149-146.eu-west-1.compute.amazonaws.com, ec2-18-200-115-67.eu-west-1.compute.amazonaws.com, ec2-34-251-149-168.eu-west-1.compute.amazonaws.com
      bigip_mgmt_url    : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443
      aws_secret_name   : f5-ec2-key-pair-14f8

graphite_grafana =
      private_ips  : 10.0.0.55
      public_ips   : 34.244.108.113
      public_dns   : ec2-34-244-108-113.eu-west-1.compute.amazonaws.com
      graphite_url : http://ec2-34-244-108-113.eu-west-1.compute.amazonaws.com
      grafana_url  : http://ec2-34-244-108-113.eu-west-1.compute.amazonaws.com:3000

webservers_broken =
      private_ips : 10.0.0.51, 10.0.0.232
      public_ips  : 3.248.182.122, 52.48.113.120
      public_dns  : ec2-3-248-182-122.eu-west-1.compute.amazonaws.com, ec2-52-48-113-120.eu-west-1.compute.amazonaws.com

webservers_nginx_one =
      private_ips : 10.0.0.167, 10.0.0.134
      public_ips  : 3.249.150.190, 3.249.184.231
      public_dns  : ec2-3-249-150-190.eu-west-1.compute.amazonaws.com, ec2-3-249-184-231.eu-west-1.compute.amazonaws.com

webservers_nginx_two =
      private_ips : 10.0.0.141, 10.0.0.9
      public_ips  : 52.213.217.52, 34.245.183.67
      public_dns  : ec2-52-213-217-52.eu-west-1.compute.amazonaws.com, ec2-34-245-183-67.eu-west-1.compute.amazonaws.com

```

One minute and 10 seconds later, the infrastructure is up and running. The terraform step finishes with some output steps that help you do determine the IP addesses and DNS names of the servers used in the setup

Let's look at the output folder to see what we've got so far

```console
# ls -1 ./output

aws_ec2.yml
aws_tfplan.tf
ec2_private_key.pem
```

The following files are created as temporary demo artifacts
 - **aws_ec2.yml:** this file contains the necessary Ansible AWS Dynamic inventory configuration, depending on your setup environment
 - **aws_tfplan.tf:** the terraform plan created and applied
 - **ec2_private_key.pem:**  the private key of the EC2 key pair created for this demo, which can be used to get SSH access to the servers. All servers are in AWS Security Groups with port 22 publically available from anywhere

Let's see in the AWS Console what actually has been created

![AWS EC2 Instances](./imgs/aws-ec2-instances.png)
*AWS EC2 Instances*


![AWS Security Groups](./imgs/aws-security-groups.png)  
*AWS Security Groups*


![AWS Elastic IP Addresses](./imgs/aws-elastic-ips.png)
*AWS Elastic IP Addresses*


![BIG-IP Mgmt Interface](./imgs/aws-bigip-mgmt-network-intf.png)
*BIG-IP Mgmt Interface*


As we are using BIG-IP in a 1NIC deployment scenario, two extra secondary ip addresses are configured, both being exposed using AWS EIP addresses. The first and primary IP address is used for management traffic on port 8443. The two secondary IP addresses are used to expose two Virtual Servers, mapping to our two tenants/partitions on BIG-IP in later configuration. The first tenant/partition will contain two virtual servers on a differenct TCP port (8080 and 8081 respectively), the second tenant/partition will contain on virtual server on TCP port 8080

For the sake of completeness, although not strictly necessary, let us also create the AWS dynamic inventory yaml file

```console
# make inventory
cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/ansible && ansible-inventory --yaml --list > /Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/aws_inventory.yml ;

# head -n 10 output/aws_inventory.yml
```
```yaml
all:
  children:
    aws_ec2:
      hosts:
        ec2-3-248-182-122.eu-west-1.compute.amazonaws.com:
          ami_launch_index: 0
          architecture: x86_64
          block_device_mappings:
          - device_name: /dev/sda1
          ...

```

This file, `aws_inventory.yml` is also stored as temporary build artifact in the output folder. It was used during development of this demo to pinpoint the correct host variables to be used in Ansible. Ansible will generate this file dynamically in its caching folder and use that one, so changing this one will not have any effect

## Ansible part

Now that our infrastructure has been spun up, lets go to Ansible to do the following step on our BIG-IP

 - Declarative Onboarding (**do role**): initial network setup
 - Application Service configuration (**as3 role**): virtual server creation
 - Telemetry Streaming configuration (**ts role**): StatsD consumer configuration

All of them are tied together in the `bigip.yml` playbook

```console
# make configure_bigip

cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/ansible && ansible-playbook bigip.yml --extra-vars "setupfile=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/setup.yml outputfolder=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output generateloadscript=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/generate_load.sh" ;

PLAY [BIG-IP Configuration Playbook] *********************

TASK [Gathering Facts] ***********************************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [Set outputfolder if makefile is not used] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [do : Set connection provider for BIG-IP tasks] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [do : Wait for BIG-IP to be ready to take configuration] *********************

...
 
```

