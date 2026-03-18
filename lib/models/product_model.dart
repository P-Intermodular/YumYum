import 'user_model.dart';
import 'package:latlong2/latlong.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final UserModel owner;
  final DateTime createdAt;
  final String type; // 'exchange' or 'sell'
  final double? price; // if type is 'sell'
  final LatLng location; // Mock location

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.owner,
    required this.createdAt,
    required this.type,
    this.price,
    required this.location,
  });
}
