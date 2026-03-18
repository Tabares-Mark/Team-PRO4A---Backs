import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../tech_admin/manage_units_screen.dart';
import '../tech_admin/venue_management_screen.dart';
import '../unit/personnel_enrolment_screen.dart';
import 'viewer_announcements_screen.dart';
import '../shared/calendar_screen.dart';
import '../shared/bug_report_screen.dart';

class ViewerAdminHome extends StatefulWidget {
  const ViewerAdminHome({super.key});

  @override
  State<ViewerAdminHome> createState() => _ViewerAdminHomeState();
}

class _ViewerAdminHomeState extends State<ViewerAdminHome> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final List<NavItem> _navItems = [
    const NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    const NavItem(icon: Icons.campaign, label: 'Announcements'),
    const NavItem(icon: Icons.business, label: 'Units'),
    const NavItem(icon: Icons.people, label: 'Personnel'),
    const NavItem(icon: Icons.pin_drop, label: 'Venue Management'),
    const NavItem(icon: Icons.calendar_month, label: 'Calendar'),
    const NavItem(icon: Icons.bug_report, label: 'Bug Reports'),
  ];

  final List<Widget> _pages = [
    const _PlaceholderPage(title: 'Dashboard'),
    const ViewerAnnouncementsScreen(),
    const ManageUnitsScreen(isReadOnly: true),
    const PersonnelEnrolmentScreen(isReadOnly: true),
    const VenueManagementScreen(isReadOnly: true),
    const CalendarScreen(calendarType: CalendarType.viewerAdmin),  
    const BugReportScreen(),
    ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Row(
          children: [
            AppSidebar(
              navItems: _navItems,
              selectedIndex: _selectedIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedIndex = index),
              isDarkMode: _isDarkMode,
              onDarkModeToggle: (val) =>
                  setState(() => _isDarkMode = val),
              roleLabel: 'Viewer Admin',
              roleColor: Colors.purple,
              roleIcon: Icons.visibility,
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Coming soon...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}