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

Launch Image With QEMU
    [Arguments]    ${configuration}
    ${result}=    Run Process    kas    shell    ${configuration}    -c    "runqemu nographic"    cwd=${TEMP_DIR}
    Sleep    60s
