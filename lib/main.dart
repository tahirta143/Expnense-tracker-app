import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'themes/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found. AI features may not work.");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider<WalletProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, walletProvider, expenseProvider) {
            expenseProvider?.updateWalletProvider(walletProvider);
            return expenseProvider ?? ExpenseProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Expense Tracker',
            theme: AppTheme.getLightTheme(),
            darkTheme: AppTheme.getDarkTheme(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
