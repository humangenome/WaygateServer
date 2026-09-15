# Security Policy

## Reporting a vulnerability

If you have found a security issue in WaygateServer or the host mod it loads, please **do not** open a public GitHub issue.

Report it privately through GitHub's security advisory form:

- Server: https://github.com/HumanGenome/WaygateServer/security/advisories/new
- App and hub: https://github.com/HumanGenome/Waygate/security/advisories/new

**There is no security mailing address.** The advisory forms above are the only reporting channel; an email address claiming to be ours is not one.

Include:

- A description of the vulnerability
- Steps to reproduce
- Affected component (server / host mod / configuration)
- Waygate version (the release tag, e.g. `v0.1.0`)
- Whether the issue is currently being exploited

Reports are acknowledged within 72 hours and triaged within 7 days.

## Scope

In scope:

- Remote code execution or unauthenticated takeover of the server process
- A connected player being able to read or write arbitrary files on the host
- Admission bypass — an unauthorised client joining, or impersonating another player or the host
- Privilege escalation out of the supervised game process
- Path traversal through world names, character names, save paths, or configuration values
- Command injection through any value the server reads from configuration or from the network

Out of scope:

- Vulnerabilities in the machine your server runs on — those belong to whoever operates it
- Vulnerabilities in retail Dimraeth itself — report those to the game's developer
- Vulnerabilities in third-party mods running alongside Waygate
- Cheating and anti-cheat concerns; Waygate does not provide anti-cheat
- Denial of service by simply sending a server more traffic than its link can carry
- Anything requiring administrative access to the host, which already implies full control

## Supported versions

Only the latest released version receives security fixes. Waygate is pre-1.0 and moves fast; there is no long-term support branch.
