# T004/T005 verification evidence

## Commands

```text
bash tests/test.sh
bash -n sshpick install.sh
dash -n install.sh
git diff --check
```

## Results

- `bash tests/test.sh`: PASS (`sshpick 1.0.0`, `PASS test_root=/tmp/sshpick-test.FSVdzV`)
  - verifies first-run creation of `$HOME/.ssh/config`;
  - verifies mode `700` for `.ssh` and `600` for `config`;
  - verifies a clear follow-up message when the new config has no concrete aliases;
  - verifies explicit `--config` paths remain fail-closed;
  - preserves list, preview deduplication, and installer idempotence checks.
- `bash -n sshpick install.sh`: PASS
- `dash -n install.sh`: PASS
- `git diff --check`: PASS
- Manual isolated-home probe: created the default config with modes `700/600` and returned status `1` with the expected next-step message.

## Scope boundary

- Changes are local in `/home/arkhi25/repo/sshpick`.
- No Git push, release, or deployment performed.
- Current worktree has only the intended local modifications in `README.md`, `sshpick`, and `tests/test.sh`, plus the plan/run evidence updates.
