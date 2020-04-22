#!/bin/bash

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

function print-help {
    echo -e "\n${BLUE}Usage: post.sh <bigip> <atc-svc> <file> ${NC}"
    echo -e "${BLUE}    <bigip> the address of the BIG-IP (URL or IP) ${NC}\n"
    echo -e "${BLUE}    <atc-svc> should be one of the following: ${NC}"
    echo -e "${BLUE}        DO  : Declarative Onboarding ${NC}"
    echo -e "${BLUE}        AS3 : Application Services 3 ${NC}"
    echo -e "${BLUE}        TS  : Telemetry Streaming ${NC}"
    echo -e "${BLUE}    <file> the file with a JSON body to post ${NC}"
    exit 0
}

if [[ -z "${1}" || -z "${2}" || -z "${3}" ]]; then
    print-help
else
    BIGIP_USER=$( grep 'admin_user:' setup.yml | head -n1 | awk '{ print $2}' | tr -d '"' )
    BIGIP_PASS=$( grep 'admin_password:' setup.yml | head -n1 | awk '{ print $2}' | tr -d '"' )

    if [[ -z "${BIGIP_USER}}" || -z "${BIGIP_PASS}}" ]]; then
        echo -e "${RED}Could not detected 'bigip_admin_user' or 'bigip_admin_password' in setup.yml ${NC}"
    fi

    BIGIP_ADDR=${1}
    ATC_ACTION=${2}
    JSON_FILE=${3}

    if [ ! -f "${JSON_FILE}" ]; then
        echo -e "${RED}File '${JSON_FILE}' does not exist ${NC}"
        print-help
    fi

    if [[ ${ATC_ACTION} == "do" || ${ATC_ACTION} == "DO" ]]; then
        REST_URL="https://${BIGIP_ADDR}:8443/mgmt/shared/declarative-onboarding"
    elif [[ ${ATC_ACTION} == "as3" || ${ATC_ACTION} == "AS3" ]]; then
        REST_URL="https://${BIGIP_ADDR}:8443/mgmt/shared/appsvcs/declare"
    elif [[ ${ATC_ACTION} == "ts" || ${ATC_ACTION} == "TS" ]]; then
        REST_URL="https://${BIGIP_ADDR}:8443/mgmt/shared/telemetry/declare"; 
    else
        echo -e "${RED}Wrong value for<atc-svc>. Should be one of DO, AS3 or TS${NC}\n"
        print-help
    fi
fi

echo -e "${GREEN}Going to perform a ${ATC_ACTION} POST on '${REST_URL}'${NC}\n"

cat ${JSON_FILE} | jq 

HTTP_COMMAND="http --body --auth ${BIGIP_USER}:${BIGIP_PASS} --verify=no POST ${REST_URL} < ${JSON_FILE}"
echo -e "\n${GREEN}${HTTP_COMMAND}\n\n"

eval "${HTTP_COMMAND}"