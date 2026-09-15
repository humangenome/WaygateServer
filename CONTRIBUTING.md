# Contributing to WaygateServer

Short and to the point.

## Which repo do I file against?

| You are looking at | File it here |
|---|---|
| A running server — startup, world saving, ports, server query, configuration | [HumanGenome/WaygateServer](https://github.com/HumanGenome/WaygateServer/issues) |
| The Waygate app — installing, connecting, the server list, updates | [HumanGenome/Waygate](https://github.com/HumanGenome/Waygate/issues) |
| Not sure | Either. It gets moved. |

## Reporting bugs

Open an issue using the **Bug report** template. Include:

- Waygate version (the release tag, e.g. `v0.1.0`) and which package you installed
- Your Dimraeth build (Steam build ID if you know it)
- Host OS
- Steps to reproduce
- The server log, and the game's own log
- Whether it reproduces on a clean world

If your issue is about managed hosting you bought — the control panel, billing, or support — contact your host directly. Waygate's GitHub issues are for the open-source server, app, and mods themselves.

## Feature requests

Open an issue using the **Feature request** template. Describe what you are trying to run, not how you think it should be built.

## Security issues

Do not open a public issue. See [SECURITY.md](.github/SECURITY.md).

## Changelog

`CHANGELOG.md` is load-bearing, not decoration. The release workflow extracts the section for the tag being released and publishes it verbatim as the release body, so:

- Every release needs a `## [x.y.z] - YYYY-MM-DD` section before it can be tagged
- Components are `### Server` and `### Client`, and nothing else
- Change types are `#### Added`, `#### Changed`, `#### Fixed`, `#### Removed`, in that order, and only the ones that apply
- Plain bullets. No bold lead-ins except a literal `**Breaking:**`, no emoji, no marketing language, no internal references

`tools/ci/lint-release-notes.sh` enforces all of it, and `.github/workflows/checks.yml` runs it on every push — so a bad section fails on the commit that wrote it, not on the tag that would have published it.

## Version numbers

The tag, the version stamped in the build, and the CHANGELOG heading must all agree. `tools/ci/assert-version.sh` checks this and runs in both workflows. Run it locally before tagging:

```
tools/ci/assert-version.sh --tag v0.1.0
```

## Pull requests

This project does not accept code pull requests while it is pre-release. Once the first stable tag ships:

- Branch from `main`, named `feat/<short-slug>` or `fix/<short-slug>`
- One logical change per commit, short subject lines
- Match the existing code style
- Justify any new dependency in the pull request description
- Run the test suite before opening the pull request

Documentation and typo fixes are welcome at any time.

## Code of conduct

Be civil. Be technical. Do not post game-piracy or anti-cheat-evasion material in issues or pull requests.
