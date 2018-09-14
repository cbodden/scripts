#!/usr/bin/env bash
#===============================================================================
#          FILE: aws_mfa_cli.sh
#         USAGE: source ./aws_mfa_cli.sh
#   DESCRIPTION: this script does MFA on the CLI for AWS usage
#       OPTIONS: none
#  REQUIREMENTS: aws cli tools
#          BUGS: so far does not work with zsh as written
#         NOTES: duration set to 3600
#        AUTHOR: Cesar B
#       CREATED: 09/14/2018 11:04:42 EDT
#      REVISION: 2
#===============================================================================

LC_ALL=C
LANG=C
set -o nounset
set -o pipefail
readonly NAME=$(basename $0)

function main()
{
    # temp file, trap statement, and OS check. exit on !{Linux,Darwin}
    case "$(uname 2>/dev/null)" in
        'Linux')
            _TMP_AWS=$(mktemp --tmpdir ${NAME}_$$-XXXX.tmp)
        ;;
        'Darwin')
            _TMP_AWS=$(mktemp /tmp/${NAME}_$$-XXXX.tmp)
        ;;
        *)
            exit 1
        ;;
    esac
    trap 'rm -rf ${_TMP_AWS} ; exit' 0 1 2 3 9 15

    # check if these deps exist else exit 1
    local DEPS="aws"
    for _DEPS in ${DEPS}
    do
        if [ -z "$(which ${_DEPS} 2>/dev/null)" ]
        then
            printf "%s\n" \
                "${_DEPS} not found"
            exit 1
        fi
    done
}

function _getMFA()
{
    printf "%s\n" \
        "For this step, we need the Assigned MFA device from :" \
        "https://console.aws.amazon.com/iam/home#/home  -- under :" \
        "Users --> Your User --> Security Credentials. " \
        "It should look something like: " \
        "arn:aws:iam::123456789012:mfa/user or GAHT1234567"
    read -p 'Assigned MFA device: ' _MFA_DEVICE
    printf "%s\n" "" ""
    printf "%s\n" \
        "For this step, we need the token code from your MFA device" \
        "which should be six number code from Authy or Google Auth " \
        "similar to 123456"
    read -p 'MFA token code: ' _MFA_TOKEN_CODE
}

function _getKeys()
{
    $(which aws) \
        sts \
        get-session-token \
        --duration-seconds 3600 \
        --serial-number ${_MFA_DEVICE} \
        --token-code ${_MFA_TOKEN_CODE} \
        > ${_TMP_AWS}
}

function _unsetKeys()
{
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}

function setKeys()
{
    export AWS_ACCESS_KEY_ID=$(cat ${_TMP_AWS} \
        | awk -F'"' '/AccessKeyId/ {print $4}')
    export AWS_SECRET_ACCESS_KEY=$(cat ${_TMP_AWS} \
        | awk -F'"' '/SecretAccessKey/ {print $4}')
    export AWS_SESSION_TOKEN=$(cat ${_TMP_AWS} \
        | awk -F'"' '/SessionToken/ {print $4}')
}

main
clear
_getMFA
_getKeys
_unsetKeys
_setKeys
