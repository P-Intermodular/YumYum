create or replace function public.establecer_actualizado_en()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

revoke all on function public.establecer_actualizado_en() from public, anon, authenticated;
revoke all on function public.crear_perfil_usuario() from public, anon, authenticated;
revoke all on function public.actualizar_ultimo_mensaje_conversacion() from public, anon, authenticated;
revoke all on function public.recalcular_valoracion_perfil() from public, anon, authenticated;
revoke all on function public.es_participante_transaccion(uuid, uuid) from public, anon;
grant execute on function public.es_participante_transaccion(uuid, uuid) to authenticated;

drop policy if exists "Imagenes de productos son publicas" on storage.objects;
drop policy if exists "Avatares son publicos" on storage.objects;

create index if not exists conversaciones_comprador_idx
  on public.conversaciones (comprador_id);
create index if not exists conversaciones_producto_idx
  on public.conversaciones (producto_id);
create index if not exists conversaciones_vendedor_idx
  on public.conversaciones (vendedor_id);
create index if not exists mensajes_remitente_idx
  on public.mensajes (remitente_id);
create index if not exists reportes_reportante_idx
  on public.reportes (reportante_id);
create index if not exists transacciones_producto_idx
  on public.transacciones (producto_id);
create index if not exists transacciones_producto_ofrecido_idx
  on public.transacciones (producto_ofrecido_id);
create index if not exists valoraciones_producto_valorado_idx
  on public.valoraciones (producto_valorado_id);
create index if not exists valoraciones_valorador_idx
  on public.valoraciones (valorador_id);
