# GitHub Secrets Configuration

This repository requires the following secrets to be configured in GitHub Settings > Secrets and variables > Actions.

## Required Secrets

### 1. `PERSONAL_ACCESS_TOKEN`
- **Purpose**: GitHub API access for creating/deleting self-hosted runners
- **Permissions**:
  - `repo` (Full control of private repositories)
  - `workflow` (Update GitHub Action workflows)
  - `admin:org` > `manage_runners:org` (if using organization runners)
- **How to create**:
  1. Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
  2. Generate new token with required permissions
  3. Copy token value
- **Used in**: `.github/workflows/tap-ci.yml` (create-runner, delete-runner jobs)

---

### 2. `HCLOUD_TOKEN`
- **Purpose**: Hetzner Cloud API access for creating/deleting servers
- **Permissions**: Read & Write
- **How to create**:
  1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
  2. Select your project
  3. Security > API Tokens > Generate API Token
  4. Copy token value
- **Used in**: `.github/workflows/tap-ci.yml` (create-runner, delete-runner jobs)

---

### 3. `OBJECTSTORAGE_API_KEY`
- **Purpose**: S3-compatible object storage access key (mapped to `AWS_ACCESS_KEY_ID`)
- **Format**: Alphanumeric string (e.g., `L5ILB4GUKOBY7XUODW4N`)
- **How to create**:
  1. Go to your object storage provider (Hetzner Storage Box, AWS S3, etc.)
  2. Create API credentials
  3. Copy access key
- **Used in**: `.github/workflows/tap-ci.yml` (extract job)

---

### 4. `OBJECTSTORAGE_API_SECRET`
- **Purpose**: S3-compatible object storage secret key (mapped to `AWS_SECRET_ACCESS_KEY`)
- **Format**: Alphanumeric string (e.g., `2Gr6r14coZNk4LBm2pnahTyId1toRB8TJmlIitZ5`)
- **How to create**: Generated alongside `OBJECTSTORAGE_API_KEY`
- **Used in**: `.github/workflows/tap-ci.yml` (extract job)

---

## Optional Secrets

### 5. `HCLOUD_SSH_KEY_ID` *(Optional)*
- **Purpose**: Disable root password and email notifications for Hetzner servers
- **Format**: Numeric ID (e.g., `12345678`)
- **How to create**:
  1. Go to Hetzner Cloud Console > Security > SSH Keys
  2. Add your SSH public key
  3. Note the key ID from the URL or API
- **Used in**: `.github/workflows/tap-ci.yml` (commented out by default)
- **Status**: Currently commented out in workflows

---

## How to Add Secrets

### For Repository Secrets:
1. Go to your GitHub repository
2. Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Enter secret name (exact match required)
5. Paste secret value
6. Click "Add secret"

### For Organization Secrets:
1. Go to your GitHub organization
2. Settings > Secrets and variables > Actions
3. Click "New organization secret"
4. Enter secret name and value
5. Select repository access
6. Click "Add secret"

---

## Security Best Practices

1. **Never commit secrets to code**: All secrets are read from GitHub Secrets
2. **Rotate tokens regularly**: Update secrets every 90 days
3. **Use least privilege**: Only grant minimum required permissions
4. **Monitor usage**: Check Hetzner and object storage usage regularly
5. **Separate credentials**: Use different tokens for different environments

---

## Verification

After adding secrets, verify they're configured correctly:

1. Go to repository Settings > Secrets and variables > Actions
2. You should see 4 secrets listed:
   - `PERSONAL_ACCESS_TOKEN`
   - `HCLOUD_TOKEN`
   - `OBJECTSTORAGE_API_KEY`
   - `OBJECTSTORAGE_API_SECRET`

3. Test by manually triggering the scheduler:
   ```bash
   # From GitHub UI: Actions > Tap Scheduler > Run workflow
   ```

---

## Troubleshooting

### "Error: Bad credentials" (PERSONAL_ACCESS_TOKEN)
- Token expired or invalid
- Token missing required permissions
- Solution: Regenerate token with correct permissions

### "Error: Invalid authentication credentials" (HCLOUD_TOKEN)
- Token invalid or project mismatch
- Solution: Generate new token from correct Hetzner project

### "Error: HTTP 403 Forbidden" (Object Storage)
- API key/secret incorrect
- Bucket permissions insufficient
- Solution: Verify credentials and bucket access

### "Error: Secret not found"
- Secret name mismatch (case-sensitive)
- Secret not accessible to repository
- Solution: Check secret name spelling and repository access

---

## DuckDB S3 Secret Configuration

### For Hetzner Object Storage

When using DuckDB with Hetzner Object Storage, use the following configuration:

```sql
CREATE OR REPLACE SECRET s3_secret (
    TYPE S3,
    PROVIDER credential_chain,
    ENDPOINT 'fsn1.your-objectstorage.com',  -- Without bucket name!
    URL_STYLE 'vhost',                        -- Use virtual-host style
    USE_SSL true,
    REGION 'us-east-1'                       -- Any region works
);
```

**Important Notes:**
- **ENDPOINT**: Use `fsn1.your-objectstorage.com` (or `nbg1`, `hel1`) WITHOUT the bucket name
- **URL_STYLE**: Must be `'vhost'` (virtual-host style), NOT `'path'`
- **PROVIDER**: Use `credential_chain` to automatically pick up `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from environment variables
- **REGION**: Any value works (`'us-east-1'` is fine)
