import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  const AppPage(
      {required this.eyebrow,
      required this.title,
      required this.child,
      this.leading,
      this.trailing,
      super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eyebrow, style: AppText.label),
                      const SizedBox(height: 4),
                      Text(title, style: AppText.title),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 14), trailing!],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xF5E2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 8))
        ],
      ),
      child: child,
    );
  }
}

class AppField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController? controller;
  final bool obscure;
  const AppField(
      {required this.label,
      required this.value,
      this.controller,
      this.obscure = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppText.label
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          controller == null
              ? Text(value, style: AppText.value)
              : TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: AppText.value,
                  decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const PrimaryButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const SecondaryButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const LinkText(this.text, {required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Text(text,
          style: const TextStyle(
              color: AppColors.brandDark,
              fontSize: 13,
              fontWeight: FontWeight.w900)));
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIcon({required this.icon, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 12,
                  offset: Offset(0, 6))
            ]),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  const ProfileAvatar({this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFFCFFAFE), Color(0xFFECFEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F111827), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: const Icon(Icons.person_rounded,
          color: AppColors.brandDark, size: 25),
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: 'Open profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: avatar,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onAction;
  const SectionHeader(
      {required this.title, required this.action, this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.section),
          GestureDetector(
              onTap: onAction,
              child: Text(action,
                  style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 13,
                      fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class BadgePill extends StatelessWidget {
  final String label;
  final BadgeKind kind;
  final IconData? icon;
  const BadgePill(
      {required this.label,
      this.kind = BadgeKind.normal,
      this.icon,
      super.key});

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      BadgeKind.warn => (const Color(0xFFFFF7ED), const Color(0xFF9A3412)),
      BadgeKind.danger => (const Color(0xFFFFF1F2), AppColors.rose),
      BadgeKind.keep => (const Color(0xFFECFDF5), const Color(0xFF047857)),
      BadgeKind.normal => (const Color(0xFFECFEFF), AppColors.brandDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: colors.$1, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.$2),
            const SizedBox(width: 5)
          ],
          Text(label,
              style: TextStyle(
                  color: colors.$2, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

enum BadgeKind { normal, warn, danger, keep }
