-- Fase A.4: restringir estados de producto accesibles desde cliente.
--
-- Un trigger BEFORE UPDATE en productos que impide que el cliente cambie
-- el estado a valores internos (reservado, completado) directamente.
--
-- Estrategia: cuando el caller es el rol 'authenticated' (query directa
-- del cliente via PostgREST), solo se permite:
--   - No cambiar estado (editar titulo, descripcion, etc.)
--   - disponible -> cancelado (el propietario cancela su producto)
--
-- Las RPCs con SECURITY DEFINER ejecutan como el owner de la funcion
-- (postgres), no como 'authenticated', por lo que el trigger no las
-- bloquea.

create or replace function public.validar_transicion_estado_producto()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Solo restringir cuando el caller es la app (rol authenticated).
  -- Las RPCs SECURITY DEFINER ejecutan como el owner y no pasan esta guarda.
  if current_user <> 'authenticated' then
    return new;
  end if;

  -- Si el estado no cambia, permitir (edicion de otros campos).
  if old.estado is not distinct from new.estado then
    return new;
  end if;

  -- Unica transicion permitida desde cliente: disponible -> cancelado.
  if old.estado = 'disponible' and new.estado = 'cancelado' then
    return new;
  end if;

  raise exception 'No tienes permiso para cambiar el estado del producto a ''%''', new.estado;
end;
$$;

create trigger trg_validar_transicion_estado_producto
before update on public.productos
for each row
execute function public.validar_transicion_estado_producto();

-- No necesita grant: los triggers se ejecutan implicitamente sobre la tabla.
-- Revocar acceso directo a la funcion por seguridad.
revoke all on function public.validar_transicion_estado_producto() from public, anon, authenticated;

notify pgrst, 'reload schema';
