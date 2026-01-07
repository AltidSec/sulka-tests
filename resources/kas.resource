*** Settings ***
Documentation    Keywords for building with kas
Library          Process
Library          OperatingSystem
Library          String
*** Variables ***
${SULKA_SERVICEUSER_USERNAME}        serviceuser
${SULKA_SERVICEUSER_OLD_PASSWORD}    test
${SULKA_SERVICEUSER_NEW_PASSWORD}    Sulka-5ecure-Distro

*** Keywords ***
Add Sulka Configuration
    [Arguments]    ${configuration}    ${cwd}=${TEMP_DIR}
    Append To File    ${cwd}/kas-sulka-configuration.yml    \ \ \ \ ${configuration}\n

Reset Sulka Configuration
    [Arguments]    ${cwd}=${TEMP_DIR}
    Run Process    git    checkout    kas-sulka-configuration.yml    cwd=${cwd}

Add Common Build Configuration
    [Arguments]    ${cwd}=${TEMP_DIR}
    ${use_global_dl}=    Get Variable Value    ${ENABLE_GLOBAL_DL_DIR}    0
    Run Keyword If    ${use_global_dl} == 1
    ...    Add Sulka Configuration    DL_DIR="/oe/downloads"    cwd=${cwd}
    ...    ELSE
    ...    Add Sulka Configuration    DL_DIR="${CURDIR}/../downloads"    cwd=${cwd}

    ${use_global_sstate}=    Get Variable Value    ${ENABLE_GLOBAL_SSTATE_DIR}    0
    Run Keyword If    ${use_global_sstate} == 1
    ...    Add Sulka Configuration    SSTATE_DIR="/oe/sstate-cache"    cwd=${cwd}
    ...    ELSE
    ...    Add Sulka Configuration    SSTATE_DIR="${CURDIR}/../sstate-cache"    cwd=${cwd}

    # Process GLOBAL_BUILD_CONFIG if it exists and contains values
    ${global_config}=    Get Variable Value    ${GLOBAL_BUILD_CONFIG}    ${EMPTY}
    Return From Keyword If    '${global_config}' == ''
    
    @{config_items}=    Split String    ${global_config}
    FOR    ${item}    IN    @{config_items}
        Add Sulka Configuration    ${item}    cwd=${cwd}
    END

Add Common User Configuration
    [Arguments]    ${cwd}=${TEMP_DIR}
    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"    cwd=${cwd}
    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."    cwd=${cwd}
    Add Sulka Configuration    SULKA_SSH_KEYS_DIR="${CURDIR}/../auth-keys/"    cwd=${cwd}
    Add Sulka Configuration    SULKA_SERVICEUSER_ENABLE_SUDO="1"    cwd=${cwd}

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
    ${handle}=    Start Process    kas    shell    ${configuration}    -c    runqemu nographic slirp qemuparams\=\"-m 1024\"    cwd=${TEMP_DIR}    stdout=kas_stdout.log    stderr=kas_stderr.log
    Sleep    280s
    RETURN    ${handle}

Stop QEMU
    [Arguments]    ${handle}
    Terminate Process    ${handle}
    Wait For Process    ${handle}    timeout=10s
