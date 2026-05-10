-- Preferencias de notificaciones por usuario.
--
-- jsonb (en lugar de columnas booleanas separadas) porque las categorías
-- crecerán con el tiempo (mensajes, valoraciones, comunidad…) sin que cada
-- nueva requiera una migración. El default cubre las tres categorías
-- iniciales en true para que los usuarios existentes sigan recibiendo
-- todas las notificaciones tras el upgrade.

alter table public.perfiles
  add column preferencias_notificaciones jsonb not null
  default '{"pedidos":true,"mensajes":true,"valoraciones":true}'::jsonb;

grant select (preferencias_notificaciones) on public.perfiles to authenticated;
grant update (preferencias_notificaciones) on public.perfiles to authenticated;

-- Recreamos obtener_mi_perfil para que devuelva el campo nuevo. El cuerpo
-- es idéntico al de la migración anterior (anadir_alergenos_perfiles),
-- con preferencias_notificaciones añadido al final del bloque del select.
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
  preferencias_notificaciones jsonb,
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
    p.preferencias_notificaciones,
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
