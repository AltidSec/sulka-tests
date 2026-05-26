*** Settings ***
Documentation    Test Sulka build configurations
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup       Reset Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Test sudo enable
    [Documentation]    Test the SULKA_SERVICEUSER_ENABLE_SUDO configuration
    [Tags]             configuration
    [Setup]            Run Keywords
    ...    Add Common Build Configuration
    ...    AND    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"
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

Test Read-Only Root File System
    [Documentation]    Test the SULKA_ENABLE_READ_ONLY_ROOTFS option
    [Tags]             configuration
    [Setup]            Run Keywords
    ...    Add Common Build Configuration
    ...    AND    Add Common User Configuration

    Build Sulka Image    ${FULL_CONFIG}

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Open Default SSH Connection
    # Ensure root file system is mounted as ro and is erofs
    ${stdout}    ${rc}    Execute Command    mount |grep /\\ |grep erofs |grep \\(ro,    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    # Check kernel command line, and ensure the ro option is set and there is no rw after it.
    # Note that the connection needs to be closed between multiple Execute Command keywords as the SSH
    # server has quite strict limit on the session count, otherwise channel errors will occur
    Close Connection
    Open Default SSH Connection
    ${stdout}=    Execute Command    cat /proc/cmdline | tr ' ' '\\n' | grep -E '^(ro|rw)$' | tail -1
    Should Be Equal As Strings    ${stdout}    ro
    # Attempt to create a file to the root file system
    Close Connection
    Open Default SSH Connection
    ${stdout}=    Execute Command    touch /test_touch    return_stdout=False    return_stderr=True
    Should Be Equal As Strings    ${stdout}    touch: cannot touch '/test_touch': Read-only file system
    Stop QEMU    ${handle}

    Add Sulka Configuration    SULKA_ENABLE_READ_ONLY_ROOTFS="0"

    Build Sulka Image    ${FULL_CONFIG}

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Open Default SSH Connection
    ${rc}=    Execute Command    mount |grep /\\ |grep ext4 |grep \\(rw,    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    Close Connection
    Open Default SSH Connection
    ${rc}=    Execute Command     [ "$(tr ' ' '\\n' < /proc/cmdline | grep -E '^(ro|rw)$' | tail -1)" != "ro" ]    return_stdout=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    ${output}=    Write Sudo SSH    sudo touch /test_touch    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    ${output}=    Write Sudo SSH    sudo ls / | grep test_touch    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Not Be Empty   ${output}

    [Teardown]    Run Keywords
    ...    Reset Sulka Configuration
    ...    AND    Stop QEMU    ${handle}

Test Serviceuser Password Format Check
    [Documentation]    The build must fail at config-parse time when SULKA_SERVICEUSER_PASSWORD
    ...                contains unescaped dollar signs. Reuses the example hash from
    ...                Add Common User Configuration with the backslash escaping removed.
    [Tags]             configuration
    [Setup]            Add Common Build Configuration

    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\$y\$jCT\$seWjSFPPf4lsQL74hWMWG1$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=False
    Should Contain    ${result.stdout}${result.stderr}    contains unescaped dollar signs

    # No need to reset configuration, last assignment takes precedence
    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD=""
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=True

    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=True

    [Teardown]    Reset Sulka Configuration
