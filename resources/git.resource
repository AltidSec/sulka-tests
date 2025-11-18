*** Settings ***
Documentation    Keywords for git
Library          Process

*** Keywords ***
Clone Repository
    [Arguments]    ${branch}    ${url}    ${checkout_dir}=${TEMP_DIR}
    ${result}=    Run Process    git    clone    -b    ${branch}    ${url}    ${checkout_dir}
