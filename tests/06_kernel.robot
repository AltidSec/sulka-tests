*** Settings ***
Documentation    Kernel related tests
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Kernel Hardening
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo kernel-hardening-checker -a    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output}    [+] Config check is finished: 'OK' - 269 / 'FAIL' - 34

    [Teardown]    Stop QEMU    ${handle}
