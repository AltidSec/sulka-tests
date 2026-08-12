*** Settings ***
Documentation    Check That Filesystem Content Is Expected
Library          String
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

Check Mount Options
    [Documentation]    Verify that the hardened mount options are in effect on the running system.
    ...                This is the runtime counterpart of Test Mount Hardening in
    ...                08_build_configurations.robot
    ${sysvinit}=    Global Build Configuration Contains    INIT_MANAGER    sysvinit

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection
    ${mounts}=    Execute Command    cat /proc/self/mounts

    Mount Should Hide Other Users Processes    ${mounts}    /proc
    Mount Should Be Hardened    ${mounts}    /run
    Mount Should Be Hardened    ${mounts}    /var/volatile
    Mount Should Be Hardened    ${mounts}    /var/lib

    IF    not ${sysvinit}
        Mount Should Be Hardened    ${mounts}    /tmp
        Mount Should Be Hardened    ${mounts}    /var/cache
    END

    [Teardown]    Stop QEMU    ${handle}

*** Keywords ***
Get Mount Options
    [Documentation]    Return the option field of ${mountpoint} from the given /proc/self/mounts content.
    [Arguments]    ${mounts}    ${mountpoint}
    @{fields}=    Get Regexp Matches    ${mounts}    (?m)^\\S+\\s+${mountpoint}\\s+\\S+\\s+(\\S+)\\s+\\d+\\s+\\d+$    1
    Length Should Be    ${fields}    1    ${mountpoint} is not a mount point of its own:\n${mounts}
    RETURN    ${fields}[0]

Mount Option Should Be Set
    [Documentation]    Fail unless the mount options of ${mountpoint} contain a field matching the
    ...                regexp ${option}.
    [Arguments]    ${mounts}    ${mountpoint}    ${option}
    ${options}=    Get Mount Options    ${mounts}    ${mountpoint}
    Should Match Regexp    ${options}    (^|,)(${option})($|,)
    ...    ${mountpoint} is mounted with ${options}, expected an option matching ${option}

Mount Should Be Hardened
    [Documentation]    Fail unless ${mountpoint} is mounted nodev, nosuid and noexec.
    [Arguments]    ${mounts}    ${mountpoint}
    Mount Option Should Be Set    ${mounts}    ${mountpoint}    nodev
    Mount Option Should Be Set    ${mounts}    ${mountpoint}    nosuid
    Mount Option Should Be Set    ${mounts}    ${mountpoint}    noexec

Mount Should Hide Other Users Processes
    [Documentation]    Fail unless ${mountpoint} is mounted with hidepid=2 or hidepid=invisble
    [Arguments]    ${mounts}    ${mountpoint}
    Mount Option Should Be Set    ${mounts}    ${mountpoint}    hidepid=(2|invisible)

Remote File Should Exist
    [Arguments]    ${path}
    ${output}=    Execute Command    ls ${path}
    Should Be Equal As Strings    ${output.strip()}    ${path}
    Sleep    1 Seconds

Remote File Should Not Exist
    [Arguments]    ${path}
    ${output}    ${error}=    Execute Command    ls ${path}    return_stderr=True
    Should Be Equal As Strings    ${error}    ls: cannot access '${path}': No such file or directory
    Sleep    1 Seconds
