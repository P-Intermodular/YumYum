-- Añade columnas para la ubicación predeterminada del usuario.
-- Se utiliza para precargar la ubicación exacta al publicar platos.
alter table public.perfiles
  add column latitud_predeterminada numeric(9, 6),
  add column longitud_predeterminada numeric(9, 6);

-- Otorga permisos de actualización para estas columnas a los usuarios autenticados.
grant update (latitud_predeterminada, longitud_predeterminada)
  on public.perfiles to authenticated;
