import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/yumyum_app_bar.dart';
import '../../../models/producto_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/producto_providers.dart';
import '../repositories/producto_repository.dart';

class PublicarProductoScreen extends ConsumerStatefulWidget {
  const PublicarProductoScreen({super.key});

  @override
  ConsumerState<PublicarProductoScreen> createState() =>
      _PublicarProductoScreenState();
}

class _PublicarProductoScreenState
    extends ConsumerState<PublicarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _bytesImagen;
  String _extensionImagen = 'jpg';
  String _tipo = 'intercambio';
  bool _cargando = false;

  Future<void> _elegirImagen() async {
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    final extension = imagen.name.split('.').last;
    setState(() {
      _bytesImagen = bytes;
      _extensionImagen = extension.isEmpty ? 'jpg' : extension;
    });
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final nuevoProducto = ProductoModel(
        id: '',
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        urlImagen: '',
        propietario: usuario,
        creadoEn: DateTime.now(),
        tipo: _tipo,
        precio: _tipo == 'venta'
            ? double.tryParse(_precioController.text.replaceAll(',', '.'))
            : null,
        ubicacion: const LatLng(40.4180, -3.7050),
      );

      await ref.read(productoRepositoryProvider).crearProducto(
            nuevoProducto,
            bytesImagen: _bytesImagen,
            extensionImagen: _extensionImagen,
          );
      ref.invalidate(productosProvider);

      if (mounted) {
        context.go('/inicio');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta publicada')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Publicar'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _cargando ? null : _elegirImagen,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _bytesImagen == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Toca para anadir foto',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : Image.memory(_bytesImagen!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tituloController,
                decoration:
                    const InputDecoration(labelText: 'Titulo de la oferta'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripcion'),
                maxLines: 4,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de oferta'),
                items: const [
                  DropdownMenuItem(
                      value: 'intercambio', child: Text('Intercambio')),
                  DropdownMenuItem(value: 'venta', child: Text('Venta')),
                ],
                onChanged: (val) => setState(() => _tipo = val!),
              ),
              if (_tipo == 'venta') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (_tipo != 'venta') return null;
                    final parsed =
                        double.tryParse((val ?? '').replaceAll(',', '.'));
                    return parsed == null ? 'Introduce un precio valido' : null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _cargando ? null : _publicar,
                child: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Publicar oferta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
