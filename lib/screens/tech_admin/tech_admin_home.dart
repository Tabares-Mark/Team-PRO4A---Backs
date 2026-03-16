import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../shared/create_announcement_screen.dart';
import '../shared/recents_screen.dart';
import '../shared/news_feed_screen.dart';
import 'manage_units_screen.dart';

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
    const NavItem(icon: Icons.build_circle, label: 'Tech Assistance Requests'),
    const NavItem(icon: Icons.bug_report, label: 'Bug Reports'),
  ];

  final List<Widget> _pages = [
    const _PlaceholderPage(title: 'Dashboard'),              // 0
    const NewsFeedScreen(),                                   // 1
    const _PlaceholderPage(title: 'Calendar'),               // 2
    const RecentsScreen(),                                    // 3 (under Activities)
    const CreateAnnouncementScreen(),                         // 4 (under Activities)
    const ManageUnitsScreen(),                                // 5 ✅
    const _PlaceholderPage(title: 'Manage Viewer Admins'),   // 6
    const _PlaceholderPage(title: 'Tech Assistance Requests'), // 7
    const _PlaceholderPage(title: 'Bug Reports'),            // 8
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