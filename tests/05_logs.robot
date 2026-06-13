*** Settings ***
Documentation    Check Logs For Errors And Warnings
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Resource         ../resources/validation.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Check Logs For Errors And Warnings
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection

    ${global_config}=    Get Variable Value    ${GLOBAL_BUILD_CONFIG}    ${EMPTY}
    IF    'INIT_MANAGER="sysvinit"' in $global_config
        @{allowed}=    Create List
        ...    .*ACPI: _OSC evaluation for CPUs failed, trying _PDC
        ${output}=    Write Sudo SSH    sudo grep -iE 'warn|error|fail' /var/log/syslog    ${SULKA_SERVICEUSER_OLD_PASSWORD}
        Validate Output Against Allowlist    ${output.strip()}    ${allowed}    warn/error lines in /var/log/messages
    ELSE
        @{allowed}=    Create List
        ...    .*ACPI: _OSC evaluation for CPUs failed, trying _PDC
        ...    .*systemd-tmpfiles.*: Failed to create directory or subvolume "/root/.ssh", ignoring: Read-only file system
        ...    .*audit: CONFIG_CHANGE op=set audit_failure=1 old=1 auid=[0-9]+ ses=[0-9]+ subj=system_u:system_r:auditctl_t:s0 res=1
        ...    .*auditctl.*: failure 1
        ...    .*syslog-ng.*: syslog-ng: Unable to write to current directory, core dumps will not be generated; dir='/', error='Read-only file system'
        ...    .*syslog-ng.*: .*WARNING: Configuration file format is too old, syslog-ng is running in compatibility mode.*
        ...    .*syslog-ng.*: .*WARNING: Your configuration file uses an obsoleted keyword, please update your configuration; keyword='stats_freq'.*
        ...    .*pam_warn.systemd-user:setcred.:.*user=.serviceuser.*
        ${output}=    Write Sudo SSH    sudo journalctl -b --no-pager -q | grep -iE 'warn|error'    ${SULKA_SERVICEUSER_OLD_PASSWORD}
        Validate Output Against Allowlist    ${output.strip()}    ${allowed}    warn/error lines in journal

        @{allowed}=    Create List
        ...    .*tsc: Unable to calibrate against PIT
        ...    .*mtrr: your CPUs had inconsistent (fixed MTRR|variable MTRR|MTRRdefType) settings
        ...    .*systemd-sysctl.*Couldn't write '[0-9]+' to '(kernel\/sysrq|kernel\/core_uses_pid)', ignoring: No such file or directory
        ...    .*kauditd_printk_skb: [0-9]+ callbacks suppressed
        ...    .*nftables input dropped: IN=(enp0s2|eth0) OUT= MAC=.* SRC=.* DST=.* PROTO=(UDP|ICMPv6) .*
        ...    .*IPv4: martian source 255.255.255.255 from 10.0.2.2, on dev (enp0s2|eth0)
        ...    .*ll header: 00000000: ff ff ff ff ff ff .*
        ...    .*PAM unable to dlopen.*pam_lastlog.*cannot open shared object file: No such file or directory
        ...    .*PAM adding faulty module: /usr/lib/security/pam_lastlog.so
        ${output}=    Write Sudo SSH    sudo journalctl -p warning -b --no-pager -q    ${SULKA_SERVICEUSER_OLD_PASSWORD}
        Validate Output Against Allowlist    ${output.strip()}    ${allowed}    warning+ priority entries in journal
    END

    @{allowed}=    Create List
    ...    .*ACPI: _OSC evaluation for CPUs failed, trying _PDC
    ...    .*tsc: Fast TSC calibration failed
    ${output}=    Write Sudo SSH    sudo dmesg | grep -iE 'warn|error|fail'    ${SULKA_SERVICEUSER_OLD_PASSWORD}
    Validate Output Against Allowlist    ${output.strip()}    ${allowed}    warn/error lines in dmesg

    [Teardown]    Stop QEMU    ${handle}

Check The System Date Gets Updated
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection
    ${output}=    Execute Command    date +%Y
    # We cannot know the exact date and guarantee that the test device
    # has network access for time, but if year is smaller than 2015
    # the initial time setup has failed
    Should Be True    ${output}>2015

    [Teardown]    Stop QEMU    ${handle}
