// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/transaction_viewmodel.dart';
import 'views/auth/auth_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/analysis/analysis_view.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const FinanceiroApp());
}

class FinanceiroApp extends StatelessWidget {
  const FinanceiroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
      ],
      child: MaterialApp(
        title: 'FinançasPro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthView(),
          '/dashboard': (_) => const DashboardView(),
          '/analysis': (_) => const AnalysisView(),
        },
      ),
    );
  }
}
