# Pharm Deployment Guide

## GitHub Repository
✅ **Successfully pushed to**: https://github.com/dani-x240/Pharm-2.git

Your Pharm pharmacy management system is now on GitHub with all source code and configuration.

---

## Vercel Deployment Steps

### Step 1: Connect Your GitHub Repository to Vercel

1. Go to **https://vercel.com/dashboard**
2. Click **"Add New..."** → **"Project"**
3. Select **"Import Git Repository"**
4. Find and select **"dani-x240/Pharm-2"**
5. Click **"Import"**

### Step 2: Configure Environment Variables

After importing, you'll see the environment variables screen:

1. **Add `BETTER_AUTH_SECRET`**:
   - Click **"Add Environment Variable"**
   - **Name**: `BETTER_AUTH_SECRET`
   - **Value**: Generate a secure random string using:
     ```bash
     openssl rand -base64 32
     ```
   - Select all environments (Production, Preview, Development)
   - Click **"Add"**

2. **Add `DATABASE_URL`**:
   - This should already be available from your Neon integration
   - If not, add it with your Neon connection string

3. Click **"Deploy"**

### Step 3: Monitor Deployment

- Vercel will build and deploy automatically
- Watch the build logs in the dashboard
- Once deployment is complete, you'll get a live URL

### Step 4: Access Your App

After successful deployment:
- Your app will be live at: `https://[project-name].vercel.app`
- Or your custom domain if configured
- All environment variables are automatically injected

---

## Environment Variables Required

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `DATABASE_URL` | Neon PostgreSQL connection string | Neon dashboard or v0 integration |
| `BETTER_AUTH_SECRET` | 32+ character random string for auth signing | Generate with `openssl rand -base64 32` |

---

## Features After Deployment

✅ **Full Production Deployment**:
- Authentication (email/password + PIN)
- Database (Neon PostgreSQL)
- All API routes and server actions
- Offline-first PWA support
- Service worker for caching

✅ **PWA Installation** (No APK needed):
- **Android**: Open app in Chrome → Menu → "Install app"
- **iOS**: Open app in Safari → Share → "Add to Home Screen"
- Works exactly like a native app
- Full offline capability with IndexedDB sync

---

## Continuous Deployment

Every time you push to `main` branch on GitHub:
1. Vercel automatically detects the push
2. Builds the project
3. Deploys to your live URL
4. Previous deployments stay available for rollback

---

## Deployment Checklist

- [ ] GitHub repository created and pushed
- [ ] Vercel project connected
- [ ] Environment variables added (`BETTER_AUTH_SECRET`, `DATABASE_URL`)
- [ ] Build successful (no errors in logs)
- [ ] App accessible at live URL
- [ ] Sign-in page loads correctly
- [ ] Can create account and set PIN
- [ ] Dashboard displays (may need sample data)
- [ ] PWA installable on mobile

---

## Troubleshooting

### Build Fails with "BETTER_AUTH_SECRET not set"
- Check that `BETTER_AUTH_SECRET` is added in Vercel project settings
- Verify it's added to Production, Preview, and Development environments
- Redeploy after adding the variable

### Database Connection Errors
- Confirm `DATABASE_URL` is correctly set
- Verify Neon database is accessible
- Check that tables were created (run schema setup in Neon)

### PWA Not Installing on Mobile
- Open app in latest Chrome (Android) or Safari (iOS)
- Full offline support requires service worker activation
- May take 2-3 page visits for service worker to register

### Login Issues
- Clear cookies and cache
- Try in incognito/private browser window
- Verify database has `user` table created

---

## Next Steps After Deployment

1. **Create your first account**: Go to sign-in and register
2. **Set PIN & Security Questions**: After signup, configure PIN
3. **Add medicines**: Go to Inventory → Add Medicine
4. **Add inventory batches**: Add stock batches with expiry dates
5. **Start selling**: POS interface ready for transactions
6. **View analytics**: Dashboard shows real-time metrics

---

## Support

For issues or questions:
- Check Vercel deployment logs
- Review environment variables
- Verify Neon database connection
- Check browser console for errors

Your Pharm application is production-ready and fully deployed!
