-- Fase A.3: bloquear solicitudes duplicadas pendientes.
--
-- 1. Resolver posibles duplicados existentes (conservar la mas reciente).
-- 2. Crear indice unico parcial para impedir duplicados futuros.
-- 3. Añadir guarda explicita en crear_solicitud_oferta para devolver
--    error claro antes de que el indice lance un error tecnico.

-- ---------------------------------------------------------------------------
-- Paso 1: resolver duplicados existentes
-- ---------------------------------------------------------------------------

-- Para cada par (producto_id, solicitante_id) con mas de una solicitud
-- pendiente, cancelar todas excepto la mas reciente.
with duplicados as (
  select id,
         row_number() over (
           partition by producto_id, solicitante_id
           order by creado_en desc
         ) as rn
  from public.solicitudes_oferta
  where estado = 'pendiente'
)
update public.solicitudes_oferta
set estado = 'cancelada',
    respondido_en = now()
where id in (
  select id from duplicados where rn > 1
);

-- ---------------------------------------------------------------------------
-- Paso 2: indice unico parcial
-- ---------------------------------------------------------------------------

create unique index if not exists solicitudes_oferta_pendiente_unica_idx
on public.solicitudes_oferta (producto_id, solicitante_id)
where estado = 'pendiente';

-- ---------------------------------------------------------------------------
-- Paso 3: guarda explicita en crear_solicitud_oferta
-- ---------------------------------------------------------------------------

-- Redefinimos la funcion completa para inyectar la validacion de duplicados
-- antes del INSERT, manteniendo toda la logica original intacta.

create or replace function public.crear_solicitud_oferta(
  p_producto_id uuid,
  p_tipo_solicitud text,
  p_producto_ofrecido_id uuid default null,
  p_mensaje text default null
)
returns table(solicitud_id uuid, conversacion_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_producto public.productos%rowtype;
  v_producto_ofrecido public.productos%rowtype;
  v_solicitud_id uuid;
  v_conversacion_id uuid;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacion requerida';
  end if;

  if p_tipo_solicitud not in ('venta', 'intercambio') then
    raise exception 'Tipo de solicitud invalido';
  end if;

  select *
  into v_producto
  from public.productos
  where id = p_producto_id;

  if not found or v_producto.estado <> 'disponible' then
    raise exception 'El producto no esta disponible';
  end if;

  if v_producto.tipo_oferta <> p_tipo_solicitud then
    raise exception 'El tipo de solicitud no coincide con la oferta';
  end if;

  if v_producto.propietario_id = v_usuario_id then
    raise exception 'No puedes solicitar tu propio producto';
  end if;

  if p_tipo_solicitud = 'venta' and p_producto_ofrecido_id is not null then
    raise exception 'Las solicitudes de venta no pueden incluir producto ofrecido';
  end if;

  -- Guarda A.3: bloquear solicitudes duplicadas pendientes.
  if exists (
    select 1 from public.solicitudes_oferta
    where producto_id = p_producto_id
      and solicitante_id = v_usuario_id
      and estado = 'pendiente'
  ) then
    raise exception 'Ya tienes una solicitud pendiente para este producto';
  end if;

  if p_tipo_solicitud = 'intercambio' then
    if p_producto_ofrecido_id is null then
      raise exception 'Las solicitudes de intercambio requieren producto ofrecido';
    end if;

    select *
    into v_producto_ofrecido
    from public.productos
    where id = p_producto_ofrecido_id;

    if not found
      or v_producto_ofrecido.propietario_id <> v_usuario_id
      or v_producto_ofrecido.estado <> 'disponible'
      or v_producto_ofrecido.tipo_oferta <> 'intercambio' then
      raise exception 'El producto ofrecido no esta disponible para intercambio';
    end if;
  end if;

  insert into public.solicitudes_oferta (
    producto_id,
    solicitante_id,
    propietario_id,
    tipo_solicitud,
    producto_ofrecido_id,
    mensaje
  )
  values (
    p_producto_id,
    v_usuario_id,
    v_producto.propietario_id,
    p_tipo_solicitud,
    p_producto_ofrecido_id,
    nullif(trim(coalesce(p_mensaje, '')), '')
  )
  returning id into v_solicitud_id;

  insert into public.conversaciones (solicitud_id, producto_id, comprador_id, vendedor_id)
  values (v_solicitud_id, p_producto_id, v_usuario_id, v_producto.propietario_id)
  returning id into v_conversacion_id;

  insert into public.notificaciones (usuario_id, tipo, titulo, contenido, datos)
  values (
    v_producto.propietario_id,
    'solicitud_oferta_creada',
    'Nueva solicitud',
    'Tienes una nueva solicitud para una oferta.',
    jsonb_build_object('solicitud_id', v_solicitud_id, 'producto_id', p_producto_id)
  );

  return query select v_solicitud_id, v_conversacion_id;
end;
$$;

-- Los grants ya existen desde la migracion base; el CREATE OR REPLACE
-- no los modifica. No hace falta re-grantear.

notify pgrst, 'reload schema';
