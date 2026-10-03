# SSHPICK-261003-portable-installer

## Problem
The current interactive `sshp` setup exists only in one home directory and cannot be reproduced safely on another instance.

## Business intent
Provide a small portable Bash SSH picker with an installer suitable for a reviewed GitHub raw URL invocation.

## Scope
- Track the `sshpick` executable source.
- Install `sshpick` and the `sshp` command link under a user-local bin directory.
- Detect/install `ssh` and `fzf` using a supported package manager unless disabled.
- Add an idempotent PATH block without overwriting shell startup files.
- Parse concrete SSH aliases and preview resolved non-secret settings.
- Verify syntax, functional parsing, installer idempotence, and shell startup syntax.

## Out of scope
- GitHub repository creation, authentication, push, release, or visibility choice.
- Copying SSH config, keys, credentials, or known_hosts.
- Rewriting the existing DevSpace repository or server provisioning scripts.

## Assumptions
- The target has POSIX `sh`, Bash, `install`, `mktemp`, and either curl or wget.
- Interactive use has Bash, OpenSSH client, and fzf.
- The future GitHub repository URL/ref will be substituted into the installer and README before publication.

## Runtime flow
1. Installer validates its destination and dependency policy.
2. It loads a local source file or fetches `sshpick` from the configured raw base.
3. It validates the payload with `bash -n`.
4. It installs `sshpick`, creates a safe `sshp` symlink, and updates PATH blocks idempotently.
5. `sshpick` parses concrete `Host` aliases, previews `ssh -G` output, and execs `ssh` for the selected alias.

## Risks and rollback
- Package installation can modify system package state; `--no-install-deps` disables it.
- Existing `sshpick` is backed up to `sshpick.bak`; an unrelated existing `sshp` file is never replaced.
- Shell files are backed up to `.sshpick.bak` before PATH mutation and syntax-checked.
- GitHub raw `main` is mutable; documentation recommends a release tag for repeatable installs.

## Tasks
- [x] T001 Inspect current setup and repository boundaries — Haku.
- [x] T002 Implement portable source, installer, docs, and focused tests — Haku.
- [ ] T003 Run final verification wave and inspect diff — Haku.
- [ ] T004 Publish to GitHub after repository access and visibility are explicitly available — Haku/user.

## Acceptance criteria
- `bash -n` passes for all shell artifacts.
- Functional test excludes wildcard/negated hosts and resolves preview fields.
- Installer works from a local source override in an isolated HOME.
- Repeated installation leaves exactly one managed PATH block per shell file.
- Existing unrelated shell content remains intact.
- No GitHub publication is claimed without remote SHA evidence.

## Definition of Done
Implementation and focused verification are complete locally; the GitHub publication boundary is reported separately until access and repository details exist.
