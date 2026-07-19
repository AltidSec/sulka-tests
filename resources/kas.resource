*** Settings ***
Documentation    Keywords for building with kas
Library          Process
Library          OperatingSystem
Library          String
Library          DateTime
Library          SSHLibrary
Resource         validation.resource

*** Variables ***
${SULKA_SERVICEUSER_USERNAME}        serviceuser
${SULKA_SERVICEUSER_OLD_PASSWORD}    test
${SULKA_SERVICEUSER_NEW_PASSWORD}    Sulka-5ecure-Distro
${MODSIGN_CA_PASSPHRASE}             1234
${GLOBAL_BUILD_CONFIG_DELIMITER}     ;;
@{ALLOWED_BUILD_WARNINGS}
...    WARNING: .* do_fetch: Failed to fetch URL .*, attempting MIRRORS if available
...    WARNING: .* do_sbom_cve_check: .* Found unpatched CVEs
...    WARNING: .* do_cve_check: Found unpatched CVE
...    WARNING: SULKA_DEVELOPMENT_MODE is enabled. This is not recommended for production builds.
...    WARNING: .* CVE_CHECK_IGNORE is deprecated in favor of CVE_STATUS
...    WARNING: linux-yocto-6.6.142.*git-r.* do_kernel_configcheck: .*: This BSP contains fragments with warnings:

*** Keywords ***
Add Sulka Configuration
    [Arguments]    ${configuration}    ${cwd}=${TEMP_DIR}
    Append To File    ${cwd}/kas-sulka-configuration.yml    \ \ \ \ ${configuration}\n

Reset Sulka Configuration
    [Arguments]    ${cwd}=${TEMP_DIR}
    Run Process    git    checkout    kas-sulka-configuration.yml    cwd=${cwd}

Generate Module Signing Keys
    [Documentation]    Generate the mandatory IMA/EVM/module-signing keys into ${key_dir} (repo-root
    ...                modsign-keys by default) with the generator script in the kas-sulka checkout at
    ...                ${cwd}; idempotent. Run under a pty via `script`, feeding ${MODSIGN_CA_PASSPHRASE}
    ...                on stdin for the CA prompts (that passphrase is never needed at build time).
    [Arguments]    ${cwd}=${TEMP_DIR}    ${key_dir}=${CURDIR}/../modsign-keys
    ${key_dir}=    Normalize Path    ${key_dir}
    ${exists}=    Run Keyword And Return Status    OperatingSystem.File Should Exist    ${key_dir}/ima-local-ca.pem
    IF    ${exists}    RETURN
    Create Directory    ${key_dir}
    ${script}=    Normalize Path    ${CURDIR}/../${cwd}/scripts/generate_ima_evm_modsign_keys.sh
    ${passphrase_lines}=    Evaluate    ('${MODSIGN_CA_PASSPHRASE}\\n' * 4)
    ${result}=    Run Process    printf '%s' "\${PASS}" | script -qec '${script}' /dev/null
    ...    cwd=${key_dir}    shell=True    env:PASS=${passphrase_lines}
    Should Be Equal As Integers    ${result.rc}    0    Module signing key generation failed:\n${result.stdout}\n${result.stderr}

Get Global Build Configuration Entries
    [Documentation]    Return ${GLOBAL_BUILD_CONFIG} as a list of local.conf entries. Entries are
    ...                separated by ${GLOBAL_BUILD_CONFIG_DELIMITER}
    ${global_config}=    Get Variable Value    ${GLOBAL_BUILD_CONFIG}    ${EMPTY}
    @{items}=    Split String    ${global_config}    ${GLOBAL_BUILD_CONFIG_DELIMITER}
    @{entries}=    Create List
    FOR    ${item}    IN    @{items}
        ${entry}=    Strip String    ${item}
        IF    $entry != ''    Append To List    ${entries}    ${entry}
    END
    RETURN    @{entries}

Global Build Configuration Contains
    [Documentation]    Return True when ${GLOBAL_BUILD_CONFIG} assigns ${value} to ${variable}.
    [Arguments]    ${variable}    ${value}
    ${pattern}=    Evaluate
    ...    re.escape($variable) + r'\\s*[?:+.=]+\\s*"?' + re.escape($value) + '"?'    modules=re
    @{entries}=    Get Global Build Configuration Entries
    FOR    ${entry}    IN    @{entries}
        ${match}=    Evaluate    bool(re.fullmatch($pattern, $entry))    modules=re
        IF    ${match}    RETURN    ${True}
    END
    RETURN    ${False}

Add Common Build Configuration
    [Documentation]    Append the default DL_DIR and SSTATE_DIR entries to the Sulka build config,
    ...                plus any extra entries listed in ${GLOBAL_BUILD_CONFIG}. The DL_DIR and
    ...                SSTATE_DIR paths point to /oe/* when ${ENABLE_GLOBAL_DL_DIR} / ${ENABLE_GLOBAL_SSTATE_DIR}
    ...                are "1" (shared host caches) and to per-checkout paths otherwise.
    ...                Also sets the mandatory module-signing variables MODSIGN_KEY_DIR / IMA_EVM_ROOT_CA,
    ...                pointing at the keys created by Generate Module Signing Keys.
    ...                ${GLOBAL_BUILD_CONFIG} entries are separated by ${GLOBAL_BUILD_CONFIG_DELIMITER};
    ...                see Get Global Build Configuration Entries.
    [Arguments]    ${cwd}=${TEMP_DIR}
    ${use_global_dl}=    Get Variable Value    ${ENABLE_GLOBAL_DL_DIR}    0
    IF    '${use_global_dl}' == '1'
        Add Sulka Configuration    DL_DIR = "/oe/downloads"    cwd=${cwd}
    ELSE
        Add Sulka Configuration    DL_DIR = "${CURDIR}/../downloads"    cwd=${cwd}
    END

    ${use_global_sstate}=    Get Variable Value    ${ENABLE_GLOBAL_SSTATE_DIR}    0
    IF    '${use_global_sstate}' == '1'
        Add Sulka Configuration    SSTATE_DIR = "/oe/sstate-cache"    cwd=${cwd}
    ELSE
        Add Sulka Configuration    SSTATE_DIR = "${CURDIR}/../sstate-cache"    cwd=${cwd}
    END
    Add Sulka Configuration    BB_HASHSERVE_DB_DIR = "\${SSTATE_DIR}"    cwd=${cwd}

    Add Sulka Configuration    MODSIGN_KEY_DIR = "${CURDIR}/../modsign-keys"    cwd=${cwd}
    Add Sulka Configuration    IMA_EVM_ROOT_CA = "\${MODSIGN_KEY_DIR}/ima-local-ca.pem"    cwd=${cwd}

    @{config_items}=    Get Global Build Configuration Entries
    FOR    ${item}    IN    @{config_items}
        Add Sulka Configuration    ${item}    cwd=${cwd}
    END

Add Common User Configuration
    [Documentation]    Append the serviceuser-related entries to the Sulka build config: install the
    ...                SSH public key from ${CURDIR}/../auth-keys/, set the serviceuser password hash,
    ...                and (by default) grant the serviceuser sudo access via
    ...                SULKA_SERVICEUSER_ENABLE_SUDO="1". Pass enable_sudo=${False} to omit the sudo
    ...                line for tests that verify sudo is disabled by default.
    [Arguments]    ${cwd}=${TEMP_DIR}    ${enable_sudo}=${True}
    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS = "1"    cwd=${cwd}
    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD = "\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."    cwd=${cwd}
    Add Sulka Configuration    SULKA_SSH_KEYS_DIR = "${CURDIR}/../auth-keys/"    cwd=${cwd}
    IF    ${enable_sudo}
        Add Sulka Configuration    SULKA_SERVICEUSER_ENABLE_SUDO = "1"    cwd=${cwd}
    END

Checkout Sulka Configuration
    [Documentation]    Fetch and check out all layer repositories for ${configuration} into ${cwd} via
    ...                `kas checkout`, without building. Suite Setup runs this with ${FULL_CONFIG} so that
    ...                meta-security (which Generate Module Signing Keys depends on) is present before the
    ...                keys are generated; it also primes the layer checkout for every later suite.
    [Arguments]    ${configuration}    ${cwd}=${TEMP_DIR}
    ${timestamp}=    Get Current Date    result_format=epoch
    Run Process    kas    checkout    ${configuration}    cwd=${cwd}    timeout=2h    stdout=kas_stdout_checkout_${timestamp}.log    stderr=kas_stderr_checkout_${timestamp}.log

Build Sulka Image
    [Arguments]    ${configuration}    ${cwd}=${TEMP_DIR}    ${expect_success}=True
    Log    Starting build...
    Checkout Sulka Configuration    ${configuration}    cwd=${cwd}
    ${timestamp}=    Get Current Date    result_format=epoch
    ${result}=    Run Process    kas    build    ${configuration}    cwd=${cwd}    timeout=3h 30m    stdout=kas_stdout_${timestamp}.log    stderr=kas_stderr_${timestamp}.log
    Log    Return code: ${result.rc}
    IF    ${expect_success}
        Should Be Equal As Integers    ${result.rc}    0    Build failed
    ELSE
        Should Not Be Equal As Integers    ${result.rc}    0    Build was expected to fail but succeeded
    END

    Sleep    5 Seconds

    RETURN    ${result}

Build Output Should Have No Unexpected Warnings
    [Documentation]    Fail if the kas build in ${result} emitted any bitbake "WARNING:" line that is
    ...                not matched by a regexp in ${ALLOWED_BUILD_WARNINGS}. Both stdout and stderr are
    ...                scanned. This can be used to detect non-fatal quality issues.
    [Arguments]    ${result}
    ${combined}=    Catenate    SEPARATOR=\n    ${result.stdout}    ${result.stderr}
    ${warnings}=    Get Lines Matching Regexp    ${combined}    WARNING:    partial_match=True
    Validate Output Against Allowlist    ${warnings}    ${ALLOWED_BUILD_WARNINGS}    build warnings

Reset Sulka Image
    [Arguments]    ${configuration}
    ${timestamp}=    Get Current Date    result_format=epoch
    ${result}=    Run Process    kas    shell    ${configuration}    -c    bitbake -c cleanall core-image-base    cwd=${TEMP_DIR}    timeout=5m    stdout=kas_stdout_${timestamp}.log    stderr=kas_stderr_${timestamp}.log

Clean Sulka Recipe
    [Documentation]    Clear a single recipe's sstate and work output so the next build regenerates it
    ...                from scratch. Use before inspecting a recipe's staged artifacts to ensure no
    ...                stale output from a previous build is read back.
    [Arguments]    ${recipe}    ${configuration}    ${cwd}=${TEMP_DIR}
    ${timestamp}=    Get Current Date    result_format=epoch
    ${result}=    Run Process    kas    shell    ${configuration}    -c    bitbake -c cleansstate ${recipe}    cwd=${cwd}    timeout=5m    stdout=kas_stdout_${timestamp}.log    stderr=kas_stderr_${timestamp}.log
    Should Be Equal As Integers    ${result.rc}    0    Failed to clean ${recipe}

Launch Image With QEMU
    [Documentation]    Start QEMU under kas; block until SSH is reachable or ${ssh_ready_timeout} elapses.
    [Arguments]    ${configuration}    ${ssh_ready_timeout}=5min
    ${timestamp}=    Get Current Date    result_format=epoch
    ${handle}=    Start Process    kas    shell    ${configuration}    -c    runqemu nographic slirp qemuparams\=\"-m 1024\"    cwd=${TEMP_DIR}    stdout=kas_stdout_${timestamp}.log    stderr=kas_stderr_${timestamp}.log
    Wait Until Keyword Succeeds    ${ssh_ready_timeout}    5s    QEMU SSH Should Accept Login
    RETURN    ${handle}

QEMU SSH Should Accept Login
    [Documentation]    Fails unless 127.0.0.1:2222 accepts a key-based login for ${SULKA_SERVICEUSER_USERNAME}.
    Open Connection    127.0.0.1    port=2222
    ${logged_in}=    Run Keyword And Return Status    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key
    Close Connection
    Should Be True    ${logged_in}    QEMU SSH not ready

Stop QEMU
    [Arguments]    ${handle}
    Terminate Process    ${handle}
    Wait For Process    ${handle}    timeout=10s
