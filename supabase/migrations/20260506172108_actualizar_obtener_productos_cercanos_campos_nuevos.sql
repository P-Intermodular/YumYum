-- Actualiza la RPC obtener_productos_cercanos para que devuelva los campos
-- añadidos a `productos` después de su última definición (categoria, etiquetas,
-- alergenos, sin_alergenos_declarados, raciones_totales, raciones_disponibles).
--
-- Sin estos campos los filtros del feed/mapa (alérgenos excluidos, etiquetas
-- dietéticas, categoría) no surtían efecto: el cliente recibía siempre
-- alergenos=[], sin_alergenos_declarados=false y categoria=null, así que la
-- condición "no contiene ninguno de los alérgenos excluidos" se cumplía
-- trivialmente para todos los productos.
--
-- Cambia la signature de RETURNS TABLE → DROP previo obligatorio porque
-- CREATE OR REPLACE no admite cambios en el tipo de retorno.

drop function if exists public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
);

create function public.obtener_productos_cercanos(
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
  categoria text,
  etiquetas text[],
  alergenos text[],
  sin_alergenos_declarados boolean,
  raciones_totales integer,
  raciones_disponibles integer,
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
    pr.categoria,
    pr.etiquetas,
    pr.alergenos,
    pr.sin_alergenos_declarados,
    pr.raciones_totales,
    pr.raciones_disponibles,
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

-- Las ACLs se pierden con DROP: re-aplicamos el patrón ya usado en migraciones
-- previas (default deny + grant explícito a authenticated).
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

-- PostgREST cachea la firma de las RPCs; sin esta señal seguiría devolviendo
-- el shape antiguo para los clientes nuevos.
notify pgrst, 'reload schema';
