*** Settings ***
Documentation    Keywords for git
Library          Process

*** Keywords ***
Clone Repository
    [Arguments]    ${branch}    ${url}
    ${result}=    Run Process    git    clone    -b    ${branch}    ${url}    ${TEMP_DIR}
