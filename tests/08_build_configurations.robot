*** Settings ***
Documentation    Test Sulka build configurations
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Test sudo enable
    [Documentation]    Test the SULKA_SERVICEUSER_ENABLE_SUDO configuration
    [Tags]             configuration
    [Setup]            Run Keywords
    ...    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"
    ...    AND    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    ...    AND    Add Sulka Configuration    SULKA_SSH_KEYS_DIR="${CURDIR}/../auth-keys/"

    Build Sulka Image    ${FULL_CONFIG}

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Open Default SSH Connection
    ${output}=    Write Sudo SSH    sudo ls /    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output.lower()}    serviceuser is not in the sudoers file
    Stop QEMU    ${handle}

    Add Sulka Configuration    SULKA_SERVICEUSER_ENABLE_SUDO="1"

    Build Sulka Image    ${FULL_CONFIG}

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Open Default SSH Connection
    ${output}=    Write Sudo SSH    sudo ls /    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Not Contain    ${output.lower()}    serviceuser is not in the sudoers file

    [Teardown]    Run Keywords
    ...    Reset Sulka Configuration
    ...    AND    Stop QEMU    ${handle}

