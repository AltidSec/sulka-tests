*** Settings ***
Documentation    Clone the shared kas-sulka workspace once before any child suite
Resource         ../resources/git.resource
Suite Setup      Clone Repository If Needed    ${KAS_SULKA_BRANCH}    https://codeberg.org/AltidSec/kas-sulka.git
