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


SET default_tablespace = '';

SET default_table_access_method = heap;



CREATE TABLE chats.users (
    "firstName" text,
    "imageUrl" text,
    "lastName" text,
    metadata jsonb,
    role text,
    id uuid NOT NULL,
    "createdAt" bigint NOT NULL,
    "updatedAt" bigint NOT NULL,
    "lastSeen" bigint NOT NULL
);

ALTER TABLE chats.users OWNER TO postgres;

ALTER TABLE ONLY chats.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY chats.users
    ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE chats.users ENABLE ROW LEVEL SECURITY;



GRANT ALL ON TABLE chats.users TO anon;
GRANT ALL ON TABLE chats.users TO authenticated;
GRANT ALL ON TABLE chats.users TO service_role;


ALTER PUBLICATION supabase_realtime ADD TABLE ONLY chats.users;