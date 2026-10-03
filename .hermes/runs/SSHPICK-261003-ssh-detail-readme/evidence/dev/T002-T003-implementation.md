# T002/T003 implementation evidence

## Source change
- `sshpick:41-63`: preview rendering now normalizes directive keys with `tolower()`, keeps one first value per supported field, and emits one compact row per field.
- This handles repeated/inherited `ssh -G` output such as `IdentityFile` plus `identityfile`, and prevents duplicate right-panel detail rows for the selected alias.

## Regression coverage
- `tests/test.sh` uses a fake `ssh` resolver that emits duplicate `IdentityFile`/`identityfile` directives with different casing.
- Assertions require exactly one `Host utils-pipeline` header, one `identityfile` row, and one `identitiesonly` row.

## Documentation asset
- Copied the user-supplied image to `docs/sshpick-preview.jpg`.
- SHA-256: `e0027d02f18dff4e407037ee925efb97ac88072de4fdedff795332cde2755d52`
- `README.md` embeds the asset and documents deterministic detail rendering.
