*** Settings ***
Documentation    Test Sulka Raspberry Pi build
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Suite Setup      Run Keywords
...    Clone Repository If Needed    ${KAS_SULKA_BRANCH}    https://codeberg.org/AltidSec/kas-sulka-raspberrypi-example.git    checkout_dir=workspace-rpi
...    AND    Add Common Build Configuration    cwd=workspace-rpi
Suite Teardown    Reset Sulka Configuration     cwd=workspace-rpi

*** Test Cases ***
Test Raspberry Pi Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    workspace-rpi/build    recursive=True

    Build Sulka Image    ${FULL_CONFIG}:kas-sulka-raspberrypi.yml    cwd=workspace-rpi
