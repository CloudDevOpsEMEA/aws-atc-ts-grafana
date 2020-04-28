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
# ls -1 output

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
<br />
<br />

![AWS Security Groups](./imgs/aws-security-groups.png)  
*AWS Security Groups*
<br />
<br />

![AWS Elastic IP Addresses](./imgs/aws-elastic-ips.png)
*AWS Elastic IP Addresses*
<br />
<br />
 
![BIG-IP Mgmt Interface](./imgs/aws-bigip-mgmt-network-intf.png)
*BIG-IP Mgmt Interface*
<br />
<br />

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

TASK [do : Set connection provider for BIG-IP tasks] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [do : Wait for BIG-IP to be ready to take configuration] *********************

TASK [do : Process DO jinja template and store result in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [Perform DO for initial device onboarding] *********************

TASK [f5devcentral.atc_deploy : POST DO declaration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com -> localhost]

TASK [f5devcentral.atc_deploy : Wait for DO Task to complete] *********************
FAILED - RETRYING: Wait for DO Task to complete (90 retries left).
FAILED - RETRYING: Wait for DO Task to complete (38 retries left).
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com -> localhost]

TASK [do : Wait for DO initial onboarding to fully complete] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [do : Store result of DO onboarding in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [do : DO final result verification of DO onboarding] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] =>
  msg: |-
    Verify on BIG-IP if your desired results was achieved
    > Admin UI   : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443
    > REST URI   : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443/mgmt/shared/declarative-onboarding
    > DOCS URL   : https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest
    > SCHEMA REF : https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/schema-reference.html
    > GITHUB SRC : https://github.com/F5Networks/f5-declarative-onboarding

...

TASK [as3 : Wait for BIG-IP to be ready to take configuration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [as3 : Merge all AS3 JSON blobs into one blob] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] => (item=nginx_one)
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] => (item=nginx_two)
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] => (item=broken)

TASK [as3 : Write the result of the merged AS3 JSON declaration in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [f5devcentral.atc_deploy : POST AS3 declaration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com -> localhost]

TASK [f5devcentral.atc_deploy : Wait for AS3 Task to complete] *********************
FAILED - RETRYING: Wait for AS3 Task to complete (20 retries left).
FAILED - RETRYING: Wait for AS3 Task to complete (15 retries left).
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com -> localhost]

TASK [f5devcentral.atc_deploy : GET AS3 declaration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com -> localhost]

TASK [as3 : Store result of AS3 deployment in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [as3 : AS3 final result verification on BIG-IP] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] =>
  msg: |-
    Verify on BIG-IP if your desired results was achieved
      > Admin UI : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443
      > REST URI : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443/mgmt/shared/appsvcs/declare
      > DOCS URL   : https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest
      > SCHEMA REF : https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/refguide/schema-reference.html
      > GITHUB SRC : https://github.com/F5Networks/f5-appsvcs-extension

...

TASK [ts : Wait for BIG-IP to be ready to take configuration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [ts : Get the private and public ip of the host running graphite/grafana/statsd] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [ts : Process jinja template and store result for artifact storage (graphite json blob for TS)] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [f5devcentral.atc_deploy : POST TS declaration] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [ts : Store result of TS registration for artifact storage (graphite json blob for TS)] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [ts : TS final result verification on BIG-IP] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] =>
  msg: |-
    Verify on BIG-IP if your desired results was achieved
      > Admin UI   : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443
      > REST URI   : https://ec2-54-77-149-146.eu-west-1.compute.amazonaws.com:8443/mgmt/shared/telemetry/declare
      > DOCS URL   : https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest
      > SCHEMA REF : https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/schema-reference.html
      > GITHUB SRC : https://github.com/F5Networks/f5-telemetry-streaming

PLAY RECAP ******************************************************************************************************************************
ec2-54-77-149-146.eu-west-1.compute.amazonaws.com : ok=72   changed=7    unreachable=0    failed=0    skipped=34   rescued=0    ignored=0

```

The above traces show the three roles executed (notice that some of the skipped steps have been removed for readability reasons). It is worth stressing out that we did merge the AS3 JSON blob declarations before submitting it. This is because the AS3 API is Tenant centric and does not allow to update or create an application without the full tenant specification containing all application definitions for that particular tenant

Your output folder shoud now look as follows

```console
# ls -1 output
as3_merged.json
as3_merged_result.json
aws_ec2.yml
aws_inventory.yml
aws_tfplan.tf
do_onboard.json
do_onboard_result.json
ec2_private_key.pem
ts_graphite_statsd.json
```

The ATC JSON blobs that have been send to BIG-IP for DO/AS3/TS are available, as well as the result. This are some screenshots of the results within the BIG-IP administrative GUI


![Team_Ningx Virtual Servers](./imgs/bigip-team-nginx-vs.png)
*Team_Ningx Virtual Servers*
<br />
<br />

![Team_Nginx Pools](./imgs/bigip-team-nginx-pool.png)
*Team_Nginx Pool*
<br />
<br />

![Team_Nginx Pool Members](./imgs/bigip-team-nginx-member.png)
*Team_Nginx Pool Members*
<br />
<br />

![Team_Broken Virtual Servers](./imgs/bigip-team-broken-vs.png)
*Team_Broken Virtual Servers*
<br />
<br />

![Team_Broken Pools](./imgs/bigip-team-broken-pool.png)
*Team_Broken Pools*
<br />
<br />

![Team_Broken Pool Members](./imgs/bigip-team-broken-member.png)
*Team_Broken Pool Members*
<br />
<br />

## Grafana / Graphite / StatsD

### BIG-IP configuration

If we look at the output of the previous step, we see that the following TS configuration has been applied

```json
{
  "class": "Telemetry",
  "MyTelemetrySystem": {
      "class": "Telemetry_System",
      "allowSelfSignedCert": true,
      "systemPoller": {
          "interval": 60
      }
  },    
  "GraphiteConsumer": {
      "class": "Telemetry_Consumer",
      "type": "Graphite",
      "host": "10.0.0.55",
      "protocol": "http",
      "port": 80
  },
  "StatsdConsumer": {
    "class": "Telemetry_Consumer",
    "type": "Statsd",
    "host":"10.0.0.55",
    "protocol": "udp",
    "port": 8125
  },
  "MyTelemetryListener": {
      "class": "Telemetry_Listener",
      "port": 6514
  }
}
```

Two consumers are configured: one for Graphite and one for StatsD. Note that for Graphite, BIG-IP will send JSON blobs with telemetry data to the `/events` endpoint. Events can be used in Grafana as annotations to enrich exiting metrics graphs. The StatsD consumer will send the same information in a metric format that is available in Graphite as metrics

### Grafana configuration

In order to configure Grafana, add Graphite as a data source and add the BIG-IP TS example dashboard, run the final step of the configuration through Ansible implemented in the `grafana.yml` playbook

```console
# make configure_grafana

cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/ansible && ansible-playbook grafana.yml --extra-vars "setupfile=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/setup.yml outputfolder=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output generateloadscript=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/generate_load.sh" ;

PLAY [Grafana Configuration Playbook] *********************

TASK [Gathering Facts] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [Set outputfolder if makefile is not used] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Get the private and public ip of the host running graphite/grafana/statsd] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Process grafana datasource for graphite jinja template and store result in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Check of grafana datasource for graphite already exists] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Add graphite datasource into grafana] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Process grafana dashboard for statsd jinja template and store result in output folder] *********************
changed: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Check if grafana dashboard for statsd already exists] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Add graphite statsd dashboard into grafana] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com]

TASK [grafana : Print the URLs for Grafana / Graphite / Statsd verification] *********************
ok: [ec2-54-77-149-146.eu-west-1.compute.amazonaws.com] =>
  msg: |-
    Verify if metrics and/or events are arriving at the following admin UIs
      > Grafana UI   : http://ec2-34-244-108-113.eu-west-1.compute.amazonaws.com:3000
      > Graphite UI  : http://ec2-34-244-108-113.eu-west-1.compute.amazonaws.com:80
      > StatsD Admin : echo "gauges" | nc ec2-34-244-108-113.eu-west-1.compute.amazonaws.com 8126

PLAY RECAP ******************************************************************************************************************************
ec2-54-77-149-146.eu-west-1.compute.amazonaws.com : ok=10   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

Let's look at StatsD first. In order to do so, you can use `netcat` as hinted in the final step above

```console
# echo "gauges" | nc ec2-34-244-108-113.eu-west-1.compute.amazonaws.com 8126
{
  'statsd.timestamp_lag': 0,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.networkInterfaces.1-0.counters-bitsIn': 297895992,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.networkInterfaces.1-0.counters-bitsOut': 0,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.networkInterfaces.mgmt.counters-bitsIn': 248764520,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.networkInterfaces.mgmt.counters-bitsOut': 134973160,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.tmmTraffic.clientSideTraffic-bitsIn': 62854192,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.tmmTraffic.clientSideTraffic-bitsOut': 229153456,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.tmmTraffic.serverSideTraffic-bitsIn': 62432120,
  'f5telemetry.ip-10-0-0-130-eu-west-1-compute-internal.system.tmmTraffic.serverSideTraffic-bitsOut': 228977008,
  ...
```

**Gauges** is one of the metric types supported by StatsD, besides counters and timers

We can have a visual representation of the StatsD gauges inside Graphite by surfing to the URL hinted above as well

![Graphite BIG-IP StatsD TS Gauges](./imgs/graphite-bigip-ts-gauges.png)
*Graphite BIG-IP StatsD TS Gauges*
<br />
<br />

We can have a visual representation of the Graphite Events inside Graphite by surfing to the URL on the `/events` endpoint


![Graphite BIG-IP Graphite Events](./imgs/graphite-bigip-ts-events.png)
*Graphite BIG-IP Graphite Events*
<br />
<br />


![Graphite BIG-IP Graphite Event Details](./imgs/graphite-bigip-ts-eventdetails.png)
*Graphite BIG-IP Graphite Event Details*
<br />
<br />

A JSON extract of such an event in more details

```json
{
  "system":{
    "hostname":"ip-10-0-0-130.eu-west-1.compute.internal",
    "machineId":"17616a24-e626-423f-bcc0-0f31563ee116",
    "version":"15.0.1.3",
    "versionBuild":"0.0.4",
    "marketingName":"BIG-IP Virtual Edition",
    "platformId":"Z100",
    "chassisId":"e3ca2aec-581c-d7a6-2630aba2d85a",
    "baseMac":"06:55:4D:C6:A0:08",
    "provisioning":{
      "afm":{
        "name":"afm",
        "level":"none"
      },
      "am":{
        "name":"am",
        "level":"none"
      },
      "apm":{
        "name":"apm",
        "level":"none"
      },
      "asm":{
        "name":"asm",
        "level":"nominal"
      },
      "avr":{
        "name":"avr",
        "level":"nominal"
      },
      "dos":{
        "name":"dos",
        "level":"none"
      },
      "ltm":{
        "name":"ltm",
        "level":"nominal"
      },
      "pem":{
        "name":"pem",
        "level":"none"
      }
    },
    "systemTimestamp":"2020-04-26T22:02:56.000Z",
    "syncMode":"standalone",
    "callBackUrl":"https://10.0.0.130",
    "diskStorage":{
      "/":{
        "1024-blocks":"428150",
        "Capacity":"36%",
        "name":"/"
      },
      "/dev":{
        "1024-blocks":"3927768",
        "Capacity":"1%",
        "name":"/dev"
      },
      "/dev/shm":{
        "1024-blocks":"3936868",
        "Capacity":"1%",
        "name":"/dev/shm"
      },
      "/run":{
        "1024-blocks":"3936868",
        "Capacity":"1%",
        "name":"/run"
      }
    }
  }
}
```

### Dashboard results

Go to the Grafana UI and check of the graphite data source and BIG-IP TS sample dashboard is available and correctly configured

![Grafana Data Source](./imgs/grafana-datasource.png)
*Grafana Data Source*
<br />
<br />

![Grafana BIG-IP TS Sample Dashboard](./imgs/grafana-dashboard.png)
*Grafana BIG-IP TS Sample Dashboard*
<br />
<br />

The dashboard uses the following variables to provide zoom down filters

![Grafana Dashboard Variables](./imgs/grafana-variables.png)
*Grafana Dashboard Variables*
<br />
<br />

### Dashboard summary

The following are  set of self describing screenshots of what the dashboard has to offer and what you can do with the TS provided metrics and data


![BIG-IP Application Health Status](./imgs/grafana-applhealth.png)
*BIG-IP Application Health Status*
<br />
<br />

![BIG-IP System Information](./imgs/grafana-system.png)
*BIG-IP System Information*
<br />
<br />

![BIG-IP Virtual Server Information](./imgs/grafana-vss.png)
*BIG-IP Virtual Server Information*
<br />
<br />

![BIG-IP Pool Information](./imgs/grafana-pools.png)
*BIG-IP Pool Information*
<br />
<br />

![BIG-IP Profile Details](./imgs/grafana-profiles.png)
*BIG-IP Profile Details*
<br />
<br />


## Traffic generation

Run the final make target ot display all the information of your setup

```console
# make info

cd /Users/me/Documents/Git/f5/aws-atc-ts-grafana/ansible && ansible-playbook info.yml --extra-vars "setupfile=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/setup.yml outputfolder=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output generateloadscript=/Users/me/Documents/Git/f5/aws-atc-ts-grafana/output/generate_load.sh" ;

PLAY [Setup Information Gathering Playbook] *********************

TASK [Gathering Facts] *********************
ok: [ec2-52-48-80-14.eu-west-1.compute.amazonaws.com]

TASK [Set outputfolder if makefile is not used] *********************
ok: [ec2-52-48-80-14.eu-west-1.compute.amazonaws.com]

TASK [info : Show the Webserver VIP Exposed public URLs] *********************
ok: [ec2-52-48-80-14.eu-west-1.compute.amazonaws.com]

TASK [info : Process traffic load script jinja template and store result in output folder] *********************
changed: [ec2-52-48-80-14.eu-west-1.compute.amazonaws.com]

TASK [info : Show BIG-IP and Grafana public admin URL] *********************
ok: [ec2-52-48-80-14.eu-west-1.compute.amazonaws.com] =>
  msg: |-
    BIG-IP : https://ec2-52-48-80-14.eu-west-1.compute.amazonaws.com:8443
    Grafana : http://ec2-3-249-47-143.eu-west-1.compute.amazonaws.com:3000

PLAY RECAP ****************************************************************************************************************************
ec2-52-48-80-14.eu-west-1.compute.amazonaws.com : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

The output folder should now contain a `generate_load.sh` script which uses [siege](https://www.joedog.org), a command line traffic generator, so you can test the dashboards with actual traffic statistics and data. The script contains a self explanatory helper for its usage

```console
# ls -1 output
as3_merged.json
as3_merged_result.json
aws_ec2.yml
aws_tfplan.tf
do_onboard.json
do_onboard_result.json
ec2_private_key.pem
generate_load.sh
grafana_datasource_graphite.json
grafana_statsd_dashboard.json
ts_graphite_statsd.json
ts_graphite_statsd_result.json

# . ./output/generate_load.sh
Usage: generate_load.sh <target> <type>
    <target> should be one of the following:
        nginx_one : HTTP exposed webserver
        nginx_two : SSL + WAF exposed webserver
        broken    : SSL exposed webserver
        all       : All of the above in parallel
    <type> only for target broken, but one of the following:
        normal : traffic generating 200 OK
        slow   : traffic with slow response
        errors : traffic with error responses
        random : traffic with random responses
```

The target `broken` can now be used to generate 4xx, 5xx and slow responses. The other targets will generate normal 2xx response traffic

This conludes the final part of the walkthrough
