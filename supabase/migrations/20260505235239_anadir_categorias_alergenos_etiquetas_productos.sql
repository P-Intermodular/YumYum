-- 1. Categoría obligatoria con CHECK enum-like.
alter table public.productos
  add column categoria text not null default 'otros';

alter table public.productos
  add constraint productos_categoria_valida check (categoria in (
    'cuchara','arroces_pastas','carnes','pescados','verduras_ensaladas',
    'tapas_aperitivos','pan_masas','postres_dulces','bebidas_licores',
    'frescos_huerto','quesos_embutidos','despensa','otros'
  ));

-- 2. Columnas de etiquetas y alérgenos (sin CHECK aún).
alter table public.productos
  add column etiquetas text[] not null default '{}';

alter table public.productos
  add column alergenos text[] not null default '{}';

alter table public.productos
  add column sin_alergenos_declarados boolean not null default false;

-- 3. Backfill: datos de prueba existentes (Brownies → postres, Lasañas → arroces).
--    Se marca sin_alergenos_declarados=true para que cumplan el CHECK que viene.
update public.productos set
  categoria = 'postres_dulces',
  sin_alergenos_declarados = true
  where titulo ilike '%brownie%';

update public.productos set
  categoria = 'arroces_pastas',
  sin_alergenos_declarados = true
  where titulo ilike '%lasaña%' or titulo ilike '%lasana%';

-- Cualquier otro producto preexistente queda con categoría 'otros' y se marca
-- como "sin alérgenos declarados" para que cumpla el CHECK. Edición posterior
-- por su propietario.
update public.productos set sin_alergenos_declarados = true
  where sin_alergenos_declarados = false and array_length(alergenos, 1) is null;

-- 4. CHECK: o hay alérgenos declarados, o se afirma explícitamente que no hay.
alter table public.productos
  add constraint productos_alergenos_declarados check (
    array_length(alergenos, 1) is not null or sin_alergenos_declarados = true
  );

-- 5. Quitar el default 'otros': nuevas inserciones deben pasar categoría explícita.
alter table public.productos alter column categoria drop default;
