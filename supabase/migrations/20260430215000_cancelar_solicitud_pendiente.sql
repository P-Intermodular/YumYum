-- Fase A.1: cancelar solicitud pendiente por el solicitante.
--
-- Permite que quien creo una solicitud la cancele antes de que el propietario
-- responda. Notifica al propietario del producto.

create or replace function public.cancelar_solicitud_oferta(p_solicitud_id uuid)
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

  if v_solicitud.solicitante_id <> v_usuario_id then
    raise exception 'Solo el solicitante puede cancelar esta solicitud';
  end if;

  if v_solicitud.estado <> 'pendiente' then
    raise exception 'La solicitud no esta pendiente';
  end if;

  update public.solicitudes_oferta
  set estado = 'cancelada',
      respondido_en = now()
  where id = p_solicitud_id;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_solicitud.propietario_id,
    'solicitud_oferta_cancelada',
    'Solicitud cancelada',
    'Una solicitud para tu producto ha sido cancelada por el solicitante.',
    jsonb_build_object(
      'solicitud_id', v_solicitud.id,
      'producto_id', v_solicitud.producto_id
    )
  );
end;
$$;

revoke all on function public.cancelar_solicitud_oferta(uuid) from public, anon, authenticated;
grant execute on function public.cancelar_solicitud_oferta(uuid) to authenticated;

notify pgrst, 'reload schema';
