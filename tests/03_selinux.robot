*** Settings ***
Documentation    Run SELinux checks on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Enforcing
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    ${output}=    Write Sudo SSH    sudo getenforce    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Should Be Equal As Strings    Enforcing    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}

Check Access Failures
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    # Wait a moment for possible access failures that do not appear immediately
    Sleep    5 minutes

    Open Default SSH Connection
 
    ${output}=    Write Sudo SSH    sudo cat /var/log/messages | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Validate AVC Output    ${output.strip()}
    ${output}=    Write Sudo SSH    sudo cat /var/log/audit/audit.log | grep -i avc    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Validate AVC Output    ${output.strip()}

    [Teardown]    Stop QEMU    ${handle}

*** Keywords ***
Validate AVC Output
    [Arguments]    ${stripped_output}
    ${length}=    Get Length    ${stripped_output}
    Return From Keyword If    ${length} == 0

    @{expected_patterns}=    Create List
    ...    .*denied.*write.*scontext=system_u:system_r:syslogd_t:s0.*tcontext=system_u:object_r:root_t:s0
    ...    .*denied.*net_admin.*comm="syslog-ng".*scontext=system_u:system_r:syslogd_t:s0.*tcontext=system_u:system_r:syslogd_t:s0

    @{lines}=    Split To Lines    ${stripped_output}
    FOR    ${line}    IN    @{lines}
        ${is_expected}=    Line Matches Any Pattern    ${line}    ${expected_patterns}
        Should Be True    ${is_expected}    Unexpected AVC denial: ${line}
    END

Line Matches Any Pattern
    [Arguments]    ${line}    ${patterns}
    FOR    ${pattern}    IN    @{patterns}
        ${matches}=    Run Keyword And Return Status    Should Match Regexp    ${line}    ${pattern}
        Return From Keyword If    ${matches}    ${True}
    END
    RETURN    ${False}
