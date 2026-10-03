# SSHPICK-261003-ssh-detail-readme

## Problem
The `sshp` preview/detail surface can show duplicate SSH configuration entries for the currently selected alias, making the right panel ambiguous. The repository README also lacks the supplied product screenshot.

## Business intent
Make the selected host detail deterministic: one detail card per selected alias, with each supported effective SSH field rendered at most once. Add the supplied screenshot to the repository and document the interface and behavior.

## Scope
- Inspect and fix the shell preview/detail rendering path in `sshpick`.
- Add a repository-local screenshot asset copied from the user-provided image.
- Update `README.md` with the screenshot and a concise UI/preview description.
- Add focused regression coverage for duplicate effective SSH fields and detail-card identity.
- Preserve the existing installer and connection behavior.

## Out of scope
- Git push, release tags, deployment, or changes to user SSH credentials/configuration.
- Rewriting the project into a different UI framework.
- Changing OpenSSH routing semantics or silently selecting a different host.

## Assumptions
- The canonical workspace is `/home/arkhi25/repo/sshpick`.
- The supplied image at `/home/arkhi25/.hermes/cache/images/img_3fea5183df58.jpg` is the intended README screenshot.
- The effective configuration source remains `ssh -F <config> -G <host>`.

## Runtime flow
1. Parse concrete host aliases from the configured SSH config.
2. fzf selects exactly one alias.
3. The preview command resolves that alias through OpenSSH.
4. The detail renderer emits one host header and one row per supported field, deduplicated by field identity while preserving first effective value.
5. Enter connects to the same selected alias using the same config file.

## Risks and rollback
- The image increases repository size; rollback is limited to the new asset and README section.
- Preview filtering could hide repeated values that are semantically meaningful; the existing UI contract is one compact row per field, so the regression test will pin that contract.
- No existing tracked or untracked changes were present at discovery; verify again before and after edits.

## Tasks
- [x] T001 Inspect repository, current branch, source, tests, and clean baseline — Haku.
- [ ] T002 Implement deterministic detail rendering and regression test — Haku.
- [ ] T003 Add screenshot asset and update README — Haku.
- [ ] T004 Run focused verification, inspect final diff, and write evidence — Haku.

## Acceptance criteria
- `sshpick --preview <alias>` emits exactly one `Host <alias>` header.
- Each supported detail key appears at most once even when `ssh -G` returns repeated directives.
- Existing list, preview resolution, installer idempotence, and connection command behavior remain intact.
- README embeds the supplied screenshot using a tracked repository-relative path and explains the right-side detail behavior.
- Shell syntax and focused tests pass from the final source.
- No push or publication is performed without separate authorization.

## Definition of Done
The source fix, screenshot, README documentation, regression coverage, and verification evidence are present in the canonical checkout; final status and remaining delivery boundary are reported by Haku.
