*** Settings ***
Documentation    Run SELinux checks on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Enforcing
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo getenforce    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Equal As Strings    Enforcing    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}

Check Access Failures
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    # Wait a moment for possible access failures that do not appear immediately
    Sleep    5 minutes

    Open Default SSH Connection
 
    ${output}=    Write Sudo SSH    sudo cat /var/log/messages | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Empty    ${output.strip()}
    ${output}=    Write Sudo SSH    sudo cat /var/log/audit/audit.log | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Empty    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}
