do $$
begin
  if exists (
    select 1
    from public.transacciones t
    left join public.perfiles p on p.id = t.comprador_id
    where p.id is null
  ) then
    raise exception 'No se puede corregir transacciones_comprador_id_fkey: hay transacciones con comprador_id sin perfil';
  end if;

  if exists (
    select 1
    from pg_constraint c
    where c.conname = 'transacciones_comprador_id_fkey'
      and c.conrelid = 'public.transacciones'::regclass
      and c.confrelid <> 'public.perfiles'::regclass
  ) then
    alter table public.transacciones
      drop constraint transacciones_comprador_id_fkey;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    where c.conname = 'transacciones_comprador_id_fkey'
      and c.conrelid = 'public.transacciones'::regclass
      and c.confrelid = 'public.perfiles'::regclass
  ) then
    alter table public.transacciones
      add constraint transacciones_comprador_id_fkey
      foreign key (comprador_id)
      references public.perfiles(id)
      on delete restrict;
  end if;
end $$;
