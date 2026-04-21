drop extension if exists "pg_net";

create extension if not exists "btree_gist" with schema "public";


  create table "public"."bookings" (
    "id" uuid not null default gen_random_uuid(),
    "court_id" uuid not null,
    "customer_id" uuid not null,
    "booking_date" date not null,
    "start_time" time without time zone not null,
    "end_time" time without time zone not null,
    "duration_hours" integer not null,
    "total_amount" numeric not null,
    "status" text not null default 'pending'::text,
    "payment_status" text not null default 'unpaid'::text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."bookings" enable row level security;


  create table "public"."courts" (
    "id" uuid not null default gen_random_uuid(),
    "stadium_id" uuid not null,
    "name" text not null,
    "sport_type" text not null,
    "description" text,
    "price_per_hour" numeric not null,
    "image_url" text,
    "open_time" time without time zone not null,
    "close_time" time without time zone not null,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now(),
    "equipments" text[]
      );


alter table "public"."courts" enable row level security;


  create table "public"."owner_applications" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "business_name" text not null,
    "phone" text not null,
    "message" text,
    "status" text not null default 'pending'::text,
    "created_at" timestamp with time zone not null default now(),
    "document_url" text
      );


alter table "public"."owner_applications" enable row level security;


  create table "public"."slots" (
    "id" uuid not null default gen_random_uuid(),
    "court_id" uuid not null,
    "booking_id" uuid,
    "start_time" timestamp without time zone not null,
    "end_time" timestamp without time zone not null,
    "status" text not null,
    "created_at" timestamp without time zone default now()
      );


alter table "public"."slots" enable row level security;


  create table "public"."stadiums" (
    "id" uuid not null default gen_random_uuid(),
    "owner_id" uuid not null,
    "name" text not null,
    "description" text,
    "address" text not null,
    "city" text not null,
    "latitude" double precision,
    "longitude" double precision,
    "image_url" text,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now(),
    "amenities" text[]
      );


alter table "public"."stadiums" enable row level security;


  create table "public"."users" (
    "id" uuid not null,
    "full_name" text,
    "email" text not null,
    "phone" text,
    "avatar_url" text,
    "is_owner" boolean not null default false,
    "is_approved" boolean not null default false,
    "is_admin" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "is_blocked" boolean default false
      );


alter table "public"."users" enable row level security;

CREATE INDEX bookings_booking_date_idx ON public.bookings USING btree (booking_date);

select 1; 
-- CREATE INDEX bookings_court_id_booking_date_tsrange_excl ON public.bookings USING gist (court_id, booking_date, tsrange((booking_date + start_time), (booking_date + end_time)));

CREATE INDEX bookings_court_id_idx ON public.bookings USING btree (court_id);

CREATE INDEX bookings_customer_id_idx ON public.bookings USING btree (customer_id);

CREATE UNIQUE INDEX bookings_pkey ON public.bookings USING btree (id);

CREATE UNIQUE INDEX courts_pkey ON public.courts USING btree (id);

CREATE INDEX courts_stadium_id_idx ON public.courts USING btree (stadium_id);

CREATE UNIQUE INDEX owner_applications_pkey ON public.owner_applications USING btree (id);

CREATE INDEX owner_applications_user_id_idx ON public.owner_applications USING btree (user_id);

CREATE UNIQUE INDEX slots_pkey ON public.slots USING btree (id);

CREATE INDEX stadiums_owner_id_idx ON public.stadiums USING btree (owner_id);

CREATE UNIQUE INDEX stadiums_pkey ON public.stadiums USING btree (id);

CREATE UNIQUE INDEX unique_pending_application_per_user ON public.owner_applications USING btree (user_id) WHERE (status = 'pending'::text);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

alter table "public"."bookings" add constraint "bookings_pkey" PRIMARY KEY using index "bookings_pkey";

alter table "public"."courts" add constraint "courts_pkey" PRIMARY KEY using index "courts_pkey";

alter table "public"."owner_applications" add constraint "owner_applications_pkey" PRIMARY KEY using index "owner_applications_pkey";

alter table "public"."slots" add constraint "slots_pkey" PRIMARY KEY using index "slots_pkey";

alter table "public"."stadiums" add constraint "stadiums_pkey" PRIMARY KEY using index "stadiums_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."bookings" add constraint "bookings_court_id_booking_date_tsrange_excl" EXCLUDE USING gist (court_id WITH =, booking_date WITH =, tsrange((booking_date + start_time), (booking_date + end_time)) WITH &&);

alter table "public"."bookings" add constraint "bookings_court_id_fkey" FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE RESTRICT not valid;

alter table "public"."bookings" validate constraint "bookings_court_id_fkey";

alter table "public"."bookings" add constraint "bookings_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE RESTRICT not valid;

alter table "public"."bookings" validate constraint "bookings_customer_id_fkey";

alter table "public"."bookings" add constraint "bookings_duration_hours_check" CHECK ((duration_hours > 0)) not valid;

alter table "public"."bookings" validate constraint "bookings_duration_hours_check";

alter table "public"."bookings" add constraint "bookings_payment_status_check" CHECK ((payment_status = ANY (ARRAY['unpaid'::text, 'paid'::text, 'refunded'::text]))) not valid;

alter table "public"."bookings" validate constraint "bookings_payment_status_check";

alter table "public"."bookings" add constraint "bookings_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text]))) not valid;

alter table "public"."bookings" validate constraint "bookings_status_check";

alter table "public"."bookings" add constraint "bookings_total_amount_check" CHECK ((total_amount > (0)::numeric)) not valid;

alter table "public"."bookings" validate constraint "bookings_total_amount_check";

alter table "public"."bookings" add constraint "valid_time_range" CHECK ((end_time > start_time)) not valid;

alter table "public"."bookings" validate constraint "valid_time_range";

alter table "public"."courts" add constraint "courts_price_per_hour_check" CHECK ((price_per_hour > (0)::numeric)) not valid;

alter table "public"."courts" validate constraint "courts_price_per_hour_check";

alter table "public"."courts" add constraint "courts_stadium_id_fkey" FOREIGN KEY (stadium_id) REFERENCES public.stadiums(id) ON DELETE CASCADE not valid;

alter table "public"."courts" validate constraint "courts_stadium_id_fkey";

alter table "public"."owner_applications" add constraint "owner_applications_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))) not valid;

alter table "public"."owner_applications" validate constraint "owner_applications_status_check";

alter table "public"."owner_applications" add constraint "owner_applications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."owner_applications" validate constraint "owner_applications_user_id_fkey";

alter table "public"."slots" add constraint "fk_booking" FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL not valid;

alter table "public"."slots" validate constraint "fk_booking";

alter table "public"."slots" add constraint "fk_court" FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE CASCADE not valid;

alter table "public"."slots" validate constraint "fk_court";

alter table "public"."slots" add constraint "slots_status_check" CHECK ((status = ANY (ARRAY['available'::text, 'booked'::text, 'blocked'::text, 'maintenance'::text]))) not valid;

alter table "public"."slots" validate constraint "slots_status_check";

alter table "public"."stadiums" add constraint "stadiums_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."stadiums" validate constraint "stadiums_owner_id_fkey";

alter table "public"."users" add constraint "users_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.users (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name'
    ),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

grant delete on table "public"."bookings" to "anon";

grant insert on table "public"."bookings" to "anon";

grant references on table "public"."bookings" to "anon";

grant select on table "public"."bookings" to "anon";

grant trigger on table "public"."bookings" to "anon";

grant truncate on table "public"."bookings" to "anon";

grant update on table "public"."bookings" to "anon";

grant delete on table "public"."bookings" to "authenticated";

grant insert on table "public"."bookings" to "authenticated";

grant references on table "public"."bookings" to "authenticated";

grant select on table "public"."bookings" to "authenticated";

grant trigger on table "public"."bookings" to "authenticated";

grant truncate on table "public"."bookings" to "authenticated";

grant update on table "public"."bookings" to "authenticated";

grant delete on table "public"."bookings" to "service_role";

grant insert on table "public"."bookings" to "service_role";

grant references on table "public"."bookings" to "service_role";

grant select on table "public"."bookings" to "service_role";

grant trigger on table "public"."bookings" to "service_role";

grant truncate on table "public"."bookings" to "service_role";

grant update on table "public"."bookings" to "service_role";

grant delete on table "public"."courts" to "anon";

grant insert on table "public"."courts" to "anon";

grant references on table "public"."courts" to "anon";

grant select on table "public"."courts" to "anon";

grant trigger on table "public"."courts" to "anon";

grant truncate on table "public"."courts" to "anon";

grant update on table "public"."courts" to "anon";

grant delete on table "public"."courts" to "authenticated";

grant insert on table "public"."courts" to "authenticated";

grant references on table "public"."courts" to "authenticated";

grant select on table "public"."courts" to "authenticated";

grant trigger on table "public"."courts" to "authenticated";

grant truncate on table "public"."courts" to "authenticated";

grant update on table "public"."courts" to "authenticated";

grant delete on table "public"."courts" to "service_role";

grant insert on table "public"."courts" to "service_role";

grant references on table "public"."courts" to "service_role";

grant select on table "public"."courts" to "service_role";

grant trigger on table "public"."courts" to "service_role";

grant truncate on table "public"."courts" to "service_role";

grant update on table "public"."courts" to "service_role";

grant delete on table "public"."owner_applications" to "anon";

grant insert on table "public"."owner_applications" to "anon";

grant references on table "public"."owner_applications" to "anon";

grant select on table "public"."owner_applications" to "anon";

grant trigger on table "public"."owner_applications" to "anon";

grant truncate on table "public"."owner_applications" to "anon";

grant update on table "public"."owner_applications" to "anon";

grant delete on table "public"."owner_applications" to "authenticated";

grant insert on table "public"."owner_applications" to "authenticated";

grant references on table "public"."owner_applications" to "authenticated";

grant select on table "public"."owner_applications" to "authenticated";

grant trigger on table "public"."owner_applications" to "authenticated";

grant truncate on table "public"."owner_applications" to "authenticated";

grant update on table "public"."owner_applications" to "authenticated";

grant delete on table "public"."owner_applications" to "service_role";

grant insert on table "public"."owner_applications" to "service_role";

grant references on table "public"."owner_applications" to "service_role";

grant select on table "public"."owner_applications" to "service_role";

grant trigger on table "public"."owner_applications" to "service_role";

grant truncate on table "public"."owner_applications" to "service_role";

grant update on table "public"."owner_applications" to "service_role";

grant delete on table "public"."slots" to "anon";

grant insert on table "public"."slots" to "anon";

grant references on table "public"."slots" to "anon";

grant select on table "public"."slots" to "anon";

grant trigger on table "public"."slots" to "anon";

grant truncate on table "public"."slots" to "anon";

grant update on table "public"."slots" to "anon";

grant delete on table "public"."slots" to "authenticated";

grant insert on table "public"."slots" to "authenticated";

grant references on table "public"."slots" to "authenticated";

grant select on table "public"."slots" to "authenticated";

grant trigger on table "public"."slots" to "authenticated";

grant truncate on table "public"."slots" to "authenticated";

grant update on table "public"."slots" to "authenticated";

grant delete on table "public"."slots" to "service_role";

grant insert on table "public"."slots" to "service_role";

grant references on table "public"."slots" to "service_role";

grant select on table "public"."slots" to "service_role";

grant trigger on table "public"."slots" to "service_role";

grant truncate on table "public"."slots" to "service_role";

grant update on table "public"."slots" to "service_role";

grant delete on table "public"."stadiums" to "anon";

grant insert on table "public"."stadiums" to "anon";

grant references on table "public"."stadiums" to "anon";

grant select on table "public"."stadiums" to "anon";

grant trigger on table "public"."stadiums" to "anon";

grant truncate on table "public"."stadiums" to "anon";

grant update on table "public"."stadiums" to "anon";

grant delete on table "public"."stadiums" to "authenticated";

grant insert on table "public"."stadiums" to "authenticated";

grant references on table "public"."stadiums" to "authenticated";

grant select on table "public"."stadiums" to "authenticated";

grant trigger on table "public"."stadiums" to "authenticated";

grant truncate on table "public"."stadiums" to "authenticated";

grant update on table "public"."stadiums" to "authenticated";

grant delete on table "public"."stadiums" to "service_role";

grant insert on table "public"."stadiums" to "service_role";

grant references on table "public"."stadiums" to "service_role";

grant select on table "public"."stadiums" to "service_role";

grant trigger on table "public"."stadiums" to "service_role";

grant truncate on table "public"."stadiums" to "service_role";

grant update on table "public"."stadiums" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "admin_select_all_bookings"
  on "public"."bookings"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));



  create policy "customers_insert_booking"
  on "public"."bookings"
  as permissive
  for insert
  to public
with check ((customer_id = auth.uid()));



  create policy "customers_select_own_bookings"
  on "public"."bookings"
  as permissive
  for select
  to public
using ((customer_id = auth.uid()));



  create policy "customers_update_own_bookings"
  on "public"."bookings"
  as permissive
  for update
  to public
using ((customer_id = auth.uid()));



  create policy "owners_select_court_bookings"
  on "public"."bookings"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM (public.courts
     JOIN public.stadiums ON ((stadiums.id = courts.stadium_id)))
  WHERE ((courts.id = bookings.court_id) AND (stadiums.owner_id = auth.uid())))));



  create policy "courts_select_active"
  on "public"."courts"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "owners_insert_court"
  on "public"."courts"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.stadiums
  WHERE ((stadiums.id = courts.stadium_id) AND (stadiums.owner_id = auth.uid())))));



  create policy "owners_select_own_courts"
  on "public"."courts"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.stadiums
  WHERE ((stadiums.id = courts.stadium_id) AND (stadiums.owner_id = auth.uid())))));



  create policy "owners_update_court"
  on "public"."courts"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.stadiums
  WHERE ((stadiums.id = courts.stadium_id) AND (stadiums.owner_id = auth.uid())))));



  create policy "admin_select_all_applications"
  on "public"."owner_applications"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));



  create policy "admin_update_applications"
  on "public"."owner_applications"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));



  create policy "users_insert_application"
  on "public"."owner_applications"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "users_select_own_application"
  on "public"."owner_applications"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "anyone_select_maintenance_slots"
  on "public"."slots"
  as permissive
  for select
  to public
using (((booking_id IS NULL) AND (status = 'maintenance'::text)));



  create policy "customers_insert_own_slots"
  on "public"."slots"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = slots.booking_id) AND (b.customer_id = auth.uid())))));



  create policy "customers_select_own_slots"
  on "public"."slots"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = slots.booking_id) AND (b.customer_id = auth.uid())))));



  create policy "customers_update_own_slots"
  on "public"."slots"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = slots.booking_id) AND (b.customer_id = auth.uid())))))
with check ((EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = slots.booking_id) AND (b.customer_id = auth.uid())))));



  create policy "owners_insert_maintenance_slots"
  on "public"."slots"
  as permissive
  for insert
  to public
with check (((booking_id IS NULL) AND (status = 'maintenance'::text) AND (EXISTS ( SELECT 1
   FROM (public.courts c
     JOIN public.stadiums s ON ((s.id = c.stadium_id)))
  WHERE ((c.id = slots.court_id) AND (s.owner_id = auth.uid()))))));



  create policy "admin_select_all_stadiums"
  on "public"."stadiums"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true)))));



  create policy "admin_update_stadiums"
  on "public"."stadiums"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.users u
  WHERE ((u.id = auth.uid()) AND (u.is_admin = true)))));



  create policy "owners_insert_stadium"
  on "public"."stadiums"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_owner = true) AND (users.is_approved = true)))));



  create policy "owners_select_own_stadiums"
  on "public"."stadiums"
  as permissive
  for select
  to public
using ((owner_id = auth.uid()));



  create policy "owners_update_stadium"
  on "public"."stadiums"
  as permissive
  for update
  to public
using (((owner_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_owner = true) AND (users.is_approved = true))))));



  create policy "stadiums_select_active"
  on "public"."stadiums"
  as permissive
  for select
  to public
using ((is_active = true));



  create policy "admin_read_all_users"
  on "public"."users"
  as permissive
  for select
  to public
using (true);



  create policy "admin_update_all_users"
  on "public"."users"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.users u
  WHERE ((u.id = auth.uid()) AND (u.is_admin = true)))));



  create policy "users_insert_own"
  on "public"."users"
  as permissive
  for insert
  to public
with check ((auth.uid() = id));



  create policy "users_select_own"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() = id));



  create policy "users_update_own"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id))
with check ((auth.uid() = id));


CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  create policy "Admins can read all proofs"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'proof_of_ownership'::text) AND (EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.id = auth.uid()) AND (users.is_admin = true))))));



  create policy "Users can read their own proof"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'proof_of_ownership'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "Users can upload their own proof"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'proof_of_ownership'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



