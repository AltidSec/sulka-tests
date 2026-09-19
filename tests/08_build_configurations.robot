*** Settings ***
Documentation    Test Sulka build configurations
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Resource         ../resources/versions.resource
Suite Setup       Reset Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Test sudo enable
    [Documentation]    Test the SULKA_SERVICEUSER_ENABLE_SUDO configuration
    [Tags]             configuration
    [Setup]            Run Keywords
    ...    Add Common Build Configuration
    ...    AND    Add Common User Configuration    enable_sudo=${False}

    Build Sulka Image    ${FULL_CONFIG}

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Open Default SSH Connection
    ${output}=    Write Sudo SSH    sudo ls /    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Contain    ${output.lower()}    serviceuser is not in the sudoers file
    Stop QEMU    ${handle}

    Add Sulka Configuration    SULKA_SERVICEUSER_ENABLE_SUDO = "1"

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

    Add Sulka Configuration    SULKA_ENABLE_READ_ONLY_ROOTFS = "0"
    Add Sulka Configuration    IMAGE_FSTYPES:append = " ext4"
    Add Sulka Configuration    QB_DEFAULT_FSTYPE = "ext4"

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

    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD = "\$y\$jCT\$seWjSFPPf4lsQL74hWMWG1$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=False
    Should Contain    ${result.stdout}${result.stderr}    contains unescaped dollar signs

    # No need to reset configuration, last assignment takes precedence
    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD = ""
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=True

    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD = "\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=True

    [Teardown]    Reset Sulka Configuration

Test Mount Hardening
    [Documentation]    Test the SULKA_HARDEN_MOUNTS configuration by inspecting the base-files fstab
    ...                staged on the host and systemd's tmp.mount unit in the built image root file
    ...                system, without booting QEMU.
    [Tags]             configuration
    [Setup]            Add Common Build Configuration

    # /tmp is a mount of its own only under systemd, where tmp.mount rather than the fstab carries
    # its options. On sysvinit /tmp is a symlink into /var/volatile and the fstab checks cover it.
    ${sysvinit}=    Global Build Configuration Contains    INIT_MANAGER    sysvinit

    ${fstab_file}=    Get Base Files Fstab Path    ${FULL_CONFIG}
    IF    not ${sysvinit}
        ${tmp_mount_file}=    Get Tmp Mount Unit Path    ${FULL_CONFIG}
    END

    Add Sulka Configuration    SULKA_HARDEN_MOUNTS = "1"
    Clean Sulka Recipe    base-files    ${FULL_CONFIG}
    Build Sulka Image    ${FULL_CONFIG}
    ${fstab}=    OperatingSystem.Get File    ${fstab_file}
    Fstab Should Contain Mount    ${fstab}    proc     /proc            proc     hidepid=2
    Fstab Should Contain Mount    ${fstab}    tmpfs    /run             tmpfs    mode=0755,nodev,nosuid,noexec,strictatime
    Fstab Should Contain Mount    ${fstab}    tmpfs    /var/volatile    tmpfs    nodev,nosuid,noexec,rootcontext=system_u:object_r:var_t:s0
    IF    not ${sysvinit}
        ${options}=    Get Expected Value    tmp_mount_options_hardened
        Tmp Mount Should Have Options    ${tmp_mount_file}    ${options}
    END

    Add Sulka Configuration    SULKA_HARDEN_MOUNTS = "0"
    Clean Sulka Recipe    base-files    ${FULL_CONFIG}
    Build Sulka Image    ${FULL_CONFIG}
    ${fstab}=    OperatingSystem.Get File    ${fstab_file}
    Fstab Should Contain Mount    ${fstab}    proc     /proc            proc     defaults
    Fstab Should Contain Mount    ${fstab}    tmpfs    /run             tmpfs    mode=0755,nodev,nosuid,strictatime
    Fstab Should Contain Mount    ${fstab}    tmpfs    /var/volatile    tmpfs    defaults,rootcontext=system_u:object_r:var_t:s0
    IF    not ${sysvinit}
        ${options}=    Get Expected Value    tmp_mount_options_default
        Tmp Mount Should Have Options    ${tmp_mount_file}    ${options}
    END

    [Teardown]    Reset Sulka Configuration

*** Keywords ***
Get Base Files Fstab Path
    [Documentation]    Return the path of the fstab staged by the base-files recipe on the host. The
    ...                staging directory carries the machine, distro and recipe version in its name, so
    ...                it is read from bitbake rather than spelled out here.
    [Arguments]    ${configuration}
    ${pkgdest}=    Get Bitbake Variable    PKGDEST    ${configuration}    recipe=base-files
    RETURN    ${pkgdest}/base-files/etc/fstab

Get Tmp Mount Unit Path
    [Documentation]    Return the path of systemd's tmp.mount unit in the image root file system built
    ...                on the host. Both the root file system location and the unit directory are read
    ...                from bitbake, as they depend on the machine, distro and image in use.
    [Arguments]    ${configuration}
    ${rootfs}=    Get Bitbake Variable    IMAGE_ROOTFS    ${configuration}    recipe=core-image-base
    ${unitdir}=    Get Bitbake Variable    systemd_system_unitdir    ${configuration}    recipe=core-image-base
    RETURN    ${rootfs}${unitdir}/tmp.mount

Fstab Should Contain Mount
    [Documentation]    Fail unless ${fstab} contains a line for the given mount point with exactly
    ...                the expected options. Field separators match arbitrary whitespace and the
    ...                dump/pass columns are pinned to "0 0".
    [Arguments]    ${fstab}    ${device}    ${mountpoint}    ${type}    ${options}
    Should Match Regexp    ${fstab}    (?m)^${device}\\s+${mountpoint}\\s+${type}\\s+${options}\\s+0\\s+0\\s*$

Tmp Mount Should Have Options
    [Documentation]    Fail unless the systemd tmp.mount unit at ${path} has exactly the expected
    ...                options.
    [Arguments]    ${path}    ${options}
    ${unit}=    OperatingSystem.Get File    ${path}
    Should Contain    ${unit}    \nOptions=${options}\n    Unexpected mount options in tmp.mount
