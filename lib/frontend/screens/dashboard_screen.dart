import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icu_app/backend/state/app_state.dart';
import 'package:icu_app/backend/models/patient.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentUserRole;

    return Scaffold(
      appBar: AppBar(
        title: Text('ICU Pro - $role'),
        actions: [
          IconButton(
            onPressed: () => appState.toggleTheme(), 
            icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode)
          ),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(role != null && role.isNotEmpty ? role[0] : 'U'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D47A1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text('Access Level: $role', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const Text('Secure Clinical Session', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            
            _drawerItem(context, Icons.dashboard, 'My Dashboard', '/dashboard'),
            
            // --- DOCTOR ONLY ---
            if (role == 'Doctor') ...[
              _drawerItem(context, Icons.menu_book_outlined, 'Clinical Protocols', '/protocols'),
              _drawerItem(context, Icons.assessment_outlined, 'Clinical Scoring (SOFA)', '/scoring'),
              _drawerItem(context, Icons.calculate, 'Advanced Dose Audit', '/dose_calculator'),
            ],

            // --- NURSE ONLY ---
            if (role == 'Nurse') ...[
              _drawerItem(context, Icons.assignment_turned_in, 'Shift Handover', '/handover'),
              _drawerItem(context, Icons.people, 'Patient Management', '/patient_management'),
              _drawerItem(context, Icons.menu_book, 'Drug Reference', '/drug_database'),
            ],

            // --- ADMIN ONLY SECTION ---
            if (role == 'Admin') ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                child: Text('SYSTEM ADMINISTRATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              _drawerItem(context, Icons.manage_accounts, 'User Management', '/user_management'),
              _drawerItem(context, Icons.bar_chart, 'Medication Analytics', '/analytics'),
              _drawerItem(context, Icons.history, 'System Audit Logs', '/audit_logs'),
              _drawerItem(context, Icons.settings_applications, 'Backend Configuration', '/config'),
            ],

            const Divider(),
            _drawerItem(context, Icons.logout, 'Log Out', '/login', isLogout: true),
          ],
        ),
      ),
      body: const RoleBasedDashboard(),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : null)),
      onTap: () {
        if (isLogout) {
          Provider.of<AppState>(context, listen: false).logout();
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

class RoleBasedDashboard extends StatelessWidget {
  const RoleBasedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = appState.currentUserRole;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(role),
          const SizedBox(height: 24),
          
          if (role == 'Admin') _buildAdminDashboard(appState, isMobile),
          if (role == 'Doctor') _buildDoctorDashboard(appState, isMobile),
          if (role == 'Nurse') _buildNurseDashboard(appState, isMobile),
          
          const SizedBox(height: 32),
          _buildContextualSection(role, appState),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String? role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, $role', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        Text('ICU Suite Pro - Customized for your role', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // --- ADMIN DASHBOARD ---
  Widget _buildAdminDashboard(AppState appState, bool isMobile) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
      children: [
        StatCard(title: 'Active Patients', value: appState.patients.length.toString(), icon: Icons.people, color: Colors.blue),
        StatCard(title: 'Total Logs', value: appState.activityLogs.length.toString(), icon: Icons.history, color: Colors.orange),
        StatCard(title: 'Sync Status', value: appState.isCloudSyncActive ? 'ONLINE' : 'OFFLINE', icon: Icons.cloud_done, color: Colors.green),
        StatCard(title: 'Staff Count', value: appState.activeStaff.length.toString(), icon: Icons.admin_panel_settings, color: Colors.purple),
      ],
    );
  }

  // --- DOCTOR DASHBOARD ---
  Widget _buildDoctorDashboard(AppState appState, bool isMobile) {
    final critical = appState.patients.where((p) => p.status == 'Critical').length;
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
      children: [
        StatCard(title: 'Critical Alerts', value: critical.toString(), icon: Icons.warning_amber, color: Colors.red),
        StatCard(title: 'Active Rounds', value: appState.patients.length.toString(), icon: Icons.assignment_ind, color: Colors.blue),
        StatCard(title: 'Clinical Guides', value: '12 New', icon: Icons.menu_book, color: Colors.teal),
      ],
    );
  }

  // --- NURSE DASHBOARD ---
  Widget _buildNurseDashboard(AppState appState, bool isMobile) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
      children: [
        StatCard(title: 'My Beds', value: appState.patients.length.toString(), icon: Icons.monitor_heart, color: Colors.teal),
        StatCard(title: 'Shift Notes', value: 'Active', icon: Icons.assignment, color: Colors.blue),
        StatCard(title: 'Available Beds', value: appState.availableBeds.length.toString(), icon: Icons.bed, color: Colors.green),
      ],
    );
  }

  Widget _buildContextualSection(String? role, AppState appState) {
    if (role == 'Admin') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Health & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...appState.activityLogs.take(5).map((log) => ListTile(
            leading: const Icon(Icons.security, color: Colors.blue),
            title: Text(log['action'] ?? ''),
            subtitle: Text(log['timestamp'] ?? ''),
          )),
        ],
      );
    } else if (role == 'Doctor') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority Patient Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...appState.patients.take(5).map((p) => ListTile(
            leading: CircleAvatar(backgroundColor: p.status == 'Critical' ? Colors.red[100] : Colors.blue[100], child: Text(p.name[0])),
            title: Text(p.name),
            subtitle: Text('Bed: ${p.bedNumber} • ${p.status}'),
            trailing: const Icon(Icons.assessment, color: Colors.blue),
          )),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Bedside Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...appState.patients.take(5).map((p) => ListTile(
            leading: const Icon(Icons.bed, color: Colors.teal),
            title: Text(p.name),
            subtitle: Text('Vitals check due: Now'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(4)),
              child: const Text('MONITOR', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      );
    }
  }
}

class StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))));
  }
}
