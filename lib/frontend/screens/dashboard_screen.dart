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
    final role = Provider.of<AppState>(context).currentUserRole;

    return Scaffold(
      appBar: AppBar(
        title: Text('ICU Dashboard - $role'),
        actions: [
          IconButton(
            onPressed: () => Provider.of<AppState>(context, listen: false).toggleTheme(), 
            icon: Icon(Provider.of<AppState>(context).isDarkMode ? Icons.light_mode : Icons.dark_mode)
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All systems normal. 0 unread notifications.'),
                  behavior: SnackBarBehavior.floating,
                )
              );
            }, 
            icon: const Icon(Icons.notifications_active_outlined)
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
                  Text('Staff: $role', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const Text('ID: 88492-A', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
            _drawerItem(context, Icons.people, 'Patient Management', '/patient_management'),
            _drawerItem(context, Icons.calculate, 'Dose Calculator', '/dose_calculator'),
            _drawerItem(context, Icons.assessment_outlined, 'Clinical Scoring (SOFA)', '/scoring'),
            _drawerItem(context, Icons.security, 'Interaction Checker', '/interaction_checker'),
            _drawerItem(context, Icons.menu_book, 'Drug Reference', '/drug_database'),
            _drawerItem(context, Icons.receipt_long, 'Prescriptions', '/prescriptions'),
            _drawerItem(context, Icons.bar_chart, 'Medication Analytics', '/analytics'),
            const Divider(),
            _drawerItem(context, Icons.history, 'Activity Logs', '/audit_logs'),
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

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final activePatients = appState.patients.length;
    final criticalAlerts = appState.patients.where((p) => p.status == 'Critical').length;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final criticalPatients = appState.patients.where((p) => p.status == 'Critical').toList();

    return RefreshIndicator(
      onRefresh: () => appState.syncWithServer(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinical Overview',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => appState.syncWithServer(),
                          icon: appState.isLoading 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sync, size: 16),
                          label: const Text('SYNC SERVER', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/emergency'),
                          icon: const Icon(Icons.warning_amber, size: 16),
                          label: const Text('EMERGENCY', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clinical Overview',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => appState.syncWithServer(),
                            icon: appState.isLoading 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.sync, size: 18),
                            label: const Text('SYNC SERVER'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: appState.isCloudSyncActive ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              appState.isCloudSyncActive ? 'CLOUD SYNC ACTIVE' : 'LOCAL MODE (SYNC DISABLED)',
                              style: TextStyle(
                                color: appState.isCloudSyncActive ? Colors.green : Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/emergency'),
                        icon: const Icon(Icons.warning_amber, size: 18),
                        label: const Text('EMERGENCY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

          const SizedBox(height: 24),

          if (criticalPatients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CRITICAL PATIENTS: ${criticalPatients.length}', 
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text('Beds: ${criticalPatients.map((p) => p.bedNumber).join(", ")} require immediate attention.',
                            style: TextStyle(color: Colors.red[900], fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/patient_management'),
                      child: const Text('VIEW ALL'),
                    ),
                  ],
                ),
              ),
            ),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 1.4 : 1.1,
            children: [
              StatCard(
                title: 'Active Patients', 
                value: activePatients.toString(), 
                icon: Icons.people, 
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/patient_management'),
              ),
              StatCard(
                title: 'Available Beds', 
                value: appState.availableBeds.length.toString(), 
                icon: Icons.bed, 
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/patient_management'),
              ),
              StatCard(
                title: 'Critical Alerts', 
                value: criticalAlerts.toString(), 
                icon: Icons.notification_important, 
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/patient_management'),
              ),
              StatCard(
                title: 'Staff Active', 
                value: appState.activeStaff.length.toString(),
                icon: Icons.medical_services, 
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Active Staff: ${appState.activeStaff.join(", ")}'),
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                },
              ),
            ],
          ),
          
          if (appState.isLoading && isMobile)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(),
            ),

          const SizedBox(height: 32),
          
          _buildShiftHandover(context, appState),

          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildPatientList(context, appState.patients)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRecentActivity(appState.activityLogs)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPatientList(context, appState.patients),
                    const SizedBox(height: 24),
                    _buildRecentActivity(appState.activityLogs),
                  ],
                );
              }
            }
          ),
        ],
      ),
    ),
  );
}

  Widget _buildShiftHandover(BuildContext context, AppState appState) {
    return Card(
      color: const Color(0xFF0D47A1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('SHIFT HANDOVER NOTES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                  onPressed: () {
                    final controller = TextEditingController(text: appState.shiftHandover);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Handover Notes'),
                        content: TextField(
                          controller: controller,
                          maxLines: 5,
                          decoration: const InputDecoration(hintText: 'Enter vital shift information...'),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                          ElevatedButton(
                            onPressed: () {
                              appState.updateHandover(controller.text);
                              Navigator.pop(context);
                            }, 
                            child: const Text('SAVE')
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appState.shiftHandover,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Last updated: Just now by Dr. Smith', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(BuildContext context, List<Patient> patients) {
    final displayPatients = patients.length > 4 ? patients.sublist(0, 4) : patients;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Patients in ICU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayPatients.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final p = displayPatients[index];
                return ListTile(
                  onTap: () => Navigator.pushNamed(context, '/patient_management'),
                  leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.person, size: 20)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Bed ${p.bedNumber} • Age: ${p.age}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.status == 'Critical' ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.status,
                      style: TextStyle(color: p.status == 'Critical' ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Map<String, dynamic>> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...logs.take(5).map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['action']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(log['time']?.toString() ?? log['timestamp']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, 
                      style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold), 
                      maxLines: 2,
                    ),
                    Text(value, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
