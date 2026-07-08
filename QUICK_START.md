# Pharm - Quick Start Guide

## What is Pharm?

Pharm is a complete, production-ready pharmacy management system built with:
- **Next.js 16** for the web app
- **Neon PostgreSQL** for the database
- **Better Auth** for secure authentication
- **Service Workers** for offline-first support
- **Responsive design** for all devices

---

## Getting Started

### 1. **Clone from GitHub**
```bash
git clone https://github.com/dani-x240/Pharm-2.git
cd Pharm-2
```

### 2. **Install Dependencies**
```bash
pnpm install
```

### 3. **Set Environment Variables**
Create a `.env.local` file:
```
DATABASE_URL=your_neon_database_url
BETTER_AUTH_SECRET=your_32_char_secret_key
```

Generate a secret with:
```bash
openssl rand -base64 32
```

### 4. **Run Development Server**
```bash
pnpm dev
```

Open http://localhost:3000 and you'll be redirected to the sign-in page.

---

## Main Features

### 📊 Dashboard
- Real-time revenue and profit tracking
- Low-stock alerts
- Expiring medicine notifications
- Monthly trend analysis

### 📦 Inventory Management
- Add/edit medicines
- Track batches with expiry dates
- Set reorder levels
- Search and filter medicines

### 💳 POS (Point of Sale)
- Quick product search
- Shopping cart with quantity control
- Real-time profit calculations
- Multiple payment methods
- Receipt generation

### 📈 Reports & Analytics
- 6-month sales trends
- Profit margin analysis
- Top-selling medicines
- Expense breakdown

### 💰 Expense Tracking
- Categorize expenses (rent, utilities, salary, etc.)
- Monthly views
- Expense analytics

### 📱 PWA (Progressive Web App)
- Works offline
- Installable on mobile
- Native-like experience
- Automatic sync when online

---

## User Flows

### First Time Setup
1. **Sign Up**: Email + Password
2. **Set PIN**: 4-6 digit PIN for quick access
3. **Security Questions**: Set 2 recovery questions
4. **Start Using**: Ready to manage pharmacy!

### Daily Operations
1. **Dashboard**: Check today's metrics
2. **POS**: Process customer sales
3. **Inventory**: Add stock as needed
4. **Reports**: View performance

### Mobile Installation
- **Android**: Chrome → Menu → "Install app"
- **iOS**: Safari → Share → "Add to Home Screen"
- Works completely offline with sync when online

---

## File Structure

```
Pharm-2/
├── app/
│   ├── api/auth/          # Authentication endpoints
│   ├── dashboard/         # Main dashboard
│   ├── inventory/         # Inventory management
│   ├── pos/              # Point of sale
│   ├── reports/          # Reports & analytics
│   ├── expenses/         # Expense tracking
│   └── actions/          # Server-side logic
├── components/
│   ├── dashboard-client.tsx
│   ├── inventory-client.tsx
│   ├── pos-client.tsx
│   ├── reports-client.tsx
│   └── ...
├── lib/
│   ├── auth.ts           # Auth configuration
│   ├── auth-client.ts    # Client-side auth
│   └── db/              # Database setup
└── public/
    ├── manifest.json     # PWA manifest
    └── sw.js            # Service worker
```

---

## Database Schema

The app creates these tables automatically:

- **user** - User accounts (Better Auth)
- **session** - Login sessions (Better Auth)
- **medicines** - Medicine catalog
- **inventory_batches** - Stock batches with expiry
- **sales_transactions** - Sale records
- **sale_items** - Items in each sale
- **expenses** - Business expenses
- **security_questions** - Account recovery
- **user_pin** - PIN storage

---

## Development Tips

### Adding a New Medicine
```javascript
// app/actions/inventory.ts
export async function addMedicine(data) {
  const userId = await getUserId()
  await db.insert(medicines).values({
    userId,
    name: data.name,
    costPrice: data.cost,
    sellingPrice: data.selling,
    ...
  })
}
```

### Creating a Sale
```javascript
// app/actions/sales.ts
export async function createSale(items) {
  const userId = await getUserId()
  // 1. Create transaction
  // 2. Add sale items
  // 3. Update inventory
  // 4. Return receipt
}
```

### Querying Data
```javascript
// Always scope by userId (no RLS on Neon)
const items = await db
  .select()
  .from(medicines)
  .where(eq(medicines.userId, userId))
```

---

## Deployment to Vercel

### Simple Method: Connect GitHub
1. Go to https://vercel.com
2. Click "New Project"
3. Connect your GitHub repo (dani-x240/Pharm-2)
4. Add `BETTER_AUTH_SECRET` environment variable
5. Deploy!

See `DEPLOYMENT.md` for detailed instructions.

---

## Browser Compatibility

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile browsers (iOS Safari, Chrome Android)

---

## Common Tasks

### Reset PIN
1. Go to /setup-pin (after login)
2. Set new PIN and security questions

### Backup Data
1. Export sales data from reports page
2. Database backed up daily on Neon

### Offline Usage
1. Set up medicines while online
2. Do sales transactions offline
3. Changes sync automatically when online

### Add Users
1. Currently single-user per account
2. Multiple accounts per pharmacy possible
3. Shared database coming soon

---

## Troubleshooting

### App won't start
```bash
# Clear dependencies and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install
pnpm dev
```

### Database connection error
- Verify `DATABASE_URL` in `.env.local`
- Check Neon dashboard for active database
- Verify firewall allows connections

### Sign-in not working
- Clear browser cookies
- Check database has `user` table
- Check `BETTER_AUTH_SECRET` is set

### PWA not installing
- Need to access app over HTTPS (Vercel provides this)
- Service worker may need 2-3 page visits to activate
- Check browser console for service worker errors

---

## Next Steps

1. **Deploy to Vercel**: See DEPLOYMENT.md
2. **Add Your Data**: Create medicines and prices
3. **Train Users**: Walk through each module
4. **Monitor Analytics**: Use reports for insights
5. **Scale Up**: Add more users/locations as needed

---

## Support

- Check the app's online documentation
- Review code comments for implementation details
- See PHARM_README.md for full feature documentation
- Check DEPLOYMENT.md for deployment questions

**Your Pharm app is ready to run your pharmacy!** 🎉
