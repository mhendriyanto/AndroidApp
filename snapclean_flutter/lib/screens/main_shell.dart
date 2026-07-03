import 'package:flutter/material.dart';

import '../screens/tabs/active_screen.dart';
import '../screens/tabs/expiring_screen.dart';
import '../screens/tabs/home_screen.dart';
import '../screens/tabs/import_screen.dart';
import '../screens/tabs/settings_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  AppController? controller;
  int lastNoticeId = 0;

  void selectTab(int next) => setState(() => index = next);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = SnapCleanScope.of(context);
    if (controller == next) return;
    controller?.removeListener(_showLatestNotice);
    controller = next;
    controller?.addListener(_showLatestNotice);
  }

  @override
  void dispose() {
    controller?.removeListener(_showLatestNotice);
    super.dispose();
  }

  void _showLatestNotice() {
    final notice = controller?.latestNotice;
    if (notice == null || notice.id == lastNoticeId || !mounted) return;
    lastNoticeId = notice.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notice.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onImport: () => selectTab(1), onActive: () => selectTab(2)),
      ImportScreen(onViewActive: () => selectTab(2)),
      const ActiveScreen(),
      const ExpiringScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        height: 84,
        decoration: const BoxDecoration(
            color: Color(0xF0FFFFFF),
            border: Border(top: BorderSide(color: Color(0xCCE2E8F0)))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: index == 0,
                    onTap: () => selectTab(0)),
                NavItem(
                    icon: Icons.add_rounded,
                    label: 'Import',
                    active: index == 1,
                    onTap: () => selectTab(1)),
                NavItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Active',
                    active: index == 2,
                    onTap: () => selectTab(2)),
                NavItem(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'Expire',
                    active: index == 3,
                    onTap: () => selectTab(3)),
                NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    active: index == 4,
                    onTap: () => selectTab(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon,
                color: active ? AppColors.brand : const Color(0xFF94A3B8),
                size: 20),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    color: active ? AppColors.brand : const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
