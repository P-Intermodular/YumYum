-- 1. Stock por producto: raciones totales (declaradas al publicar) y
--    raciones disponibles (decrementan al aceptar solicitudes).
alter table public.productos
  add column raciones_totales int not null default 1
    check (raciones_totales >= 1);

alter table public.productos
  add column raciones_disponibles int not null default 1
    check (raciones_disponibles >= 0);

alter table public.productos
  add constraint productos_disponibles_lte_totales
    check (raciones_disponibles <= raciones_totales);

-- 2. Backfill: productos disponibles tienen 1/1; los demás 0/1.
update public.productos
  set raciones_totales = 1,
      raciones_disponibles = case when estado = 'disponible' then 1 else 0 end;

-- 3. Añadir 'agotado' al CHECK del estado del producto. Sustituye el existente.
alter table public.productos drop constraint productos_estado_check;
alter table public.productos
  add constraint productos_estado_check check (estado in (
    'disponible','reservado','agotado','completado','cancelado'
  ));

-- 4. Cantidad solicitada en solicitudes_oferta. Default 1 retro-compatible.
alter table public.solicitudes_oferta
  add column cantidad int not null default 1 check (cantidad >= 1);

alter table public.solicitudes_oferta
  add column cantidad_ofrecida int check (cantidad_ofrecida >= 1);

-- Backfill: las solicitudes de intercambio existentes deben tener
-- cantidad_ofrecida = 1 para cumplir el CHECK que se añade después.
update public.solicitudes_oferta
  set cantidad_ofrecida = 1
  where tipo_solicitud = 'intercambio';

alter table public.solicitudes_oferta
  add constraint solicitudes_cantidad_ofrecida_valida check (
    (tipo_solicitud = 'venta' and cantidad_ofrecida is null) or
    (tipo_solicitud = 'intercambio' and cantidad_ofrecida is not null)
  );

-- 5. Cantidades en transacciones (mismo patrón).
alter table public.transacciones
  add column cantidad int not null default 1 check (cantidad >= 1);

alter table public.transacciones
  add column cantidad_ofrecida int check (cantidad_ofrecida >= 1);

update public.transacciones
  set cantidad_ofrecida = 1
  where tipo = 'intercambio';

alter table public.transacciones
  add constraint transacciones_cantidad_ofrecida_valida check (
    (tipo = 'venta' and cantidad_ofrecida is null) or
    (tipo = 'intercambio' and cantidad_ofrecida is not null)
  );
