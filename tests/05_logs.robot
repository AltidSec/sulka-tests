*** Settings ***
Documentation    Check Logs For Errors And Warnings
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Logs For Errors And Warnings
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo cat /var/log/messages    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Not Contain    warn    ${output.lower()}
    Should Not Contain    error    ${output.lower()}

    ${output}=    Write Sudo SSH    sudo dmesg     ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Not Contain    warn    ${output.lower()}
    Should Not Contain    error    ${output.lower()}

    [Teardown]    Stop QEMU    ${handle}

Check The System Date Gets Updated
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Default SSH Connection
    ${output}=    Execute Command    date +%Y
    # We cannot know the exact date and guarantee that the test device
    # has network access for time, but if year is smaller than 2015
    # the initial time setup has failed
    Should Be True    ${output}>2015

    [Teardown]    Stop QEMU    ${handle}
