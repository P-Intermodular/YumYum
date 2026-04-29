do $$
begin
  if exists (
    select 1
    from public.transacciones t
    left join public.perfiles p on p.id = t.comprador_id
    where p.id is null
  ) then
    raise exception 'No se puede crear transacciones_comprador_id_fkey: hay transacciones con comprador_id sin perfil';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'transacciones_comprador_id_fkey'
      and conrelid = 'public.transacciones'::regclass
  ) then
    alter table public.transacciones
      add constraint transacciones_comprador_id_fkey
      foreign key (comprador_id)
      references public.perfiles(id)
      on delete restrict;
  end if;
end $$;
