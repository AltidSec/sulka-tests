*** Settings ***
Documentation    Version-specific expected values selected by ${KAS_SULKA_BRANCH}.

*** Variables ***
&{SCARTHGAP_EXPECTED}
...    lynis_suggestions_sysvinit=Suggestions (18):
...    lynis_warnings_sysvinit=Warnings (1):
...    lynis_suggestions_default=Suggestions (14):
...    lynis_warnings_default=Great, no warnings
...    oscap_fail_count=2
...    kernel_hardening=[+] Config check is finished: 'OK' - 300 / 'FAIL' - 52
...    tmp_mount_options_hardened=mode=1777,strictatime,nosuid,nodev,noexec,size=50%%,nr_inodes=1m
...    tmp_mount_options_default=mode=1777,strictatime,nosuid,nodev,size=50%%,nr_inodes=1m
&{WRYNOSE_EXPECTED}
...    lynis_suggestions_sysvinit=Suggestions (17):
...    lynis_warnings_sysvinit=Warnings (1):
...    lynis_suggestions_default=Suggestions (16):
...    lynis_warnings_default=Great, no warnings
...    oscap_fail_count=2
...    kernel_hardening=[+] Config check is finished: 'OK' - 317 / 'FAIL' - 35
...    tmp_mount_options_hardened=mode=1777,strictatime,nosuid,nodev,noexec,size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota
...    tmp_mount_options_default=mode=1777,strictatime,nosuid,nodev,size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

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
