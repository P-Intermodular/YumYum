-- Recrear las RPCs del flujo de solicitud/aceptación/cancelación para que
-- gestionen el stock por raciones, soportando trueque cuantificado en ambos
-- lados (cantidad y cantidad_ofrecida).

-- ============================================================
-- crear_solicitud_oferta: añade p_cantidad y p_cantidad_ofrecida.
-- ============================================================
drop function if exists public.crear_solicitud_oferta(uuid, text, uuid, text);
drop function if exists public.crear_solicitud_oferta(uuid, text, uuid, text, integer, integer);

create or replace function public.crear_solicitud_oferta(
  p_producto_id uuid,
  p_tipo_solicitud text,
  p_producto_ofrecido_id uuid default null,
  p_mensaje text default null,
  p_cantidad int default 1,
  p_cantidad_ofrecida int default null
)
returns table(solicitud_id uuid, conversacion_id uuid)
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_producto public.productos%rowtype;
  v_producto_ofrecido public.productos%rowtype;
  v_solicitud_id uuid;
  v_conversacion_id uuid;
  v_cantidad_ofrecida int;
begin
  if v_usuario_id is null then raise exception 'Autenticacion requerida'; end if;
  if p_tipo_solicitud not in ('venta', 'intercambio') then
    raise exception 'Tipo de solicitud invalido';
  end if;
  if p_cantidad is null or p_cantidad < 1 then
    raise exception 'La cantidad debe ser al menos 1';
  end if;

  select * into v_producto from public.productos where id = p_producto_id;
  if not found or v_producto.estado <> 'disponible' then
    raise exception 'El producto no esta disponible';
  end if;
  if v_producto.tipo_oferta <> p_tipo_solicitud then
    raise exception 'El tipo de solicitud no coincide con la oferta';
  end if;
  if v_producto.propietario_id = v_usuario_id then
    raise exception 'No puedes solicitar tu propio producto';
  end if;
  if p_cantidad > v_producto.raciones_disponibles then
    raise exception 'Solo quedan % raciones disponibles', v_producto.raciones_disponibles;
  end if;

  if p_tipo_solicitud = 'venta' then
    if p_producto_ofrecido_id is not null then
      raise exception 'Las solicitudes de venta no pueden incluir producto ofrecido';
    end if;
    v_cantidad_ofrecida := null;
  else
    -- intercambio
    if p_producto_ofrecido_id is null then
      raise exception 'Las solicitudes de intercambio requieren producto ofrecido';
    end if;
    if p_cantidad_ofrecida is null or p_cantidad_ofrecida < 1 then
      raise exception 'La cantidad ofrecida debe ser al menos 1';
    end if;

    select * into v_producto_ofrecido
      from public.productos where id = p_producto_ofrecido_id;
    if not found
       or v_producto_ofrecido.propietario_id <> v_usuario_id
       or v_producto_ofrecido.estado <> 'disponible'
       or v_producto_ofrecido.tipo_oferta <> 'intercambio' then
      raise exception 'El producto ofrecido no esta disponible para intercambio';
    end if;
    if p_cantidad_ofrecida > v_producto_ofrecido.raciones_disponibles then
      raise exception 'Solo tienes % raciones disponibles del producto que ofreces',
        v_producto_ofrecido.raciones_disponibles;
    end if;
    v_cantidad_ofrecida := p_cantidad_ofrecida;
  end if;

  if exists (
    select 1 from public.solicitudes_oferta
    where producto_id = p_producto_id
      and solicitante_id = v_usuario_id
      and estado = 'pendiente'
  ) then
    raise exception 'Ya tienes una solicitud pendiente para este producto';
  end if;

  insert into public.solicitudes_oferta (
    producto_id, solicitante_id, propietario_id, tipo_solicitud,
    producto_ofrecido_id, mensaje, cantidad, cantidad_ofrecida
  )
  values (
    p_producto_id, v_usuario_id, v_producto.propietario_id, p_tipo_solicitud,
    p_producto_ofrecido_id, nullif(trim(coalesce(p_mensaje, '')), ''),
    p_cantidad, v_cantidad_ofrecida
  )
  returning id into v_solicitud_id;

  insert into public.conversaciones (solicitud_id, producto_id, solicitante_id, propietario_id)
  values (v_solicitud_id, p_producto_id, v_usuario_id, v_producto.propietario_id)
  returning id into v_conversacion_id;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_producto.propietario_id, 'solicitud_oferta_creada', 'Nueva solicitud',
    'Tienes una nueva solicitud para una oferta.',
    jsonb_build_object('solicitud_id', v_solicitud_id, 'producto_id', p_producto_id)
  );

  return query select v_solicitud_id, v_conversacion_id;
end;
$$;

-- ============================================================
-- aceptar_solicitud_oferta: decrementa raciones, estado 'agotado' si llega a 0.
-- ============================================================
create or replace function public.aceptar_solicitud_oferta(p_solicitud_id uuid)
returns table(transaccion_id uuid, conversacion_id uuid)
language plpgsql
security definer
set search_path = 'public'
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
  v_disponibles_solicitado int;
  v_disponibles_ofrecido int;
begin
  if v_usuario_id is null then raise exception 'Autenticacion requerida'; end if;

  select * into v_solicitud
    from public.solicitudes_oferta where id = p_solicitud_id for update;
  if not found then raise exception 'Solicitud no encontrada'; end if;
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

  -- Bloqueamos las filas de productos para evitar que otra transaccion
  -- decremente raciones simultaneamente.
  perform 1 from public.productos
    where id = any(v_productos_ids) order by id for update;
  get diagnostics v_bloqueados = row_count;
  if v_bloqueados <> array_length(v_productos_ids, 1) then
    raise exception 'Uno o mas productos no existen';
  end if;

  select * into v_producto_solicitado
    from public.productos where id = v_solicitud.producto_id;
  if v_producto_solicitado.propietario_id <> v_solicitud.propietario_id
     or v_producto_solicitado.estado <> 'disponible'
     or v_producto_solicitado.tipo_oferta <> v_solicitud.tipo_solicitud then
    raise exception 'El producto solicitado ya no esta disponible';
  end if;
  if v_producto_solicitado.raciones_disponibles < v_solicitud.cantidad then
    raise exception 'Ya no quedan suficientes raciones (% disponibles)',
      v_producto_solicitado.raciones_disponibles;
  end if;

  if v_solicitud.tipo_solicitud = 'intercambio' then
    select * into v_producto_ofrecido
      from public.productos where id = v_solicitud.producto_ofrecido_id;
    if not found
       or v_producto_ofrecido.propietario_id <> v_solicitud.solicitante_id
       or v_producto_ofrecido.estado <> 'disponible'
       or v_producto_ofrecido.tipo_oferta <> 'intercambio' then
      raise exception 'El producto ofrecido ya no esta disponible';
    end if;
    if v_producto_ofrecido.raciones_disponibles < v_solicitud.cantidad_ofrecida then
      raise exception 'El solicitante ya no tiene suficientes raciones del producto que ofrece';
    end if;
  end if;

  -- Decrementar raciones del producto solicitado.
  v_disponibles_solicitado := v_producto_solicitado.raciones_disponibles - v_solicitud.cantidad;
  update public.productos
    set raciones_disponibles = v_disponibles_solicitado,
        estado = case when v_disponibles_solicitado = 0 then 'agotado' else 'disponible' end
    where id = v_solicitud.producto_id;

  -- Decrementar raciones del producto ofrecido en intercambio.
  if v_solicitud.tipo_solicitud = 'intercambio' then
    v_disponibles_ofrecido := v_producto_ofrecido.raciones_disponibles - v_solicitud.cantidad_ofrecida;
    update public.productos
      set raciones_disponibles = v_disponibles_ofrecido,
          estado = case when v_disponibles_ofrecido = 0 then 'agotado' else 'disponible' end
      where id = v_solicitud.producto_ofrecido_id;
  end if;

  -- Crear transaccion con cantidades.
  insert into public.transacciones (
    solicitud_id, tipo, producto_id, producto_ofrecido_id,
    solicitante_id, propietario_id, total, estado, cantidad, cantidad_ofrecida
  )
  values (
    v_solicitud.id, v_solicitud.tipo_solicitud, v_solicitud.producto_id,
    v_solicitud.producto_ofrecido_id,
    v_solicitud.solicitante_id, v_solicitud.propietario_id,
    case when v_solicitud.tipo_solicitud = 'venta'
      then v_producto_solicitado.precio * v_solicitud.cantidad
      else null end,
    'aceptada',
    v_solicitud.cantidad,
    v_solicitud.cantidad_ofrecida
  )
  returning id into v_transaccion_id;

  insert into public.conversaciones (solicitud_id, producto_id, solicitante_id, propietario_id)
  values (v_solicitud.id, v_solicitud.producto_id, v_solicitud.solicitante_id, v_solicitud.propietario_id)
  on conflict (solicitud_id) do update
    set producto_id = excluded.producto_id,
        solicitante_id = excluded.solicitante_id,
        propietario_id = excluded.propietario_id
  returning id into v_conversacion_id;

  update public.solicitudes_oferta
    set estado = 'aceptada', respondido_en = now()
    where id = v_solicitud.id;

  -- Auto-denegar otras solicitudes pendientes que excedan ahora el stock.
  with denegadas as (
    update public.solicitudes_oferta s
    set estado = 'auto_denegada', respondido_en = now()
    where s.id <> v_solicitud.id
      and s.estado = 'pendiente'
      and (
        (s.producto_id = v_solicitud.producto_id and s.cantidad > v_disponibles_solicitado)
        or (
          v_solicitud.tipo_solicitud = 'intercambio'
          and s.producto_id = v_solicitud.producto_ofrecido_id
          and s.cantidad > coalesce(v_disponibles_ofrecido, 0)
        )
      )
    returning id, solicitante_id, producto_id, producto_ofrecido_id
  )
  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  select solicitante_id, 'solicitud_oferta_auto_denegada', 'Solicitud no disponible',
    'Una solicitud relacionada ya no esta disponible porque otra fue aceptada.',
    jsonb_build_object('solicitud_id', id, 'producto_id', producto_id, 'producto_ofrecido_id', producto_ofrecido_id)
  from denegadas;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_solicitud.solicitante_id, 'solicitud_oferta_aceptada', 'Solicitud aceptada',
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

-- ============================================================
-- cancelar_transaccion: restituye raciones; vuelve a 'disponible' si era 'agotado'.
-- ============================================================
create or replace function public.cancelar_transaccion(p_transaccion_id uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_transaccion public.transacciones%rowtype;
  v_contraparte_id uuid;
  v_producto_solicitado public.productos%rowtype;
  v_producto_ofrecido public.productos%rowtype;
  v_nuevas_disponibles_solicitado int;
  v_nuevas_disponibles_ofrecido int;
begin
  if v_usuario_id is null then raise exception 'Autenticacion requerida'; end if;

  select * into v_transaccion from public.transacciones where id = p_transaccion_id for update;
  if not found then raise exception 'Transaccion no encontrada'; end if;
  if v_usuario_id not in (v_transaccion.solicitante_id, v_transaccion.propietario_id) then
    raise exception 'Solo los participantes pueden cancelar esta transaccion';
  end if;
  if v_transaccion.estado <> 'aceptada' then
    raise exception 'La transaccion no puede cancelarse desde su estado actual';
  end if;

  update public.transacciones set estado = 'cancelada' where id = p_transaccion_id;

  -- Restituir raciones del producto solicitado.
  select * into v_producto_solicitado
    from public.productos where id = v_transaccion.producto_id for update;
  v_nuevas_disponibles_solicitado :=
    least(v_producto_solicitado.raciones_disponibles + v_transaccion.cantidad,
          v_producto_solicitado.raciones_totales);
  update public.productos
    set raciones_disponibles = v_nuevas_disponibles_solicitado,
        estado = case
          when v_producto_solicitado.estado = 'agotado' and v_nuevas_disponibles_solicitado > 0
            then 'disponible'
          else v_producto_solicitado.estado
        end
    where id = v_transaccion.producto_id;

  -- Restituir raciones del producto ofrecido en intercambio.
  if v_transaccion.tipo = 'intercambio' and v_transaccion.producto_ofrecido_id is not null then
    select * into v_producto_ofrecido
      from public.productos where id = v_transaccion.producto_ofrecido_id for update;
    v_nuevas_disponibles_ofrecido :=
      least(v_producto_ofrecido.raciones_disponibles + coalesce(v_transaccion.cantidad_ofrecida, 0),
            v_producto_ofrecido.raciones_totales);
    update public.productos
      set raciones_disponibles = v_nuevas_disponibles_ofrecido,
          estado = case
            when v_producto_ofrecido.estado = 'agotado' and v_nuevas_disponibles_ofrecido > 0
              then 'disponible'
            else v_producto_ofrecido.estado
          end
      where id = v_transaccion.producto_ofrecido_id;
  end if;

  v_contraparte_id := case when v_usuario_id = v_transaccion.solicitante_id
    then v_transaccion.propietario_id else v_transaccion.solicitante_id end;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (v_contraparte_id, 'transaccion_cancelada', 'Transaccion cancelada',
    'Una transaccion ha sido cancelada por la otra parte.',
    jsonb_build_object('transaccion_id', v_transaccion.id, 'producto_id', v_transaccion.producto_id));
end;
$$;

-- ============================================================
-- completar_transaccion: ya no toca el estado del producto; las raciones
-- ya fueron decrementadas al aceptar. Solo marca la transaccion como completada.
-- ============================================================
create or replace function public.completar_transaccion(p_transaccion_id uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_transaccion public.transacciones%rowtype;
begin
  if v_usuario_id is null then raise exception 'Autenticacion requerida'; end if;
  select * into v_transaccion from public.transacciones where id = p_transaccion_id for update;
  if not found then raise exception 'Transaccion no encontrada'; end if;
  if v_usuario_id not in (v_transaccion.solicitante_id, v_transaccion.propietario_id) then
    raise exception 'Solo los participantes pueden completar esta transaccion';
  end if;
  if v_transaccion.estado <> 'aceptada' then
    raise exception 'La transaccion no puede completarse desde su estado actual';
  end if;

  update public.transacciones
    set estado = 'completada', completado_en = now()
    where id = p_transaccion_id;
end;
$$;

grant execute on function public.crear_solicitud_oferta(uuid, text, uuid, text, integer, integer) to authenticated;
grant execute on function public.aceptar_solicitud_oferta(uuid) to authenticated;
grant execute on function public.cancelar_transaccion(uuid) to authenticated;
grant execute on function public.completar_transaccion(uuid) to authenticated;
