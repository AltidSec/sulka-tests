*** Settings ***
Documentation    Test Sulka build
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Suite Setup      Run Keywords
...    Clone Repository    ${KAS_SULKA_BRANCH}    https://codeberg.org/AltidSec/kas-sulka.git
...    AND    Add Common Build Configuration
Suite Teardown    Reset Sulka Configuration

*** Variables ***
${KAS_SULKA_BRANCH}    scarthgap

*** Test Cases ***
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
    [Setup]            Add Sulka Configuration    FIRST_BOOT_RELABEL = "1"

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Build Sulka Image    ${CORE_CONFIG}    expect_success=False

    [Teardown]    Reset Sulka Configuration
