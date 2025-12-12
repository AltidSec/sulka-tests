*** Settings ***
Documentation    Check Processes
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Running Processes
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo ps auxww    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output}    /sbin/auditd
    Should Contain    ${output}    /usr/sbin/syslog-ng

    [Teardown]    Stop QEMU    ${handle}

