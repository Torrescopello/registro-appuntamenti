-- ============================================================
-- Registro Appuntamenti · Torre di Scopello
-- Struttura del database (Supabase / PostgreSQL)
-- ============================================================
-- Come usarlo:
--   1. Apri il progetto Supabase > SQL Editor > New query.
--   2. Incolla TUTTO questo testo.
--   3. In fondo, nella sezione "PRIMO AMMINISTRATORE", scrivi la tua
--      email e il tuo nome al posto di quelli di esempio.
--   4. Premi Run.
-- Si può eseguire più volte senza danni.
-- ============================================================

-- ---------- Squadra: chi può entrare nell'app ----------
create table if not exists public.staff (
  email      text primary key check (email = lower(email)),
  nome       text not null,
  ruolo      text not null default 'staff' check (ruolo in ('admin','staff')),
  attivo     boolean not null default true,
  creato_il  timestamptz not null default now()
);

-- ---------- Coppie ----------
create table if not exists public.coppie (
  id               uuid primary key default gen_random_uuid(),
  sposo1           text,
  sposo2           text,
  email            text,
  telefono         text,
  paese            text,
  citta            text,
  lingua           text,
  fonte            text,
  fonte_dettaglio  text,
  primo_contatto   date,
  data_matrimonio  date,
  data_flessibile  text,
  ospiti           text,
  budget           text,
  pacchetto        text,
  marina           boolean not null default false,
  stato            text not null default 'nuovo'
                   check (stato in ('nuovo','appuntamento','fatto','proposta','contratto','confermato','perso')),
  data_firma       date,
  note             text,
  creato_il        timestamptz not null default now(),
  creato_da        text default lower(coalesce(auth.jwt()->>'email','')),
  aggiornato_il    timestamptz not null default now()
);

-- ---------- Appuntamenti ----------
create table if not exists public.appuntamenti (
  id             uuid primary key default gen_random_uuid(),
  coppia_id      uuid not null references public.coppie(id) on delete cascade,
  data           date not null,
  ora            time,
  tipo           text,
  chi_nome       text,
  esito          text not null default 'programmato'
                 check (esito in ('programmato','svolto','annullato','noshow')),
  nota           text,
  creato_il      timestamptz not null default now(),
  aggiornato_il  timestamptz not null default now()
);
create index if not exists appuntamenti_coppia_idx on public.appuntamenti(coppia_id);
create index if not exists appuntamenti_data_idx   on public.appuntamenti(data);

-- ---------- Storia (passaggi e note) ----------
create table if not exists public.eventi (
  id           uuid primary key default gen_random_uuid(),
  coppia_id    uuid not null references public.coppie(id) on delete cascade,
  creato_il    timestamptz not null default now(),
  tipo         text,
  testo        text not null,
  automatico   boolean not null default false,
  autore_nome  text,
  autore_email text default lower(coalesce(auth.jwt()->>'email',''))
);
create index if not exists eventi_coppia_idx on public.eventi(coppia_id);

-- ---------- Aggiornamento automatico di "aggiornato_il" ----------
create or replace function public.tocca_aggiornato() returns trigger
language plpgsql as $$
begin new.aggiornato_il := now(); return new; end $$;

drop trigger if exists coppie_aggiornato on public.coppie;
create trigger coppie_aggiornato before update on public.coppie
  for each row execute function public.tocca_aggiornato();
drop trigger if exists appuntamenti_aggiornato on public.appuntamenti;
create trigger appuntamenti_aggiornato before update on public.appuntamenti
  for each row execute function public.tocca_aggiornato();

-- ---------- Chi è l'utente collegato ----------
create or replace function public.mia_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt()->>'email','')) $$;

create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.staff where email = public.mia_email() and attivo)
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.staff where email = public.mia_email() and attivo and ruolo = 'admin')
$$;

-- ---------- Regole di accesso (Row Level Security) ----------
-- Senza un account attivo nella Squadra non si legge e non si scrive nulla.
alter table public.staff        enable row level security;
alter table public.coppie       enable row level security;
alter table public.appuntamenti enable row level security;
alter table public.eventi       enable row level security;

drop policy if exists staff_leggi    on public.staff;
drop policy if exists staff_gestisci on public.staff;
create policy staff_leggi    on public.staff for select to authenticated using (public.is_staff());
create policy staff_gestisci on public.staff for all    to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists coppie_leggi     on public.coppie;
drop policy if exists coppie_crea      on public.coppie;
drop policy if exists coppie_modifica  on public.coppie;
drop policy if exists coppie_elimina   on public.coppie;
create policy coppie_leggi    on public.coppie for select to authenticated using (public.is_staff());
create policy coppie_crea     on public.coppie for insert to authenticated with check (public.is_staff());
create policy coppie_modifica on public.coppie for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy coppie_elimina  on public.coppie for delete to authenticated using (public.is_admin());

drop policy if exists appuntamenti_tutto on public.appuntamenti;
create policy appuntamenti_tutto on public.appuntamenti for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

drop policy if exists eventi_leggi   on public.eventi;
drop policy if exists eventi_crea    on public.eventi;
drop policy if exists eventi_elimina on public.eventi;
create policy eventi_leggi   on public.eventi for select to authenticated using (public.is_staff());
create policy eventi_crea    on public.eventi for insert to authenticated with check (public.is_staff());
create policy eventi_elimina on public.eventi for delete to authenticated using (public.is_admin());

-- Permessi delle tabelle: solo per chi ha fatto l'accesso (le regole sopra
-- decidono poi cosa può vedere). Nessun accesso per chi non ha fatto l'accesso.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.staff, public.coppie, public.appuntamenti, public.eventi to authenticated;
grant execute on function public.mia_email(), public.is_staff(), public.is_admin() to authenticated;
revoke all on public.staff, public.coppie, public.appuntamenti, public.eventi from anon;

-- ---------- Solo le email della Squadra possono creare un account ----------
create or replace function public.solo_staff_registra() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists(select 1 from public.staff where email = lower(new.email) and attivo) then
    raise exception 'Questa email non è autorizzata. Chiedi all''amministratore di aggiungerti alla Squadra.';
  end if;
  return new;
end $$;

drop trigger if exists solo_staff_registra on auth.users;
create trigger solo_staff_registra before insert on auth.users
  for each row execute function public.solo_staff_registra();

-- ============================================================
-- PRIMO AMMINISTRATORE
-- Sostituisci l'email con quella aziendale (in minuscolo), poi Run.
-- ============================================================
insert into public.staff (email, nome, ruolo)
values ('email-aziendale@esempio.it', 'Torre di Scopello', 'admin')
on conflict (email) do update set ruolo = 'admin', attivo = true, nome = excluded.nome;
