// Indirección con conditional imports: en web carga `theme_color_web_real`
// (que usa `package:web`); en móvil/desktop carga el stub no-op.
//
// El identificador `dart.library.js_interop` solo se resuelve a true cuando
// la app se compila para web, así que en otras plataformas el `package:web`
// no se importa y no falla la compilación.
export 'theme_color_web_stub.dart'
    if (dart.library.js_interop) 'theme_color_web_real.dart';
