-- Fase 1.6: sincronizar email de auth.users en perfiles.
--
-- Si un usuario cambia su email en Supabase Auth, perfiles.email debe
-- reflejar el cambio automaticamente. Esto evita emails desactualizados
-- y prepara el terreno para bajas logicas con anonimizado.

create or replace function public.sincronizar_email_perfil()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Solo actuar cuando el email realmente cambia.
  if new.email is distinct from old.email then
    update public.perfiles
    set email = new.email
    where id = new.id;
  end if;

  return new;
end;
$$;

-- Idempotente: eliminar trigger previo si existe para poder recrear.
drop trigger if exists trigger_sincronizar_email_perfil on auth.users;

create trigger trigger_sincronizar_email_perfil
after update on auth.users
for each row execute function public.sincronizar_email_perfil();

-- Restringir acceso a la funcion: solo el sistema (triggers) la usa,
-- no debe ser invocable por roles de aplicacion.
revoke all on function public.sincronizar_email_perfil() from public, anon, authenticated;
