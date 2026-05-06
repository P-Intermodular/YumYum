-- Fase A.2: cancelar transaccion aceptada por cualquier participante.
--
-- Permite que cualquier participante cancele una transaccion en estado
-- 'aceptada'. Los productos involucrados vuelven a 'disponible' y se
-- notifica a la contraparte.

create or replace function public.cancelar_transaccion(p_transaccion_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_transaccion public.transacciones%rowtype;
  v_contraparte_id uuid;
  v_productos_ids uuid[];
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
    raise exception 'Solo los participantes pueden cancelar esta transaccion';
  end if;

  if v_transaccion.estado <> 'aceptada' then
    raise exception 'La transaccion no puede cancelarse desde su estado actual';
  end if;

  -- Cancelar la transaccion.
  update public.transacciones
  set estado = 'cancelada'
  where id = p_transaccion_id;

  -- Devolver productos a disponible.
  v_productos_ids := array[v_transaccion.producto_id];
  if v_transaccion.producto_ofrecido_id is not null then
    v_productos_ids := array[
      v_transaccion.producto_id,
      v_transaccion.producto_ofrecido_id
    ];
  end if;

  update public.productos
  set estado = 'disponible'
  where id = any(v_productos_ids)
    and estado = 'reservado';

  -- Notificar a la contraparte.
  v_contraparte_id := case
    when v_usuario_id = v_transaccion.solicitante_id
    then v_transaccion.propietario_id
    else v_transaccion.solicitante_id
  end;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_contraparte_id,
    'transaccion_cancelada',
    'Transaccion cancelada',
    'Una transaccion ha sido cancelada por la otra parte.',
    jsonb_build_object(
      'transaccion_id', v_transaccion.id,
      'producto_id', v_transaccion.producto_id
    )
  );
end;
$$;

revoke all on function public.cancelar_transaccion(uuid) from public, anon, authenticated;
grant execute on function public.cancelar_transaccion(uuid) to authenticated;

notify pgrst, 'reload schema';
