-- Las migraciones anteriores añadieron columnas a public.productos
-- (categoria, etiquetas, alergenos, sin_alergenos_declarados,
-- raciones_totales, raciones_disponibles) pero olvidaron dar los grants
-- column-level a `authenticated`. PostgREST sirve SELECT/INSERT explícitos
-- columna a columna, así que sin el grant la API rechaza con 42501
-- ("permission denied") cuando la query las menciona, incluso si la
-- política RLS las permitiría.
--
-- UPDATE no se concede aquí: las RPCs (aceptar/cancelar) corren como
-- SECURITY DEFINER y ya pueden modificar todo. Si en el futuro hay
-- "Editar producto" se añadirá UPDATE explícito.

grant select (
  categoria,
  etiquetas,
  alergenos,
  sin_alergenos_declarados,
  raciones_totales,
  raciones_disponibles
) on public.productos to authenticated;

grant insert (
  categoria,
  etiquetas,
  alergenos,
  sin_alergenos_declarados,
  raciones_totales,
  raciones_disponibles
) on public.productos to authenticated;
