# Dotfiles — GitHub Advanced Security Enablement Plan

**Goal:** Enable GitHub Advanced Security (GHAS) secret scanning with push protection on `doughgle/dotfiles` and remediate any secrets found in git history.

**Prerequisites check** (completed 2026-07-17):
- Repo: `doughgle/dotfiles` — **public** ✅
- GH CLI token: **expired** — needs `gh auth login` before API steps
- GHAS availability: **free on public repos** (secret scanning included, no Enterprise license needed) ✅
- Repo admin access: **owner** (`doughgle`) controls the repo ✅

---

## Task 1: Enable Secret Scanning + Push Protection

**Via GitHub UI** (recommended — no auth token needed):

1. Navigate to `https://github.com/doughgle/dotfiles/settings/security_analysis`
2. Under **"Secret scanning"** click **Enable**
3. Under **"Push protection"** click **Enable**
4. Confirm the toggle changes

**Via API** (alternative, requires `gh auth login` first):

```bash
# 1. Authenticate
gh auth login -h github.com

# 2. Enable secret scanning
gh api -X PATCH repos/doughgle/dotfiles \
  -f security_and_analysis[secret_scanning][status]=enabled

# 3. Enable push protection
gh api -X PATCH repos/doughgle/dotfiles \
  -f security_and_analysis[secret_scanning_push_protection][status]=enabled
```

**Verification:**

```bash
# Check current security settings
gh api repos/doughgle/dotfiles \
  --jq '.security_and_analysis'
```

Expected: `secret_scanning.status = enabled`, `secret_scanning_push_protection.status = enabled`

---

## Task 2: Scan Results — Review and Triage

**Wait for initial scan to complete** (GitHub scans full git history automatically after enabling — typically 5–15 minutes for a small repo).

### 2a. Fetch alerts

```bash
# List all open secret scanning alerts
gh api repos/doughgle/dotfiles/secret-scanning/alerts \
  --jq '.[] | {number, secret_type, secret, file_path, commit}'
```

### 2b. Triage each alert

For each alert, one of:

| Disposition | When | Action |
|-------------|------|--------|
| `revoked` | Secret was already rotated | Mark in UI, close alert |
| `false_positive` | Pattern match but no real secret | Mark as false positive |
| `open` | Secret is still valid | **Immediately rotate**, then mark revoked |

### 2c. Known historical items that may trigger alerts

From the pre-audit (see `2026-07-16-dotfiles-backup-plan.md`):

| Commit | What was there | Likely alert? |
|--------|---------------|---------------|
| `c88a86c` (initial) | `.k3d/k3d-default.yaml` — k3s cluster config | Low — no known secret pattern in content |
| `c88a86c` (initial) | `.gitconfig` — `[credential] helper = libsecret` | Low — helper path, not a credential |
| `8746ec6` (commit msg) | Mentions `[user]`, `[sendemail]` sections | Low — commit message text only |

If GHAS finds no alerts: the repo is clean. Proceed to Task 5.

---

## Task 5: Remediate and Verify

### 5a. Remediate if alerts found

If GHAS detects a valid secret in git history:

```bash
# 1. Rotate the exposed secret IMMEDIATELY (before purging history)
#    For example: GitHub PAT → https://github.com/settings/tokens
#    AWS key → AWS IAM console

# 2. Purge file from git history (example — adjust paths to match alert)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch <path-from-alert>' \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push to remove from remote history
git push origin --force --all
git push origin --force --tags

# 4. Notify anyone who has cloned since the secret was introduced
```

### 5b. Verify cleanup

```bash
# Confirm alerts resolve after force-push
gh api repos/doughgle/dotfiles/secret-scanning/alerts \
  --jq 'length'

# Expected: 0 open alerts
```

### 5c. Apply custom patterns for repo-specific false positives

Create `.github/secret_scanning.yml`:

```yaml
name: dotfiles-custom-patterns
patterns:
  - name: Local-home-path
    description: Home directory path in shell configs (not a secret)
    pattern: '/home/[a-z_][a-z0-9_-]*/'
    type: regex
    detection:
      - path: '\.bashrc'
      - path: '\.config/fish/config\.fish'
  - name: SSH-key-path-reference
    description: SSH key path in gitconfig (not the key itself)
    pattern: '~/.ssh/[a-zA-Z0-9_-]+'
    type: regex
    detection:
      - path: '\.gitconfig'
```

### 5d. Verify alert dispositions

```bash
gh api repos/doughgle/dotfiles/secret-scanning/alerts \
  --jq '.[] | {number: .number, secret_type: .secret_type, resolution: .resolution, resolved_by: .resolved_by.login, resolved_at: .resolved_at}'
```

All alerts should be closed with appropriate resolutions.

---

## Post-Plan Checklist

- [x] **Task 1** — Secret scanning enabled
- [x] **Task 1** — Push protection enabled
- [x] **Task 2** — Initial scan completed
- [x] **Task 2** — Alerts reviewed and triaged
- [x] **Task 5** — Valid secrets rotated (if any) — N/A, no valid secrets found
- [x] **Task 5** — Git history purged (if needed) — N/A, no secrets to purge
- [x] **Task 5** — Custom patterns committed (if needed)
- [x] **Task 5** — Final verification: 0 open alerts
