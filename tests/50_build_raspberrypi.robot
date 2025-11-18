*** Settings ***
Documentation     Test Sulka build
Library           OperatingSystem
Resource          ../resources/git.resource
Resource          ../resources/kas.resource
Suite Setup       Clone Repository    scarthgap    https://codeberg.org/AltidSec/kas-sulka-raspberrypi-example.git    checkout_dir=workspace-rpi
Suite Teardown    Reset Sulka Configuration    cwd=workspace-rpi

*** Test Cases ***
Test Raspberry Pi Build
    [Documentation]    Clone git repo and run kas build for Raspberry Pi
    [Tags]             bitbake    build

    Remove Directory    workspace-rpi/build    recursive=True

    Build Sulka Image    kas-sulka.yml:kas-sulka-raspberrypi.yml    cwd=workspace-rpi
