-- Esquema base unificado de YumYum para nuevos proyectos Supabase.
create extension if not exists pgcrypto;
create extension if not exists cube;
create extension if not exists earthdistance;

create table public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  email text not null unique,
  url_avatar text not null default '',
  ciudad text,
  preferencias text[] not null default '{}',
  certificacion_sanitaria text,
  es_moderador boolean not null default false,
  valoracion_media numeric(3, 2) not null default 0,
  numero_valoraciones integer not null default 0,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.productos (
  id uuid primary key default gen_random_uuid(),
  propietario_id uuid not null references public.perfiles(id) on delete restrict,
  titulo text not null,
  descripcion text not null,
  tipo_oferta text not null check (tipo_oferta in ('venta', 'intercambio')),
  precio numeric(10, 2),
  estado text not null default 'disponible'
    check (estado in ('disponible', 'reservado', 'completado', 'cancelado')),
  latitud_publica numeric(9, 6) not null,
  longitud_publica numeric(9, 6) not null,
  latitud_exacta numeric(9, 6),
  longitud_exacta numeric(9, 6),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  check (
    (tipo_oferta = 'venta' and precio is not null and precio >= 0)
    or
    (tipo_oferta = 'intercambio' and precio is null)
  )
);

create table public.imagenes_producto (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid not null references public.productos(id) on delete cascade,
  ruta_storage text not null,
  url_publica text not null,
  posicion integer not null default 0,
  creado_en timestamptz not null default now(),
  unique(producto_id, posicion)
);

create table public.solicitudes_oferta (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid not null references public.productos(id) on delete restrict,
  solicitante_id uuid not null references public.perfiles(id) on delete cascade,
  propietario_id uuid not null references public.perfiles(id) on delete cascade,
  tipo_solicitud text not null check (tipo_solicitud in ('venta', 'intercambio')),
  producto_ofrecido_id uuid references public.productos(id) on delete restrict,
  mensaje text,
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'aceptada', 'denegada', 'auto_denegada', 'cancelada')),
  creado_en timestamptz not null default now(),
  respondido_en timestamptz,
  check (solicitante_id <> propietario_id),
  check (
    (tipo_solicitud = 'venta' and producto_ofrecido_id is null)
    or
    (tipo_solicitud = 'intercambio' and producto_ofrecido_id is not null)
  )
);

create table public.transacciones (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null unique references public.solicitudes_oferta(id) on delete restrict,
  tipo text not null check (tipo in ('venta', 'intercambio')),
  producto_id uuid not null references public.productos(id) on delete restrict,
  producto_ofrecido_id uuid references public.productos(id) on delete restrict,
  comprador_id uuid not null references public.perfiles(id) on delete restrict,
  vendedor_id uuid not null references public.perfiles(id) on delete restrict,
  total numeric(10, 2),
  estado text not null default 'aceptada'
    check (estado in ('pendiente', 'aceptada', 'completada', 'cancelada', 'reportada')),
  creado_en timestamptz not null default now(),
  completado_en timestamptz,
  check (comprador_id <> vendedor_id),
  check (
    (tipo = 'venta' and total is not null and producto_ofrecido_id is null)
    or
    (tipo = 'intercambio' and total is null and producto_ofrecido_id is not null)
  )
);

create table public.conversaciones (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null unique references public.solicitudes_oferta(id) on delete cascade,
  producto_id uuid not null references public.productos(id) on delete restrict,
  comprador_id uuid not null references public.perfiles(id) on delete cascade,
  vendedor_id uuid not null references public.perfiles(id) on delete cascade,
  ultimo_mensaje_en timestamptz,
  creado_en timestamptz not null default now(),
  check (comprador_id <> vendedor_id)
);

create table public.mensajes (
  id uuid primary key default gen_random_uuid(),
  conversacion_id uuid not null references public.conversaciones(id) on delete cascade,
  remitente_id uuid not null references public.perfiles(id) on delete cascade,
  contenido text not null check (length(trim(contenido)) > 0),
  creado_en timestamptz not null default now(),
  leido_en timestamptz
);

create table public.valoraciones (
  id uuid primary key default gen_random_uuid(),
  transaccion_id uuid not null references public.transacciones(id) on delete cascade,
  valorador_id uuid not null references public.perfiles(id) on delete cascade,
  valorado_id uuid not null references public.perfiles(id) on delete cascade,
  producto_valorado_id uuid references public.productos(id) on delete restrict,
  puntuacion integer not null check (puntuacion between 1 and 5),
  comentario text,
  creado_en timestamptz not null default now(),
  check (valorador_id <> valorado_id),
  unique(transaccion_id, valorador_id)
);

create table public.reportes (
  id uuid primary key default gen_random_uuid(),
  reportante_id uuid not null references public.perfiles(id) on delete cascade,
  tipo_objetivo text not null check (tipo_objetivo in ('producto', 'perfil', 'mensaje')),
  objetivo_id uuid not null,
  motivo text not null,
  estado text not null default 'abierta'
    check (estado in ('abierta', 'en_revision', 'resuelta', 'descartada')),
  creado_en timestamptz not null default now(),
  resuelto_en timestamptz
);

create table public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles(id) on delete cascade,
  tipo text not null,
  titulo text not null,
  contenido text not null,
  datos jsonb not null default '{}'::jsonb,
  leido_en timestamptz,
  creado_en timestamptz not null default now()
);

create index productos_estado_creado_en_idx on public.productos (estado, creado_en desc);
create index productos_propietario_estado_idx on public.productos (propietario_id, estado);
create index imagenes_producto_producto_posicion_idx on public.imagenes_producto (producto_id, posicion);
create index solicitudes_oferta_propietario_estado_creado_en_idx on public.solicitudes_oferta (propietario_id, estado, creado_en desc);
create index solicitudes_oferta_solicitante_estado_creado_en_idx on public.solicitudes_oferta (solicitante_id, estado, creado_en desc);
create index solicitudes_oferta_producto_estado_idx on public.solicitudes_oferta (producto_id, estado);
create index solicitudes_oferta_producto_ofrecido_estado_idx on public.solicitudes_oferta (producto_ofrecido_id, estado);
create index transacciones_comprador_estado_creado_en_idx on public.transacciones (comprador_id, estado, creado_en desc);
create index transacciones_vendedor_estado_creado_en_idx on public.transacciones (vendedor_id, estado, creado_en desc);
create index conversaciones_solicitud_idx on public.conversaciones (solicitud_id);
create index mensajes_conversacion_creado_en_idx on public.mensajes (conversacion_id, creado_en desc);
create index notificaciones_no_leidas_usuario_creado_en_idx
  on public.notificaciones (usuario_id, creado_en desc)
  where leido_en is null;
create index valoraciones_valorado_creado_en_idx on public.valoraciones (valorado_id, creado_en desc);
create index if not exists productos_ubicacion_idx
  on public.productos
  using gist (
    ll_to_earth(
      latitud_publica::double precision,
      longitud_publica::double precision
    )
  )
  where estado = 'disponible';

create or replace function public.establecer_actualizado_en()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

create trigger perfiles_establecer_actualizado_en
before update on public.perfiles
for each row execute function public.establecer_actualizado_en();

create trigger productos_establecer_actualizado_en
before update on public.productos
for each row execute function public.establecer_actualizado_en();

create or replace function public.crear_perfil_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.perfiles (id, email, nombre, url_avatar)
  values (
    new.id,
    new.email,
    coalesce(
      nullif(new.raw_user_meta_data->>'nombre', ''),
      nullif(new.raw_user_meta_data->>'name', ''),
      split_part(new.email, '@', 1)
    ),
    coalesce(nullif(new.raw_user_meta_data->>'url_avatar', ''), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger trigger_crear_perfil_usuario
after insert on auth.users
for each row execute function public.crear_perfil_usuario();

create or replace function public.es_participante_transaccion(p_producto_id uuid, p_usuario_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_usuario_id = auth.uid()
    and exists (
      select 1
      from public.transacciones t
      where (t.producto_id = p_producto_id or t.producto_ofrecido_id = p_producto_id)
        and t.estado in ('aceptada', 'completada')
        and p_usuario_id in (t.comprador_id, t.vendedor_id)
    );
$$;

create or replace function public.crear_solicitud_oferta(
  p_producto_id uuid,
  p_tipo_solicitud text,
  p_producto_ofrecido_id uuid default null,
  p_mensaje text default null
)
returns table(solicitud_id uuid, conversacion_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_producto public.productos%rowtype;
  v_producto_ofrecido public.productos%rowtype;
  v_solicitud_id uuid;
  v_conversacion_id uuid;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  if p_tipo_solicitud not in ('venta', 'intercambio') then
    raise exception 'Tipo de solicitud invalido';
  end if;

  select *
  into v_producto
  from public.productos
  where id = p_producto_id;

  if not found or v_producto.estado <> 'disponible' then
    raise exception 'El producto no esta disponible';
  end if;

  if v_producto.tipo_oferta <> p_tipo_solicitud then
    raise exception 'El tipo de solicitud no coincide con la oferta';
  end if;

  if v_producto.propietario_id = v_usuario_id then
    raise exception 'No puedes solicitar tu propio producto';
  end if;

  if p_tipo_solicitud = 'venta' and p_producto_ofrecido_id is not null then
    raise exception 'Las solicitudes de venta no pueden incluir producto ofrecido';
  end if;

  if p_tipo_solicitud = 'intercambio' then
    if p_producto_ofrecido_id is null then
      raise exception 'Las solicitudes de intercambio requieren producto ofrecido';
    end if;

    select *
    into v_producto_ofrecido
    from public.productos
    where id = p_producto_ofrecido_id;

    if not found
      or v_producto_ofrecido.propietario_id <> v_usuario_id
      or v_producto_ofrecido.estado <> 'disponible'
      or v_producto_ofrecido.tipo_oferta <> 'intercambio' then
      raise exception 'El producto ofrecido no esta disponible para intercambio';
    end if;
  end if;

  insert into public.solicitudes_oferta (
    producto_id,
    solicitante_id,
    propietario_id,
    tipo_solicitud,
    producto_ofrecido_id,
    mensaje
  )
  values (
    p_producto_id,
    v_usuario_id,
    v_producto.propietario_id,
    p_tipo_solicitud,
    p_producto_ofrecido_id,
    nullif(trim(coalesce(p_mensaje, '')), '')
  )
  returning id into v_solicitud_id;

  insert into public.conversaciones (solicitud_id, producto_id, comprador_id, vendedor_id)
  values (v_solicitud_id, p_producto_id, v_usuario_id, v_producto.propietario_id)
  returning id into v_conversacion_id;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_producto.propietario_id,
    'solicitud_oferta_creada',
    'Nueva solicitud',
    'Tienes una nueva solicitud para una oferta.',
    jsonb_build_object('solicitud_id', v_solicitud_id, 'producto_id', p_producto_id)
  );

  return query select v_solicitud_id, v_conversacion_id;
end;
$$;

create or replace function public.aceptar_solicitud_oferta(p_solicitud_id uuid)
returns table(transaccion_id uuid, conversacion_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_solicitud public.solicitudes_oferta%rowtype;
  v_producto_solicitado public.productos%rowtype;
  v_producto_ofrecido public.productos%rowtype;
  v_productos_ids uuid[];
  v_bloqueados integer;
  v_transaccion_id uuid;
  v_conversacion_id uuid;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  select *
  into v_solicitud
  from public.solicitudes_oferta
  where id = p_solicitud_id
  for update;

  if not found then
    raise exception 'Solicitud no encontrada';
  end if;

  if v_solicitud.propietario_id <> v_usuario_id then
    raise exception 'Solo el propietario del producto puede aceptar esta solicitud';
  end if;

  if v_solicitud.estado <> 'pendiente' then
    raise exception 'La solicitud no esta pendiente';
  end if;

  v_productos_ids := array[v_solicitud.producto_id];
  if v_solicitud.tipo_solicitud = 'intercambio' then
    v_productos_ids := array[v_solicitud.producto_id, v_solicitud.producto_ofrecido_id];
  end if;

  perform 1
  from public.productos
  where id = any(v_productos_ids)
  order by id
  for update;

  get diagnostics v_bloqueados = row_count;

  if v_bloqueados <> array_length(v_productos_ids, 1) then
    raise exception 'Uno o mas productos no existen';
  end if;

  select *
  into v_producto_solicitado
  from public.productos
  where id = v_solicitud.producto_id;

  if v_producto_solicitado.propietario_id <> v_solicitud.propietario_id
    or v_producto_solicitado.estado <> 'disponible'
    or v_producto_solicitado.tipo_oferta <> v_solicitud.tipo_solicitud then
    raise exception 'El producto solicitado ya no esta disponible';
  end if;

  if v_solicitud.tipo_solicitud = 'intercambio' then
    select *
    into v_producto_ofrecido
    from public.productos
    where id = v_solicitud.producto_ofrecido_id;

    if not found
      or v_producto_ofrecido.propietario_id <> v_solicitud.solicitante_id
      or v_producto_ofrecido.estado <> 'disponible'
      or v_producto_ofrecido.tipo_oferta <> 'intercambio' then
      raise exception 'El producto ofrecido ya no esta disponible';
    end if;
  end if;

  update public.productos
  set estado = 'reservado'
  where id = any(v_productos_ids);

  insert into public.transacciones (
    solicitud_id,
    tipo,
    producto_id,
    producto_ofrecido_id,
    comprador_id,
    vendedor_id,
    total,
    estado
  )
  values (
    v_solicitud.id,
    v_solicitud.tipo_solicitud,
    v_solicitud.producto_id,
    v_solicitud.producto_ofrecido_id,
    v_solicitud.solicitante_id,
    v_solicitud.propietario_id,
    case when v_solicitud.tipo_solicitud = 'venta' then v_producto_solicitado.precio else null end,
    'aceptada'
  )
  returning id into v_transaccion_id;

  insert into public.conversaciones (solicitud_id, producto_id, comprador_id, vendedor_id)
  values (v_solicitud.id, v_solicitud.producto_id, v_solicitud.solicitante_id, v_solicitud.propietario_id)
  on conflict (solicitud_id) do update
    set producto_id = excluded.producto_id,
        comprador_id = excluded.comprador_id,
        vendedor_id = excluded.vendedor_id
  returning id into v_conversacion_id;

  update public.solicitudes_oferta
  set estado = 'aceptada',
      respondido_en = now()
  where id = v_solicitud.id;

  with denegadas as (
    update public.solicitudes_oferta
    set estado = 'auto_denegada',
        respondido_en = now()
    where id <> v_solicitud.id
      and estado = 'pendiente'
      and (
        producto_id = any(v_productos_ids)
        or producto_ofrecido_id = any(v_productos_ids)
      )
    returning id, solicitante_id, producto_id, producto_ofrecido_id
  )
  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  select
    solicitante_id,
    'solicitud_oferta_auto_denegada',
    'Solicitud no disponible',
    'Una solicitud relacionada ya no esta disponible porque otra fue aceptada.',
    jsonb_build_object(
      'solicitud_id', id,
      'producto_id', producto_id,
      'producto_ofrecido_id', producto_ofrecido_id
    )
  from denegadas;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_solicitud.solicitante_id,
    'solicitud_oferta_aceptada',
    'Solicitud aceptada',
    'Tu solicitud ha sido aceptada.',
    jsonb_build_object(
      'solicitud_id', v_solicitud.id,
      'transaccion_id', v_transaccion_id,
      'conversacion_id', v_conversacion_id
    )
  );

  return query select v_transaccion_id, v_conversacion_id;
end;
$$;

create or replace function public.denegar_solicitud_oferta(p_solicitud_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_solicitud public.solicitudes_oferta%rowtype;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  select *
  into v_solicitud
  from public.solicitudes_oferta
  where id = p_solicitud_id
  for update;

  if not found then
    raise exception 'Solicitud no encontrada';
  end if;

  if v_solicitud.propietario_id <> v_usuario_id then
    raise exception 'Solo el propietario del producto puede denegar esta solicitud';
  end if;

  if v_solicitud.estado <> 'pendiente' then
    raise exception 'La solicitud no esta pendiente';
  end if;

  update public.solicitudes_oferta
  set estado = 'denegada',
      respondido_en = now()
  where id = p_solicitud_id;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_solicitud.solicitante_id,
    'solicitud_oferta_denegada',
    'Solicitud denegada',
    'Tu solicitud ha sido denegada.',
    jsonb_build_object('solicitud_id', v_solicitud.id, 'producto_id', v_solicitud.producto_id)
  );
end;
$$;

create or replace function public.completar_transaccion(p_transaccion_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_transaccion public.transacciones%rowtype;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  select *
  into v_transaccion
  from public.transacciones
  where id = p_transaccion_id
  for update;

  if not found then
    raise exception 'Transaccion no encontrada';
  end if;

  if v_usuario_id not in (v_transaccion.comprador_id, v_transaccion.vendedor_id) then
    raise exception 'Solo los participantes pueden completar esta transaccion';
  end if;

  if v_transaccion.estado <> 'aceptada' then
    raise exception 'La transaccion no puede completarse desde su estado actual';
  end if;

  update public.transacciones
  set estado = 'completada',
      completado_en = now()
  where id = p_transaccion_id;

  update public.productos
  set estado = 'completado'
  where id in (
    v_transaccion.producto_id,
    coalesce(v_transaccion.producto_ofrecido_id, v_transaccion.producto_id)
  );
end;
$$;

create or replace function public.recalcular_valoracion_perfil()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.perfiles
  set valoracion_media = coalesce((
        select round(avg(puntuacion)::numeric, 2)
        from public.valoraciones
        where valorado_id = new.valorado_id
      ), 0),
      numero_valoraciones = (
        select count(*)::integer
        from public.valoraciones
        where valorado_id = new.valorado_id
      )
  where id = new.valorado_id;

  return new;
end;
$$;

create trigger valoraciones_recalcular_valoracion_perfil
after insert on public.valoraciones
for each row execute function public.recalcular_valoracion_perfil();

create or replace function public.actualizar_ultimo_mensaje_conversacion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversaciones
  set ultimo_mensaje_en = new.creado_en
  where id = new.conversacion_id;

  return new;
end;
$$;

create trigger mensajes_actualizar_ultimo_mensaje_conversacion
after insert on public.mensajes
for each row execute function public.actualizar_ultimo_mensaje_conversacion();

create or replace function public.obtener_ubicacion_exacta_producto(p_producto_id uuid)
returns table(producto_id uuid, latitud_exacta numeric, longitud_exacta numeric)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  if not exists (
    select 1
    from public.productos p
    where p.id = p_producto_id
      and (
        p.propietario_id = v_usuario_id
        or public.es_participante_transaccion(p.id, v_usuario_id)
      )
  ) then
    raise exception 'La ubicacion exacta no esta disponible';
  end if;

  return query
  select p.id, p.latitud_exacta, p.longitud_exacta
  from public.productos p
  where p.id = p_producto_id;
end;
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

alter table public.perfiles enable row level security;
alter table public.productos enable row level security;
alter table public.imagenes_producto enable row level security;
alter table public.solicitudes_oferta enable row level security;
alter table public.transacciones enable row level security;
alter table public.conversaciones enable row level security;
alter table public.mensajes enable row level security;
alter table public.valoraciones enable row level security;
alter table public.reportes enable row level security;
alter table public.notificaciones enable row level security;

create policy "Usuarios autenticados pueden leer perfiles"
on public.perfiles for select
to authenticated
using (true);

create policy "Usuarios pueden actualizar su propio perfil"
on public.perfiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "Usuarios autenticados pueden leer productos visibles"
on public.productos for select
to authenticated
using (
  estado = 'disponible'
  or propietario_id = auth.uid()
  or public.es_participante_transaccion(id, auth.uid())
);

create policy "Usuarios pueden crear sus propios productos"
on public.productos for insert
to authenticated
with check (propietario_id = auth.uid() and estado = 'disponible');

create policy "Usuarios pueden actualizar sus propios productos"
on public.productos for update
to authenticated
using (propietario_id = auth.uid())
with check (propietario_id = auth.uid());

create policy "Usuarios pueden leer imagenes de productos visibles"
on public.imagenes_producto for select
to authenticated
using (
  exists (
    select 1
    from public.productos p
    where p.id = producto_id
  )
);

create policy "Usuarios pueden crear imagenes de sus productos"
on public.imagenes_producto for insert
to authenticated
with check (
  exists (
    select 1
    from public.productos p
    where p.id = producto_id
      and p.propietario_id = auth.uid()
  )
);

create policy "Usuarios pueden leer sus solicitudes"
on public.solicitudes_oferta for select
to authenticated
using (solicitante_id = auth.uid() or propietario_id = auth.uid());

create policy "Participantes pueden leer transacciones"
on public.transacciones for select
to authenticated
using (comprador_id = auth.uid() or vendedor_id = auth.uid());

create policy "Participantes pueden leer conversaciones"
on public.conversaciones for select
to authenticated
using (comprador_id = auth.uid() or vendedor_id = auth.uid());

create policy "Participantes pueden leer mensajes"
on public.mensajes for select
to authenticated
using (
  exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and auth.uid() in (c.comprador_id, c.vendedor_id)
  )
);

create policy "Participantes pueden enviar mensajes"
on public.mensajes for insert
to authenticated
with check (
  remitente_id = auth.uid()
  and exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and auth.uid() in (c.comprador_id, c.vendedor_id)
  )
);

create policy "Usuarios autenticados pueden leer valoraciones"
on public.valoraciones for select
to authenticated
using (true);

create policy "Participantes pueden valorar transacciones completadas"
on public.valoraciones for insert
to authenticated
with check (
  valorador_id = auth.uid()
  and exists (
    select 1
    from public.transacciones t
    where t.id = transaccion_id
      and t.estado = 'completada'
      and auth.uid() in (t.comprador_id, t.vendedor_id)
      and valorado_id in (t.comprador_id, t.vendedor_id)
      and valorado_id <> auth.uid()
      and (
        producto_valorado_id is null
        or producto_valorado_id in (t.producto_id, t.producto_ofrecido_id)
      )
  )
);

create policy "Usuarios pueden crear reportes"
on public.reportes for insert
to authenticated
with check (reportante_id = auth.uid());

create policy "Usuarios leen sus reportes y moderadores leen todas"
on public.reportes for select
to authenticated
using (
  reportante_id = auth.uid()
  or exists (
    select 1
    from public.perfiles p
    where p.id = auth.uid()
      and p.es_moderador
  )
);

create policy "Usuarios pueden leer sus notificaciones"
on public.notificaciones for select
to authenticated
using (usuario_id = auth.uid());

create policy "Usuarios pueden marcar notificaciones leidas"
on public.notificaciones for update
to authenticated
using (usuario_id = auth.uid())
with check (usuario_id = auth.uid());

revoke all on public.perfiles from anon, authenticated;
revoke all on public.productos from anon, authenticated;
revoke all on public.imagenes_producto from anon, authenticated;
revoke all on public.solicitudes_oferta from anon, authenticated;
revoke all on public.transacciones from anon, authenticated;
revoke all on public.conversaciones from anon, authenticated;
revoke all on public.mensajes from anon, authenticated;
revoke all on public.valoraciones from anon, authenticated;
revoke all on public.reportes from anon, authenticated;
revoke all on public.notificaciones from anon, authenticated;

grant usage on schema public to authenticated;
grant select on public.perfiles to authenticated;
grant update (
  nombre,
  url_avatar,
  ciudad,
  preferencias,
  certificacion_sanitaria,
  actualizado_en
) on public.perfiles to authenticated;

grant select (
  id,
  propietario_id,
  titulo,
  descripcion,
  tipo_oferta,
  precio,
  estado,
  latitud_publica,
  longitud_publica,
  creado_en,
  actualizado_en
) on public.productos to authenticated;
grant insert (
  propietario_id,
  titulo,
  descripcion,
  tipo_oferta,
  precio,
  estado,
  latitud_publica,
  longitud_publica,
  latitud_exacta,
  longitud_exacta
) on public.productos to authenticated;
grant update (
  titulo,
  descripcion,
  tipo_oferta,
  precio,
  estado,
  latitud_publica,
  longitud_publica,
  latitud_exacta,
  longitud_exacta,
  actualizado_en
) on public.productos to authenticated;

grant select, insert on public.imagenes_producto to authenticated;
grant select on public.solicitudes_oferta to authenticated;
grant select on public.transacciones to authenticated;
grant select on public.conversaciones to authenticated;
grant select, insert on public.mensajes to authenticated;
grant select, insert on public.valoraciones to authenticated;
grant select, insert on public.reportes to authenticated;
grant select on public.notificaciones to authenticated;
grant update (leido_en) on public.notificaciones to authenticated;

revoke all on function public.crear_solicitud_oferta(uuid, text, uuid, text) from public, anon, authenticated;
revoke all on function public.aceptar_solicitud_oferta(uuid) from public, anon, authenticated;
revoke all on function public.denegar_solicitud_oferta(uuid) from public, anon, authenticated;
revoke all on function public.completar_transaccion(uuid) from public, anon, authenticated;
revoke all on function public.obtener_ubicacion_exacta_producto(uuid) from public, anon, authenticated;
revoke all on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) from public, anon, authenticated;

grant execute on function public.crear_solicitud_oferta(uuid, text, uuid, text) to authenticated;
grant execute on function public.aceptar_solicitud_oferta(uuid) to authenticated;
grant execute on function public.denegar_solicitud_oferta(uuid) to authenticated;
grant execute on function public.completar_transaccion(uuid) to authenticated;
grant execute on function public.obtener_ubicacion_exacta_producto(uuid) to authenticated;
grant execute on function public.obtener_productos_cercanos(
  double precision,
  double precision,
  double precision,
  integer
) to authenticated;

insert into storage.buckets (id, name, public)
values
  ('imagenes-productos', 'imagenes-productos', true),
  ('avatares', 'avatares', true)
on conflict (id) do update set public = excluded.public;

create policy "Imagenes de productos son publicas"
on storage.objects for select
using (bucket_id = 'imagenes-productos');

create policy "Avatares son publicos"
on storage.objects for select
using (bucket_id = 'avatares');

create policy "Usuarios suben imagenes de productos en su carpeta"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Usuarios actualizan imagenes de productos en su carpeta"
on storage.objects for update
to authenticated
using (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Usuarios suben avatares en su carpeta"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Usuarios actualizan avatares en su carpeta"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = auth.uid()::text
);

alter publication supabase_realtime add table public.mensajes;
alter publication supabase_realtime add table public.conversaciones;
alter publication supabase_realtime add table public.solicitudes_oferta;
alter publication supabase_realtime add table public.transacciones;
alter publication supabase_realtime add table public.notificaciones;
