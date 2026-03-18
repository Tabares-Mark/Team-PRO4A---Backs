import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../shared/create_announcement_screen.dart';
import '../shared/recents_screen.dart';
import '../shared/news_feed_screen.dart';
import 'personnel_enrolment_screen.dart';
import 'account_information_screen.dart';
import '../shared/calendar_screen.dart';
import '../shared/bug_report_screen.dart';

class UnitHome extends StatefulWidget {
  const UnitHome({super.key});

  @override
  State<UnitHome> createState() => _UnitHomeState();
}

class _UnitHomeState extends State<UnitHome> {
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
  NavItem(
    icon: Icons.manage_accounts,
    label: 'Account Management',
    children: [
      const NavItem(icon: Icons.info_outline, label: 'Account Information'),
      const NavItem(icon: Icons.person_add, label: 'Personnel Enrolment'),
      const NavItem(icon: Icons.bug_report, label: 'Bug Reports'),
    ],
  ),
];

 final List<Widget> _pages = [
  const _PlaceholderPage(title: 'Dashboard'),   
  const NewsFeedScreen(),
  const CalendarScreen(calendarType: CalendarType.unit),  
  const RecentsScreen(),                         
  const CreateAnnouncementScreen(),             
  const AccountInformationScreen(),  
  const PersonnelEnrolmentScreen(),  
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
  onItemSelected: (index) => setState(() => _selectedIndex = index),
  isDarkMode: _isDarkMode,
  onDarkModeToggle: (val) => setState(() => _isDarkMode = val),
  roleLabel: 'Unit',
  roleColor: Colors.green,
  roleIcon: Icons.business,
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