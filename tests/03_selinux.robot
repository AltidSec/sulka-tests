*** Settings ***
Documentation    Run SELinux checks on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Enforcing
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=1m
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

    ${output}=    Write Sudo SSH    sudo getenforce    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Equal As Strings    Enforcing    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}

Check Access Failures
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    # Wait a moment for possible access failures that do not appear immediately
    Sleep    5 minutes

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=1m
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key
 
    ${output}=    Write Sudo SSH    sudo cat /var/log/messages | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Empty    ${output.strip()}
    ${output}=    Write Sudo SSH    sudo cat /var/log/audit/audit.log | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Empty    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}
