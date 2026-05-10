import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';

enum YumNavTab { home, map, publish, pedidos, chats }

class YumBottomNav extends StatelessWidget {
  final YumNavTab currentTab;
  final ValueChanged<YumNavTab> onTabSelected;

  const YumBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    // Para que este efecto se vea bien sobre el contenido,
    // el Scaffold debe tener extendBody: true.
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colors.cream,
            colors.cream.withValues(alpha: 0.95),
            colors.cream.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              isSelected: currentTab == YumNavTab.home,
              onTap: () => onTabSelected(YumNavTab.home),
            ),
            _NavItem(
              icon: Icons.map_outlined,
              label: 'Mapa',
              isSelected: currentTab == YumNavTab.map,
              onTap: () => onTabSelected(YumNavTab.map),
            ),
            _PrimaryNavItem(
              onTap: () => onTabSelected(YumNavTab.publish),
            ),
            _NavItem(
              icon: Icons.receipt_long_outlined,
              label: 'Pedidos',
              isSelected: currentTab == YumNavTab.pedidos,
              onTap: () => onTabSelected(YumNavTab.pedidos),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chats',
              isSelected: currentTab == YumNavTab.chats,
              onTap: () => onTabSelected(YumNavTab.chats),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final color = isSelected ? colors.terracotta : colors.inkSoft;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryNavItem extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryNavItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;

    return Transform.translate(
      offset: const Offset(0, -20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.terracotta,
            shape: BoxShape.circle,
            border: Border.all(color: colors.paper, width: 4),
            boxShadow: [
              BoxShadow(
                color: colors.terracotta.withValues(alpha: 0.55),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: colors.paper,
            size: 28,
          ),
        ),
      ),
    );
  }
}
