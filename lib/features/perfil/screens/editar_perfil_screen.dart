import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
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
        context.pop();
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
    final colors = context.yumColors;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Editar perfil',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              // Avatar con botón de cámara terracotta
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
                    Material(
                      color: colors.terracotta,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _seleccionarImagen,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: colors.paper,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Campos de texto
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre público',
                  prefixIcon:
                      Icon(Icons.person_outline, color: colors.inkSoft, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _ciudadController,
                decoration: InputDecoration(
                  labelText: 'Ciudad de residencia',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: colors.inkSoft,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                maxLength: 280,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  hintText:
                      'Cuéntale a tus vecinos qué cocinas y qué te inspira…',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 56),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: colors.inkSoft,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preferencias alimentarias
              Text(
                'Preferencias alimentarias',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      color: colors.ink,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _opcionesPreferencias.map((opcion) {
                  return _ChipPreferencia(
                    label: opcion,
                    seleccionada: _preferenciasSeleccionadas.contains(opcion),
                    onTap: () {
                      setState(() {
                        if (_preferenciasSeleccionadas.contains(opcion)) {
                          _preferenciasSeleccionadas.remove(opcion);
                        } else {
                          _preferenciasSeleccionadas.add(opcion);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Botón Guardar
              YumButton(
                text: estadoGuardado.isLoading ? 'Guardando…' : 'Guardar cambios',
                fullWidth: true,
                onPressed: estadoGuardado.isLoading ? null : _guardarPerfil,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de selección con tinte olive cuando está activo (no Material green).
class _ChipPreferencia extends StatelessWidget {
  final String label;
  final bool seleccionada;
  final VoidCallback onTap;

  const _ChipPreferencia({
    required this.label,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: seleccionada
              ? colors.olive.withValues(alpha: 0.18)
              : colors.cream2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionada
                ? colors.olive.withValues(alpha: 0.45)
                : colors.line,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seleccionada) ...[
              Icon(Icons.check_rounded, size: 14, color: colors.oliveDeep),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: seleccionada ? colors.oliveDeep : colors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
