*** Settings ***
Documentation    Keywords for building with kas
Library          Process
Library          OperatingSystem

*** Keywords ***
Add Sulka Configuration
    [Arguments]    ${configuration}
    Append To File    ${TEMP_DIR}/kas-sulka-configuration.yml    \ \ \ \ ${configuration}\n

Reset Sulka Configuration
    Run Process    git    checkout    kas-sulka-configuration.yml    cwd=${TEMP_DIR}

Add Common Build Configuration
    Add Sulka Configuration    DL_DIR="${CURDIR}/../${TEMP_DIR}/downloads"
    Add Sulka Configuration    SSTATE_DIR="${CURDIR}/../${TEMP_DIR}/sstate-cache"

Add Common User Configuration
    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"
    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
    Add Sulka Configuration    SULKA_SSH_KEYS_DIR="${CURDIR}/../auth-keys/"
    Enable Sudo

Enable Sudo
    Append To File    ${TEMP_DIR}/meta-sulka-distro/recipes-extended/sudo/files/serviceuser.conf    Defaults:serviceuser secure_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin", timestamp_timeout=0\n
    Append To File    ${TEMP_DIR}/meta-sulka-distro/recipes-extended/sudo/files/serviceuser.conf    serviceuser ALL=(ALL:ALL) ALL\n

Build Sulka Image
    [Arguments]    ${configuration}
    Log    Starting build...
    ${result}=    Run Process    kas    build    ${configuration}    cwd=${TEMP_DIR}    timeout=3h 30m    stdout=kas_stdout.log    stderr=kas_stderr.log
    Log    Return code: ${result.rc}
    Should Be Equal As Integers    ${result.rc}    0    Build failed
    RETURN    ${result}

Reset Sulka Image
    [Arguments]    ${configuration}
    ${result}=    Run Process    kas    shell    ${configuration}    -c    bitbake -c cleanall core-image-base    cwd=${TEMP_DIR}    timeout=5m    stdout=kas_stdout.log    stderr=kas_stderr.log

Launch Image With QEMU
    [Arguments]    ${configuration}
    ${handle}=    Start Process    kas    shell    ${configuration}    -c    runqemu nographic slirp    cwd=${TEMP_DIR}    stdout=kas_stdout.log    stderr=kas_stderr.log
    Sleep    240s
    RETURN    ${handle}

Stop QEMU
    [Arguments]    ${handle}
    Terminate Process    ${handle}
    Wait For Process    ${handle}    timeout=10s
