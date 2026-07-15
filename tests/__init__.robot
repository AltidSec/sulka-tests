*** Settings ***
Documentation    Clone the shared kas-sulka workspace and generate module signing keys before any child suite
Resource         ../resources/git.resource
Resource         ../resources/kas.resource
Suite Setup      Run Keywords
...                  Clone Repository If Needed    ${KAS_SULKA_BRANCH}    https://codeberg.org/AltidSec/kas-sulka.git
...                  AND    Checkout Sulka Configuration    ${FULL_CONFIG}
...                  AND    Generate Module Signing Keys
