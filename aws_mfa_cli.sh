#!/usr/bin/env bash
#===============================================================================
#          FILE: aws_mfa_cli.sh
#         USAGE: source ./aws_mfa_cli.sh || . ./aws_mfa_cli.sh
#   DESCRIPTION: this script does MFA on the CLI for AWS usage
#       OPTIONS: none
#  REQUIREMENTS: aws cli tools
#          BUGS: so far not sure
#         NOTES: duration set to 3600
#        AUTHOR: Cesar B
#       CREATED: 09/14/2018 11:04:42 EDT
#      REVISION: 4
#===============================================================================

LC_ALL=C
LANG=C
NAME=$(basename $0)

function main()
{
    # temp file via OS check and trap statement. exit on !{Linux || Darwin}
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
    trap 'rm ${_TMP_AWS}' 0 1 3 9 15
    trap 'trap - SIGINT; rm ${_TMP_AWS}; kill -SIGINT $$' SIGINT;

    # if $SHELL == /bin/bash have some default sets
    case "$(echo $SHELL 2>/dev/null)" in
        '/bin/bash')
            set -o nounset
            set -o pipefail
            ;;
    esac

    # check if deps exist else exit 1
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

function _cleanup()
{
    rm /tmp/${NAME}*
}

function _getMFA()
{
    # grab MFA device
    printf "%s\n" \
        "For this step, we need the Assigned MFA device from :" \
        "https://console.aws.amazon.com/iam/home#/home  -- under :" \
        "Users --> Your User --> Security Credentials. " \
        "It should look something like: " \
        "arn:aws:iam::123456789012:mfa/user or GAHT1234567"
    printf "%s" \
        "Assigned MFA device: "
    read _MFA_DEVICE

    # grab MFA token code
    printf "%s\n" "" \
        "For this step, we need the token code from your MFA device" \
        "which should be six number code from Authy or Google Auth " \
        "similar to 123456"
    printf "%s" \
        "MFA token code: "
    read _MFA_TOKEN_CODE
}

function _getKeys()
{
    # query AWS for secret access key and session token while setting duration
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
    # unset previous access kley id, secret access key, and session token
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}

function _setKeys()
{
    # set new access key id, secret access key, and session token
    export AWS_ACCESS_KEY_ID=$( \
        awk -F'"' '/AccessKeyId/ {print $4}' ${_TMP_AWS})
    export AWS_SECRET_ACCESS_KEY=$( \
        awk -F'"' '/SecretAccessKey/ {print $4}' ${_TMP_AWS})
    export AWS_SESSION_TOKEN=$( \
        awk -F'"' '/SessionToken/ {print $4}' ${_TMP_AWS})
}

# run functions
main
_cleanup
clear
_getMFA
_getKeys
_unsetKeys
_setKeys
