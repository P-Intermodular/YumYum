import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/yumyum_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userOpt = ref.watch(authProvider).value;

    if (userOpt == null) {
      return const Scaffold(
        body: Center(child: Text('No has iniciado sesión')),
      );
    }

    final topColor = Colors.green.shade200;

    return Scaffold(
      appBar: const YumYumAppBar(
        title: 'Perfil',
        showBackButton: true,
        showProfileButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top background half (optional, or just use appbar color)
            // But from screenshot it seems the appbar is green and the body is white.
            const SizedBox(height: 24),
            
            // Profile image with border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: topColor, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userOpt.profileImageUrl),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name and Email
            Text(
              userOpt.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F4A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userOpt.email,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Rating badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '4.8',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildStatBox('2', 'Platos', topColor),
                  const SizedBox(width: 12),
                  _buildStatBox('23', 'Ventas', topColor),
                  const SizedBox(width: 12),
                  _buildStatBox('15', 'Compras', topColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    title: 'Ubicación',
                    content: 'Madrid, España',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: 'Miembro desde',
                    content: 'Enero 2026',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mis platos publicados
            _buildSectionTitle('Mis platos publicados'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildHorizontalProductCard(
                    imageUrl: 'https://images.unsplash.com/photo-1544928147-79a2dbc1f389?q=80&w=600&auto=format&fit=crop', // Paella placeholder
                    title: 'Paella Valenciana',
                    price: '12€',
                    rating: '4.8',
                  ),
                  const SizedBox(width: 16),
                  _buildHorizontalProductCard(
                    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=600&auto=format&fit=crop', // Sopa placeholder
                    title: 'Sopa de Lentejas',
                    price: '5€',
                    rating: '4.6',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Valoraciones recibidas
            _buildSectionTitle('Valoraciones recibidas'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildReviewCard(
                authorName: 'Carlos López',
                rating: 5,
                comment: '¡Deliciosa! Justo como la de mi abuela',
              ),
            ),
            
            // Logout option at the very bottom
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4A5B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
              ],
              Text(
                content,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4A5B),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalProductCard({
    required String imageUrl,
    required String title,
    required String price,
    required String rating,
  }) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
                Container(height: 120, color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4A5B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String authorName,
    required int rating,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1F4A5B)),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        color: index < rating ? Colors.amber : Colors.grey.shade300,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
