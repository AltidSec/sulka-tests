*** Settings ***
Documentation    Check That Filesystem Content Is Expected
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Files
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    # syslog-ng should exist but awk related files should be removed
    Remote File Should Exist        /usr/sbin/syslog-ng
    Remote File Should Not Exist    /usr/sbin/syslog-ng-debun
    Remote File Should Not Exist    /usr/share/syslog-ng/include/scl/syslogconf

    [Teardown]    Stop QEMU    ${handle}

*** Keywords ***
Remote File Should Exist
    [Arguments]    ${path}
    ${output}=    Write SSH    ls ${path}
    Should Be Equal As Strings    ${output.strip()}    ${path}

Remote File Should Not Exist
    [Arguments]    ${path}
    ${output}=    Write SSH    ls ${path}
    Should Contain    ${output}    No such file or directory
