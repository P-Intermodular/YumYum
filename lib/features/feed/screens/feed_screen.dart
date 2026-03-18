import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../models/product_model.dart';
import '../../product/repositories/product_repository.dart';

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productRepositoryProvider).getProducts();
});

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comida Cerca de Ti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) => RefreshIndicator(
          onRefresh: () async => ref.refresh(productsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(product: product);
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.type == 'exchange' 
                              ? Colors.purple.shade100 
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.type == 'exchange' 
                              ? 'Intercambio' 
                              : '${product.price?.toStringAsFixed(2)} €',
                          style: TextStyle(
                            color: product.type == 'exchange' 
                                ? Colors.purple.shade800 
                                : Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(product.owner.profileImageUrl),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.owner.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM HH:mm').format(product.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
