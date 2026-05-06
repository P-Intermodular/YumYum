import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/editar_perfil_controller.dart';

/// Opciones de preferencias alimentarias disponibles en la aplicación.
const _opcionesPreferencias = [
  'Vegano',
  'Vegetariano',
  'Sin Gluten',
  'Sin Lactosa',
  'Halal',
  'Kosher',
];

/// Pantalla para que el usuario modifique sus datos públicos y avatar.
class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _bioController = TextEditingController();

  final List<String> _preferenciasSeleccionadas = [];
  File? _nuevaImagenLocal;

  @override
  void initState() {
    super.initState();
    // Pre-poblar los datos actuales del usuario al abrir la pantalla
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario != null) {
      _nombreController.text = usuario.nombre;
      _ciudadController.text = usuario.ciudad ?? '';
      _bioController.text = usuario.bio ?? '';
      _preferenciasSeleccionadas.addAll(usuario.preferencias);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Abre la galería para seleccionar una nueva foto de perfil.
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _nuevaImagenLocal = File(pickedFile.path);
      });
    }
  }

  /// Valida el formulario y solicita la actualización al controlador.
  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(editarPerfilControllerProvider.notifier).actualizarPerfil(
            nombre: _nombreController.text,
            ciudad: _ciudadController.text,
            bio: _bioController.text,
            preferencias: _preferenciasSeleccionadas,
            nuevoAvatar: _nuevaImagenLocal,
          );

      if (mounted) {
        mostrarExito(context, 'Perfil actualizado correctamente');
        context.pop(); // Volver a la pantalla de perfil
      }
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacionProvider).value;
    final estadoGuardado = ref.watch(editarPerfilControllerProvider);

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Editar Perfil',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Sección de Avatar
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  if (_nuevaImagenLocal != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(_nuevaImagenLocal!),
                    )
                  else
                    AvatarUsuario(
                      nombre: usuario.nombre,
                      identificadorColor: usuario.id,
                      urlImagen: usuario.urlImagenPerfil,
                      radius: 50,
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F4A5B),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      iconSize: 20,
                      onPressed: _seleccionarImagen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Campos de texto
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre público',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ciudadController,
              decoration: const InputDecoration(
                labelText: 'Ciudad de residencia',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              maxLength: 280,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Biografía',
                hintText: 'Cuéntale a tus vecinos qué cocinas y qué te inspira…',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.menu_book_outlined),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Selector de preferencias (Chips)
            const Text(
              'Preferencias Alimentarias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _opcionesPreferencias.map((opcion) {
                final seleccionada =
                    _preferenciasSeleccionadas.contains(opcion);
                return FilterChip(
                  label: Text(opcion),
                  selected: seleccionada,
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green.shade800,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _preferenciasSeleccionadas.add(opcion);
                      } else {
                        _preferenciasSeleccionadas.remove(opcion);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 48),

            // Botón Guardar
            ElevatedButton(
              onPressed: estadoGuardado.isLoading ? null : _guardarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4A5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: estadoGuardado.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar Cambios',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
