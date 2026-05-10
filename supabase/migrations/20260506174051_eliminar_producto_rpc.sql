-- RPC eliminar_producto: borrado híbrido del catálogo.
--
-- Política:
--  - Solo el propietario puede eliminar su plato.
--  - Si el plato no tiene actividad asociada (sin solicitudes, transacciones,
--    valoraciones o conversaciones que lo referencien), DELETE real. Esto
--    aprovecha el ON DELETE CASCADE de imagenes_producto y favoritos para
--    limpiar las dependencias.
--  - Si tiene actividad, soft delete: UPDATE estado = 'cancelado'. La FK
--    RESTRICT en solicitudes/transacciones/conversaciones/valoraciones
--    impediría un DELETE real y, sobre todo, queremos preservar el histórico.
--
-- Devuelve `true` cuando hizo DELETE real para que el cliente sepa que debe
-- limpiar también los blobs de Storage; `false` si fue soft delete y los
-- blobs deben mantenerse hasta una eventual purga manual.
--
-- security definer para saltar el trigger validar_transicion_estado_producto,
-- que solo permite disponible→cancelado desde rol authenticated. Aquí
-- queremos poder cancelar también un plato 'agotado' o 'reservado'.

create or replace function public.eliminar_producto(p_producto_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario uuid := auth.uid();
  v_propietario uuid;
  v_actividad integer;
begin
  if v_usuario is null then
    raise exception 'Autenticacion requerida';
  end if;

  select propietario_id into v_propietario
    from public.productos where id = p_producto_id for update;
  if not found then
    raise exception 'Producto no encontrado';
  end if;
  if v_propietario <> v_usuario then
    raise exception 'Solo el propietario puede eliminar este plato';
  end if;

  -- Conteo agregado de cualquier referencia que bloquee un DELETE real.
  select
    (select count(*) from public.solicitudes_oferta
       where producto_id = p_producto_id
          or producto_ofrecido_id = p_producto_id) +
    (select count(*) from public.transacciones
       where producto_id = p_producto_id
          or producto_ofrecido_id = p_producto_id) +
    (select count(*) from public.valoraciones
       where producto_valorado_id = p_producto_id) +
    (select count(*) from public.conversaciones
       where producto_id = p_producto_id)
  into v_actividad;

  if v_actividad = 0 then
    -- Cascade limpia imagenes_producto (filas, no blobs) y favoritos.
    delete from public.productos where id = p_producto_id;
    return true;
  end if;

  -- Soft delete idempotente: si ya está cancelado, no hacemos nada y
  -- devolvemos false para que el cliente no intente limpiar Storage.
  update public.productos
    set estado = 'cancelado'
    where id = p_producto_id and estado <> 'cancelado';
  return false;
end;
$$;

revoke all on function public.eliminar_producto(uuid)
  from public, anon, authenticated;
grant execute on function public.eliminar_producto(uuid) to authenticated;

notify pgrst, 'reload schema';
