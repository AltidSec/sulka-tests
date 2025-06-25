*** Settings ***
Documentation    Test Sulka build
Library          Process
Library          OperatingSystem

*** Variables ***
${GIT_REPO_URL}     https://codeberg.org/AltidSec/kas-sulka.git
${GIT_BRANCH}       scarthgap
${TEMP_DIR}         workspace

*** Test Cases ***
Test Sulka Build
    [Documentation]    Clone git repo and run kas build
    [Tags]             bitbake    build

    Remove Directory    ${TEMP_DIR}    recursive=True
    Create Directory    ${TEMP_DIR}

    ${result}=    Run Process    git    clone    -b    ${GIT_BRANCH}    ${GIT_REPO_URL}    ${TEMP_DIR}
    Should Be Equal As Integers    ${result.rc}    0    Failed to clone repository
    Log    Repository cloned successfully

    Log    Starting build...
    ${result}=    Run Process    kas    build    kas-sulka.yml    cwd=${TEMP_DIR}    timeout=3h 30m    stdout=kas_stdout.log    stderr=kas_stderr.log

    Log    Return code: ${result.rc}

    Should Be Equal As Integers    ${result.rc}    0    Build failed
