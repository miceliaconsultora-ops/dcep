-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Athletes Table
create table if not exists athletes (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text,
  stats jsonb default '{}'::jsonb,
  created_at timestamp with time zone default now()
);

-- Evaluations Table
create table if not exists evaluations (
  id uuid primary key default uuid_generate_v4(),
  athlete_id uuid references athletes(id) on delete cascade,
  evaluation_date timestamp with time zone default now(),
  technique_scores jsonb not null default '{}'::jsonb,
  tactical_score integer check (tactical_score between 1 and 5),
  physical_score integer check (physical_score between 1 and 5),
  notes text,
  created_at timestamp with time zone default now()
);

-- Shifts Table
create table if not exists shifts (
  id uuid primary key default uuid_generate_v4(),
  shift_date timestamp with time zone not null,
  court_number integer,
  players uuid[] default '{}',
  created_at timestamp with time zone default now()
);

-- RLS Policies
alter table athletes enable row level security;
alter table evaluations enable row level security;
alter table shifts enable row level security;

create policy "Allow public read" on athletes for select to public using (true);
create policy "Allow public read" on evaluations for select to public using (true);
create policy "Allow public read" on shifts for select to public using (true);
