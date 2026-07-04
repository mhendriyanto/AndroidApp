import 'package:flutter/material.dart';

import '../screens/tabs/active_screen.dart';
import '../screens/tabs/home_screen.dart';
import '../screens/tabs/import_screen.dart';
import '../screens/tabs/saved_screen.dart';
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

  void selectTab(int next) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => index = next);
  }

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
      HomeScreen(onActive: () => selectTab(1)),
      const ActiveScreen(),
      const SavedScreen(),
      const SettingsScreen(),
      ImportScreen(
          onViewActive: () => selectTab(1),
          onViewSaved: () => selectTab(2),
          onClose: () => selectTab(0)),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 74,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.94),
            border: const Border(
              top: BorderSide(color: Color(0xDDE2E8F0)),
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  offset: Offset(0, -8))
            ],
          ),
          child: Row(
            children: [
              NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: index == 0,
                  onTap: () => selectTab(0)),
              NavItem(
                  icon: Icons.folder_rounded,
                  label: 'Timers',
                  active: index == 1,
                  onTap: () => selectTab(1)),
              ImportNavButton(
                  active: index == 4,
                  onTap: () => selectTab(4)),
              NavItem(
                  icon: Icons.bookmark_rounded,
                  label: 'Saved',
                  active: index == 2,
                  onTap: () => selectTab(2)),
              NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  active: index == 3,
                  onTap: () => selectTab(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportNavButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const ImportNavButton({required this.active, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.brand.withOpacity(active ? .28 : .18),
                    blurRadius: active ? 18 : 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 30),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 48,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFECFEFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: active ? AppColors.brandDark : const Color(0xFF94A3B8),
                  size: 20),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: active
                          ? AppColors.brandDark
                          : const Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}
