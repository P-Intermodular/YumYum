-- Restaura la politica SELECT del bucket "avatares" que se elimino en la
-- migracion 20260429095748 (hardening) y que se habia vuelto a crear a
-- mano desde el dashboard con nombre auto-generado ("SELECT tk3snb_0").
-- Restringe la lectura via API REST al dueno de la carpeta; las URLs
-- publicas siguen funcionando porque el bucket avatares es public:true.

drop policy if exists "SELECT tk3snb_0" on storage.objects;

drop policy if exists "Usuarios leen avatares en su carpeta" on storage.objects;
create policy "Usuarios leen avatares en su carpeta"
on storage.objects for select
to authenticated
using (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
