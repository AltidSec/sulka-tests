*** Settings ***
Documentation    Helpers for validating command output against regexp allowlists
Library          String
Library          Collections

*** Keywords ***
Line Matches Any Pattern
    [Documentation]    Return True if ${line} matches at least one regexp in ${patterns}, else False.
    [Arguments]    ${line}    ${patterns}
    FOR    ${pattern}    IN    @{patterns}
        ${matches}=    Run Keyword And Return Status    Should Match Regexp    ${line}    ${pattern}
        IF    ${matches}    RETURN    ${True}
    END
    RETURN    ${False}

Validate Output Against Allowlist
    [Documentation]    Fail unless every line of ${output} matches one of the allowed regexps in
    ...                ${allowed_patterns}. All unexpected lines are collected and reported together.
    ...                ${description} is interpolated into the failure message. Empty output passes.
    [Arguments]    ${output}    ${allowed_patterns}    ${description}=lines
    @{unexpected}=    Create List
    @{lines}=    Split To Lines    ${output}
    FOR    ${line}    IN    @{lines}
        ${is_expected}=    Line Matches Any Pattern    ${line}    ${allowed_patterns}
        IF    not ${is_expected}    Append To List    ${unexpected}    ${line}
    END
    ${report}=    Catenate    SEPARATOR=\n    @{unexpected}
    Should Be Empty    ${unexpected}    Unexpected ${description}:\n${report}
