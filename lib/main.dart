import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/frontend/screens/login_screen.dart';
import 'package:icu_app/frontend/screens/registration_screen.dart';
import 'package:icu_app/frontend/screens/forgot_password_screen.dart';
import 'package:icu_app/frontend/screens/db_config_screen.dart';
import 'package:icu_app/frontend/screens/dashboard_screen.dart';
import 'package:icu_app/frontend/screens/patient_management.dart';
import 'package:icu_app/frontend/screens/dose_calculator.dart';
import 'package:icu_app/frontend/screens/interaction_checker.dart';
import 'package:icu_app/frontend/screens/prescriptions.dart';
import 'package:icu_app/frontend/screens/audit_logs.dart';
import 'package:icu_app/frontend/screens/emergency.dart';
import 'package:icu_app/frontend/screens/analytics.dart';
import 'package:icu_app/frontend/screens/report_generator.dart';
import 'package:icu_app/frontend/screens/scoring.dart';
import 'package:icu_app/frontend/screens/drug_database.dart';
import 'package:icu_app/frontend/screens/clinical_protocols.dart';
import 'package:icu_app/frontend/screens/shift_handover.dart';
import 'package:icu_app/frontend/screens/user_management.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const ICUSuitePro(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ICUSuitePro extends StatelessWidget {
  const ICUSuitePro({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ICU Suite Pro',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00B0FF),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF0D47A1),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => MedicalLoginScreen(), 
        '/register': (context) => RegistrationScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/config': (context) => DbConfigScreen(),
        '/dashboard': (context) => MainShell(),
        '/patient_management': (context) => PatientManagementScreen(),
        '/dose_calculator': (context) => DoseCalculatorScreen(),
        '/interaction_checker': (context) => InteractionScreen(),
        '/prescriptions': (context) => PrescriptionScreen(),
        '/audit_logs': (context) => AuditLogScreen(),
        '/emergency': (context) => EmergencyScreen(),
        '/analytics': (context) => AnalyticsScreen(),
        '/reports': (context) => ReportGeneratorScreen(),
        '/scoring': (context) => ScoringScreen(),
        '/drug_database': (context) => DrugDatabaseScreen(),
        '/protocols': (context) => ClinicalProtocolsScreen(),
        '/handover': (context) => ShiftHandoverScreen(),
        '/user_management': (context) => UserManagementScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services_rounded, size: 80, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 24),
            Text('ICU SUITE PRO',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                  letterSpacing: 2,
                )),
            const Text('Professional Critical Care System',
                style: TextStyle(color: Colors.grey, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}
