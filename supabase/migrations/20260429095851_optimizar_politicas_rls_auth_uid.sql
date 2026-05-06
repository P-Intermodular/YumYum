drop policy if exists "Usuarios pueden actualizar su propio perfil" on public.perfiles;
create policy "Usuarios pueden actualizar su propio perfil"
on public.perfiles for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "Usuarios autenticados pueden leer productos visibles" on public.productos;
create policy "Usuarios autenticados pueden leer productos visibles"
on public.productos for select
to authenticated
using (
  estado = 'disponible'
  or propietario_id = (select auth.uid())
  or public.es_participante_transaccion(id, (select auth.uid()))
);

drop policy if exists "Usuarios pueden crear sus propios productos" on public.productos;
create policy "Usuarios pueden crear sus propios productos"
on public.productos for insert
to authenticated
with check (propietario_id = (select auth.uid()) and estado = 'disponible');

drop policy if exists "Usuarios pueden actualizar sus propios productos" on public.productos;
create policy "Usuarios pueden actualizar sus propios productos"
on public.productos for update
to authenticated
using (propietario_id = (select auth.uid()))
with check (propietario_id = (select auth.uid()));

drop policy if exists "Usuarios pueden crear imagenes de sus productos" on public.imagenes_producto;
create policy "Usuarios pueden crear imagenes de sus productos"
on public.imagenes_producto for insert
to authenticated
with check (
  exists (
    select 1
    from public.productos p
    where p.id = producto_id
      and p.propietario_id = (select auth.uid())
  )
);

drop policy if exists "Usuarios pueden leer sus solicitudes" on public.solicitudes_oferta;
create policy "Usuarios pueden leer sus solicitudes"
on public.solicitudes_oferta for select
to authenticated
using (
  solicitante_id = (select auth.uid())
  or propietario_id = (select auth.uid())
);

drop policy if exists "Participantes pueden leer transacciones" on public.transacciones;
create policy "Participantes pueden leer transacciones"
on public.transacciones for select
to authenticated
using (
  comprador_id = (select auth.uid())
  or vendedor_id = (select auth.uid())
);

drop policy if exists "Participantes pueden leer conversaciones" on public.conversaciones;
create policy "Participantes pueden leer conversaciones"
on public.conversaciones for select
to authenticated
using (
  comprador_id = (select auth.uid())
  or vendedor_id = (select auth.uid())
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
      and (select auth.uid()) in (c.comprador_id, c.vendedor_id)
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
      and (select auth.uid()) in (c.comprador_id, c.vendedor_id)
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
      and (select auth.uid()) in (t.comprador_id, t.vendedor_id)
      and valorado_id in (t.comprador_id, t.vendedor_id)
      and valorado_id <> (select auth.uid())
      and (
        producto_valorado_id is null
        or producto_valorado_id in (t.producto_id, t.producto_ofrecido_id)
      )
  )
);

drop policy if exists "Usuarios pueden crear reportes" on public.reportes;
create policy "Usuarios pueden crear reportes"
on public.reportes for insert
to authenticated
with check (reportante_id = (select auth.uid()));

drop policy if exists "Usuarios leen sus reportes y moderadores leen todas" on public.reportes;
create policy "Usuarios leen sus reportes y moderadores leen todas"
on public.reportes for select
to authenticated
using (
  reportante_id = (select auth.uid())
  or exists (
    select 1
    from public.perfiles p
    where p.id = (select auth.uid())
      and p.es_moderador
  )
);

drop policy if exists "Usuarios pueden leer sus notificaciones" on public.notificaciones;
create policy "Usuarios pueden leer sus notificaciones"
on public.notificaciones for select
to authenticated
using (usuario_id = (select auth.uid()));

drop policy if exists "Usuarios pueden marcar notificaciones leidas" on public.notificaciones;
create policy "Usuarios pueden marcar notificaciones leidas"
on public.notificaciones for update
to authenticated
using (usuario_id = (select auth.uid()))
with check (usuario_id = (select auth.uid()));

drop policy if exists "Usuarios suben imagenes de productos en su carpeta" on storage.objects;
create policy "Usuarios suben imagenes de productos en su carpeta"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Usuarios actualizan imagenes de productos en su carpeta" on storage.objects;
create policy "Usuarios actualizan imagenes de productos en su carpeta"
on storage.objects for update
to authenticated
using (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'imagenes-productos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Usuarios suben avatares en su carpeta" on storage.objects;
create policy "Usuarios suben avatares en su carpeta"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Usuarios actualizan avatares en su carpeta" on storage.objects;
create policy "Usuarios actualizan avatares en su carpeta"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
