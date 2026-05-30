*** Settings ***
Documentation    Keywords for git
Library          OperatingSystem
Library          Process

*** Keywords ***
Clone Repository If Needed
    [Arguments]    ${branch}    ${url}    ${checkout_dir}=${TEMP_DIR}
    ${exists}=    Run Keyword And Return Status    Directory Should Exist    ${checkout_dir}/.git
    IF    not ${exists}
        ${result}=    Run Process    git    clone    -b    ${branch}    ${url}    ${checkout_dir}
    END
