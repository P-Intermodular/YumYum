-- Nueva policy para permitir a los participantes marcar los mensajes de la
-- otra persona como leídos.
--
-- La RLS solo controla qué filas se pueden actualizar; los GRANT controlan
-- qué columnas. El esquema base hace `revoke all` sobre mensajes y solo
-- otorga `select, insert`, así que sin el GRANT UPDATE de abajo cualquier
-- intento del cliente devolvería `permission denied for table mensajes`
-- antes de evaluar la RLS. Restringimos el grant a la columna `leido_en`
-- para que un participante no pueda alterar el contenido o el remitente
-- de los mensajes de la contraparte aunque la RLS le permita la fila.

drop policy if exists "Participantes pueden actualizar mensajes ajenos" on public.mensajes;

create policy "Participantes pueden actualizar mensajes ajenos"
on public.mensajes for update
to authenticated
using (
  remitente_id <> (select auth.uid())
  and exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and (select auth.uid()) in (c.solicitante_id, c.propietario_id)
  )
)
with check (
  remitente_id <> (select auth.uid())
  and exists (
    select 1
    from public.conversaciones c
    where c.id = conversacion_id
      and (select auth.uid()) in (c.solicitante_id, c.propietario_id)
  )
);

grant update (leido_en) on public.mensajes to authenticated;

notify pgrst, 'reload schema';
