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

# A first run on a machine without ~/.ssh/config should bootstrap the
# standard config path instead of failing with a confusing missing-file error.
missing_home="$test_root/missing-home"
set +e
HOME="$missing_home" "$repo/sshpick" --list > "$test_root/missing-list.txt" 2> "$test_root/missing-error.txt"
missing_status=$?
set -e
[ "$missing_status" -eq 1 ]
[ -f "$missing_home/.ssh/config" ]
[ "$(stat -c '%a' "$missing_home/.ssh")" = 700 ]
[ "$(stat -c '%a' "$missing_home/.ssh/config")" = 600 ]
grep -Fq "created SSH config" "$test_root/missing-error.txt"
grep -Fq "Host alias" "$test_root/missing-error.txt"

HOME="$test_home" "$repo/sshpick" --preview alpha > "$test_root/preview.txt"
grep -Eq '^hostname[[:space:]]+192\.0\.2\.10$' "$test_root/preview.txt"
grep -Eq '^user[[:space:]]+deploy$' "$test_root/preview.txt"
grep -Eq '^port[[:space:]]+2222$' "$test_root/preview.txt"

# The detail panel is a single compact card. Repeated directives from a
# resolver must not create duplicate rows, even if their casing differs.
mkdir -p "$test_root/bin"
cat > "$test_root/bin/ssh" <<'EOF'
#!/usr/bin/env bash
cat <<'OUTPUT'
hostname utils-pipeline.internal
user developer
port 22
IdentityFile ~/.ssh/id_ed25519
IDENTITYFILE ~/.ssh/id_ed25519
identitiesonly yes
OUTPUT
EOF
chmod +x "$test_root/bin/ssh"
PATH="$test_root/bin:$PATH" HOME="$test_home" "$repo/sshpick" --preview utils-pipeline > "$test_root/dedup-preview.txt"
[ "$(grep -Ec '^Host utils-pipeline$' "$test_root/dedup-preview.txt")" -eq 1 ]
[ "$(grep -Eic '^identityfile[[:space:]]' "$test_root/dedup-preview.txt")" -eq 1 ]
[ "$(grep -Ec '^identitiesonly[[:space:]]+yes$' "$test_root/dedup-preview.txt")" -eq 1 ]

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
