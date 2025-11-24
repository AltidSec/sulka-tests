*** Settings ***
Documentation    Check Processes
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Running Processes
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo ps auxww    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output}    /sbin/auditd
    Should Contain    ${output}    /usr/sbin/rsyslogd

    [Teardown]    Stop QEMU    ${handle}

