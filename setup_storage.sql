-- SUPABASE STORAGE SETUP FOR PROFILE PHOTOS
-- Run this in Supabase SQL Editor

-- 1. Create the bucket for profile photos
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- 2. Storage Policies for 'avatars' bucket
create policy "Public Access" 
on storage.objects for select 
using ( bucket_id = 'avatars' );

create policy "Users can upload their own avatar" 
on storage.objects for insert 
with check (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own avatar" 
on storage.objects for update 
using (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
