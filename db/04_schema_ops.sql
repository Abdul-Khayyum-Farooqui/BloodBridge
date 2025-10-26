--
-- PostgreSQL database dump
--

\restrict InXfe1oa0dKsDIT9gCmbdoYuJ3OtS5EpRkRtv5dP3IAdaalK5SEtjTBgOiGUJ5o

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
-- Name: ops; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ops;


--
-- Name: tx_validate_entities(); Type: FUNCTION; Schema: ops; Owner: -
--

CREATE FUNCTION ops.tx_validate_entities() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE ok integer;
BEGIN
  -- fulfilled_by: DONOR first (compare as text)
  IF COALESCE(NEW.fulfilled_by_entity_type::text,'') = 'Donor' THEN
    SELECT 1 INTO ok FROM core.donors WHERE donor_id = NEW.fulfilled_by_entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'fulfilled_by_entity_id % not found in donors', NEW.fulfilled_by_entity_id;
    END IF;

  ELSIF COALESCE(NEW.fulfilled_by_entity_type::text,'') IN ('Hospital','BloodBank') THEN
    SELECT 1 INTO ok FROM core.organizations WHERE org_id = NEW.fulfilled_by_entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'fulfilled_by_entity_id % not found in organizations', NEW.fulfilled_by_entity_id;
    END IF;
  END IF;

  -- requester (also compare as text)
  IF COALESCE(NEW.requester_entity_type::text,'') IN ('Hospital','BloodBank') THEN
    SELECT 1 INTO ok FROM core.organizations WHERE org_id = NEW.requester_entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'requester_entity_id % not found in organizations', NEW.requester_entity_id;
    END IF;
  ELSIF COALESCE(NEW.requester_entity_type::text,'') = 'Donor' THEN
    SELECT 1 INTO ok FROM core.donors WHERE donor_id = NEW.requester_entity_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'requester_entity_id % not found in donors', NEW.requester_entity_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: validate_fulfilled_fk(); Type: FUNCTION; Schema: ops; Owner: -
--

CREATE FUNCTION ops.validate_fulfilled_fk() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_exists boolean;
BEGIN
  -- If NULL pair -> ok (handled by check)
  IF NEW.fulfilled_by_entity_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.fulfilled_by_entity_type IN ('Hospital','BloodBank') THEN
    SELECT EXISTS (
      SELECT 1 FROM core.organizations o
      WHERE o.org_id = NEW.fulfilled_by_entity_id
    ) INTO v_exists;

    IF NOT v_exists THEN
      RAISE EXCEPTION
        'fulfilled_by_entity_id % not found in organizations for type %',
        NEW.fulfilled_by_entity_id, NEW.fulfilled_by_entity_type
        USING ERRCODE = 'foreign_key_violation';
    END IF;

  ELSIF NEW.fulfilled_by_entity_type = 'Donor' THEN
    SELECT EXISTS (
      SELECT 1 FROM core.donors d
      WHERE d.donor_id = NEW.fulfilled_by_entity_id
    ) INTO v_exists;

    IF NOT v_exists THEN
      RAISE EXCEPTION
        'fulfilled_by_entity_id % not found in donors',
        NEW.fulfilled_by_entity_id
        USING ERRCODE = 'foreign_key_violation';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: inventory; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.inventory (
    org_id text NOT NULL,
    blood_type text NOT NULL,
    component text NOT NULL,
    units integer NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT inventory_blood_type_check CHECK ((upper(blood_type) = ANY (ARRAY['O+'::text, 'O-'::text, 'A+'::text, 'A-'::text, 'B+'::text, 'B-'::text, 'AB+'::text, 'AB-'::text]))),
    CONSTRAINT inventory_component_check CHECK ((component = ANY (ARRAY['RBC'::text, 'Plasma'::text, 'Platelets'::text, 'Whole'::text]))),
    CONSTRAINT inventory_units_check CHECK ((units >= 0))
);


--
-- Name: transaction_logs; Type: TABLE; Schema: ops; Owner: -
--

CREATE TABLE ops.transaction_logs (
    transaction_id text NOT NULL,
    request_id text NOT NULL,
    requester_entity_type public.entity_role NOT NULL,
    requester_entity_id text NOT NULL,
    fulfilled_by_entity_type public.entity_role,
    fulfilled_by_entity_id text,
    blood_type text,
    component text,
    units_fulfilled integer,
    level integer,
    requested_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    status text NOT NULL,
    request_to text,
    notes text,
    inventory_updated text,
    units_requested integer,
    CONSTRAINT chk_fulfilled_pair_null CHECK ((((fulfilled_by_entity_type IS NULL) AND (fulfilled_by_entity_id IS NULL)) OR ((fulfilled_by_entity_type IS NOT NULL) AND (fulfilled_by_entity_id IS NOT NULL)))),
    CONSTRAINT chk_fulfilled_type_allowed CHECK (((fulfilled_by_entity_type = ANY (ARRAY['Hospital'::public.entity_role, 'BloodBank'::public.entity_role, 'Donor'::public.entity_role])) OR (fulfilled_by_entity_type IS NULL))),
    CONSTRAINT chk_request_to_enum CHECK (((request_to = ANY (ARRAY['BloodBank'::text, 'Donor'::text, 'Hospital'::text])) OR (request_to IS NULL))),
    CONSTRAINT chk_units_fulfilled_valid CHECK (((units_fulfilled >= 0) AND ((units_requested IS NULL) OR (units_fulfilled <= units_requested)))),
    CONSTRAINT chk_units_requested_valid CHECK (((units_requested IS NULL) OR (units_requested >= 0))),
    CONSTRAINT transaction_logs_requester_entity_type_check CHECK ((requester_entity_type = ANY (ARRAY['Hospital'::public.entity_role, 'BloodBank'::public.entity_role])))
);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (org_id, blood_type, component, updated_at);


--
-- Name: transaction_logs transaction_logs_pkey; Type: CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.transaction_logs
    ADD CONSTRAINT transaction_logs_pkey PRIMARY KEY (transaction_id);


--
-- Name: inv_org_bt_comp_idx; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX inv_org_bt_comp_idx ON ops.inventory USING btree (org_id, blood_type, component) INCLUDE (units);


--
-- Name: inventory_updated_at_idx; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX inventory_updated_at_idx ON ops.inventory USING btree (updated_at DESC);


--
-- Name: tx_ful_ent_idx; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX tx_ful_ent_idx ON ops.transaction_logs USING btree (fulfilled_by_entity_type, fulfilled_by_entity_id);


--
-- Name: tx_req_ent_idx; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX tx_req_ent_idx ON ops.transaction_logs USING btree (requester_entity_type, requester_entity_id);


--
-- Name: tx_status_idx; Type: INDEX; Schema: ops; Owner: -
--

CREATE INDEX tx_status_idx ON ops.transaction_logs USING btree (status);


--
-- Name: transaction_logs trg_tx_validate_entities; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER trg_tx_validate_entities BEFORE INSERT OR UPDATE ON ops.transaction_logs FOR EACH ROW EXECUTE FUNCTION ops.tx_validate_entities();


--
-- Name: transaction_logs trg_validate_fulfilled_fk; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER trg_validate_fulfilled_fk BEFORE INSERT OR UPDATE ON ops.transaction_logs FOR EACH ROW EXECUTE FUNCTION ops.validate_fulfilled_fk();


--
-- Name: inventory ts_insert_blocker; Type: TRIGGER; Schema: ops; Owner: -
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON ops.inventory FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: transaction_logs fk_transactionlogs_requester_org; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.transaction_logs
    ADD CONSTRAINT fk_transactionlogs_requester_org FOREIGN KEY (requester_entity_id) REFERENCES core.organizations(org_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: inventory inventory_org_id_fkey; Type: FK CONSTRAINT; Schema: ops; Owner: -
--

ALTER TABLE ONLY ops.inventory
    ADD CONSTRAINT inventory_org_id_fkey FOREIGN KEY (org_id) REFERENCES core.organizations(org_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict InXfe1oa0dKsDIT9gCmbdoYuJ3OtS5EpRkRtv5dP3IAdaalK5SEtjTBgOiGUJ5o

