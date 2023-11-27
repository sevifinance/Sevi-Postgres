-- this test must be run on a database named 'contrib_regression'
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

-- INIT

SELECT anon.init();

CREATE ROLE oscar_the_owner LOGIN PASSWORD 'xlfneifzmqdef';
ALTER DATABASE :DBNAME OWNER TO oscar_the_owner;

SET ROLE oscar_the_owner;

CREATE SCHEMA test;

CREATE TABLE test.no_masks AS SELECT 1 ;

CREATE TABLE test.cards (
  id integer NOT NULL,
  board_id integer NOT NULL,
  data TEXT
);

INSERT INTO test.cards VALUES
(1, 1, 'Paint house'),
(2, 1, 'Clean'),
(3, 1, 'Cook'),
(4, 1, 'Vacuum'),
(999999,0, E'(,Very"Weird\'\'value\t trying\n to\,break '' CSV\)export)');

CREATE TABLE test.customer (
  id SERIAL,
  name TEXT,
  "CreditCard" TEXT
);

INSERT INTO test.customer(name,"CreditCard")
VALUES
('Schwarzenegger','1234567812345678'),
('Stalone'       ,'2683464645336781'),
('Lundgren'      ,'6877322588932345');


SECURITY LABEL FOR anon ON COLUMN test.customer.name
IS E'MASKED WITH FUNCTION md5(''0'') ';

SECURITY LABEL FOR anon ON COLUMN test.customer."CreditCard"
IS E'MASKED WITH FUNCTION md5(''0'') ';

CREATE TABLE test."COMPANY" (
  rn SERIAL,
  "IBAN" TEXT,
  BRAND TEXT
);

INSERT INTO test."COMPANY"
VALUES (1991,'12345677890','Cyberdyne Systems');

SECURITY LABEL FOR anon ON COLUMN test."COMPANY"."IBAN"
IS E'MASKED WITH FUNCTION md5(''0'') ';

SECURITY LABEL FOR anon ON COLUMN test."COMPANY".brand
IS E'MASKED WITH VALUE $$CONFIDENTIAL$$ ';


CREATE SEQUENCE public.seq42;
ALTER SEQUENCE public.seq42 RESTART WITH 42;

RESET ROLE;

CREATE ROLE dump_anon LOGIN PASSWORD 'x';
ALTER ROLE dump_anon SET anon.transparent_dynamic_masking = True;
SECURITY LABEL FOR anon ON ROLE dump_anon IS 'MASKED';

GRANT USAGE ON SCHEMA public TO dump_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dump_anon;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO dump_anon;

GRANT USAGE ON SCHEMA test TO dump_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA test TO dump_anon;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA test TO dump_anon;



--
-- A. Dump
--

\! PGPASSWORD=x pg_dump --user dump_anon --dbname=contrib_regression --no-security-labels > tests/tmp/_pg_dump_A.sql

--
-- B. Restore
--

DROP SCHEMA test CASCADE;
DROP SEQUENCE public.seq42;

RESET ROLE;
DROP EXTENSION anon;
SET ROLE oscar_the_owner;

\! psql -f tests/tmp/_pg_dump_A.sql contrib_regression >/dev/null

--
-- C. Masked Data is Masked
--
SELECT "IBAN" = md5('0') FROM test."COMPANY";
SELECT brand = 'CONFIDENTIAL' FROM test."COMPANY";

--
-- D. Check the sequence values
--
SELECT pg_catalog.nextval('test.customer_id_seq') = 4;
SELECT pg_catalog.nextval('public.seq42') = 42;


--
-- E. Remove Anon extension
--
-- WORKS ONLY WITH pg_dump > 14
--\! pg_dump --extension pg_catalog.plpgsql contrib_regression | grep 'CREATE EXTENSION' | grep anon


--  CLEAN
RESET ROLE;
DROP SCHEMA test CASCADE;
DROP SEQUENCE public.seq42;

REASSIGN OWNED BY oscar_the_owner TO postgres;
DROP ROLE oscar_the_owner;

REVOKE ALL ON SCHEMA public FROM dump_anon;
REASSIGN OWNED BY dump_anon TO postgres;
DROP ROLE dump_anon;

DROP EXTENSION anon CASCADE;
DROP EXTENSION pgcrypto;
