import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../repositories/product_repository.dart';
import '../../feed/screens/feed_screen.dart';
import '../../../core/widgets/yumyum_app_bar.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: const YumYumAppBar(
        title: 'Detalles',
        showBackButton: true,
      ),
      body: productsAsync.when(
        data: (products) {
          final productOpt = products.where((p) => p.id == productId).toList();
          if (productOpt.isEmpty) {
            return const Center(child: Text('Producto no encontrado'));
          }
          final product = productOpt.first;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'img-${product.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              product.type == 'exchange' 
                                  ? 'Intercambio' 
                                  : '${product.price?.toStringAsFixed(2)} €',
                              style: TextStyle(
                                  color: product.type == 'exchange' ? Colors.purple.shade900 : Colors.green.shade900,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: product.type == 'exchange' ? Colors.purple.shade100 : Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.owner.profileImageUrl),
                        ),
                        title: Text(product.owner.name),
                        subtitle: const Text('Ver perfil'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Descripción',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Create chat or navigate to chat
              context.push('/chat_room/chat1'); // mock chat id
            },
            child: const Text('Contactar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
