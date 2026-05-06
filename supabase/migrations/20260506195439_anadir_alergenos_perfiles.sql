-- Alergenos personales del usuario en su perfil. Hasta ahora `preferencias`
-- mezclaba dieta y alergias en una sola lista; separamos los del Anexo II
-- para poder, en el futuro, filtrar el feed automáticamente por las
-- alergias declaradas del usuario.

alter table public.perfiles
  add column alergenos text[] not null default '{}';

-- PostgREST sirve SELECT/UPDATE columna a columna; sin grants column-level
-- el cliente recibe 42501 aunque la policy permita la operación.
grant select (alergenos) on public.perfiles to authenticated;
grant update (alergenos) on public.perfiles to authenticated;

-- Recreamos obtener_mi_perfil para incluir alergenos en el shape.
-- CREATE OR REPLACE no admite cambios en RETURNS TABLE, así que usamos DROP
-- previo. Las ACLs se reemiten al final.
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
  alergenos text[],
  certificacion_sanitaria text,
  es_moderador boolean,
  valoracion_media numeric,
  numero_valoraciones integer,
  pedidos_completados integer,
  creado_en timestamptz,
  actualizado_en timestamptz,
  latitud_predeterminada numeric,
  longitud_predeterminada numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.nombre,
    p.email,
    p.url_avatar,
    p.ciudad,
    p.bio,
    p.preferencias,
    p.alergenos,
    p.certificacion_sanitaria,
    p.es_moderador,
    p.valoracion_media,
    p.numero_valoraciones,
    coalesce(
      (
        select count(*)::int
        from public.transacciones t
        where t.propietario_id = p.id
          and t.estado = 'completada'
      ),
      0
    ) as pedidos_completados,
    p.creado_en,
    p.actualizado_en,
    p.latitud_predeterminada,
    p.longitud_predeterminada
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

revoke all on function public.obtener_mi_perfil() from public, anon, authenticated;
grant execute on function public.obtener_mi_perfil() to authenticated;

notify pgrst, 'reload schema';
