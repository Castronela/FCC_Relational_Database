--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10 (Debian 15.10-0+deb12u1)
-- Dumped by pg_dump version 15.10 (Debian 15.10-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE number_guess_userbase;
--
-- Name: number_guess_userbase; Type: DATABASE; Schema: -; Owner: david
--

CREATE DATABASE number_guess_userbase WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LOCALE_PROVIDER = libc LOCALE = 'C';


ALTER DATABASE number_guess_userbase OWNER TO david;

\connect number_guess_userbase

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: players; Type: TABLE; Schema: public; Owner: david
--

CREATE TABLE public.players (
    username character varying(22) NOT NULL,
    games_played integer DEFAULT 0,
    best_game integer
);


ALTER TABLE public.players OWNER TO david;

--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: david
--



--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: david
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (username);


--
-- PostgreSQL database dump complete
--

