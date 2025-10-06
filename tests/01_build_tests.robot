*** Settings ***
Documentation    Test Sulka build
Library          OperatingSystem
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Suite Setup      Run Keywords
...    Clone Repository    scarthgap    https://codeberg.org/AltidSec/kas-sulka.git
...    AND    Add Sulka Configuration    DL_DIR="${CURDIR}/../${TEMP_DIR}/downloads"
...    AND    Add Sulka Configuration    SSTATE_DIR="${CURDIR}/../${TEMP_DIR}/sstate-cache"
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Test Sulka Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Build Sulka Image    kas-sulka.yml

Test Full Sulka Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}/build    recursive=True

    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
