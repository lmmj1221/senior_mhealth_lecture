# 🚨 URGENT: Security Alert - Exposed API Key

## Immediate Actions Required

Your Firebase API key has been exposed in a public GitHub repository and detected by Google Cloud Platform. Follow these steps immediately:

## Step 1: Push the Security Fix
```bash
# Push the committed changes to remove exposed keys from repository
git push origin master
```

## Step 2: Regenerate the Firebase API Key

1. **Go to Google Cloud Console**:
   - Visit: https://console.cloud.google.com/
   - Select project: `senior-mhealth-lee`

2. **Navigate to API Credentials**:
   - Menu → APIs & Services → Credentials
   - Or direct link: https://console.cloud.google.com/apis/credentials

3. **Delete the Compromised Key**:
   - Find the exposed key: `AIzaSyBADpElIbBcQ1-euIP2apXxJKn3lXUdHS4`
   - Click on the key name
   - Click "DELETE" button
   - Confirm deletion

4. **Create a New API Key**:
   - Click "+ CREATE CREDENTIALS" → API Key
   - Copy the new API key immediately
   - Click "RESTRICT KEY" to add restrictions

## Step 3: Add API Key Restrictions

1. **Application Restrictions**:
   - Select "HTTP referrers (web sites)" for web apps
   - Add allowed referrers:
     - `https://senior-mhealth-lee.firebaseapp.com/*`
     - `https://your-domain.com/*`
     - `http://localhost:3000/*` (for development)

2. **API Restrictions**:
   - Select "Restrict key"
   - Choose only necessary APIs:
     - Firebase Management API
     - Firebase ML API
     - Firebase Remote Config API
     - Identity Toolkit API

3. **Save Changes**

## Step 4: Update Your Local Environment

1. **Create a `.env.local` file** (not `.env`):
```bash
# Create .env.local with new credentials
cp .env .env.local
```

2. **Update the new API key in `.env.local`**:
```env
FIREBASE_API_KEY=your_new_api_key_here
```

3. **Never commit `.env.local`** (already in .gitignore)

## Step 5: Update Firebase Configuration

1. **Update Firebase config in your app**:
   - For web: Update `firebase.config.js` or environment variables
   - For mobile: Run `flutterfire configure` again
   - For backend: Update Cloud Functions environment

2. **Test all services** to ensure they work with the new key

## Step 6: Monitor for Unauthorized Usage

1. **Check API usage**:
   - Console → APIs & Services → Dashboard
   - Look for unusual spikes or unauthorized usage

2. **Review Firebase Authentication logs**:
   - Firebase Console → Authentication → Users
   - Check for unauthorized sign-ups

3. **Enable alerts**:
   - Console → Monitoring → Alerting
   - Set up alerts for unusual API usage

## Prevention Best Practices

### Never Commit Sensitive Data
- Always use `.env.local` or `.env.development.local`
- Never commit files containing actual API keys
- Use placeholders in documentation

### Use Environment Variables
```javascript
// Good - use environment variables
const apiKey = process.env.FIREBASE_API_KEY;

// Bad - hardcoded key
const apiKey = "AIzaSyBADpElIbBcQ1-euIP2apXxJKn3lXUdHS4";
```

### Git Pre-commit Hooks
Consider adding pre-commit hooks to detect exposed secrets:
```bash
# Install pre-commit
pip install pre-commit

# Add to .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
```

### Use Secret Management Services
- Google Secret Manager
- GitHub Secrets (for GitHub Actions)
- Vercel Environment Variables

## Verification Checklist

- [ ] Security fix committed and pushed to repository
- [ ] Old API key deleted from Google Cloud Console
- [ ] New API key created with restrictions
- [ ] Local environment updated with new key
- [ ] All services tested and working
- [ ] No unusual activity in API usage logs
- [ ] Team notified about the incident

## Additional Resources

- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)

## Support

If you need assistance:
- Google Cloud Support: https://cloud.google.com/support
- Firebase Support: https://firebase.google.com/support

---

⚠️ **Remember**: Treat API keys like passwords. Never share them publicly or commit them to version control.