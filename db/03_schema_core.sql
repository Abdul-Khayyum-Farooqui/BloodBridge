--
-- PostgreSQL database dump
--

\restrict 7HIT3NusapAlAsqYyiCEHwnYqfjeioNtUhX99bdoEROaA0UchFmCaWKMZBomtJx

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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

--
-- Name: core; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA core;


--
-- Name: auth_validate_fk(); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.auth_validate_fk() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.role IN ('Hospital','BloodBank') THEN
    IF NOT EXISTS (SELECT 1 FROM core.organizations o WHERE o.org_id = NEW.id) THEN
      RAISE EXCEPTION 'auth.id % not found in organizations for role %', NEW.id, NEW.role;
    END IF;
  ELSIF NEW.role = 'Donor' THEN
    IF NOT EXISTS (SELECT 1 FROM core.donors d WHERE d.donor_id = NEW.id) THEN
      RAISE EXCEPTION 'auth.id % not found in donors for role %', NEW.id, NEW.role;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth (
    username text NOT NULL,
    id text NOT NULL,
    role public.entity_role NOT NULL,
    password text NOT NULL
);


--
-- Name: donors; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.donors (
    donor_id text NOT NULL,
    firstname text NOT NULL,
    middlename text,
    lastname text NOT NULL,
    gender text NOT NULL,
    bloodtype text NOT NULL,
    level integer NOT NULL,
    age integer NOT NULL,
    phone text,
    email text,
    address text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    zip text NOT NULL,
    medicalhistory text,
    last_donation_date date,
    preferred_contact text NOT NULL,
    CONSTRAINT chk_age CHECK ((age > 0)),
    CONSTRAINT chk_bloodtype CHECK ((upper(bloodtype) = ANY (ARRAY['A+'::text, 'A-'::text, 'B+'::text, 'B-'::text, 'AB+'::text, 'AB-'::text, 'O+'::text, 'O-'::text]))),
    CONSTRAINT chk_contact_one_required CHECK ((((phone IS NOT NULL) AND (TRIM(BOTH FROM phone) <> ''::text)) OR ((email IS NOT NULL) AND (TRIM(BOTH FROM email) <> ''::text)))),
    CONSTRAINT chk_level CHECK ((level = ANY (ARRAY[1, 2, 3]))),
    CONSTRAINT chk_preferred_contact CHECK ((lower(preferred_contact) = ANY (ARRAY['sms'::text, 'email'::text, 'both'::text])))
);


--
-- Name: organizations; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.organizations (
    org_id text NOT NULL,
    org_type public.entity_role NOT NULL,
    name text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    zip text NOT NULL,
    phone text,
    email text,
    CONSTRAINT chk_contact_info CHECK ((((phone IS NOT NULL) AND (TRIM(BOTH FROM phone) <> ''::text)) OR ((email IS NOT NULL) AND (TRIM(BOTH FROM email) <> ''::text)))),
    CONSTRAINT organizations_org_id_check CHECK ((org_id ~ '^[A-Za-z0-9]+$'::text)),
    CONSTRAINT organizations_org_type_check CHECK ((org_type = ANY (ARRAY['Hospital'::public.entity_role, 'BloodBank'::public.entity_role])))
);


--
-- Name: auth auth_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth
    ADD CONSTRAINT auth_pkey PRIMARY KEY (username);


--
-- Name: donors donors_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donors
    ADD CONSTRAINT donors_pkey PRIMARY KEY (donor_id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (org_id);


--
-- Name: donors_bloodtype_city_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX donors_bloodtype_city_idx ON core.donors USING btree (bloodtype, city);


--
-- Name: auth trg_auth_validate_fk; Type: TRIGGER; Schema: core; Owner: -
--

CREATE TRIGGER trg_auth_validate_fk BEFORE INSERT OR UPDATE ON core.auth FOR EACH ROW EXECUTE FUNCTION core.auth_validate_fk();


--
-- PostgreSQL database dump complete
--

\unrestrict 7HIT3NusapAlAsqYyiCEHwnYqfjeioNtUhX99bdoEROaA0UchFmCaWKMZBomtJx

