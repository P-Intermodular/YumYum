-- Añade biografía corta al perfil de usuario.
-- La bio se considera contenido público de creador (visible desde un perfil
-- ajeno en la siguiente fase). Aquí se restringe únicamente la longitud y se
-- amplía el grant de UPDATE para que el propio usuario pueda editarla bajo la
-- política RLS existente "Usuarios pueden actualizar su propio perfil".

alter table public.perfiles
  add column if not exists bio text;

alter table public.perfiles
  drop constraint if exists perfiles_bio_longitud;

alter table public.perfiles
  add constraint perfiles_bio_longitud
    check (bio is null or char_length(bio) <= 280);

grant update (bio) on public.perfiles to authenticated;

-- La RPC obtener_mi_perfil debe devolver también la bio. Cambiar la firma
-- exige recrear la función.
drop function if exists public.obtener_mi_perfil();

create function public.obtener_mi_perfil()
returns table (
  id uuid,
  nombre text,
  email text,
  url_avatar text,
  ciudad text,
  bio text,
  preferencias text[],
  certificacion_sanitaria text,
  es_moderador boolean,
  valoracion_media numeric,
  numero_valoraciones integer,
  creado_en timestamptz,
  actualizado_en timestamptz,
  latitud_predeterminada numeric,
  longitud_predeterminada numeric
)
language sql
stable
security definer
set search_path = 'public'
as $$
  select
    p.id,
    p.nombre,
    p.email,
    p.url_avatar,
    p.ciudad,
    p.bio,
    p.preferencias,
    p.certificacion_sanitaria,
    p.es_moderador,
    p.valoracion_media,
    p.numero_valoraciones,
    p.creado_en,
    p.actualizado_en,
    p.latitud_predeterminada,
    p.longitud_predeterminada
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

grant execute on function public.obtener_mi_perfil() to authenticated;
