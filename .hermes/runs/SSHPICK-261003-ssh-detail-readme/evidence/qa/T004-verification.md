# T004 verification evidence

## Commands

```text
bash tests/test.sh
bash -n sshpick install.sh
dash -n install.sh
git diff --check
```

## Results

- `bash tests/test.sh`: PASS (`sshpick 1.0.0`, `PASS test_root=/tmp/sshpick-test.dXDYik`)
- `bash -n sshpick install.sh`: PASS
- `dash -n install.sh`: PASS
- `git diff --check`: PASS
- Direct real OpenSSH preview for `utils-pipeline`: one `Host utils-pipeline` header and one row each for `user`, `hostname`, `port`, and `identityfile`.
- Final source/README/test hashes were captured before this evidence write; no source files changed afterward.

## Scope boundary

- Changes are local in `/home/arkhi25/repo/sshpick`.
- No Git push, release, or deployment performed.
