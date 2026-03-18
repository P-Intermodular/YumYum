import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> addProduct(ProductModel product);
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
});

class MockProductRepository implements ProductRepository {
  final List<ProductModel> _mockProducts = [
    ProductModel(
      id: '101',
      title: 'Tarta de Manzana Casera',
      description: 'He hecho demasiada tarta de manzana. Intercambio por algún postre salado o vendo mi porción extra.',
      imageUrl: 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=500',
      owner: UserModel(id: '2', name: 'Ana', email: 'ana@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=5'),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'exchange',
      location: const LatLng(40.4168, -3.7038), // Madrid
    ),
    ProductModel(
      id: '102',
      title: 'Tupper de Lentejas',
      description: 'Lentejas tradicionales con chorizo. Ración grande. Vendo porque cociné para toda la semana.',
      imageUrl: 'https://images.unsplash.com/photo-1548811218-12c8b87ee077?w=500',
      owner: UserModel(id: '3', name: 'Carlos', email: 'carlos@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=11'),
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'sell',
      price: 4.50,
      location: const LatLng(40.4200, -3.7000), 
    ),
    ProductModel(
      id: '103',
      title: 'Pan de Masa Madre',
      description: 'Pan artesano recién horneado. Cambio por huevos camperos.',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
      owner: UserModel(id: '4', name: 'María', email: 'maria@ejemplo.com', profileImageUrl: 'https://i.pravatar.cc/150?img=9'),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: 'exchange',
      location: const LatLng(40.4120, -3.7100), 
    ),
  ];

  @override
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return List.unmodifiable(_mockProducts);
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockProducts.insert(0, product);
    return product;
  }
}
