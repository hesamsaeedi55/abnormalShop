# 🔐 Login Security - Quick Reference Guide

## Your Login Endpoint
```
POST https://myshop-backend-an7h.onrender.com/accounts/token/

Body: {"email": "user@example.com", "password": "password"}
```

---

## Security Flow (Automatic)

```
┌─────────────────────────────────────────────────────┐
│  Failed Attempt Count → Security Response          │
├─────────────────────────────────────────────────────┤
│  0-3 attempts   → Tier 1: Normal (instant)         │
│  4-5 attempts   → Tier 2: Warning + 2s delay       │
│  6-8 attempts   → Tier 3: CAPTCHA + 5s delay       │
│  9-10 attempts  → Tier 4: Email Code + 10s delay   │
│  11+ attempts   → Tier 5: Account Lock (1 hour)    │
└─────────────────────────────────────────────────────┘
```

---

## What Happens at Each Tier

### Tier 1-2: User Friendly
- Normal login flow
- Generic error messages
- Progressive warnings

### Tier 3: CAPTCHA Required
```json
POST /accounts/token/
{
  "email": "user@example.com",
  "password": "password",
  "captcha_token": "token_here"
}
```
- User receives warning email
- CAPTCHA appears on frontend

### Tier 4: Email Verification
```json
POST /accounts/token/
{
  "email": "user@example.com", 
  "password": "password",
  "verification_code": "123456"
}
```
- 6-digit code emailed
- 10 minute expiration
- 3 max attempts

### Tier 5: Account Locked
- 1 hour automatic lock
- Email with unlock link
- Manual unlock via: `GET /accounts/unlock/{token}/`

---

## Key Numbers

| Limit Type | Value | Action |
|-----------|-------|--------|
| Per Minute (IP) | 5 attempts | Temporary block |
| Per Hour (IP) | 30 attempts | 24h IP ban |
| Per Day (Email) | 11 attempts | Account lock |
| Lock Duration | 1 hour | Auto-unlock |
| Fast Attack | 10 in 2min | Immediate lock |

---

## Security Endpoints

```bash
# Check Status
POST /accounts/security/status/
Body: {"email": "user@example.com"}

# Resend Code
POST /accounts/resend-code/
Body: {"email": "user@example.com"}

# Unlock Account
GET /accounts/unlock/{token}/

# Dashboard (Admin)
GET /accounts/security/dashboard/
```

---

## Monitoring

### Django Admin
`https://your-domain.com/admin/`
- Login Attempts
- Account Locks
- Verification Codes

### Logs
`myshop2/myshop/logs/security.log`

---

## Quick Fixes

### Unlock Account Manually
```bash
python manage.py shell
>>> from accounts.models import AccountLock
>>> lock = AccountLock.objects.get(email='user@email.com', is_active=True)
>>> lock.unlock(method='admin')
```

### Adjust Security Level
Edit `myshop2/myshop/myshop/settings.py`:
```python
LOGIN_SECURITY_TIER_5_LOCK = 15  # Instead of 11
```

### Test Email Delivery
```bash
python manage.py shell
>>> from accounts.email_service import SecurityEmailService
>>> SecurityEmailService.send_warning_email('test@email.com', 6, 2, '127.0.0.1')
```

---

## Response Examples

### Success
```json
{
  "access": "eyJ0eXAi...",
  "refresh": "eyJ0eXAi...",
  "user_id": 123,
  "security": {
    "tier": 1,
    "message": "Login successful"
  }
}
```

### Failed (Tier 2)
```json
{
  "detail": "Invalid email or password. 2 attempt(s) remaining before additional security measures."
}
```

### CAPTCHA Required (Tier 3)
```json
{
  "captcha_required": true,
  "message": "Please complete the CAPTCHA verification."
}
```

### Verification Required (Tier 4)
```json
{
  "verification_required": true,
  "message": "Verification code sent to your email. Please enter it to continue."
}
```

### Account Locked (Tier 5)
```json
{
  "detail": "Account temporarily locked for security. Try again in 55 minute(s)."
}
```

---

## Email Templates Sent

1. **Warning Email** (Tier 3)
   - Subject: "⚠️ Security Alert: Multiple Failed Login Attempts"
   - Content: Warning with attempt count

2. **Verification Code** (Tier 4)
   - Subject: "🔒 Your Verification Code"
   - Content: 6-digit code

3. **Account Locked** (Tier 5)
   - Subject: "🔐 Account Temporarily Locked - Action Required"
   - Content: Lock reason + unlock link

4. **Unlock Success**
   - Subject: "✅ Your Account Has Been Unlocked"
   - Content: Confirmation

---

## Configuration File
All settings: `myshop2/myshop/myshop/settings.py`

Search for: `LOGIN_SECURITY_`

---

**System Status:** ✅ Production Ready  
**Documentation:** LOGIN_SECURITY_SYSTEM_COMPLETE.md

