import 'dart:io';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: child,
            ),
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
  final bool scrollable;

  const AppPage(
      {required this.eyebrow,
      required this.title,
      required this.child,
      this.leading,
      this.trailing,
      this.scrollable = true,
      super.key});

  @override
  Widget build(BuildContext context) {
    final background = SnapCleanScope.of(context).appBackground;
    final titleStyle = background.isDark
        ? AppText.title.copyWith(color: Colors.white)
        : AppText.title;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: background.colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: scrollable ? null : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 112),
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
                        Text(_titleCase(title), style: titleStyle),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 14),
                    trailing!
                  ],
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  String _titleCase(String value) {
    return value.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word == word.toUpperCase()) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xF5E2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D0F172A), blurRadius: 24, offset: Offset(0, 12))
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
  final TextInputType? keyboardType;
  final bool obscure;
  const AppField(
      {required this.label,
      required this.value,
      this.controller,
      this.keyboardType,
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
                  keyboardType: keyboardType,
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

class AppSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  const AppSearchBar(
      {this.hint = 'Search screenshots',
      this.onTap,
      this.onChanged,
      this.controller,
      super.key});

  @override
  Widget build(BuildContext context) {
    final editable = onChanged != null || controller != null;
    final content = Row(
      children: [
        const Icon(Icons.search_rounded, color: AppColors.subtle),
        const SizedBox(width: 9),
        Expanded(
          child: editable
              ? TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                  decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(
                          color: AppColors.subtle,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      contentPadding: EdgeInsets.zero),
                )
              : Text(hint,
                  style: const TextStyle(
                      color: AppColors.subtle,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
        ),
      ],
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onTap;
  const ProfileAvatar({this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final avatarImagePath = SnapCleanScope.of(context).user.avatarImagePath;
    final avatar = Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
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
      child: avatarImagePath == null || avatarImagePath.isEmpty
          ? const Icon(Icons.person_rounded,
              color: AppColors.brandDark, size: 25)
          : Image.file(
              File(avatarImagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                  color: AppColors.brandDark, size: 25),
            ),
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

class StatStrip extends StatelessWidget {
  final List<StatTileData> items;
  const StatStrip({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < items.length; index++) ...[
          Expanded(child: StatTile(data: items[index])),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class StatTileData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const StatTileData(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});
}

class StatTile extends StatelessWidget {
  final StatTileData data;
  const StatTile({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 14, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color, size: 19),
          const Spacer(),
          Text(data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const InsightCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.color = AppColors.brand,
      this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: color.withOpacity(.11),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.value),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.label),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
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

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  const EmptyStateCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.actionLabel,
      this.actionIcon,
      this.onAction,
      super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: AppColors.brandDark, size: 34),
          ),
          const SizedBox(height: 15),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontWeight: FontWeight.w700)),
          if (actionLabel != null &&
              onAction != null &&
              actionIcon != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(
                label: actionLabel!, icon: actionIcon!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final String title;
  final String subtitle;
  final Widget child;
  const LoadingOverlay(
      {required this.visible,
      required this.title,
      required this.subtitle,
      required this.child,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: visible,
          child: Opacity(opacity: visible ? .3 : 1, child: child),
        ),
        if (visible) ...[
          Positioned.fill(child: Container(color: const Color(0x990F172A))),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x330F172A),
                        blurRadius: 34,
                        offset: Offset(0, 18))
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(strokeWidth: 4)),
                  const SizedBox(height: 16),
                  Text(title, style: AppText.value),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      textAlign: TextAlign.center, style: AppText.label),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<bool> showConfirmSheet(BuildContext context,
    {required String title,
    required String message,
    String confirmLabel = 'Confirm',
    IconData icon = Icons.warning_amber_rounded,
    bool danger = false}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateCard(
            icon: icon,
            title: title,
            subtitle: message,
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context, false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                    label: confirmLabel,
                    icon: danger ? Icons.delete_rounded : Icons.check_rounded,
                    onTap: () => Navigator.pop(context, true)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

void showSuccessSheet(BuildContext context,
    {required String title,
    required String message,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    IconData? secondaryIcon,
    VoidCallback? onSecondary}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateCard(
              icon: Icons.check_circle_rounded,
              title: title,
              subtitle: message),
          PrimaryButton(
              label: primaryLabel,
              icon: primaryIcon,
              onTap: () {
                Navigator.pop(context);
                onPrimary();
              }),
          if (secondaryLabel != null &&
              secondaryIcon != null &&
              onSecondary != null) ...[
            const SizedBox(height: 12),
            SecondaryButton(
                label: secondaryLabel,
                icon: secondaryIcon,
                onTap: () {
                  Navigator.pop(context);
                  onSecondary();
                }),
          ],
        ],
      ),
    ),
  );
}
