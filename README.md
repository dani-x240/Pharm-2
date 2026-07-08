# Pharm - Pharmacy Management System

A complete, production-ready pharmacy management application built with modern web technologies. Manage inventory, process sales, track expenses, and analyze business performance - all with offline-first capability.

## Live Demo

**Coming Soon** - Deploy to Vercel following the [Deployment Guide](DEPLOYMENT.md)

## Features

### 🏥 Complete Pharmacy Operations
- **Dashboard** - Real-time KPI metrics (revenue, profit, inventory value, expenses)
- **Inventory Management** - Track medicines, batches, expiry dates, and stock levels
- **POS System** - Professional point-of-sale interface for fast checkout
- **Sales Tracking** - Record all transactions with profit calculations
- **Expense Tracking** - Categorize and monitor business expenses
- **Reports & Analytics** - 6-month trends, profit margins, top sellers

### 📱 Mobile-First & PWA
- **Responsive Design** - Works perfectly on phones, tablets, and desktops
- **Installable App** - Install like a native app on Android/iOS
- **Offline Support** - Complete functionality without internet
- **Service Worker** - Automatic caching and background sync
- **No APK Required** - Works as a web app on all devices

### 🔐 Secure Authentication
- **Email & Password** - Standard secure login
- **PIN Protection** - Fast 4-6 digit PIN access
- **Security Questions** - Account recovery mechanism
- **Session Management** - Automatic timeouts and security

### 🗄️ Database & Backend
- **Neon PostgreSQL** - Scalable cloud database
- **Drizzle ORM** - Type-safe database queries
- **Better Auth** - Industry-standard authentication
- **Server Actions** - Secure backend operations

### 📊 Analytics & Reporting
- Date range filtering
- Revenue trends (6 months)
- Profit margin analysis
- Top products by sales
- Expense breakdowns
- Monthly performance metrics

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Frontend** | Next.js 16, React 19, Tailwind CSS v4 |
| **Backend** | Next.js Server Actions |
| **Database** | Neon PostgreSQL, Drizzle ORM |
| **Authentication** | Better Auth |
| **UI Components** | shadcn/ui, Lucide Icons |
| **PWA** | Service Workers, IndexedDB |
| **Hosting** | Vercel (recommended) |

## Quick Start

### Development

```bash
# Clone repository
git clone https://github.com/dani-x240/Pharm-2.git
cd Pharm-2

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env.local
# Add your DATABASE_URL and BETTER_AUTH_SECRET

# Run development server
pnpm dev

# Open http://localhost:3000
```

### Production Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions on deploying to Vercel.

Quick steps:
1. Push code to GitHub ✅ (Done)
2. Connect to Vercel dashboard
3. Add environment variables
4. Deploy!

## Project Structure

```
pharm-2/
├── app/                          # Next.js app directory
│   ├── dashboard/               # Main dashboard page
│   ├── inventory/               # Inventory management
│   ├── pos/                     # Point of sale interface
│   ├── reports/                 # Analytics & reporting
│   ├── expenses/                # Expense tracking
│   ├── sign-in/                 # Authentication
│   ├── setup-pin/               # PIN setup
│   ├── api/auth/               # Auth endpoints
│   └── actions/                 # Server actions
├── components/                   # React components
│   ├── dashboard-client.tsx
│   ├── inventory-client.tsx
│   ├── pos-client.tsx
│   ├── reports-client.tsx
│   ├── expenses-client.tsx
│   └── ...
├── lib/
│   ├── auth.ts                  # Auth configuration
│   ├── auth-client.ts           # Client auth
│   ├── db/                      # Database setup
│   │   ├── index.ts
│   │   └── schema.ts
│   └── utils.ts
├── public/
│   ├── manifest.json            # PWA manifest
│   ├── sw.js                    # Service worker
│   └── icons/
└── DEPLOYMENT.md                # Deployment guide
└── QUICK_START.md               # Quick start guide
```

## Database Schema

### Core Tables
- `user` - User accounts
- `session` - Login sessions
- `medicines` - Medicine catalog
- `inventory_batches` - Stock batches with expiry dates
- `sales_transactions` - Sale transactions
- `sale_items` - Items in each sale
- `expenses` - Business expenses
- `security_questions` - Recovery questions
- `user_pin` - PIN storage

## Usage Guide

### First Time Users

1. **Sign Up** - Register with email and password
2. **Set PIN** - Configure 4-6 digit PIN for quick access
3. **Add Medicines** - Populate your medicine catalog
4. **Add Inventory** - Add stock batches with prices and expiry
5. **Start Selling** - Use POS to process transactions

### Daily Operations

- **Morning** - Check dashboard for low stock and expiring medicines
- **Sales** - Use POS interface for fast checkout
- **Restock** - Add new inventory batches as needed
- **Analytics** - Review reports for performance insights

### Mobile Installation

**Android:**
1. Open app in Chrome
2. Tap menu (3 dots)
3. Select "Install app"
4. App appears on home screen

**iOS:**
1. Open app in Safari
2. Tap share button
3. Select "Add to Home Screen"
4. App works like native app

## Features Detail

### Dashboard
- Real-time revenue tracking
- Profit & margin calculations
- Low-stock alerts (customizable threshold)
- Expiring medicine notifications
- Monthly trend analysis
- Quick action buttons

### Inventory
- Search medicines by name/generic name
- Add/edit medicines with cost and selling prices
- Track batches with batch numbers and expiry dates
- Set reorder levels
- View available stock quantity
- Filter by expiration and stock status

### POS (Point of Sale)
- Quick product search
- Add to cart with quantity controls
- Real-time profit margin display
- Multiple payment methods (cash, card, transfer, credit)
- Professional checkout interface
- Receipt generation
- Transaction history

### Reports
- 6-month revenue trends
- Profit margin analysis
- Top-selling medicines
- Sale date filtering
- Monthly breakdowns
- PDF export ready

### Expenses
- Categorize expenses (rent, utilities, salary, supplies, etc.)
- Add notes to each expense
- Monthly views and summaries
- Category-wise analysis
- Quick entry form

## Security Features

- Password minimum 8 characters
- PIN hashing with SHA-256
- Session-based authentication
- Per-query user isolation (no RLS needed)
- CSRF protection
- Secure cookies
- Server-side validation

## Performance

- Optimized bundle size (~150KB gzipped)
- Next.js 16 with Turbopack
- SSR + Static generation
- Automatic code splitting
- Service worker caching
- IndexedDB for offline data

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile browsers (iOS Safari, Chrome Android)

## Offline Functionality

- View cached data while offline
- Create sales/expenses offline
- Automatic sync when online
- Service worker manages caching
- IndexedDB for local storage
- No data loss

## Deployment

### Vercel (Recommended)
- See [DEPLOYMENT.md](DEPLOYMENT.md)
- Free tier includes 12 Serverless Functions
- Automatic deployments from GitHub
- Custom domains supported

### Other Platforms
- AWS Amplify
- Firebase Hosting
- Railway
- Render
- Netlify (with limitations)

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host:port/dbname

# Authentication (required)
BETTER_AUTH_SECRET=your-32-character-random-string

# Optional
BETTER_AUTH_URL=https://yourdomain.com  # Custom domain
```

Generate `BETTER_AUTH_SECRET`:
```bash
openssl rand -base64 32
```

## Development

### Available Scripts

```bash
pnpm dev       # Start development server
pnpm build     # Build for production
pnpm start     # Start production server
pnpm lint      # Run linter
```

### Adding Features

1. Create server action in `app/actions/`
2. Create component in `components/`
3. Use in pages under `app/`
4. Test locally with `pnpm dev`
5. Push to GitHub for auto-deployment

### Database Migrations

Schema is managed through Neon MCP. To add tables:

```sql
CREATE TABLE table_name (
  id SERIAL PRIMARY KEY,
  userId TEXT NOT NULL,
  -- columns
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

## Troubleshooting

### Sign-in not working
- Check DATABASE_URL is correct
- Verify BETTER_AUTH_SECRET is set
- Clear browser cookies
- Check database `user` table exists

### PWA not installing
- Must be on HTTPS (Vercel provides this)
- Service worker registers on 2nd visit
- Check browser console for errors
- Try different browser

### Offline issues
- Service worker needs page refresh to activate
- Check IndexedDB in DevTools
- Clear service worker cache and reinstall

### Performance issues
- Check network tab for slow requests
- Monitor Core Web Vitals
- Use Vercel Analytics
- Optimize images

## Contributing

Contributions welcome! Please:
1. Fork repository
2. Create feature branch
3. Make changes
4. Test locally
5. Submit pull request

## License

MIT License - feel free to use commercially

## Support

- 📖 Read [QUICK_START.md](QUICK_START.md) for detailed guide
- 🚀 See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment help
- 💬 Open GitHub issues for bugs/features
- 📧 Contact for questions

## Roadmap

- [ ] Multi-location support
- [ ] Team collaboration
- [ ] Advanced reporting (PDF export)
- [ ] Supplier management
- [ ] Invoice generation
- [ ] Customer loyalty program
- [ ] Mobile native app (React Native)
- [ ] API for external integrations

## Credits

Built with:
- [Next.js](https://nextjs.org)
- [React](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)
- [Neon](https://neon.tech)
- [Better Auth](https://betterauth.dev)
- [shadcn/ui](https://ui.shadcn.com)

---

**Pharm** - Simplifying pharmacy management with modern technology.

GitHub: https://github.com/dani-x240/Pharm-2
