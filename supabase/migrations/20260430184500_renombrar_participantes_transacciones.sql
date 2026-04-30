-- Fase 1.5: nombres neutrales para participantes de transacciones y chats.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transacciones'
      and column_name = 'comprador_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transacciones'
      and column_name = 'solicitante_id'
  ) then
    alter table public.transacciones
      rename column comprador_id to solicitante_id;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transacciones'
      and column_name = 'vendedor_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transacciones'
      and column_name = 'propietario_id'
  ) then
    alter table public.transacciones
      rename column vendedor_id to propietario_id;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'conversaciones'
      and column_name = 'comprador_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'conversaciones'
      and column_name = 'solicitante_id'
  ) then
    alter table public.conversaciones
      rename column comprador_id to solicitante_id;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'conversaciones'
      and column_name = 'vendedor_id'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'conversaciones'
      and column_name = 'propietario_id'
  ) then
    alter table public.conversaciones
      rename column vendedor_id to propietario_id;
  end if;
end $$;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.transacciones'::regclass
      and conname = 'transacciones_comprador_id_fkey'
  ) and not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transacciones'::regclass
      and conname = 'transacciones_solicitante_id_fkey'
  ) then
    alter table public.transacciones
      rename constraint transacciones_comprador_id_fkey
      to transacciones_solicitante_id_fkey;
  end if;

  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.transacciones'::regclass
      and conname = 'transacciones_vendedor_id_fkey'
  ) and not exists (
    select 1 from pg_constraint
    where conrelid = 'public.transacciones'::regclass
      and conname = 'transacciones_propietario_id_fkey'
  ) then
    alter table public.transacciones
      rename constraint transacciones_vendedor_id_fkey
      to transacciones_propietario_id_fkey;
  end if;

  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.conversaciones'::regclass
      and conname = 'conversaciones_comprador_id_fkey'
  ) and not exists (
    select 1 from pg_constraint
    where conrelid = 'public.conversaciones'::regclass
      and conname = 'conversaciones_solicitante_id_fkey'
  ) then
    alter table public.conversaciones
      rename constraint conversaciones_comprador_id_fkey
      to conversaciones_solicitante_id_fkey;
  end if;

  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.conversaciones'::regclass
      and conname = 'conversaciones_vendedor_id_fkey'
  ) and not exists (
    select 1 from pg_constraint
    where conrelid = 'public.conversaciones'::regclass
      and conname = 'conversaciones_propietario_id_fkey'
  ) then
    alter table public.conversaciones
      rename constraint conversaciones_vendedor_id_fkey
      to conversaciones_propietario_id_fkey;
  end if;
end $$;

alter index if exists public.transacciones_comprador_estado_creado_en_idx
  rename to transacciones_solicitante_estado_creado_en_idx;
alter index if exists public.transacciones_vendedor_estado_creado_en_idx
  rename to transacciones_propietario_estado_creado_en_idx;
alter index if exists public.conversaciones_comprador_idx
  rename to conversaciones_solicitante_idx;
alter index if exists public.conversaciones_vendedor_idx
  rename to conversaciones_propietario_idx;

do $$
declare
  v_constraint text;
begin
  select conname
  into v_constraint
  from pg_constraint
  where conrelid = 'public.transacciones'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%solicitante_id%'
    and pg_get_constraintdef(oid) ilike '%propietario_id%'
    and conname <> 'transacciones_participantes_distintos_check'
  limit 1;

  if v_constraint is not null
    and not exists (
      select 1 from pg_constraint
      where conrelid = 'public.transacciones'::regclass
        and conname = 'transacciones_participantes_distintos_check'
    ) then
    execute format(
      'alter table public.transacciones rename constraint %I to transacciones_participantes_distintos_check',
      v_constraint
    );
  end if;

  select conname
  into v_constraint
  from pg_constraint
  where conrelid = 'public.conversaciones'::regclass
    and contype = 'c'
    and pg_get_constraintdef(oid) ilike '%solicitante_id%'
    and pg_get_constraintdef(oid) ilike '%propietario_id%'
    and conname <> 'conversaciones_participantes_distintos_check'
  limit 1;

  if v_constraint is not null
    and not exists (
      select 1 from pg_constraint
      where conrelid = 'public.conversaciones'::regclass
        and conname = 'conversaciones_participantes_distintos_check'
    ) then
    execute format(
      'alter table public.conversaciones rename constraint %I to conversaciones_participantes_distintos_check',
      v_constraint
    );
  end if;
end $$;

create or replace function public.es_participante_transaccion(
  p_producto_id uuid,
  p_usuario_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_usuario_id = (select auth.uid())
    and exists (
      select 1
      from public.transacciones t
      where (t.producto_id = p_producto_id or t.producto_ofrecido_id = p_producto_id)
        and t.estado in ('aceptada', 'completada')
        and p_usuario_id in (t.solicitante_id, t.propietario_id)
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

  insert into public.conversaciones (
    solicitud_id,
    producto_id,
    solicitante_id,
    propietario_id
  )
  values (
    v_solicitud_id,
    p_producto_id,
    v_usuario_id,
    v_producto.propietario_id
  )
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
    v_productos_ids := array[
      v_solicitud.producto_id,
      v_solicitud.producto_ofrecido_id
    ];
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
    solicitante_id,
    propietario_id,
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

  insert into public.conversaciones (
    solicitud_id,
    producto_id,
    solicitante_id,
    propietario_id
  )
  values (
    v_solicitud.id,
    v_solicitud.producto_id,
    v_solicitud.solicitante_id,
    v_solicitud.propietario_id
  )
  on conflict (solicitud_id) do update
    set producto_id = excluded.producto_id,
        solicitante_id = excluded.solicitante_id,
        propietario_id = excluded.propietario_id
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

  if v_usuario_id not in (
    v_transaccion.solicitante_id,
    v_transaccion.propietario_id
  ) then
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

drop policy if exists "Participantes pueden leer transacciones" on public.transacciones;
create policy "Participantes pueden leer transacciones"
on public.transacciones for select
to authenticated
using (
  solicitante_id = (select auth.uid())
  or propietario_id = (select auth.uid())
);

drop policy if exists "Participantes pueden leer conversaciones" on public.conversaciones;
create policy "Participantes pueden leer conversaciones"
on public.conversaciones for select
to authenticated
using (
  solicitante_id = (select auth.uid())
  or propietario_id = (select auth.uid())
);

drop policy if exists "Participantes pueden leer mensajes" on public.mensajes;
create policy "Participantes pueden leer mensajes"
on public.mensajes for select
to authenticated
using (
  exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and (select auth.uid()) in (c.solicitante_id, c.propietario_id)
  )
);

drop policy if exists "Participantes pueden enviar mensajes" on public.mensajes;
create policy "Participantes pueden enviar mensajes"
on public.mensajes for insert
to authenticated
with check (
  remitente_id = (select auth.uid())
  and exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and (select auth.uid()) in (c.solicitante_id, c.propietario_id)
  )
);

drop policy if exists "Participantes pueden valorar transacciones completadas" on public.valoraciones;
create policy "Participantes pueden valorar transacciones completadas"
on public.valoraciones for insert
to authenticated
with check (
  valorador_id = (select auth.uid())
  and exists (
    select 1
    from public.transacciones t
    where t.id = transaccion_id
      and t.estado = 'completada'
      and (select auth.uid()) in (t.solicitante_id, t.propietario_id)
      and valorado_id in (t.solicitante_id, t.propietario_id)
      and valorado_id <> (select auth.uid())
      and (
        producto_valorado_id is null
        or producto_valorado_id in (t.producto_id, t.producto_ofrecido_id)
      )
  )
);

revoke all on function public.crear_solicitud_oferta(uuid, text, uuid, text) from public, anon, authenticated;
revoke all on function public.aceptar_solicitud_oferta(uuid) from public, anon, authenticated;
revoke all on function public.completar_transaccion(uuid) from public, anon, authenticated;
revoke all on function public.es_participante_transaccion(uuid, uuid) from public, anon;

grant execute on function public.crear_solicitud_oferta(uuid, text, uuid, text) to authenticated;
grant execute on function public.aceptar_solicitud_oferta(uuid) to authenticated;
grant execute on function public.completar_transaccion(uuid) to authenticated;
grant execute on function public.es_participante_transaccion(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
