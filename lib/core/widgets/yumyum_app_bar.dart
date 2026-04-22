import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable, unified AppBar for the YumYum app.
///
/// Provides consistent styling across all screens:
/// - Soft green gradient background
/// - Bold, centered title in dark teal
/// - Optional notification bell and profile icon on the right
/// - Optional leading widget (hamburger menu or back button)
class YumYumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileButton;
  final bool showNotificationButton;
  final bool showBackButton;
  final List<Widget>? extraActions;

  const YumYumAppBar({
    super.key,
    required this.title,
    this.showProfileButton = true,
    this.showNotificationButton = false,
    this.showBackButton = false,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF1F4A5B);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: headerColor, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: headerColor,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFD5ECD4), // Soft sage/mint green
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        ...?extraActions,
        if (showNotificationButton)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: headerColor),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
        if (showProfileButton)
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: headerColor),
            onPressed: () => context.push('/profile'),
          ),
      ],
    );
  }
}
