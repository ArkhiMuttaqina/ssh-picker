#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/sshpick-test.XXXXXX)"
test_home="$test_root/home"
mkdir -p "$test_home/.ssh"

cat > "$test_home/.ssh/config" <<'EOF'
Host alpha alpha-alt
  HostName 192.0.2.10
  User deploy
  Port 2222
  IdentityFile ~/.ssh/id_test

Host *.internal
  User wildcard

Host !blocked
  HostName 192.0.2.20

Host beta
  HostName beta.example.test
EOF

HOME="$test_home" "$repo/sshpick" --list > "$test_root/hosts.txt"
printf '%s\n' alpha alpha-alt beta > "$test_root/expected-hosts.txt"
diff -u "$test_root/expected-hosts.txt" "$test_root/hosts.txt"

HOME="$test_home" "$repo/sshpick" --preview alpha > "$test_root/preview.txt"
grep -Eq '^hostname[[:space:]]+192\.0\.2\.10$' "$test_root/preview.txt"
grep -Eq '^user[[:space:]]+deploy$' "$test_root/preview.txt"
grep -Eq '^port[[:space:]]+2222$' "$test_root/preview.txt"

HOME="$test_home" sh "$repo/install.sh" \
  --source-file "$repo/sshpick" \
  --no-install-deps > "$test_root/install-first.txt"
HOME="$test_home" sh "$repo/install.sh" \
  --source-file "$repo/sshpick" \
  --no-install-deps > "$test_root/install-second.txt"

[ -x "$test_home/.local/bin/sshpick" ]
[ -L "$test_home/.local/bin/sshp" ]
[ "$(grep -Fc '# >>> sshpick installer >>>' "$test_home/.bashrc")" -eq 1 ]
[ "$(grep -Fc '# >>> sshpick installer >>>' "$test_home/.profile")" -eq 1 ]
[ "$(grep -Fc 'alias sshp=sshpick' "$test_home/.bashrc")" -eq 1 ]
bash -n "$test_home/.bashrc"
bash -n "$test_home/.profile"
HOME="$test_home" "$test_home/.local/bin/sshp" --version | grep -Fx 'sshpick 1.0.0'

printf 'PASS test_root=%s\n' "$test_root"
