import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../shared/create_announcement_screen.dart';
import '../shared/recents_screen.dart';
import '../shared/news_feed_screen.dart';
import 'manage_units_screen.dart';
import 'venue_management_screen.dart';
import 'manage_viewer_admins_screen.dart';
import 'tech_assistance_requests_screen.dart';
import '../shared/calendar_screen.dart';
import 'bug_reports_management_screen.dart';

class TechAdminHome extends StatefulWidget {
  const TechAdminHome({super.key});

  @override
  State<TechAdminHome> createState() => _TechAdminHomeState();
}

class _TechAdminHomeState extends State<TechAdminHome> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final List<NavItem> _navItems = [
    const NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    const NavItem(icon: Icons.feed, label: 'News Feed'),
    const NavItem(icon: Icons.calendar_month, label: 'Calendar'),
    NavItem(
      icon: Icons.history,
      label: 'Activities',
      children: [
        const NavItem(icon: Icons.dynamic_feed, label: 'Recents'),
        const NavItem(icon: Icons.campaign, label: 'Create Announcements'),
      ],
    ),
    const NavItem(icon: Icons.business, label: 'Manage Units'),
    const NavItem(icon: Icons.admin_panel_settings, label: 'Manage Viewer Admins'),
    const NavItem(icon: Icons.pin_drop, label: 'Venue Management'),
    const NavItem(icon: Icons.build_circle, label: 'Tech Assistance Requests'),
    const NavItem(icon: Icons.bug_report, label: 'Bug Reports'),
  ];

  final List<Widget> _pages = [
    const _PlaceholderPage(title: 'Dashboard'),                 // 1
    const NewsFeedScreen(),                                     // 2 ✅
    const CalendarScreen(calendarType: CalendarType.techAdmin), // 3 ✅ 
    const RecentsScreen(),                                      // 4 ✅
    const CreateAnnouncementScreen(),                           // 5 ✅
    const ManageUnitsScreen(),                                  // 6 ✅
    const ManageViewerAdminsScreen(),                           // 7 ✅
    const VenueManagementScreen(),                              // 8 ✅
    const TechAssistanceRequestsScreen(),                       // 9 ✅
    const BugReportsManagementScreen(),                         // 10✅
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
              onItemSelected: (index) => setState(() => _selectedIndex = index),
              isDarkMode: _isDarkMode,
              onDarkModeToggle: (val) => setState(() => _isDarkMode = val),
              roleLabel: 'Tech Admin',
              roleColor: AppTheme.primaryBlue,
              roleIcon: Icons.shield,
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
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Coming soon...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}