create extension if not exists cube;
create extension if not exists earthdistance;

create index if not exists productos_ubicacion_idx
  on public.productos
  using gist (
    ll_to_earth(
      latitud_publica::double precision,
      longitud_publica::double precision
    )
  )
  where estado = 'disponible';

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
      select to_jsonb(p)
      from public.perfiles p
      where p.id = pr.propietario_id
    ) as perfiles,
    (
      select coalesce(
        jsonb_agg(to_jsonb(ip) order by ip.posicion)
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

revoke all on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) from public, anon, authenticated;

grant execute on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) to authenticated;
