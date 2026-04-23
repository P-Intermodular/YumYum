# YumYum

Aplicacion Flutter para intercambio y venta local de comida casera.

## Configuracion compartida

La app lee la configuracion de Supabase mediante `--dart-define`.
En este repo dejamos versionado un `.env` de desarrollo para que el equipo pueda arrancar el proyecto sin configurar nada extra.

```env
SUPABASE_URL=https://gnzrintyysnpuiadzrce.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
```

`SUPABASE_ANON_KEY` es publica para el cliente y se usa solo en desarrollo.
No hay que subir `service_role`, tokens privados ni otras credenciales sensibles.

Si en algun momento hay que apuntar a otro proyecto de Supabase, se puede usar `.env.example` como plantilla.

## Puesta en marcha

1. Instala Flutter.
2. Desde la raiz del proyecto ejecuta `flutter pub get`.
3. Entra en la carpeta `scripts`.
4. Ejecuta el script `run_dev.ps1`.

Arranque rapido en Chrome:

```powershell
cd .\scripts
.\run_dev.ps1
```

El script lee el `.env` del proyecto y pasa `SUPABASE_URL` y `SUPABASE_ANON_KEY` a Flutter automaticamente.
