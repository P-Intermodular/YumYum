-- Tabla `favoritos`: relacion many-to-many entre usuarios y productos
-- guardados como favoritos. La PK compuesta evita duplicados naturalmente.
--
-- RLS: cada usuario solo puede leer, insertar o borrar sus propios
-- favoritos. No permitimos UPDATE — el toggle siempre es delete + insert,
-- nunca una mutacion en sitio.

create table public.favoritos (
  usuario_id uuid not null references public.perfiles(id) on delete cascade,
  producto_id uuid not null references public.productos(id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, producto_id)
);

create index favoritos_usuario_creado_idx
  on public.favoritos (usuario_id, creado_en desc);

alter table public.favoritos enable row level security;

create policy "Usuarios pueden leer sus favoritos"
  on public.favoritos for select
  using ((select auth.uid()) = usuario_id);

create policy "Usuarios pueden anadir favoritos"
  on public.favoritos for insert
  with check ((select auth.uid()) = usuario_id);

create policy "Usuarios pueden quitar favoritos"
  on public.favoritos for delete
  using ((select auth.uid()) = usuario_id);

revoke all on public.favoritos from anon, authenticated;
grant select, insert, delete on public.favoritos to authenticated;

alter publication supabase_realtime add table public.favoritos;
