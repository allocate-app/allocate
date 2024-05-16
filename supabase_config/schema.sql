
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.email_confirmed_at is not null and old.email_confirmed_at IS null then
    insert into public.user (id)
    values (new.id);
  end if;
  return new;
end
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."allocateUsers" (
    "id" bigint NOT NULL,
    "uuid" "uuid" NOT NULL,
    "username" "text" NOT NULL,
    "bandwidth" smallint DEFAULT '0'::smallint NOT NULL,
    "checkDelete" boolean DEFAULT true NOT NULL,
    "checkClose" boolean DEFAULT true NOT NULL,
    "curMornID" bigint,
    "curAftID" bigint,
    "curEveID" bigint,
    "themeType" smallint DEFAULT '0'::smallint NOT NULL,
    "toneMapping" smallint DEFAULT '0'::smallint,
    "primarySeed" bigint DEFAULT '4284960932'::bigint NOT NULL,
    "secondarySeed" bigint,
    "tertiarySeed" bigint,
    "useUltraHighContrast" boolean DEFAULT false NOT NULL,
    "reduceMotion" boolean DEFAULT false NOT NULL,
    "groupSort" smallint,
    "groupDesc" boolean,
    "deadlineSort" smallint,
    "deadlineDesc" boolean,
    "reminderSort" smallint,
    "reminderDesc" boolean,
    "routineSort" smallint,
    "routineDesc" boolean,
    "toDoSort" smallint,
    "toDoDesc" boolean,
    "deleteSchedule" smallint DEFAULT '0'::smallint NOT NULL,
    "lastOpened" "text" DEFAULT ''::"text" NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL,
    "email" "text" DEFAULT ''::"text" NOT NULL
);

ALTER TABLE "public"."allocateUsers" OWNER TO "postgres";

COMMENT ON TABLE "public"."allocateUsers" IS 'User parameters';

CREATE TABLE IF NOT EXISTS "public"."deadlines" (
    "id" bigint NOT NULL,
    "uuid" "uuid" DEFAULT "auth"."uid"(),
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "repeatID" bigint DEFAULT '-1'::bigint NOT NULL,
    "notificationID" integer DEFAULT '-1'::integer NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "startDate" "text",
    "originalStart" "text",
    "dueDate" "text",
    "originalDue" "text",
    "warnDate" "text",
    "originalWarn" "text",
    "priority" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatableState" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatable" boolean DEFAULT false NOT NULL,
    "frequency" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatDays" boolean[] DEFAULT '{f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    "repeatSkip" smallint DEFAULT '1'::smallint NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL,
    "toDelete" boolean DEFAULT false NOT NULL,
    "warnMe" boolean DEFAULT false NOT NULL
);

ALTER TABLE "public"."deadlines" OWNER TO "postgres";

COMMENT ON TABLE "public"."deadlines" IS 'Deadline model';

CREATE TABLE IF NOT EXISTS "public"."groups" (
    "id" bigint NOT NULL,
    "uuid" "uuid",
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "toDelete" boolean DEFAULT false NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL
);

ALTER TABLE "public"."groups" OWNER TO "postgres";

COMMENT ON TABLE "public"."groups" IS 'Group model';

CREATE TABLE IF NOT EXISTS "public"."reminders" (
    "id" bigint NOT NULL,
    "uuid" "uuid" DEFAULT "auth"."uid"(),
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "repeatID" bigint DEFAULT '-1'::bigint NOT NULL,
    "notificationID" integer DEFAULT '-1'::integer NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "dueDate" "text",
    "originalDue" "text",
    "frequency" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatableState" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatable" boolean DEFAULT false NOT NULL,
    "repeatSkip" smallint DEFAULT '1'::smallint NOT NULL,
    "repeatDays" boolean[] DEFAULT '{f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    "toDelete" boolean DEFAULT false NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL
);

ALTER TABLE "public"."reminders" OWNER TO "postgres";

COMMENT ON TABLE "public"."reminders" IS 'Reminder model';

CREATE TABLE IF NOT EXISTS "public"."routines" (
    "id" bigint DEFAULT '0'::bigint NOT NULL,
    "uuid" "uuid",
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "expectedDuration" bigint DEFAULT '0'::bigint NOT NULL,
    "realDuration" bigint DEFAULT '0'::bigint NOT NULL,
    "toDelete" boolean DEFAULT false NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL,
    "weight" smallint DEFAULT '0'::smallint NOT NULL
);

ALTER TABLE "public"."routines" OWNER TO "postgres";

COMMENT ON TABLE "public"."routines" IS 'Routine Model';

CREATE TABLE IF NOT EXISTS "public"."subtasks" (
    "id" bigint NOT NULL,
    "uuid" "uuid",
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "weight" smallint DEFAULT '0'::smallint NOT NULL,
    "taskID" bigint,
    "toDelete" boolean DEFAULT false NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL
);

ALTER TABLE "public"."subtasks" OWNER TO "postgres";

COMMENT ON TABLE "public"."subtasks" IS 'Subtask model';

CREATE TABLE IF NOT EXISTS "public"."toDos" (
    "id" bigint DEFAULT '0'::bigint NOT NULL,
    "uuid" "uuid",
    "groupID" bigint DEFAULT '-1'::bigint,
    "repeatID" bigint DEFAULT '-1'::bigint NOT NULL,
    "groupIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "customViewIndex" bigint DEFAULT '-1'::bigint NOT NULL,
    "taskType" smallint DEFAULT '0'::smallint NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "weight" smallint DEFAULT '0'::smallint NOT NULL,
    "expectedDuration" bigint DEFAULT '0'::bigint NOT NULL,
    "realDuration" bigint DEFAULT '0'::bigint NOT NULL,
    "priority" smallint DEFAULT '0'::smallint NOT NULL,
    "startDate" "text",
    "originalStart" "text",
    "dueDate" "text",
    "originalDue" "text",
    "myDay" boolean DEFAULT false NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "repeatable" boolean DEFAULT false NOT NULL,
    "frequency" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatableState" smallint DEFAULT '0'::smallint NOT NULL,
    "repeatDays" boolean[] DEFAULT '{f,f,f,f,f,f,f}'::boolean[] NOT NULL,
    "repeatSkip" smallint DEFAULT '1'::smallint NOT NULL,
    "toDelete" boolean DEFAULT false NOT NULL,
    "lastUpdated" "text" DEFAULT ''::"text" NOT NULL
);

ALTER TABLE "public"."toDos" OWNER TO "postgres";

COMMENT ON TABLE "public"."toDos" IS 'Task model';

ALTER TABLE ONLY "public"."allocateUsers"
    ADD CONSTRAINT "allocateUser_id_key" UNIQUE ("id");

ALTER TABLE ONLY "public"."allocateUsers"
    ADD CONSTRAINT "allocateUser_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."deadlines"
    ADD CONSTRAINT "deadlines_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."subtasks"
    ADD CONSTRAINT "subtasks_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."toDos"
    ADD CONSTRAINT "toDos_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."allocateUsers"
    ADD CONSTRAINT "allocateUsers_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."deadlines"
    ADD CONSTRAINT "deadlines_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."subtasks"
    ADD CONSTRAINT "subtasks_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."toDos"
    ADD CONSTRAINT "toDos_uuid_fkey" FOREIGN KEY ("uuid") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Enable CRUD for Authenticated based on user id" ON "public"."subtasks" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for authenticated based on user id" ON "public"."routines" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for authenticated based on uuid" ON "public"."deadlines" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for authenticated based on uuid" ON "public"."groups" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for authenticated based on uuid" ON "public"."reminders" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for authenticated users based on user id" ON "public"."toDos" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

CREATE POLICY "Enable CRUD for users based on user_id" ON "public"."allocateUsers" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "uuid")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "uuid"));

ALTER TABLE "public"."allocateUsers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."deadlines" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."groups" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."reminders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."routines" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."subtasks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."toDos" ENABLE ROW LEVEL SECURITY;

ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."allocateUsers";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."deadlines";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."groups";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."reminders";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."routines";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."subtasks";

ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."toDos";

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."allocateUsers" TO "anon";
GRANT ALL ON TABLE "public"."allocateUsers" TO "authenticated";
GRANT ALL ON TABLE "public"."allocateUsers" TO "service_role";

GRANT ALL ON TABLE "public"."deadlines" TO "anon";
GRANT ALL ON TABLE "public"."deadlines" TO "authenticated";
GRANT ALL ON TABLE "public"."deadlines" TO "service_role";

GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";

GRANT ALL ON TABLE "public"."reminders" TO "anon";
GRANT ALL ON TABLE "public"."reminders" TO "authenticated";
GRANT ALL ON TABLE "public"."reminders" TO "service_role";

GRANT ALL ON TABLE "public"."routines" TO "anon";
GRANT ALL ON TABLE "public"."routines" TO "authenticated";
GRANT ALL ON TABLE "public"."routines" TO "service_role";

GRANT ALL ON TABLE "public"."subtasks" TO "anon";
GRANT ALL ON TABLE "public"."subtasks" TO "authenticated";
GRANT ALL ON TABLE "public"."subtasks" TO "service_role";

GRANT ALL ON TABLE "public"."toDos" TO "anon";
GRANT ALL ON TABLE "public"."toDos" TO "authenticated";
GRANT ALL ON TABLE "public"."toDos" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
