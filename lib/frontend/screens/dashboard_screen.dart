import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/backend/models/patient.dart';
import '../widgets/custom_card.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AppState>(context).currentUserRole;

    return Scaffold(
      appBar: AppBar(
        title: Text('ICU Dashboard - $role'),
        actions: [
          IconButton(onPressed: () => Provider.of<AppState>(context, listen: false).toggleTheme(), icon: Icon(Provider.of<AppState>(context).isDarkMode ? Icons.light_mode : Icons.dark_mode)),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          CircleAvatar(backgroundColor: Colors.blue[100], child: Text(role?[0] ?? 'U')),
          const SizedBox(width: 20),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(decoration: BoxDecoration(color: Color(0xFF0D47A1)), child: Icon(Icons.account_circle, color: Colors.white, size: 50)),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
            _drawerItem(context, Icons.people, 'Patient Management', '/patient_management'),
            _drawerItem(context, Icons.calculate, 'Dose Calculator', '/dose_calculator'),
            _drawerItem(context, Icons.assessment_outlined, 'SOFA Score', '/scoring'),
            _drawerItem(context, Icons.logout, 'Logout', '/login', isLogout: true),
          ],
        ),
      ),
      body: const DashboardContent(),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : null)),
      onTap: () { if (isLogout) { Provider.of<AppState>(context, listen: false).logout(); Navigator.pushReplacementNamed(context, '/login'); } else { Navigator.pop(context); Navigator.pushNamed(context, route); } },
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Overview', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              StatCard(title: 'Active Patients', value: appState.patients.length.toString(), icon: Icons.people, color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/patient_management')),
              StatCard(title: 'Available Beds', value: appState.availableBeds.length.toString(), icon: Icons.bed, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]))));
  }
}
