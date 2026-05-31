*** Settings ***
Documentation    Version-specific expected values selected by ${KAS_SULKA_BRANCH}.

*** Variables ***
&{SCARTHGAP_EXPECTED}
...    lynis_suggestions_sysvinit=Suggestions (18):
...    lynis_suggestions_default=Suggestions (16):
...    oscap_fail_count=2
...    kernel_hardening=[+] Config check is finished: 'OK' - 269 / 'FAIL' - 34
&{WRYNOSE_EXPECTED}
...    lynis_suggestions_sysvinit=Suggestions (18):
...    lynis_suggestions_default=Suggestions (16):
...    oscap_fail_count=2
...    kernel_hardening=[+] Config check is finished: 'OK' - 269 / 'FAIL' - 34

*** Keywords ***
Get Expected Value
    [Documentation]    Return the ${key} expected value for the current ${KAS_SULKA_BRANCH}.
    [Arguments]    ${key}
    ${branch}=    Get Variable Value    ${KAS_SULKA_BRANCH}    ${EMPTY}
    IF    'scarthgap' in '${branch}'
        ${values}=    Set Variable    ${SCARTHGAP_EXPECTED}
    ELSE IF    'wrynose' in '${branch}'
        ${values}=    Set Variable    ${WRYNOSE_EXPECTED}
    ELSE
        Fail    No version-specific expected values defined for KAS_SULKA_BRANCH '${branch}'
    END
    RETURN    ${values}[${key}]
