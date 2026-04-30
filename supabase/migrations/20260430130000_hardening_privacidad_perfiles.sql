-- Fase 1: privacidad de perfiles y datos expuestos.

create or replace function public.obtener_mi_perfil()
returns table (
  id uuid,
  nombre text,
  email text,
  url_avatar text,
  ciudad text,
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
set search_path = public
as $$
  select
    p.id,
    p.nombre,
    p.email,
    p.url_avatar,
    p.ciudad,
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

create or replace function public.obtener_productos_cercanos(
  p_latitud double precision,
  p_longitud double precision,
  p_radio_km double precision,
  p_limite integer default 50
)
returns table (
  id uuid,
  propietario_id uuid,
  titulo text,
  descripcion text,
  tipo_oferta text,
  precio numeric,
  estado text,
  latitud_publica numeric,
  longitud_publica numeric,
  creado_en timestamptz,
  perfiles jsonb,
  imagenes_producto jsonb,
  distancia_km numeric
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    pr.id,
    pr.propietario_id,
    pr.titulo,
    pr.descripcion,
    pr.tipo_oferta,
    pr.precio,
    pr.estado,
    pr.latitud_publica,
    pr.longitud_publica,
    pr.creado_en,
    (
      select jsonb_build_object(
        'id', p.id,
        'nombre', p.nombre,
        'url_avatar', p.url_avatar,
        'valoracion_media', p.valoracion_media,
        'numero_valoraciones', p.numero_valoraciones
      )
      from public.perfiles p
      where p.id = pr.propietario_id
    ) as perfiles,
    (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'id', ip.id,
            'url_publica', ip.url_publica,
            'posicion', ip.posicion
          )
          order by ip.posicion
        )
          filter (where ip.id is not null),
        '[]'::jsonb
      )
      from public.imagenes_producto ip
      where ip.producto_id = pr.id
    ) as imagenes_producto,
    round((
      earth_distance(
        ll_to_earth(p_latitud, p_longitud),
        ll_to_earth(
          pr.latitud_publica::double precision,
          pr.longitud_publica::double precision
        )
      ) / 1000.0
    )::numeric, 3) as distancia_km
  from public.productos pr
  where pr.estado = 'disponible'
    and earth_box(
      ll_to_earth(p_latitud, p_longitud),
      greatest(coalesce(p_radio_km, 10), 1) * 1000.0
    ) @> ll_to_earth(
      pr.latitud_publica::double precision,
      pr.longitud_publica::double precision
    )
    and earth_distance(
      ll_to_earth(p_latitud, p_longitud),
      ll_to_earth(
        pr.latitud_publica::double precision,
        pr.longitud_publica::double precision
      )
    ) <= greatest(coalesce(p_radio_km, 10), 1) * 1000.0
  order by distancia_km asc, pr.creado_en desc
  limit greatest(coalesce(p_limite, 50), 1);
$$;

-- La policy SELECT de perfiles sigue permitiendo filas a usuarios autenticados.
-- La privacidad se controla aqui con grants por columna publica.
-- `ciudad` queda privada por diseno hasta decidir un modelo publico explicito.
revoke select on public.perfiles from authenticated;
revoke update (
  nombre,
  url_avatar,
  ciudad,
  preferencias,
  certificacion_sanitaria,
  actualizado_en,
  latitud_predeterminada,
  longitud_predeterminada
) on public.perfiles from authenticated;

grant select (
  id,
  nombre,
  url_avatar,
  valoracion_media,
  numero_valoraciones
) on public.perfiles to authenticated;

grant update (
  nombre,
  url_avatar,
  ciudad,
  preferencias,
  certificacion_sanitaria,
  latitud_predeterminada,
  longitud_predeterminada
) on public.perfiles to authenticated;

revoke update (actualizado_en) on public.productos from authenticated;

revoke select on public.imagenes_producto from authenticated;
grant select (
  id,
  producto_id,
  url_publica,
  posicion,
  creado_en
) on public.imagenes_producto to authenticated;

revoke all on function public.obtener_mi_perfil() from public, anon, authenticated;
revoke all on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) from public, anon, authenticated;

grant execute on function public.obtener_mi_perfil() to authenticated;
grant execute on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) to authenticated;
