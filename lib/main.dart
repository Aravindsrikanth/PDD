import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// The only two imports you need now:
import 'package:icu_app/backend.dart';
import 'package:icu_app/frontend.dart';

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

class ICUSuitePro extends StatelessWidget {
  const ICUSuitePro({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return MaterialApp(
      title: 'ICU Suite Pro',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 24),
            Text('ICU SUITE PRO', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
