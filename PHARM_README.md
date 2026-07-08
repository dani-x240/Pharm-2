# Pharm - Pharmacy Management System

A complete, production-ready pharmacy management system built with Next.js 16, Neon PostgreSQL, Better Auth, and Drizzle ORM.

## Features

### Core Features
- **PIN + Security Questions Authentication** - Secure dual-factor authentication system
- **Real-time Dashboard Analytics** - Live metrics for revenue, profit, inventory value, and expenses
- **Complete Inventory Management** - Track medicines, batches, expiry dates, and low-stock alerts
- **POS Interface** - Professional point-of-sale checkout with cart management
- **Advanced Reporting** - Sales, profit, and expense analytics with monthly trends
- **Expense Tracking** - Categorize and track all operating expenses
- **Offline-First PWA** - Works completely offline with automatic sync when online

### Technical Features
- **Service Workers** - Offline caching and background sync capabilities
- **IndexedDB** - Client-side database for offline data persistence
- **Server Actions** - Secure backend operations with automatic scoping
- **Real-time Data** - Live updates across all modules
- **Responsive Design** - Works perfectly on mobile, tablet, and desktop
- **Dark Mode Support** - Built-in dark mode with system preference detection

## Tech Stack

- **Frontend**: Next.js 16, React 19, Tailwind CSS v4
- **Backend**: Next.js Server Actions, PostgreSQL
- **Database**: Neon PostgreSQL + Drizzle ORM
- **Authentication**: Better Auth (email + password + PIN)
- **UI Components**: shadcn/ui
- **Icons**: Lucide React

## Installation & Setup

### Prerequisites
- Node.js 18+ (with pnpm)
- Neon PostgreSQL account
- Environment variables configured in Vercel

### Environment Variables Required
```
DATABASE_URL=postgresql://[user]:[password]@[host]/[database]
BETTER_AUTH_SECRET=[generated-secret]
```

Generate `BETTER_AUTH_SECRET` with:
```bash
openssl rand -base64 32
```

### Local Development

1. **Install dependencies**
```bash
pnpm install
```

2. **Set environment variables**
   - Create `.env.local` in project root
   - Add `DATABASE_URL` and `BETTER_AUTH_SECRET`

3. **Run development server**
```bash
pnpm dev
```

4. **Access the app**
   - Open http://localhost:3000
   - Sign up or sign in
   - Set up PIN and security questions
   - Access dashboard

## Project Structure

```
app/
├── layout.tsx                 # Root layout with PWA setup
├── page.tsx                   # Home (redirects to dashboard)
├── sign-in/page.tsx          # Sign-in page
├── sign-up/page.tsx          # Sign-up page
├── setup-pin/page.tsx        # PIN & security setup
├── dashboard/page.tsx        # Analytics dashboard
├── inventory/page.tsx        # Inventory management
├── pos/page.tsx              # Point of sale
├── reports/page.tsx          # Reports & analytics
├── expenses/page.tsx         # Expense tracking
├── api/auth/[...all]/route.ts # Better Auth handler
└── actions/                   # Server actions
    ├── auth.ts               # Authentication helpers
    ├── inventory.ts          # Inventory operations
    ├── sales.ts              # Sales transactions
    └── expenses.ts           # Expense operations

components/
├── dashboard-client.tsx       # Dashboard UI
├── inventory-client.tsx       # Inventory UI
├── pos-client.tsx            # POS UI
├── reports-client.tsx        # Reports UI
├── expenses-client.tsx       # Expenses UI
├── pin-setup-form.tsx        # PIN setup form
├── auth-form.tsx             # Auth form
└── ui/                        # shadcn/ui components

lib/
├── auth.ts                   # Better Auth config
├── auth-client.ts            # Better Auth client
└── db/
    ├── index.ts              # Drizzle instance
    └── schema.ts             # Database schema

public/
├── manifest.json             # PWA manifest
└── sw.js                     # Service worker
```

## Database Schema

### Core Tables
- `user` - User accounts (Better Auth)
- `session` - User sessions (Better Auth)
- `account` - Auth accounts (Better Auth)
- `verification` - Email verification (Better Auth)

### Pharm Tables
- `medicines` - Medicine catalog
- `inventory_batches` - Stock batches with expiry tracking
- `sales_transactions` - All sales with profit calculation
- `sale_items` - Individual items in each sale
- `expenses` - Operating expenses by category
- `security_questions` - Recovery questions
- `user_pin` - Hashed PINs for app access

## Authentication Flow

1. **Sign Up** - Create account with email and password
2. **Email Verification** - Verify email address
3. **PIN Setup** - Set 4-6 digit PIN
4. **Security Questions** - Answer 2 security questions for account recovery
5. **Access Dashboard** - Full access to all features

## Offline Features

The app includes a comprehensive offline-first architecture:

- **Service Worker** - Caches all assets and API responses
- **Network First for APIs** - Tries network first, falls back to cache
- **Cache First for Static Assets** - Uses cached assets when offline
- **Background Sync** - Queues sales and expenses for sync when online
- **IndexedDB** - Local database for offline data
- **Offline Page** - User-friendly offline indicator

## Key Pages

### Dashboard (`/dashboard`)
- Real-time analytics with KPIs
- Monthly revenue and profit trends
- Inventory alerts
- Quick action buttons

### Inventory (`/inventory`)
- Add/edit medicines
- Track inventory batches
- Monitor stock levels
- Expiry date tracking
- Low-stock alerts

### POS (`/pos`)
- Search and add medicines to cart
- Adjust quantities
- See profit margin
- Process payments
- Multiple payment methods

### Reports (`/reports`)
- Date range filtering
- Revenue and profit tracking
- Top sales analysis
- 6-month trends
- Performance metrics

### Expenses (`/expenses`)
- Categorize expenses
- Monthly breakdown
- Category analysis
- Transaction history

## Deployment

### Deploy to Vercel

1. **Connect GitHub repo**
   - Push code to GitHub
   - Connect repo to Vercel

2. **Set Environment Variables**
   - Go to Vercel Project Settings → Environment Variables
   - Add `DATABASE_URL` and `BETTER_AUTH_SECRET`

3. **Deploy**
   - Push to main branch
   - Vercel auto-deploys
   - Monitor deployment

### Generate APK (Android)

To convert to native Android app:

1. Use **Capacitor** or **React Native Web** wrapper
2. Build APK with Android Studio
3. Install on device

For immediate mobile access:
- Install as PWA on Android/iOS
- Open app URL on device
- Tap "Install" or "Add to Home Screen"
- Works like native app with offline support

## PWA Installation

### Android
1. Open app in Chrome
2. Tap menu (⋮) → "Install app"
3. Confirm installation
4. App appears on home screen

### iOS
1. Open app in Safari
2. Tap share (↑) → "Add to Home Screen"
3. Name and add
4. App appears on home screen

## Performance Tips

- Inventory batches are automatically cleaned of expired items
- Sales and expense data is paginated for faster loading
- Service worker caches reduce bandwidth usage
- IndexedDB provides instant local data access

## Security

- PIN is hashed with SHA-256
- Security questions answers are hashed
- All API calls scoped to authenticated user
- No sensitive data in local storage
- CSRF protection via Better Auth
- Password minimum 8 characters

## Support & Troubleshooting

### Clear Cache
- Chrome DevTools → Application → Clear site data
- Or reinstall PWA

### Reset Data
- Delete database branch in Neon console
- Create new branch
- Re-authenticate

### Service Worker Issues
- Check browser console for errors
- Unregister SW in DevTools
- Hard refresh (Ctrl+Shift+R)

## License

This is a custom application built for pharmacy management.

## Credits

Built with:
- Next.js 16
- Neon PostgreSQL
- Better Auth
- Drizzle ORM
- shadcn/ui
- Tailwind CSS
