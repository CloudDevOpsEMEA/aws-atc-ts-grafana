# Ansible AWS EC2 dynamic inventory plugin
# https://docs.ansible.com/ansible/2.6/plugins/inventory/aws_ec2.html
plugin: aws_ec2

regions:
  - ${region}

filters:
    tag:Environment: ${environment}

hostnames:
  - dns-name

keyed_groups:
  # add hosts to tag_Name_Value groups for each Name/Value tag pair
  - prefix: tag
    key: tags
