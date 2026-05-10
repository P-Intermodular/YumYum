-- Limita a 5 el numero maximo de imagenes por producto.
--
-- La tabla `imagenes_producto` ya garantiza unicidad de (producto_id, posicion),
-- asi que basta con acotar el rango de posicion a [0, 4] para que un producto
-- no pueda tener mas de 5 imagenes. La UI de publicar producto refuerza el
-- limite, pero esta restriccion lo protege a nivel de BD ante llamadas
-- directas o errores en el cliente.

alter table public.imagenes_producto
  add constraint imagenes_producto_posicion_rango
  check (posicion >= 0 and posicion < 5);
