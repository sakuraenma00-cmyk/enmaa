create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Student',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  course text not null,
  priority text not null default 'medium' check (priority in ('high', 'medium', 'low')),
  due_date timestamptz not null,
  description text not null default '',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.assignment_completions (
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key (assignment_id, user_id)
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  student_name text not null default 'Student',
  image_url text not null,
  storage_path text not null,
  notes text not null default '',
  created_at timestamptz not null default now()
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'assignments') then
      alter publication supabase_realtime add table public.assignments;
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'submissions') then
      alter publication supabase_realtime add table public.submissions;
    end if;
  end if;
end;
$$;

grant usage on schema public to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.assignments to authenticated;
grant select, insert, delete on public.assignment_completions to authenticated;
grant select, insert on public.submissions to authenticated;

alter table public.profiles enable row level security;
alter table public.assignments enable row level security;
alter table public.assignment_completions enable row level security;
alter table public.submissions enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "assignments_read_network" on public.assignments;
create policy "assignments_read_network" on public.assignments for select to authenticated using (true);
drop policy if exists "assignments_insert_own" on public.assignments;
create policy "assignments_insert_own" on public.assignments for insert to authenticated with check (auth.uid() = created_by);
drop policy if exists "assignments_update_creator" on public.assignments;
create policy "assignments_update_creator" on public.assignments for update to authenticated using (auth.uid() = created_by) with check (auth.uid() = created_by);
drop policy if exists "assignments_delete_creator" on public.assignments;
create policy "assignments_delete_creator" on public.assignments for delete to authenticated using (auth.uid() = created_by);

drop policy if exists "completions_read_own" on public.assignment_completions;
create policy "completions_read_own" on public.assignment_completions for select to authenticated using (auth.uid() = user_id);
drop policy if exists "completions_insert_own" on public.assignment_completions;
create policy "completions_insert_own" on public.assignment_completions for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "completions_delete_own" on public.assignment_completions;
create policy "completions_delete_own" on public.assignment_completions for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "submissions_read_network" on public.submissions;
create policy "submissions_read_network" on public.submissions for select to authenticated using (true);
drop policy if exists "submissions_insert_own" on public.submissions;
create policy "submissions_insert_own" on public.submissions for insert to authenticated with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('finished-work', 'finished-work', true, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = true, file_size_limit = 10485760, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "finished_work_upload_own_folder" on storage.objects;
create policy "finished_work_upload_own_folder" on storage.objects for insert to authenticated
with check (bucket_id = 'finished-work' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "finished_work_read_public" on storage.objects;
create policy "finished_work_read_public" on storage.objects for select to public
using (bucket_id = 'finished-work');
drop policy if exists "finished_work_delete_own_folder" on storage.objects;
create policy "finished_work_delete_own_folder" on storage.objects for delete to authenticated
using (bucket_id = 'finished-work' and (storage.foldername(name))[1] = auth.uid()::text);
