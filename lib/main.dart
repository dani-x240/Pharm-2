import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'database/db_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/expenses_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_recovery_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/customer_debt_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database helper eagerly
  await DbHelper.instance.database;

  runApp(const PharmApp());
}

class PharmApp extends StatelessWidget {
  const PharmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
      ],
      child: MaterialApp(
        title: 'Pharm',
        debugShowCheckedModeBanner: false,
        
        // Premium Light Theme
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: const Color(0xFF0D9488),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D9488),
            brightness: Brightness.light,
            primary: const Color(0xFF0D9488),
            secondary: const Color(0xFF0F766E),
            surface: Colors.white,
            error: Colors.redAccent,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        
        // Premium Dark Theme
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF0D9488),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D9488),
            brightness: Brightness.dark,
            primary: const Color(0xFF0D9488),
            secondary: const Color(0xFF14B8A6),
            surface: const Color(0xFF1E293B),
            background: const Color(0xFF0F172A),
            error: Colors.redAccent,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            color: Color(0xFF1E293B),
          ),
        ),
        
        themeMode: ThemeMode.system, // Auto detect light/dark preference
        
        home: const Gatekeeper(),
        routes: {
          '/setup': (_) => const SetupScreen(),
          '/login': (_) => const LoginScreen(),
          '/pin-recovery': (_) => const PinRecoveryScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/pos': (_) => const PosScreen(),
          '/inventory': (_) => const InventoryScreen(),
          '/expenses': (_) => const ExpensesScreen(),
          '/reports': (_) => const ReportsScreen(),
          '/debts': (_) => const CustomerDebtScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}

// Controls screen routing based on install setup and authentication states.
class Gatekeeper extends StatelessWidget {
  const Gatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // 1. If shop is not setup yet, show Welcome Setup screen
    if (!auth.isSetupCompleted) {
      return const SetupScreen();
    }
    
    // 2. If authenticated, unlock dashboard
    if (auth.isAuthenticated) {
      return const DashboardScreen();
    }
    
    // 3. Otherwise show PIN lock screen
    return const LoginScreen();
  }
}
