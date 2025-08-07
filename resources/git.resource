*** Settings ***
Documentation    Keywords for git
Library          Process

*** Variables ***
${GIT_REPO_URL}     https://codeberg.org/AltidSec/kas-sulka.git
${GIT_BRANCH}       scarthgap

*** Keywords ***
Clone Repository
    [Arguments]    ${branch}    ${url}
    ${result}=    Run Process    git    clone    -b    ${GIT_BRANCH}    ${GIT_REPO_URL}    ${TEMP_DIR}
