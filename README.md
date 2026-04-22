# YumYum

Aplicacion Flutter para intercambio y venta local de comida casera.

## Configuracion local

La app lee la configuracion de Supabase mediante `--dart-define`.
Para no escribir las claves en cada arranque, crea un archivo `.env` local con:

```env
SUPABASE_URL=https://gnzrintyysnpuiadzrce.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
```

`.env` esta ignorado por git. El archivo versionado es `.env.example`.

Arranque rapido en Chrome:

```powershell
.\scripts\run_dev.ps1
```

Para otro dispositivo:

```powershell
.\scripts\run_dev.ps1 -Device windows
```
