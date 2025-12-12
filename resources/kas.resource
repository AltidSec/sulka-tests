*** Settings ***
Documentation    Keywords for building with kas
Library          Process
Library          OperatingSystem

*** Variables ***
${SULKA_SERVICEUSER_USERNAME}        serviceuser
${SULKA_SERVICEUSER_OLD_PASSWORD}    test
${SULKA_SERVICEUSER_NEW_PASSWORD}    Sulka-5ecure-Distro

*** Keywords ***
Add Sulka Configuration
    [Arguments]    ${configuration}
    Append To File    ${TEMP_DIR}/kas-sulka-configuration.yml    \ \ \ \ ${configuration}\n

Reset Sulka Configuration
    [Arguments]    ${cwd}=${TEMP_DIR}
    Run Process    git    checkout    kas-sulka-configuration.yml    cwd=${cwd}

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
    [Arguments]    ${configuration}    ${cwd}=${TEMP_DIR}    ${expect_success}=True
    Log    Starting build...
    ${result}=    Run Process    kas    build    ${configuration}    cwd=${cwd}    timeout=3h 30m    stdout=kas_stdout.log    stderr=kas_stderr.log
    Log    Return code: ${result.rc}
    IF    ${expect_success}
        Should Be Equal As Integers    ${result.rc}    0    Build failed
    ELSE
        Should Not Be Equal As Integers    ${result.rc}    0    Build was expected to fail but succeeded
    END

    RETURN    ${result}

Reset Sulka Image
    [Arguments]    ${configuration}
    ${result}=    Run Process    kas    shell    ${configuration}    -c    bitbake -c cleanall core-image-base    cwd=${TEMP_DIR}    timeout=5m    stdout=kas_stdout.log    stderr=kas_stderr.log

Launch Image With QEMU
    [Arguments]    ${configuration}
    ${handle}=    Start Process    kas    shell    ${configuration}    -c    runqemu nographic slirp    cwd=${TEMP_DIR}    stdout=kas_stdout.log    stderr=kas_stderr.log
    Sleep    280s
    RETURN    ${handle}

Stop QEMU
    [Arguments]    ${handle}
    Terminate Process    ${handle}
    Wait For Process    ${handle}    timeout=10s
