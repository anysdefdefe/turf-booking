create extension if not exists "pg_cron" with schema "pg_catalog";

drop policy "anyone_select_maintenance_slots" on "public"."slots";

drop policy "customers_insert_own_slots" on "public"."slots";

drop policy "customers_select_own_slots" on "public"."slots";

drop policy "customers_update_own_slots" on "public"."slots";

drop policy "owners_insert_maintenance_slots" on "public"."slots";

revoke delete on table "public"."slots" from "anon";

revoke insert on table "public"."slots" from "anon";

revoke references on table "public"."slots" from "anon";

revoke select on table "public"."slots" from "anon";

revoke trigger on table "public"."slots" from "anon";

revoke truncate on table "public"."slots" from "anon";

revoke update on table "public"."slots" from "anon";

revoke delete on table "public"."slots" from "authenticated";

revoke insert on table "public"."slots" from "authenticated";

revoke references on table "public"."slots" from "authenticated";

revoke select on table "public"."slots" from "authenticated";

revoke trigger on table "public"."slots" from "authenticated";

revoke truncate on table "public"."slots" from "authenticated";

revoke update on table "public"."slots" from "authenticated";

revoke delete on table "public"."slots" from "service_role";

revoke insert on table "public"."slots" from "service_role";

revoke references on table "public"."slots" from "service_role";

revoke select on table "public"."slots" from "service_role";

revoke trigger on table "public"."slots" from "service_role";

revoke truncate on table "public"."slots" from "service_role";

revoke update on table "public"."slots" from "service_role";

alter table "public"."slots" drop constraint "fk_booking";

alter table "public"."slots" drop constraint "fk_court";

alter table "public"."slots" drop constraint "slots_status_check";

alter table "public"."slots" drop constraint "slots_pkey";

drop index if exists "public"."slots_pkey";

drop table "public"."slots";


  create table "public"."blocked_slots" (
    "id" uuid not null default gen_random_uuid(),
    "court_id" uuid not null,
    "owner_id" uuid not null,
    "block_date" date not null,
    "start_time" time without time zone not null,
    "end_time" time without time zone not null,
    "reason" text,
    "status" text not null default 'blocked'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."blocked_slots" enable row level security;

CREATE UNIQUE INDEX blocked_slots_pkey ON public.blocked_slots USING btree (id);

CREATE INDEX idx_blocked_slots_court_date ON public.blocked_slots USING btree (court_id, block_date);

CREATE INDEX idx_blocked_slots_owner ON public.blocked_slots USING btree (owner_id);

alter table "public"."blocked_slots" add constraint "blocked_slots_pkey" PRIMARY KEY using index "blocked_slots_pkey";

alter table "public"."blocked_slots" add constraint "blocked_slots_court_id_fkey" FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE CASCADE not valid;

alter table "public"."blocked_slots" validate constraint "blocked_slots_court_id_fkey";

alter table "public"."blocked_slots" add constraint "blocked_slots_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."blocked_slots" validate constraint "blocked_slots_owner_id_fkey";

alter table "public"."blocked_slots" add constraint "valid_status" CHECK ((status = ANY (ARRAY['blocked'::text, 'unblocked'::text]))) not valid;

alter table "public"."blocked_slots" validate constraint "valid_status";

alter table "public"."blocked_slots" add constraint "valid_time_range" CHECK ((start_time < end_time)) not valid;

alter table "public"."blocked_slots" validate constraint "valid_time_range";

grant delete on table "public"."blocked_slots" to "anon";

grant insert on table "public"."blocked_slots" to "anon";

grant references on table "public"."blocked_slots" to "anon";

grant select on table "public"."blocked_slots" to "anon";

grant trigger on table "public"."blocked_slots" to "anon";

grant truncate on table "public"."blocked_slots" to "anon";

grant update on table "public"."blocked_slots" to "anon";

grant delete on table "public"."blocked_slots" to "authenticated";

grant insert on table "public"."blocked_slots" to "authenticated";

grant references on table "public"."blocked_slots" to "authenticated";

grant select on table "public"."blocked_slots" to "authenticated";

grant trigger on table "public"."blocked_slots" to "authenticated";

grant truncate on table "public"."blocked_slots" to "authenticated";

grant update on table "public"."blocked_slots" to "authenticated";

grant delete on table "public"."blocked_slots" to "service_role";

grant insert on table "public"."blocked_slots" to "service_role";

grant references on table "public"."blocked_slots" to "service_role";

grant select on table "public"."blocked_slots" to "service_role";

grant trigger on table "public"."blocked_slots" to "service_role";

grant truncate on table "public"."blocked_slots" to "service_role";

grant update on table "public"."blocked_slots" to "service_role";


  create policy "blocked_slots_delete"
  on "public"."blocked_slots"
  as permissive
  for delete
  to authenticated
using ((auth.uid() = owner_id));



  create policy "blocked_slots_insert"
  on "public"."blocked_slots"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = owner_id));



  create policy "blocked_slots_select_all"
  on "public"."blocked_slots"
  as permissive
  for select
  to authenticated
using (true);



  create policy "blocked_slots_update"
  on "public"."blocked_slots"
  as permissive
  for update
  to authenticated
using ((auth.uid() = owner_id))
with check ((auth.uid() = owner_id));



  create policy "court and stadium insert 44e0ot_0"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'stadium_and_court_image'::text) AND (name ~~ ((auth.uid())::text || '/%'::text))));



  create policy "delete court/stadium images 44e0ot_0"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using ((bucket_id = 'stadium_and_court_image'::text));



  create policy "delete court/stadium images 44e0ot_1"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'stadium_and_court_image'::text));



  create policy "public access to image 44e0ot_0"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'stadium_and_court_image'::text));



  create policy "update court / stadium image 44e0ot_0"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'stadium_and_court_image'::text) AND (name ~~ ((auth.uid())::text || '/%'::text))));



  create policy "update court / stadium image 44e0ot_1"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'stadium_and_court_image'::text) AND (name ~~ ((auth.uid())::text || '/%'::text))));



