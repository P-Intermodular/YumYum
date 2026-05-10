-- Grants y policy necesarios para soportar edición y eliminación de platos
-- desde el cliente. Hasta ahora la migración `20260506005754` dejó UPDATE
-- explícitamente fuera ("se añadirá cuando exista Editar producto"), y la
-- columna `ruta_storage` de `imagenes_producto` no estaba en SELECT, lo que
-- bloqueaba el flujo de limpiar Storage tras un borrado o tras quitar una
-- imagen al editar.

-- 1) Editar producto: dejar al propietario actualizar las columnas que la
-- pantalla de edición permite tocar. La policy UPDATE de `productos` ya
-- restringe filas (propietario_id = auth.uid()); aquí solo desbloqueamos
-- los grants column-level que PostgREST exige.
grant update (
  categoria,
  etiquetas,
  alergenos,
  sin_alergenos_declarados,
  raciones_totales,
  raciones_disponibles
) on public.productos to authenticated;

-- 2) Limpiar blobs en Storage al editar/eliminar requiere conocer la ruta
-- del fichero. El bucket es público (la URL pública contiene la ruta),
-- así que exponer SELECT sobre `ruta_storage` no añade información que no
-- esté ya disponible.
grant select (ruta_storage) on public.imagenes_producto to authenticated;

-- 3) Editar permite quitar imágenes existentes: el cliente hace
-- DELETE FROM imagenes_producto WHERE id IN (...). Hace falta GRANT DELETE
-- a nivel de tabla y una policy que limite las filas borrables al
-- propietario del producto al que pertenecen.
grant delete on public.imagenes_producto to authenticated;

create policy "Usuarios pueden borrar imagenes de sus productos"
  on public.imagenes_producto for delete
  using (
    exists (
      select 1 from public.productos pr
      where pr.id = imagenes_producto.producto_id
        and pr.propietario_id = (select auth.uid())
    )
  );

notify pgrst, 'reload schema';
