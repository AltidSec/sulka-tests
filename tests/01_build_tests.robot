*** Settings ***
Documentation    Test Sulka build
Library          OperatingSystem
Library          DateTime
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Suite Setup      Add Common Build Configuration
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Test Build Environment
    [Documentation]    Check the build env for expected values
    [Tags]             bitbake    build

    ${timestamp}=    Get Current Date    result_format=epoch
    Run Process    kas    checkout    ${CORE_CONFIG}    cwd=${TEMP_DIR}    timeout=2h    stdout=kas_stdout_checkout_${timestamp}.log    stderr=kas_stderr_checkout_${timestamp}.log
    Run Process    kas    shell    ${CORE_CONFIG}    -c    bitbake -e core-image-base    cwd=${TEMP_DIR}    timeout=3m    stdout=kas_stdout_${timestamp}.log    stderr=kas_stderr_${timestamp}.log

    # Check distro features
    ${result}=    Run Process    grep    kas_stdout_${timestamp}.log    -e    ^DISTRO_FEATURES\=.*security    cwd=${TEMP_DIR}
    Should Be Equal As Integers    ${result.rc}    0
    ${result}=    Run Process    grep    kas_stdout_${timestamp}.log    -e    ^DISTRO_FEATURES\=.*integrity    cwd=${TEMP_DIR}
    Should Be Equal As Integers    ${result.rc}    0

    Sleep    5 Seconds

Test Sulka Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Build Sulka Image    ${CORE_CONFIG}

Test Full Sulka Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Build Sulka Image    ${FULL_CONFIG}

Test Non GPLv3 Sulka Build
    [Documentation]    Ensure that the default build does not contain GPLv3 licensed code
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Add Sulka Configuration    INCOMPATIBLE_LICENSE:pn-core-image-base = "GPL-3.0* LGPL-3.0*"

    # The development image contains GPLv3 licensed code, so use it as a sanity check
    Build Sulka Image    ${DEVEL_CONFIG}    expect_success=False
    Build Sulka Image    ${CORE_CONFIG}

    [Teardown]    Reset Sulka Configuration

Test FIRST_BOOT_RELABEL Fails
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build
    [Setup]            Add Common Build Configuration

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Add Sulka Configuration    FIRST_BOOT_RELABEL = "1"

    Build Sulka Image    ${CORE_CONFIG}    expect_success=False

    [Teardown]    Reset Sulka Configuration
