*** Settings ***
Documentation    Kernel related tests
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Kernel Hardening
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo kernel-hardening-checker -a    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output}    [+] Config check is finished: 'OK' - 269 / 'FAIL' - 34

    [Teardown]    Stop QEMU    ${handle}
