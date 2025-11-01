# GitHub Actions Setup Guide - Private Flutter SDK Repository

## Overview
Your GitHub Actions workflow needs a Personal Access Token (PAT) to access your private `QuicUIFlutterSDK` repository.

## Step 1: Create a Personal Access Token (PAT)

### On GitHub.com:

1. **Go to GitHub Settings**
   - Navigate to: https://github.com/settings/tokens
   - Or: Click your profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Click "Generate new token" → "Generate new token (classic)"**

3. **Configure the Token:**
   - **Token name:** `FLUTTER_SDK_TOKEN` (or any descriptive name)
   - **Expiration:** Choose 90 days or No expiration (for CI/CD, no expiration is recommended)
   
4. **Select Scopes:**
   Required permissions:
   - ✅ `repo` (Full control of private repositories)
     - This includes: repo:status, repo_deployment, public_repo, repo:invite, security_events
   - ✅ `read:user` (Read user profile data)
   
   Optional but recommended:
   - ✅ `workflow` (Update GitHub Action workflows)

5. **Generate and Copy**
   - Click "Generate token"
   - **IMPORTANT:** Copy the token immediately - you won't see it again!
   - Format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Add Token to GitHub Actions Secrets

### In Your Repository:

1. **Go to Repository Settings**
   - Navigate to: https://github.com/Ikolvi/QuicUICodepush/settings
   - Or: Repository → Settings

2. **Go to Secrets and Variables**
   - Left sidebar → "Secrets and variables" → "Actions"

3. **Create New Repository Secret**
   - Click "New repository secret"
   
4. **Configure Secret:**
   - **Name:** `FLUTTER_SDK_TOKEN`
   - **Secret:** Paste the token you copied (the `ghp_...` value)
   - Click "Add secret"

### You should now see:
```
Secrets
FLUTTER_SDK_TOKEN (used 0 times) ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
```

## Step 3: Verify Workflow Configuration

The workflow is already configured to use this secret:

```yaml
- name: Use Custom QuicUI Flutter SDK
  run: |
    # Clone the custom QuicUI Flutter SDK fork with PAT authentication
    git clone --depth 1 --branch 3.35.7 https://x-access-token:${{ secrets.FLUTTER_SDK_TOKEN }}@github.com/Ikolvi/QuicUIFlutterSDK.git ~/flutter-custom
    
    # Update PATH to use custom Flutter SDK
    echo "$HOME/flutter-custom/bin" >> $GITHUB_PATH
    
    # Verify Flutter installation
    flutter --version
    dart --version
  continue-on-error: true
```

## Step 4: Test the Workflow

1. **Push a Change** or **Trigger Workflow Manually:**
   - Go to: Repository → Actions
   - Select "Test" workflow
   - Click "Run workflow"

2. **Monitor the Build:**
   - Watch the workflow run
   - Check the "Use Custom QuicUI Flutter SDK" step for success

3. **Expected Output:**
   ```
   Cloning into '/home/runner/flutter-custom'...
   Flutter 3.35.7 • channel stable
   Dart SDK version: 3.5.7
   ```

## Troubleshooting

### Error: "Repository not found"
- ✅ Verify token has `repo` scope
- ✅ Verify token name in workflow matches secret name: `FLUTTER_SDK_TOKEN`
- ✅ Verify repository URL is correct: `Ikolvi/QuicUIFlutterSDK`

### Error: "fatal: could not read Username"
- ✅ Verify token is set in repository secrets
- ✅ Verify secret name in workflow: `${{ secrets.FLUTTER_SDK_TOKEN }}`
- ✅ Regenerate token if it was revoked

### Error: "Invalid token"
- ✅ Verify token hasn't expired
- ✅ Verify token hasn't been revoked
- ✅ Verify you copied the complete token (starts with `ghp_`)

### Token Not Found in Workflow
- ✅ Verify secret is in **Repository** secrets, not Organization secrets
- ✅ Verify you spelled the secret name exactly: `FLUTTER_SDK_TOKEN`
- ✅ Refresh the page to see newly added secrets

## Security Best Practices

1. **Token Scope:** Only grant `repo` scope (minimum required)
2. **Token Expiration:** Set expiration for enhanced security
3. **Rotation:** Periodically rotate tokens (every 90 days recommended)
4. **Revocation:** If compromised, immediately revoke the token
5. **Audit:** GitHub shows when each secret is last used

## Token Usage in Workflow

The token is used in the format:
```
https://x-access-token:TOKEN@github.com/OWNER/REPO.git
```

This is **secure** because:
- Token only exposed during git operations
- GitHub Actions masks token in logs
- Token is scoped to the workflow run
- No token stored in repository code

## Next Steps

1. ✅ Create Personal Access Token on GitHub
2. ✅ Add `FLUTTER_SDK_TOKEN` to Repository Secrets
3. ✅ Verify workflow configuration (already done)
4. ✅ Trigger a test workflow run
5. ✅ Monitor build output

## Additional Resources

- [GitHub Personal Access Tokens Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [GitHub API Authentication](https://docs.github.com/en/rest/authentication/authenticating-with-the-rest-api)

---

**Workflow File:** `.github/workflows/test.yaml`  
**Secret Name:** `FLUTTER_SDK_TOKEN`  
**Repository:** `Ikolvi/QuicUIFlutterSDK` (private)  
**Last Updated:** November 1, 2025
