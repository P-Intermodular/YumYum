-- Habilita la vista pública del perfil de otro usuario y añade la métrica
-- de pedidos completados (transacciones donde el usuario es propietario).

-- 1. Ampliar SELECT column-level a las columnas estrictamente públicas.
--    No se exponen email, certificación, preferencias, ubicación ni es_moderador.
grant select (bio, ciudad, creado_en) on public.perfiles to authenticated;

-- 2. RPC para resolver el perfil público de cualquier usuario.
--    SECURITY DEFINER: el count sobre transacciones lo necesita porque la
--    política RLS de transacciones solo permite ver las propias.
create or replace function public.obtener_perfil_publico(p_usuario_id uuid)
returns table (
  id uuid,
  nombre text,
  url_avatar text,
  ciudad text,
  bio text,
  valoracion_media numeric,
  numero_valoraciones integer,
  pedidos_completados integer,
  creado_en timestamptz
)
language sql
stable
security definer
set search_path = 'public'
as $$
  select
    p.id,
    p.nombre,
    p.url_avatar,
    p.ciudad,
    p.bio,
    p.valoracion_media,
    p.numero_valoraciones,
    coalesce(
      (
        select count(*)::int
        from public.transacciones t
        where t.propietario_id = p_usuario_id
          and t.estado = 'completada'
      ),
      0
    ) as pedidos_completados,
    p.creado_en
  from public.perfiles p
  where p.id = p_usuario_id;
$$;

grant execute on function public.obtener_perfil_publico(uuid) to authenticated;

-- 3. Recrear obtener_mi_perfil incluyendo pedidos_completados, para que la
--    pantalla de mi perfil pueda mostrar la métrica sin un segundo round-trip.
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
  pedidos_completados integer,
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

grant execute on function public.obtener_mi_perfil() to authenticated;
