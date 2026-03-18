import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/product_repository.dart';
import '../../feed/screens/feed_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _type = 'exchange';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    setState(() => _isLoading = true);

    final newProduct = ProductModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', // Mock random image
      owner: user,
      createdAt: DateTime.now(),
      type: _type,
      price: _type == 'sell' ? double.tryParse(_priceController.text) : null,
      location: const LatLng(40.4180, -3.7050), // Mock location
    );

    await ref.read(productRepositoryProvider).addProduct(newProduct);
    ref.invalidate(productsProvider); // Refresh feed
    
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/feed');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Oferta publicada!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Comida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Toca para añadir foto', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título de la oferta'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo de oferta'),
                items: const [
                  DropdownMenuItem(value: 'exchange', child: Text('Intercambio')),
                  DropdownMenuItem(value: 'sell', child: Text('Venta')),
                ],
                onChanged: (val) => setState(() => _type = val!),
              ),
              if (_type == 'sell') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Precio (€)'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar Oferta'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
