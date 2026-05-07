import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/alergenos_ue.dart';
import '../../../core/constants/etiquetas_dieteticas.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/label_seccion.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/editar_perfil_controller.dart';

/// Pantalla de edición del perfil del usuario.
///
/// Sigue el patrón Figma para subpantallas: TopBar compacta con back y
/// 'Guardar' sutil a la derecha como atajo, marcado uniforme de
/// obligatorios/opcionales con `LabelSeccion`, y un CTA grande al final
/// del scroll para usuarios que prefieren ver todo el formulario antes
/// de guardar.
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
  final _picker = ImagePicker();

  /// Valor canónico de cada etiqueta dietética, indexado por la versión en
  /// minúsculas. Permite recuperar selecciones antiguas guardadas con casing
  /// distinto (p.ej. "Sin Gluten" vs "Sin gluten").
  static final Map<String, String> _etiquetaCanonicaPorMinuscula = {
    for (final etq in EtiquetasDieteticas.todas) etq.toLowerCase(): etq,
  };

  final Set<String> _preferencias = {};
  final Set<String> _alergenos = {};
  File? _nuevoAvatar;

  /// Marca explícita para borrar el avatar al guardar (vs. no tocar nada).
  /// Cuando es true se ignora `_nuevoAvatar`.
  bool _quitarAvatar = false;

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;

    _nombreController.text = usuario.nombre;
    _ciudadController.text = usuario.ciudad ?? '';
    _bioController.text = usuario.bio ?? '';

    // Recuperación tolerante de selecciones antiguas: matcheamos en minúsculas
    // y guardamos siempre el casing canónico actual.
    _preferencias.addAll(
      usuario.preferencias
          .map((p) => _etiquetaCanonicaPorMinuscula[p.toLowerCase()])
          .whereType<String>(),
    );
    _alergenos.addAll(
      usuario.alergenos.where(AlergenosUe.todos.contains),
    );

    // Listener para refrescar el contador de bio en vivo.
    _bioController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ─── Avatar ────────────────────────────────────────────────────────────

  Future<void> _abrirSheetAvatar(bool tieneAvatar) async {
    final colors = context.yumColors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: colors.ink),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.ink),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),
              if (tieneAvatar)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.terracottaDeep,
                  ),
                  title: Text(
                    'Quitar foto',
                    style: TextStyle(color: colors.terracottaDeep),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _nuevoAvatar = null;
                      _quitarAvatar = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final imagen = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (imagen == null || !mounted) return;
      setState(() {
        _nuevoAvatar = File(imagen.path);
        _quitarAvatar = false;
      });
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  // ─── Acciones ──────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(editarPerfilControllerProvider.notifier).actualizarPerfil(
            nombre: _nombreController.text,
            ciudad: _ciudadController.text,
            bio: _bioController.text,
            preferencias: _preferencias.toList(),
            alergenos: _alergenos.toList(),
            nuevoAvatar: _nuevoAvatar,
            quitarAvatar: _quitarAvatar,
          );
      if (!mounted) return;
      mostrarExito(context, 'Perfil actualizado');
      context.pop();
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacionProvider).value;
    final cargando = ref.watch(editarPerfilControllerProvider).isLoading;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: YumAppBar(
        title: 'Editar perfil',
        showBack: true,
        action: _BotonGuardarSutil(
          cargando: cargando,
          onPressed: _guardar,
        ),
      ),
      body: YumBackground(
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              children: [
                Center(
                  child: _AvatarEditable(
                    usuario: usuario,
                    nuevoAvatar: _nuevoAvatar,
                    quitarAvatar: _quitarAvatar,
                    onTap: () => _abrirSheetAvatar(
                      _nuevoAvatar != null ||
                          (!_quitarAvatar &&
                              usuario.urlImagenPerfil.isNotEmpty),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const LabelSeccion(text: 'Email'),
                const SizedBox(height: 8),
                _CampoEmailReadonly(correo: usuario.correo),
                const SizedBox(height: 18),
                const LabelSeccion(text: 'Nombre público', obligatorio: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracion('Cómo te ven tus vecinos'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 18),
                const LabelSeccion(text: 'Ciudad o zona', opcional: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ciudadController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracion('Ej. Malasaña, Madrid'),
                ),
                const SizedBox(height: 18),
                const LabelSeccion(text: 'Bio', opcional: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLength: 280,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoracion(
                    'Cuéntale a tus vecinos qué cocinas y qué te inspira…',
                  ).copyWith(
                    // Quitamos el contador automático de Material; lo pintamos
                    // nosotros mismos justo debajo para integrarlo con la estética.
                    counterText: '',
                  ),
                ),
                _ContadorBio(longitud: _bioController.text.length),
                const SizedBox(height: 18),
                const LabelSeccion(
                  text: 'Preferencias dietéticas',
                  opcional: true,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final etq in EtiquetasDieteticas.todas)
                      _ChipSeleccionable(
                        label: etq,
                        activa: _preferencias.contains(etq),
                        tono: _TonoChip.olive,
                        onTap: () => setState(() {
                          _preferencias.contains(etq)
                              ? _preferencias.remove(etq)
                              : _preferencias.add(etq);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const LabelSeccion(
                  text: 'Tus alérgenos personales',
                  opcional: true,
                ),
                const SizedBox(height: 4),
                Text(
                  'Si declaras alérgenos, podrás filtrar el feed para evitar '
                  'platos que los contengan.',
                  style: TextStyle(
                    color: context.yumColors.inkSoft,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in AlergenosUe.todos)
                      _ChipSeleccionable(
                        label: a,
                        activa: _alergenos.contains(a),
                        tono: _TonoChip.warn,
                        onTap: () => setState(() {
                          _alergenos.contains(a)
                              ? _alergenos.remove(a)
                              : _alergenos.add(a);
                        }),
                      ),
                  ],
                ),
                // La sección "Cuenta" (cambiar contraseña, ubicación
                // predeterminada) vive ahora en Ajustes — son acciones de
                // cuenta/seguridad, no datos personales editables.
                const SizedBox(height: 32),
                YumButton(
                  text: cargando ? 'Guardando…' : 'Guardar cambios',
                  fullWidth: true,
                  onPressed: cargando ? null : _guardar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header

/// Acción "Guardar" sutil en la esquina superior derecha de la TopBar.
/// Atajo para usuarios que no quieren scrollear hasta el CTA grande final.
class _BotonGuardarSutil extends StatelessWidget {
  final bool cargando;
  final VoidCallback onPressed;

  const _BotonGuardarSutil({required this.cargando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: cargando ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.terracottaDeep,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(cargando ? 'Guardando…' : 'Guardar'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar

class _AvatarEditable extends StatelessWidget {
  final dynamic usuario;
  final File? nuevoAvatar;
  final bool quitarAvatar;
  final VoidCallback onTap;

  const _AvatarEditable({
    required this.usuario,
    required this.nuevoAvatar,
    required this.quitarAvatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final urlVigente = quitarAvatar ? '' : usuario.urlImagenPerfil as String;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.line, width: 1.5),
          ),
          child: nuevoAvatar != null
              ? CircleAvatar(
                  radius: 48,
                  backgroundImage: FileImage(nuevoAvatar!),
                )
              : AvatarUsuario(
                  nombre: usuario.nombre as String,
                  identificadorColor: usuario.id as String,
                  urlImagen: urlVigente,
                  radius: 48,
                ),
        ),
        Material(
          color: colors.terracotta,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.camera_alt_rounded,
                color: colors.paper,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Email readonly

class _CampoEmailReadonly extends StatelessWidget {
  final String correo;
  const _CampoEmailReadonly({required this.correo});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.cream2,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: colors.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.inkSoft, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'El email no se puede cambiar desde aquí.',
          style: TextStyle(color: colors.inkSoft, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contador de bio

class _ContadorBio extends StatelessWidget {
  final int longitud;
  static const int _max = 280;

  const _ContadorBio({required this.longitud});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final cercaDelLimite = longitud > _max - 20;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$longitud / $_max',
          style: TextStyle(
            color: cercaDelLimite ? colors.terracottaDeep : colors.inkSoft,
            fontSize: 11,
            fontWeight: cercaDelLimite ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip seleccionable (mismo patrón que en publicar)

enum _TonoChip { olive, warn }

class _ChipSeleccionable extends StatelessWidget {
  final String label;
  final bool activa;
  final _TonoChip tono;
  final VoidCallback onTap;

  const _ChipSeleccionable({
    required this.label,
    required this.activa,
    required this.tono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    Color bg;
    Color border;
    Color textColor;
    if (activa) {
      switch (tono) {
        case _TonoChip.olive:
          bg = colors.olive.withValues(alpha: 0.18);
          border = colors.oliveDeep.withValues(alpha: 0.45);
          textColor = colors.oliveDeep;
          break;
        case _TonoChip.warn:
          bg = colors.mustard.withValues(alpha: 0.28);
          border = colors.mustard.withValues(alpha: 0.7);
          textColor = colors.ink;
          break;
      }
    } else {
      bg = colors.paper;
      border = colors.line;
      textColor = colors.inkSoft;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12.5,
            fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Atajos a sub-pantallas

// _AtajoTile vivía aquí para los atajos a "Editar ubicación" y "Cambiar
// contraseña". Esos atajos se movieron a la pantalla de Ajustes (acciones
// de cuenta/seguridad), así que el widget ya no se usa.
