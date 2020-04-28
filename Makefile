.PHONY: plan_infra deploy_infra destroy_infra reset_infra
.PHONY: configure_bigip configure_grafana info
.PHONY: install_galaxy_modules inventory clean_output terraform_validate terraform_update bigip_payg_amis
.PHONY: all

## Input variables ##
SETUP_FILE=${CURDIR}/setup.yml
TERRAFORM_FOLDER=${CURDIR}/terraform
ANSIBLE_FOLDER=${CURDIR}/ansible

## Output variables ##
OUTPUT_FOLDER=${CURDIR}/output
TERRAFORM_PLAN=${OUTPUT_FOLDER}/aws_tfplan.tf
AWS_EC2_PRIVATE_KEY=${OUTPUT_FOLDER}/ec2_private_key.pem
ANSIBLE_DYNAMIC_AWS_INVENTORY=${OUTPUT_FOLDER}/aws_inventory.yml
ANSIBLE_DYNAMIC_AWS_INVENTORY_CONFIG=${OUTPUT_FOLDER}/aws_ec2.yml
GENERATE_LOAD_SCRIPT=${OUTPUT_FOLDER}/generate_load.sh

## Exec arguments ##
TERRAFORM_EXTRA_ARGS=-var "setupfile=${SETUP_FILE}" -var "ec2privatekey=${AWS_EC2_PRIVATE_KEY}" -var "awsinventoryconfig=${ANSIBLE_DYNAMIC_AWS_INVENTORY_CONFIG}"
# ANSIBLE_EXTRA_ARGS=-vvv --extra-vars "setupfile=${SETUP_FILE} outputfolder=${OUTPUT_FOLDER}"
ANSIBLE_EXTRA_ARGS=--extra-vars "setupfile=${SETUP_FILE} outputfolder=${OUTPUT_FOLDER} generateloadscript=${GENERATE_LOAD_SCRIPT}"

#####################
# Terraform Targets #
#####################

plan_infra: 
	cd ${TERRAFORM_FOLDER} && terraform init -input=false ;
	cd ${TERRAFORM_FOLDER} && terraform plan -out=${TERRAFORM_PLAN} -input=false ${TERRAFORM_EXTRA_ARGS} ;

deploy_infra: plan_infra
	cd ${TERRAFORM_FOLDER} && terraform apply -input=false -auto-approve ${TERRAFORM_PLAN} ;


destroy_infra: clean_output
	cd ${TERRAFORM_FOLDER} && terraform destroy -auto-approve ${TERRAFORM_EXTRA_ARGS} ;

reset_infra: destroy_infra clean_output deploy_infra inventory

###################
# Ansible Targets #
###################

configure_bigip:
	cd ${ANSIBLE_FOLDER} && ansible-playbook bigip.yml ${ANSIBLE_EXTRA_ARGS} ;

configure_grafana:
	cd ${ANSIBLE_FOLDER} && ansible-playbook grafana.yml ${ANSIBLE_EXTRA_ARGS} ;

info:
	cd ${ANSIBLE_FOLDER} && ansible-playbook info.yml ${ANSIBLE_EXTRA_ARGS} ;

##################
# Helper Targets #
##################

install_galaxy_modules:
	ansible-galaxy install f5devcentral.atc_deploy ; \
	ansible-galaxy collection install f5networks.f5_modules

inventory:
	cd ${ANSIBLE_FOLDER} && ansible-inventory --yaml --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY} ;

clean_output:
	rm -f ${OUTPUT_FOLDER}/*.yml ${OUTPUT_FOLDER}/*.json ${OUTPUT_FOLDER}/*.tf ${OUTPUT_FOLDER}/*.sh ${OUTPUT_FOLDER}/*.pem ./terraform/.terraform

terraform_validate: 
	cd ${TERRAFORM_FOLDER} && terraform validate ;
	cd ${TERRAFORM_FOLDER} && terraform fmt -recursive ;

terraform_update: 
	cd ${TERRAFORM_FOLDER} && terraform get -update=true ;

bigip_payg_amis:
	$(shell aws ec2 describe-images --owners 679593333241 | grep PAYG | grep Description)

all: deploy_infra configure_bigip configure_grafana info