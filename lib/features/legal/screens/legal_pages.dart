import 'package:flutter/material.dart';

import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';

class AvisoLegalScreen extends StatelessWidget {
  const AvisoLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Aviso legal',
      sections: [
        _LegalSection(
          heading: 'Titular del servicio',
          body:
              'YumYum es una plataforma digital para conectar vecinos que comparten comida casera. '
              'Este texto es informativo y puede completarse con los datos fiscales definitivos del titular.',
        ),
        _LegalSection(
          heading: 'Objeto',
          body:
              'La app facilita la publicación y gestión de ofertas de comida entre usuarios registrados.',
        ),
        _LegalSection(
          heading: 'Contacto',
          body:
              'Para consultas legales o incidencias, contacta con soporte desde la sección de ajustes.',
        ),
      ],
    );
  }
}

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Política de privacidad',
      sections: [
        _LegalSection(
          heading: 'Datos que tratamos',
          body:
              'Tratamos los datos mínimos necesarios para crear cuenta, mostrar perfil y operar pedidos/chat.',
        ),
        _LegalSection(
          heading: 'Finalidad',
          body:
              'Los datos se usan para prestar el servicio, prevenir fraude y mejorar la experiencia de uso.',
        ),
        _LegalSection(
          heading: 'Derechos',
          body:
              'Puedes solicitar acceso, rectificación, supresión y limitación del tratamiento conforme a la normativa aplicable.',
        ),
      ],
    );
  }
}

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Términos y condiciones',
      sections: [
        _LegalSection(
          heading: 'Uso de la plataforma',
          body:
              'Al registrarte aceptas usar YumYum de forma lícita y respetuosa con el resto de usuarios.',
        ),
        _LegalSection(
          heading: 'Publicaciones y pedidos',
          body:
              'Cada usuario es responsable de la veracidad de la información publicada y de la gestión de sus pedidos.',
        ),
        _LegalSection(
          heading: 'Suspensión de cuenta',
          body:
              'YumYum podrá limitar o suspender cuentas ante incumplimientos graves de estas condiciones.',
        ),
      ],
    );
  }
}

class PoliticaCookiesScreen extends StatelessWidget {
  const PoliticaCookiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Política de cookies',
      sections: [
        _LegalSection(
          heading: 'Qué son',
          body:
              'Las cookies son pequeños archivos que ayudan a recordar preferencias y mejorar la navegación.',
        ),
        _LegalSection(
          heading: 'Qué usamos en YumYum',
          body:
              'Usamos cookies técnicas necesarias para el funcionamiento básico y preferencia de configuración.',
        ),
        _LegalSection(
          heading: 'Gestión',
          body:
              'Puedes aceptar o rechazar cookies opcionales desde el banner mostrado al entrar en la app.',
        ),
      ],
    );
  }
}

class HojasReclamacionesScreen extends StatelessWidget {
  const HojasReclamacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Hojas de reclamaciones',
      sections: [
        _LegalSection(
          heading: 'Información',
          body:
              'Si necesitas hoja de reclamaciones, te enviaremos un correo con las instrucciones.',
        ),
      ],
    );
  }
}

class PlataformaOdrScreen extends StatelessWidget {
  const PlataformaOdrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Plataforma ODR UE',
      sections: [
        _LegalSection(
          heading: 'Resolución de litigios en línea',
          body:
              'La Comisión Europea facilita una plataforma para resolver conflictos de '
              'consumo en línea: https://ec.europa.eu/consumers/odr',
        ),
        _LegalSection(
          heading: 'Uso orientativo',
          body:
              'Esta página es informativa. Si procede, puedes usar ese enlace oficial '
              'para tramitar reclamaciones de consumo dentro de la UE.',
        ),
      ],
    );
  }
}

class _LegalScaffold extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;

  const _LegalScaffold({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: YumAppBar(title: title, showBack: true),
      body: YumBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            for (final section in sections) ...[
              Text(
                section.heading,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(section.body, style: textTheme.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 18),
            ],
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'Plataforma ODR UE: https://ec.europa.eu/consumers/odr',
              style: textTheme.bodySmall,
            ),

          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});
}

