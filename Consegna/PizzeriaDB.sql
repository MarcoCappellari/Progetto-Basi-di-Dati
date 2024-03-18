--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3
-- Dumped by pg_dump version 15.3

-- Started on 2023-08-20 14:18:05

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
-- TOC entry 3425 (class 1262 OID 16602)
-- Name: PizzeriaDB; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "PizzeriaDB" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Italian_Italy.1252';


ALTER DATABASE "PizzeriaDB" OWNER TO postgres;

\connect "PizzeriaDB"

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
-- TOC entry 3426 (class 0 OID 0)
-- Dependencies: 3425
-- Name: DATABASE "PizzeriaDB"; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE "PizzeriaDB" IS 'Database di Giurisato Andrea e Cappellari Marco ';


--
-- TOC entry 226 (class 1255 OID 16729)
-- Name: check_ingredienti_pizza(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_ingredienti_pizza() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    Ingredienti_mancanti INT;
BEGIN
    SELECT COUNT(*) INTO    Ingredienti_mancanti
    FROM Contiene AS c
    LEFT JOIN Ingrediente AS i ON c.NomeIngrediente = i.NomeIngrediente
    WHERE c.NomePizza = NEW.NomePizza AND (i.NomeIngrediente IS NULL OR i.Disponibile = FALSE);

    IF    Ingredienti_mancanti > 0 THEN
        RAISE EXCEPTION 'Non possiamo aggiungere questa pizza all’ordinazione perchè mancano ingredienti.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_ingredienti_pizza() OWNER TO postgres;

--
-- TOC entry 225 (class 1255 OID 16727)
-- Name: check_prenotazioni(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_prenotazioni() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Prenota AS p
        WHERE p.DataP = NEW.DataP
          AND p.NumeroTavolo = NEW.NumeroTavolo
          AND ABS(EXTRACT(EPOCH FROM (p.Ora - NEW.Ora))) < 3600
    ) THEN
        RAISE EXCEPTION 'Il tavolo è già prenotato per quest’ora';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_prenotazioni() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 16710)
-- Name: appartiene; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appartiene (
    nomepizza character varying(20) NOT NULL,
    idordinazione integer NOT NULL,
    quantita integer NOT NULL,
    CONSTRAINT appartiene_quantita_check CHECK ((quantita > 0))
);


ALTER TABLE public.appartiene OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16622)
-- Name: cameriere; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cameriere (
    idcameriere integer NOT NULL,
    dataassunzione date NOT NULL,
    nome character varying(20) NOT NULL,
    cognome character varying(20) NOT NULL,
    datanascita date NOT NULL,
    sesso character(1) NOT NULL,
    telefono character varying(20) NOT NULL,
    pagaoraria numeric(4,2) NOT NULL,
    CONSTRAINT cameriere_check CHECK (((datanascita < dataassunzione) AND (age((dataassunzione)::timestamp with time zone, (datanascita)::timestamp with time zone) >= '18 years'::interval))),
    CONSTRAINT cameriere_pagaoraria_check CHECK ((pagaoraria > (0)::numeric)),
    CONSTRAINT cameriere_sesso_check CHECK ((sesso = ANY (ARRAY['M'::bpchar, 'F'::bpchar])))
);


ALTER TABLE public.cameriere OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16603)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    mail character varying(50) NOT NULL,
    nome character varying(50) NOT NULL,
    cognome character varying(50) NOT NULL,
    datanascita date NOT NULL,
    numerotelefono character varying(20) NOT NULL
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16680)
-- Name: contiene; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contiene (
    nomepizza character varying(20) NOT NULL,
    nomeingrediente character varying(20) NOT NULL
);


ALTER TABLE public.contiene OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16632)
-- Name: cuoco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuoco (
    idcuoco integer NOT NULL,
    dataassunzione date NOT NULL,
    nome character varying(20) NOT NULL,
    cognome character varying(20) NOT NULL,
    datanascita date NOT NULL,
    sesso character(1) NOT NULL,
    telefono character varying(20) NOT NULL,
    pagaperpizza numeric(3,2) NOT NULL,
    pizzeperora integer NOT NULL,
    CONSTRAINT cuoco_check CHECK (((datanascita < dataassunzione) AND (age((dataassunzione)::timestamp with time zone, (datanascita)::timestamp with time zone) >= '18 years'::interval))),
    CONSTRAINT cuoco_pagaperpizza_check CHECK ((pagaperpizza > (0)::numeric)),
    CONSTRAINT cuoco_pizzeperora_check CHECK ((pizzeperora > 0)),
    CONSTRAINT cuoco_sesso_check CHECK ((sesso = ANY (ARRAY['M'::bpchar, 'F'::bpchar])))
);


ALTER TABLE public.cuoco OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16669)
-- Name: ingrediente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ingrediente (
    nomeingrediente character varying(20) NOT NULL,
    surgelato boolean NOT NULL,
    valorenutrizionale integer NOT NULL,
    disponibile boolean NOT NULL,
    CONSTRAINT ingrediente_valorenutrizionale_check CHECK ((valorenutrizionale >= 0))
);


ALTER TABLE public.ingrediente OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16695)
-- Name: ordinazione; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ordinazione (
    idordinazione integer NOT NULL,
    oraordinazione time without time zone NOT NULL,
    dataordinazione date NOT NULL,
    mail_cliente character varying(50) NOT NULL,
    cuoco integer NOT NULL
);


ALTER TABLE public.ordinazione OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16675)
-- Name: pizza; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pizza (
    nomepizza character varying(20) NOT NULL,
    vegetariana boolean NOT NULL,
    prezzo numeric(5,2) NOT NULL
);


ALTER TABLE public.pizza OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16654)
-- Name: prenota; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prenota (
    ora time without time zone NOT NULL,
    datap date NOT NULL,
    mail_cliente character varying(50) NOT NULL,
    numerotavolo integer NOT NULL
);


ALTER TABLE public.prenota OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16643)
-- Name: tavolo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tavolo (
    numerotavolo integer NOT NULL,
    posti integer NOT NULL,
    sala character varying(15) NOT NULL,
    cameriere integer,
    CONSTRAINT tavolo_posti_check CHECK ((posti > 0))
);


ALTER TABLE public.tavolo OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16610)
-- Name: tessera; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tessera (
    cliente character varying(50) NOT NULL,
    dataiscrizione date NOT NULL,
    punti integer DEFAULT 0,
    CONSTRAINT tessera_punti_check CHECK ((punti >= 0))
);


ALTER TABLE public.tessera OWNER TO postgres;

--
-- TOC entry 3419 (class 0 OID 16710)
-- Dependencies: 224
-- Data for Name: appartiene; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.appartiene VALUES ('Valtellina', 1, 1);
INSERT INTO public.appartiene VALUES ('Diavola', 1, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 2, 2);
INSERT INTO public.appartiene VALUES ('Carbonara', 2, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 2, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 3, 3);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 3, 4);
INSERT INTO public.appartiene VALUES ('Margherita', 4, 2);
INSERT INTO public.appartiene VALUES ('Marinara', 5, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 5, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 5, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 5, 4);
INSERT INTO public.appartiene VALUES ('Delicata', 6, 1);
INSERT INTO public.appartiene VALUES ('Mais', 6, 4);
INSERT INTO public.appartiene VALUES ('Diavola', 7, 2);
INSERT INTO public.appartiene VALUES ('Funghi', 8, 2);
INSERT INTO public.appartiene VALUES ('Parmigiana', 9, 1);
INSERT INTO public.appartiene VALUES ('Demonio', 9, 3);
INSERT INTO public.appartiene VALUES ('Zucchine', 9, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 10, 2);
INSERT INTO public.appartiene VALUES ('Mais', 10, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 11, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 12, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 13, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 14, 2);
INSERT INTO public.appartiene VALUES ('Demonio', 15, 2);
INSERT INTO public.appartiene VALUES ('Asparagi', 16, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 17, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 17, 4);
INSERT INTO public.appartiene VALUES ('Pugliese', 18, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 19, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 20, 2);
INSERT INTO public.appartiene VALUES ('Misto mare', 21, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 22, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 23, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 24, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 25, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 26, 1);
INSERT INTO public.appartiene VALUES ('Pomodorini', 27, 4);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 28, 3);
INSERT INTO public.appartiene VALUES ('Speck', 29, 4);
INSERT INTO public.appartiene VALUES ('Pugliese', 30, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 30, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 31, 3);
INSERT INTO public.appartiene VALUES ('Asparagi', 31, 2);
INSERT INTO public.appartiene VALUES ('Brie e speck', 32, 4);
INSERT INTO public.appartiene VALUES ('Cracker', 33, 4);
INSERT INTO public.appartiene VALUES ('Radicchio', 34, 1);
INSERT INTO public.appartiene VALUES ('Margherita', 35, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 36, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 37, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 37, 4);
INSERT INTO public.appartiene VALUES ('Asparagi', 38, 3);
INSERT INTO public.appartiene VALUES ('Zucchine', 39, 3);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 40, 4);
INSERT INTO public.appartiene VALUES ('Pugliese', 40, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 40, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 41, 3);
INSERT INTO public.appartiene VALUES ('Speck', 42, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 43, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 44, 3);
INSERT INTO public.appartiene VALUES ('Patatosa', 45, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 45, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 46, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 47, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 48, 1);
INSERT INTO public.appartiene VALUES ('Pancetta', 49, 3);
INSERT INTO public.appartiene VALUES ('Salsiccia', 50, 2);
INSERT INTO public.appartiene VALUES ('Melanzane', 51, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 52, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 52, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 53, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 54, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 55, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 56, 1);
INSERT INTO public.appartiene VALUES ('Porcini', 57, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 58, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 59, 1);
INSERT INTO public.appartiene VALUES ('Delicata', 60, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 61, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 61, 3);
INSERT INTO public.appartiene VALUES ('Parmigiana', 61, 1);
INSERT INTO public.appartiene VALUES ('Porchetta', 62, 1);
INSERT INTO public.appartiene VALUES ('Speck', 62, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 63, 3);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 63, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 64, 1);
INSERT INTO public.appartiene VALUES ('Diavola', 65, 4);
INSERT INTO public.appartiene VALUES ('Brie e speck', 66, 3);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 66, 3);
INSERT INTO public.appartiene VALUES ('Parmigiana', 67, 2);
INSERT INTO public.appartiene VALUES ('Cortigiana', 67, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 67, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 68, 1);
INSERT INTO public.appartiene VALUES ('Zucchine', 68, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 68, 3);
INSERT INTO public.appartiene VALUES ('Crudo', 69, 2);
INSERT INTO public.appartiene VALUES ('Leggera', 69, 1);
INSERT INTO public.appartiene VALUES ('Crudo', 70, 2);
INSERT INTO public.appartiene VALUES ('Porchetta', 70, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 71, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 71, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 71, 3);
INSERT INTO public.appartiene VALUES ('Cracker', 71, 3);
INSERT INTO public.appartiene VALUES ('Marinara', 72, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 73, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 74, 4);
INSERT INTO public.appartiene VALUES ('Crudo', 75, 4);
INSERT INTO public.appartiene VALUES ('Capricciosa', 76, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 76, 2);
INSERT INTO public.appartiene VALUES ('Carbonara', 77, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto', 78, 1);
INSERT INTO public.appartiene VALUES ('Carbonara', 79, 4);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 80, 4);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 81, 1);
INSERT INTO public.appartiene VALUES ('Cracker', 82, 1);
INSERT INTO public.appartiene VALUES ('Cracker', 83, 1);
INSERT INTO public.appartiene VALUES ('Marinara', 84, 4);
INSERT INTO public.appartiene VALUES ('Carbonara', 85, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 85, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto', 86, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 86, 4);
INSERT INTO public.appartiene VALUES ('Mais', 87, 2);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 87, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 88, 2);
INSERT INTO public.appartiene VALUES ('Porcini', 89, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 90, 4);
INSERT INTO public.appartiene VALUES ('Chiodini', 90, 4);
INSERT INTO public.appartiene VALUES ('Pomodorini', 91, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 92, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 92, 1);
INSERT INTO public.appartiene VALUES ('Funghi', 92, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 93, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 94, 3);
INSERT INTO public.appartiene VALUES ('Delicata', 95, 1);
INSERT INTO public.appartiene VALUES ('Mais', 96, 1);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 96, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 97, 4);
INSERT INTO public.appartiene VALUES ('Leggera', 97, 1);
INSERT INTO public.appartiene VALUES ('Porcini', 98, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto', 98, 2);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 99, 4);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 100, 1);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 101, 4);
INSERT INTO public.appartiene VALUES ('Zucchine', 102, 2);
INSERT INTO public.appartiene VALUES ('Pomodorini', 103, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 104, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 105, 1);
INSERT INTO public.appartiene VALUES ('Crudo', 106, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 107, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 108, 4);
INSERT INTO public.appartiene VALUES ('Porcini', 109, 4);
INSERT INTO public.appartiene VALUES ('Speck', 110, 3);
INSERT INTO public.appartiene VALUES ('Misto mare', 110, 1);
INSERT INTO public.appartiene VALUES ('Pomodorini', 111, 2);
INSERT INTO public.appartiene VALUES ('Marinara', 111, 4);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 112, 4);
INSERT INTO public.appartiene VALUES ('Cracker', 113, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 114, 4);
INSERT INTO public.appartiene VALUES ('Patatosa', 114, 3);
INSERT INTO public.appartiene VALUES ('Zucchine', 114, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 115, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 116, 2);
INSERT INTO public.appartiene VALUES ('Chiodini', 117, 4);
INSERT INTO public.appartiene VALUES ('Brie e speck', 118, 2);
INSERT INTO public.appartiene VALUES ('Leggera', 119, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 119, 3);
INSERT INTO public.appartiene VALUES ('Contadina', 119, 2);
INSERT INTO public.appartiene VALUES ('Demonio', 120, 4);
INSERT INTO public.appartiene VALUES ('Pomodorini', 121, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 121, 4);
INSERT INTO public.appartiene VALUES ('Pancetta', 121, 4);
INSERT INTO public.appartiene VALUES ('Porcini', 121, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 122, 4);
INSERT INTO public.appartiene VALUES ('Bresaola', 123, 1);
INSERT INTO public.appartiene VALUES ('Bresaola', 124, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 125, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 126, 2);
INSERT INTO public.appartiene VALUES ('Salsiccia', 127, 3);
INSERT INTO public.appartiene VALUES ('Margherita', 128, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 129, 4);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 129, 2);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 130, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 131, 1);
INSERT INTO public.appartiene VALUES ('Porcini', 132, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 133, 1);
INSERT INTO public.appartiene VALUES ('Mais', 134, 4);
INSERT INTO public.appartiene VALUES ('Patatosa', 134, 2);
INSERT INTO public.appartiene VALUES ('Cortigiana', 134, 4);
INSERT INTO public.appartiene VALUES ('Capricciosa', 135, 4);
INSERT INTO public.appartiene VALUES ('Margherita', 135, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 135, 2);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 136, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 136, 3);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 137, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 137, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto', 138, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 139, 3);
INSERT INTO public.appartiene VALUES ('Misto mare', 140, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 140, 1);
INSERT INTO public.appartiene VALUES ('Mais', 141, 3);
INSERT INTO public.appartiene VALUES ('Salsiccia', 142, 3);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 142, 4);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 143, 4);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 144, 1);
INSERT INTO public.appartiene VALUES ('Margherita', 145, 4);
INSERT INTO public.appartiene VALUES ('Margherita', 146, 1);
INSERT INTO public.appartiene VALUES ('Cortigiana', 147, 2);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 148, 2);
INSERT INTO public.appartiene VALUES ('Delicata', 149, 3);
INSERT INTO public.appartiene VALUES ('Melanzane', 149, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 149, 3);
INSERT INTO public.appartiene VALUES ('Patatosa', 150, 4);
INSERT INTO public.appartiene VALUES ('Chiodini', 151, 4);
INSERT INTO public.appartiene VALUES ('Porcini', 151, 4);
INSERT INTO public.appartiene VALUES ('Hawaiian', 152, 1);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 153, 4);
INSERT INTO public.appartiene VALUES ('Capricciosa', 153, 2);
INSERT INTO public.appartiene VALUES ('Pugliese', 153, 2);
INSERT INTO public.appartiene VALUES ('Leggera', 154, 3);
INSERT INTO public.appartiene VALUES ('Porchetta', 155, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 156, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 157, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 158, 1);
INSERT INTO public.appartiene VALUES ('Demonio', 159, 1);
INSERT INTO public.appartiene VALUES ('Radicchio', 160, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 161, 4);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 162, 1);
INSERT INTO public.appartiene VALUES ('Leggera', 163, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 164, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 165, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 166, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 167, 3);
INSERT INTO public.appartiene VALUES ('Parmigiana', 168, 1);
INSERT INTO public.appartiene VALUES ('Brie e speck', 169, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 170, 3);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 171, 1);
INSERT INTO public.appartiene VALUES ('Hawaiian', 172, 4);
INSERT INTO public.appartiene VALUES ('Bresaola', 173, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 173, 1);
INSERT INTO public.appartiene VALUES ('Zucchine', 174, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 174, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto', 175, 2);
INSERT INTO public.appartiene VALUES ('Crudo', 175, 4);
INSERT INTO public.appartiene VALUES ('Radicchio', 176, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 177, 4);
INSERT INTO public.appartiene VALUES ('Patatosa', 177, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 178, 4);
INSERT INTO public.appartiene VALUES ('Speck', 179, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 180, 2);
INSERT INTO public.appartiene VALUES ('Margherita', 180, 3);
INSERT INTO public.appartiene VALUES ('Hawaiian', 181, 4);
INSERT INTO public.appartiene VALUES ('Misto mare', 182, 4);
INSERT INTO public.appartiene VALUES ('Hawaiian', 183, 1);
INSERT INTO public.appartiene VALUES ('Diavola', 184, 3);
INSERT INTO public.appartiene VALUES ('Speck', 184, 2);
INSERT INTO public.appartiene VALUES ('Sicilia', 184, 3);
INSERT INTO public.appartiene VALUES ('Bresaola', 185, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 186, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 187, 1);
INSERT INTO public.appartiene VALUES ('Porcini', 188, 4);
INSERT INTO public.appartiene VALUES ('Porchetta', 189, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 190, 1);
INSERT INTO public.appartiene VALUES ('Leggera', 190, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 190, 1);
INSERT INTO public.appartiene VALUES ('Viennese', 191, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 192, 2);
INSERT INTO public.appartiene VALUES ('Patatosa', 193, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 194, 3);
INSERT INTO public.appartiene VALUES ('Parmigiana', 195, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 196, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 197, 4);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 198, 4);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 199, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 200, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 201, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 202, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 203, 1);
INSERT INTO public.appartiene VALUES ('Demonio', 204, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 205, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 206, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 207, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 208, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 208, 3);
INSERT INTO public.appartiene VALUES ('Salsiccia', 209, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto', 209, 4);
INSERT INTO public.appartiene VALUES ('Zucchine', 210, 4);
INSERT INTO public.appartiene VALUES ('Margherita', 211, 4);
INSERT INTO public.appartiene VALUES ('Funghi', 211, 4);
INSERT INTO public.appartiene VALUES ('Carbonara', 212, 2);
INSERT INTO public.appartiene VALUES ('Demonio', 212, 2);
INSERT INTO public.appartiene VALUES ('Speck', 213, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 214, 1);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 214, 2);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 215, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 216, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 216, 4);
INSERT INTO public.appartiene VALUES ('Radicchio', 216, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 217, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 217, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 218, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 219, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 220, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 221, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 222, 4);
INSERT INTO public.appartiene VALUES ('Cracker', 223, 4);
INSERT INTO public.appartiene VALUES ('Leggera', 224, 3);
INSERT INTO public.appartiene VALUES ('Leggera', 225, 3);
INSERT INTO public.appartiene VALUES ('Asparagi', 226, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 227, 1);
INSERT INTO public.appartiene VALUES ('Viennese', 228, 2);
INSERT INTO public.appartiene VALUES ('Chiodini', 229, 3);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 230, 1);
INSERT INTO public.appartiene VALUES ('Funghi', 231, 2);
INSERT INTO public.appartiene VALUES ('Misto mare', 232, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 233, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 233, 3);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 234, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 235, 1);
INSERT INTO public.appartiene VALUES ('Valtellina', 236, 3);
INSERT INTO public.appartiene VALUES ('Melanzane', 237, 4);
INSERT INTO public.appartiene VALUES ('Zucchine', 238, 4);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 239, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 239, 2);
INSERT INTO public.appartiene VALUES ('Margherita', 240, 1);
INSERT INTO public.appartiene VALUES ('Margherita', 241, 1);
INSERT INTO public.appartiene VALUES ('Margherita', 242, 1);
INSERT INTO public.appartiene VALUES ('Cracker', 243, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 244, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 244, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 245, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 246, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 247, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 248, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 249, 3);
INSERT INTO public.appartiene VALUES ('Cracker', 250, 2);
INSERT INTO public.appartiene VALUES ('Margherita', 251, 3);
INSERT INTO public.appartiene VALUES ('Asparagi', 251, 1);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 251, 2);
INSERT INTO public.appartiene VALUES ('Carbonara', 251, 2);
INSERT INTO public.appartiene VALUES ('Leggera', 252, 1);
INSERT INTO public.appartiene VALUES ('Pugliese', 253, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 254, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 255, 3);
INSERT INTO public.appartiene VALUES ('Pomodorini', 256, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 257, 1);
INSERT INTO public.appartiene VALUES ('Crudo', 258, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 259, 1);
INSERT INTO public.appartiene VALUES ('Porchetta', 260, 1);
INSERT INTO public.appartiene VALUES ('Pomodorini', 261, 4);
INSERT INTO public.appartiene VALUES ('Pomodorini', 262, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 263, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 264, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 265, 2);
INSERT INTO public.appartiene VALUES ('Brie e speck', 266, 3);
INSERT INTO public.appartiene VALUES ('Valtellina', 266, 1);
INSERT INTO public.appartiene VALUES ('Diavola', 267, 2);
INSERT INTO public.appartiene VALUES ('Mais', 268, 3);
INSERT INTO public.appartiene VALUES ('Diavola', 269, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 269, 1);
INSERT INTO public.appartiene VALUES ('Mais', 270, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 271, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 272, 1);
INSERT INTO public.appartiene VALUES ('Demonio', 272, 2);
INSERT INTO public.appartiene VALUES ('Sicilia', 272, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 273, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 274, 1);
INSERT INTO public.appartiene VALUES ('Speck', 275, 3);
INSERT INTO public.appartiene VALUES ('Marinara', 276, 2);
INSERT INTO public.appartiene VALUES ('Asparagi', 277, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 278, 1);
INSERT INTO public.appartiene VALUES ('Contadina', 279, 4);
INSERT INTO public.appartiene VALUES ('Pancetta', 280, 3);
INSERT INTO public.appartiene VALUES ('Margherita', 281, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 282, 4);
INSERT INTO public.appartiene VALUES ('Porchetta', 282, 2);
INSERT INTO public.appartiene VALUES ('Cracker', 282, 2);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 283, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 284, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 284, 1);
INSERT INTO public.appartiene VALUES ('Viennese', 285, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 286, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 287, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 288, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 289, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 289, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 290, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 291, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 292, 1);
INSERT INTO public.appartiene VALUES ('Speck', 293, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 293, 3);
INSERT INTO public.appartiene VALUES ('Chiodini', 294, 2);
INSERT INTO public.appartiene VALUES ('Capricciosa', 294, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto', 295, 4);
INSERT INTO public.appartiene VALUES ('Mais', 296, 1);
INSERT INTO public.appartiene VALUES ('Margherita', 296, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 297, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 298, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 299, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 300, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 301, 1);
INSERT INTO public.appartiene VALUES ('Bresaola', 302, 1);
INSERT INTO public.appartiene VALUES ('Bresaola', 303, 1);
INSERT INTO public.appartiene VALUES ('Contadina', 304, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 305, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 306, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 307, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 308, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 309, 4);
INSERT INTO public.appartiene VALUES ('Crudo', 310, 4);
INSERT INTO public.appartiene VALUES ('Crudo', 311, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 312, 3);
INSERT INTO public.appartiene VALUES ('Marinara', 313, 3);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 314, 3);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 315, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 316, 2);
INSERT INTO public.appartiene VALUES ('Pugliese', 316, 2);
INSERT INTO public.appartiene VALUES ('Contadina', 317, 2);
INSERT INTO public.appartiene VALUES ('Porcini', 318, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 318, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 319, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto', 320, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 320, 2);
INSERT INTO public.appartiene VALUES ('Contadina', 321, 4);
INSERT INTO public.appartiene VALUES ('Asparagi', 322, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 323, 1);
INSERT INTO public.appartiene VALUES ('Speck', 324, 2);
INSERT INTO public.appartiene VALUES ('Speck', 325, 2);
INSERT INTO public.appartiene VALUES ('Asparagi', 326, 2);
INSERT INTO public.appartiene VALUES ('Asparagi', 327, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 328, 1);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 329, 1);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 330, 4);
INSERT INTO public.appartiene VALUES ('Viennese', 331, 3);
INSERT INTO public.appartiene VALUES ('Capricciosa', 332, 4);
INSERT INTO public.appartiene VALUES ('Viennese', 333, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 334, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 335, 3);
INSERT INTO public.appartiene VALUES ('Valtellina', 336, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 337, 3);
INSERT INTO public.appartiene VALUES ('Carbonara', 337, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 337, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto', 338, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 338, 2);
INSERT INTO public.appartiene VALUES ('Melanzane', 339, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 340, 4);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 341, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 342, 3);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 343, 4);
INSERT INTO public.appartiene VALUES ('Pomodorini', 344, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 345, 1);
INSERT INTO public.appartiene VALUES ('Leggera', 346, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 347, 4);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 348, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 348, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 348, 2);
INSERT INTO public.appartiene VALUES ('Misto mare', 349, 1);
INSERT INTO public.appartiene VALUES ('Misto mare', 350, 1);
INSERT INTO public.appartiene VALUES ('Misto mare', 351, 1);
INSERT INTO public.appartiene VALUES ('Misto mare', 352, 1);
INSERT INTO public.appartiene VALUES ('Porcini', 353, 4);
INSERT INTO public.appartiene VALUES ('Porcini', 354, 4);
INSERT INTO public.appartiene VALUES ('Bresaola', 355, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 356, 4);
INSERT INTO public.appartiene VALUES ('Porcini', 356, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 357, 3);
INSERT INTO public.appartiene VALUES ('Valtellina', 357, 3);
INSERT INTO public.appartiene VALUES ('Chiodini', 357, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 358, 1);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 359, 4);
INSERT INTO public.appartiene VALUES ('Diavola', 359, 2);
INSERT INTO public.appartiene VALUES ('Cracker', 360, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 361, 3);
INSERT INTO public.appartiene VALUES ('Hawaiian', 362, 2);
INSERT INTO public.appartiene VALUES ('Brie e speck', 363, 2);
INSERT INTO public.appartiene VALUES ('Melanzane', 364, 4);
INSERT INTO public.appartiene VALUES ('Asparagi', 364, 1);
INSERT INTO public.appartiene VALUES ('Valtellina', 365, 1);
INSERT INTO public.appartiene VALUES ('Misto mare', 365, 1);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 366, 2);
INSERT INTO public.appartiene VALUES ('Chiodini', 367, 1);
INSERT INTO public.appartiene VALUES ('Melanzane', 368, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 369, 3);
INSERT INTO public.appartiene VALUES ('Diavola', 370, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 371, 4);
INSERT INTO public.appartiene VALUES ('Brie e speck', 372, 2);
INSERT INTO public.appartiene VALUES ('Valtellina', 372, 2);
INSERT INTO public.appartiene VALUES ('Porchetta', 373, 2);
INSERT INTO public.appartiene VALUES ('Porchetta', 374, 4);
INSERT INTO public.appartiene VALUES ('Misto mare', 374, 2);
INSERT INTO public.appartiene VALUES ('Chiodini', 375, 1);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 376, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 377, 4);
INSERT INTO public.appartiene VALUES ('Speck', 378, 1);
INSERT INTO public.appartiene VALUES ('Speck', 379, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 380, 4);
INSERT INTO public.appartiene VALUES ('Mais', 381, 4);
INSERT INTO public.appartiene VALUES ('Viennese', 382, 4);
INSERT INTO public.appartiene VALUES ('Mais', 383, 1);
INSERT INTO public.appartiene VALUES ('Delicata', 384, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 385, 2);
INSERT INTO public.appartiene VALUES ('Cracker', 386, 1);
INSERT INTO public.appartiene VALUES ('Misto mare', 386, 4);
INSERT INTO public.appartiene VALUES ('Viennese', 386, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 387, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 388, 2);
INSERT INTO public.appartiene VALUES ('Chiodini', 389, 1);
INSERT INTO public.appartiene VALUES ('Parmigiana', 390, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 391, 1);
INSERT INTO public.appartiene VALUES ('Carbonara', 391, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 391, 1);
INSERT INTO public.appartiene VALUES ('Leggera', 392, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 392, 2);
INSERT INTO public.appartiene VALUES ('Speck', 392, 3);
INSERT INTO public.appartiene VALUES ('Chiodini', 393, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 393, 2);
INSERT INTO public.appartiene VALUES ('Misto mare', 394, 1);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 394, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 394, 2);
INSERT INTO public.appartiene VALUES ('Patatosa', 395, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 396, 4);
INSERT INTO public.appartiene VALUES ('Misto mare', 396, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 397, 3);
INSERT INTO public.appartiene VALUES ('Cortigiana', 398, 3);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 399, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 400, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 401, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 402, 2);
INSERT INTO public.appartiene VALUES ('Brie e speck', 403, 4);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 404, 1);
INSERT INTO public.appartiene VALUES ('Bresaola', 404, 4);
INSERT INTO public.appartiene VALUES ('Valtellina', 404, 1);
INSERT INTO public.appartiene VALUES ('Zucchine', 405, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 405, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 406, 3);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 407, 4);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 408, 2);
INSERT INTO public.appartiene VALUES ('Melanzane', 409, 1);
INSERT INTO public.appartiene VALUES ('Melanzane', 410, 1);
INSERT INTO public.appartiene VALUES ('Radicchio', 411, 1);
INSERT INTO public.appartiene VALUES ('Radicchio', 412, 1);
INSERT INTO public.appartiene VALUES ('Radicchio', 413, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 414, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 415, 4);
INSERT INTO public.appartiene VALUES ('Carbonara', 416, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 417, 4);
INSERT INTO public.appartiene VALUES ('Radicchio', 418, 3);
INSERT INTO public.appartiene VALUES ('Viennese', 419, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 420, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 421, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 422, 3);
INSERT INTO public.appartiene VALUES ('Patatosa', 423, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 424, 4);
INSERT INTO public.appartiene VALUES ('Speck', 424, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 424, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 425, 1);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 426, 4);
INSERT INTO public.appartiene VALUES ('Speck', 427, 4);
INSERT INTO public.appartiene VALUES ('Funghi', 428, 4);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 429, 1);
INSERT INTO public.appartiene VALUES ('Brie e speck', 430, 4);
INSERT INTO public.appartiene VALUES ('Zucchine', 430, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 431, 2);
INSERT INTO public.appartiene VALUES ('Misto mare', 431, 2);
INSERT INTO public.appartiene VALUES ('Marinara', 432, 4);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 433, 4);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 434, 1);
INSERT INTO public.appartiene VALUES ('Zucchine', 435, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 436, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 437, 1);
INSERT INTO public.appartiene VALUES ('Crudo', 438, 3);
INSERT INTO public.appartiene VALUES ('Crudo', 439, 3);
INSERT INTO public.appartiene VALUES ('Crudo', 440, 3);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 441, 3);
INSERT INTO public.appartiene VALUES ('Mais', 442, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 443, 2);
INSERT INTO public.appartiene VALUES ('Mais', 444, 4);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 445, 4);
INSERT INTO public.appartiene VALUES ('Hawaiian', 445, 4);
INSERT INTO public.appartiene VALUES ('Brie e speck', 446, 1);
INSERT INTO public.appartiene VALUES ('Valtellina', 446, 2);
INSERT INTO public.appartiene VALUES ('Zucchine', 447, 1);
INSERT INTO public.appartiene VALUES ('Melanzane', 448, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 449, 4);
INSERT INTO public.appartiene VALUES ('Funghi', 450, 2);
INSERT INTO public.appartiene VALUES ('Marinara', 451, 3);
INSERT INTO public.appartiene VALUES ('Chiodini', 452, 2);
INSERT INTO public.appartiene VALUES ('Cracker', 453, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto', 453, 1);
INSERT INTO public.appartiene VALUES ('Pancetta', 454, 4);
INSERT INTO public.appartiene VALUES ('Leggera', 455, 1);
INSERT INTO public.appartiene VALUES ('Pugliese', 456, 2);
INSERT INTO public.appartiene VALUES ('Pomodorini', 457, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 458, 4);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 458, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 459, 2);
INSERT INTO public.appartiene VALUES ('Funghi', 459, 4);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 460, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 460, 2);
INSERT INTO public.appartiene VALUES ('Pugliese', 461, 1);
INSERT INTO public.appartiene VALUES ('Capricciosa', 462, 3);
INSERT INTO public.appartiene VALUES ('Salsiccia', 463, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 464, 4);
INSERT INTO public.appartiene VALUES ('Misto mare', 464, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 465, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 466, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 467, 4);
INSERT INTO public.appartiene VALUES ('Funghi', 468, 1);
INSERT INTO public.appartiene VALUES ('Leggera', 469, 4);
INSERT INTO public.appartiene VALUES ('Cracker', 470, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 471, 3);
INSERT INTO public.appartiene VALUES ('Viennese', 472, 1);
INSERT INTO public.appartiene VALUES ('Cortigiana', 472, 4);
INSERT INTO public.appartiene VALUES ('Viennese', 473, 1);
INSERT INTO public.appartiene VALUES ('Contadina', 474, 1);
INSERT INTO public.appartiene VALUES ('Chiodini', 474, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 475, 1);
INSERT INTO public.appartiene VALUES ('Demonio', 476, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto', 476, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto', 477, 3);
INSERT INTO public.appartiene VALUES ('Patatosa', 478, 3);
INSERT INTO public.appartiene VALUES ('Napoli', 479, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 480, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 481, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 482, 2);
INSERT INTO public.appartiene VALUES ('Bresaola', 483, 4);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 484, 2);
INSERT INTO public.appartiene VALUES ('Margherita', 484, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 485, 3);
INSERT INTO public.appartiene VALUES ('Porcini', 486, 1);
INSERT INTO public.appartiene VALUES ('Capricciosa', 487, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 487, 4);
INSERT INTO public.appartiene VALUES ('Parmigiana', 487, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 488, 2);
INSERT INTO public.appartiene VALUES ('Pomodorini', 489, 3);
INSERT INTO public.appartiene VALUES ('Contadina', 489, 2);
INSERT INTO public.appartiene VALUES ('Napoli', 490, 3);
INSERT INTO public.appartiene VALUES ('Porchetta', 491, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 492, 4);
INSERT INTO public.appartiene VALUES ('Porchetta', 492, 3);
INSERT INTO public.appartiene VALUES ('Speck', 492, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 492, 3);
INSERT INTO public.appartiene VALUES ('Margherita', 493, 1);
INSERT INTO public.appartiene VALUES ('Delicata', 493, 1);
INSERT INTO public.appartiene VALUES ('Contadina', 493, 4);
INSERT INTO public.appartiene VALUES ('Pugliese', 494, 4);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 494, 2);
INSERT INTO public.appartiene VALUES ('Delicata', 495, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 496, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 496, 4);
INSERT INTO public.appartiene VALUES ('Marinara', 497, 2);
INSERT INTO public.appartiene VALUES ('Demonio', 497, 4);
INSERT INTO public.appartiene VALUES ('Valtellina', 497, 4);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 497, 2);
INSERT INTO public.appartiene VALUES ('Porcini', 498, 3);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 499, 4);
INSERT INTO public.appartiene VALUES ('Asparagi', 499, 1);
INSERT INTO public.appartiene VALUES ('Pugliese', 500, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 501, 3);
INSERT INTO public.appartiene VALUES ('Chiodini', 501, 3);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 502, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 502, 2);
INSERT INTO public.appartiene VALUES ('Melanzane', 502, 4);
INSERT INTO public.appartiene VALUES ('Speck', 503, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 504, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 504, 2);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 505, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 506, 1);
INSERT INTO public.appartiene VALUES ('Porchetta', 507, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 508, 4);
INSERT INTO public.appartiene VALUES ('Chiodini', 509, 3);
INSERT INTO public.appartiene VALUES ('Melanzane', 510, 1);
INSERT INTO public.appartiene VALUES ('Melanzane', 511, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 512, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 513, 1);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 514, 1);
INSERT INTO public.appartiene VALUES ('Marinara', 515, 2);
INSERT INTO public.appartiene VALUES ('Brie e speck', 516, 3);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 517, 1);
INSERT INTO public.appartiene VALUES ('Pomodorini', 518, 1);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 518, 1);
INSERT INTO public.appartiene VALUES ('Valtellina', 519, 2);
INSERT INTO public.appartiene VALUES ('Crudo', 520, 4);
INSERT INTO public.appartiene VALUES ('Carbonara', 521, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 522, 4);
INSERT INTO public.appartiene VALUES ('Prosciutto', 523, 3);
INSERT INTO public.appartiene VALUES ('Prosciutto', 524, 3);
INSERT INTO public.appartiene VALUES ('Contadina', 525, 3);
INSERT INTO public.appartiene VALUES ('Demonio', 526, 4);
INSERT INTO public.appartiene VALUES ('Delicata', 526, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 527, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 528, 2);
INSERT INTO public.appartiene VALUES ('Zucchine', 529, 1);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 530, 3);
INSERT INTO public.appartiene VALUES ('Asparagi', 531, 1);
INSERT INTO public.appartiene VALUES ('Brie e speck', 531, 3);
INSERT INTO public.appartiene VALUES ('Radicchio', 532, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 533, 1);
INSERT INTO public.appartiene VALUES ('Pugliese', 534, 2);
INSERT INTO public.appartiene VALUES ('Pugliese', 535, 2);
INSERT INTO public.appartiene VALUES ('Pugliese', 536, 2);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 537, 1);
INSERT INTO public.appartiene VALUES ('Viennese', 537, 1);
INSERT INTO public.appartiene VALUES ('Melanzane', 537, 4);
INSERT INTO public.appartiene VALUES ('Napoli', 538, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e mais', 539, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 540, 3);
INSERT INTO public.appartiene VALUES ('Porchetta', 541, 4);
INSERT INTO public.appartiene VALUES ('Pugliese', 542, 2);
INSERT INTO public.appartiene VALUES ('Viennese', 543, 3);
INSERT INTO public.appartiene VALUES ('Viennese', 544, 3);
INSERT INTO public.appartiene VALUES ('Valtellina', 545, 3);
INSERT INTO public.appartiene VALUES ('Sicilia', 545, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 545, 1);
INSERT INTO public.appartiene VALUES ('Brie e speck', 546, 3);
INSERT INTO public.appartiene VALUES ('Porchetta', 547, 2);
INSERT INTO public.appartiene VALUES ('Valtellina', 548, 3);
INSERT INTO public.appartiene VALUES ('Margherita', 549, 1);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 550, 2);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 551, 2);
INSERT INTO public.appartiene VALUES ('Demonio', 552, 1);
INSERT INTO public.appartiene VALUES ('Crudo', 553, 4);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 554, 2);
INSERT INTO public.appartiene VALUES ('Ricotta e spinaci', 555, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 556, 3);
INSERT INTO public.appartiene VALUES ('Pomodorini', 556, 4);
INSERT INTO public.appartiene VALUES ('Funghi', 556, 3);
INSERT INTO public.appartiene VALUES ('Radicchio', 557, 3);
INSERT INTO public.appartiene VALUES ('Marinara', 558, 3);
INSERT INTO public.appartiene VALUES ('Brie e speck', 559, 3);
INSERT INTO public.appartiene VALUES ('Pancetta', 560, 1);
INSERT INTO public.appartiene VALUES ('Mais', 561, 4);
INSERT INTO public.appartiene VALUES ('Melanzane', 562, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 563, 4);
INSERT INTO public.appartiene VALUES ('Porchetta', 564, 4);
INSERT INTO public.appartiene VALUES ('Leggera', 565, 3);
INSERT INTO public.appartiene VALUES ('Pugliese', 565, 1);
INSERT INTO public.appartiene VALUES ('Speck', 565, 2);
INSERT INTO public.appartiene VALUES ('Pancetta', 566, 4);
INSERT INTO public.appartiene VALUES ('Pancetta', 567, 4);
INSERT INTO public.appartiene VALUES ('Pancetta', 568, 4);
INSERT INTO public.appartiene VALUES ('Crudo', 569, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 570, 2);
INSERT INTO public.appartiene VALUES ('Radicchio', 570, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 571, 1);
INSERT INTO public.appartiene VALUES ('Asparagi', 571, 3);
INSERT INTO public.appartiene VALUES ('Funghi', 572, 3);
INSERT INTO public.appartiene VALUES ('Radicchio', 573, 4);
INSERT INTO public.appartiene VALUES ('Margherita', 574, 4);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 575, 2);
INSERT INTO public.appartiene VALUES ('Noci e gorgonzola', 576, 2);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 577, 2);
INSERT INTO public.appartiene VALUES ('Gamberetti', 578, 1);
INSERT INTO public.appartiene VALUES ('Quattro stagioni', 579, 1);
INSERT INTO public.appartiene VALUES ('Sicilia', 579, 2);
INSERT INTO public.appartiene VALUES ('Hawaiian', 579, 1);
INSERT INTO public.appartiene VALUES ('Brie e speck', 579, 3);
INSERT INTO public.appartiene VALUES ('Quattro formaggi', 580, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 581, 1);
INSERT INTO public.appartiene VALUES ('Tonno e cipolla', 582, 1);
INSERT INTO public.appartiene VALUES ('Gamberetti', 583, 2);
INSERT INTO public.appartiene VALUES ('Cortigiana', 584, 4);
INSERT INTO public.appartiene VALUES ('Cortigiana', 585, 4);
INSERT INTO public.appartiene VALUES ('Zucchine', 586, 3);
INSERT INTO public.appartiene VALUES ('Wurstel e patatine', 587, 3);
INSERT INTO public.appartiene VALUES ('Salsiccia', 588, 4);
INSERT INTO public.appartiene VALUES ('Mais', 589, 2);
INSERT INTO public.appartiene VALUES ('Delicata', 590, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 591, 3);
INSERT INTO public.appartiene VALUES ('Delicata', 592, 1);
INSERT INTO public.appartiene VALUES ('Delicata', 593, 1);
INSERT INTO public.appartiene VALUES ('Napoli', 594, 1);
INSERT INTO public.appartiene VALUES ('Pancetta', 595, 4);
INSERT INTO public.appartiene VALUES ('Salsiccia', 595, 4);
INSERT INTO public.appartiene VALUES ('Gamberetti', 596, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto', 596, 4);
INSERT INTO public.appartiene VALUES ('Carbonara', 596, 4);
INSERT INTO public.appartiene VALUES ('Demonio', 596, 2);
INSERT INTO public.appartiene VALUES ('Prosciutto e funghi', 596, 1);
INSERT INTO public.appartiene VALUES ('Mais', 596, 4);
INSERT INTO public.appartiene VALUES ('Bresaola', 597, 3);
INSERT INTO public.appartiene VALUES ('Patatosa', 597, 4);
INSERT INTO public.appartiene VALUES ('Contadina', 597, 4);
INSERT INTO public.appartiene VALUES ('Sicilia', 598, 2);
INSERT INTO public.appartiene VALUES ('Marinara', 598, 3);
INSERT INTO public.appartiene VALUES ('Delicata', 599, 4);
INSERT INTO public.appartiene VALUES ('Gorgonzola', 599, 2);
INSERT INTO public.appartiene VALUES ('Salsiccia', 600, 3);
INSERT INTO public.appartiene VALUES ('Gamberetti', 600, 3);
INSERT INTO public.appartiene VALUES ('Porcini', 600, 3);


--
-- TOC entry 3411 (class 0 OID 16622)
-- Dependencies: 216
-- Data for Name: cameriere; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cameriere VALUES (922478, '2018-10-31', 'Pietro', 'Rocca', '1993-12-31', 'M', '3160084514', 9.96);
INSERT INTO public.cameriere VALUES (906613, '2012-11-27', 'Matteo', 'Giorgi', '1990-04-10', 'M', '3605504407', 14.46);
INSERT INTO public.cameriere VALUES (849113, '2017-05-13', 'Sofia', 'Giorgi', '1960-06-26', 'F', '7999479713', 16.21);
INSERT INTO public.cameriere VALUES (207600, '2023-08-02', 'Leonardo', 'Benedetti', '1976-07-25', 'M', '7240720863', 13.55);
INSERT INTO public.cameriere VALUES (992375, '2013-01-14', 'Alessandro', 'Lombardi', '1966-04-03', 'M', '0097638196', 19.15);
INSERT INTO public.cameriere VALUES (155572, '2022-11-28', 'Gabriel', 'Piazza', '1998-10-01', 'M', '3458131979', 7.41);
INSERT INTO public.cameriere VALUES (574865, '2019-10-24', 'Bianca', 'Grassi', '1977-11-24', 'F', '3259967448', 10.36);
INSERT INTO public.cameriere VALUES (170147, '2015-10-12', 'Vittoria', 'Sanna', '1967-07-13', 'F', '0805711939', 9.88);
INSERT INTO public.cameriere VALUES (859817, '2021-04-24', 'Azzurra', 'Marchi', '1987-07-23', 'F', '4482163899', 9.72);
INSERT INTO public.cameriere VALUES (528689, '2020-05-25', 'Andrea', 'Poli', '1953-03-09', 'M', '2988494985', 15.83);
INSERT INTO public.cameriere VALUES (281137, '2022-01-05', 'Antonio', 'Santis', '1997-11-08', 'M', '6120665788', 7.21);
INSERT INTO public.cameriere VALUES (944410, '2022-09-25', 'Sara', 'Massimo', '1996-11-02', 'F', '2044824940', 12.98);
INSERT INTO public.cameriere VALUES (997257, '2014-09-09', 'Michele', 'Morelli', '1973-03-22', 'M', '7453507239', 9.76);
INSERT INTO public.cameriere VALUES (853886, '2017-09-29', 'Mia', 'Benedetti', '1957-03-26', 'F', '8556564172', 10.78);
INSERT INTO public.cameriere VALUES (566818, '2013-11-19', 'Mattia', 'Lombardi', '1952-12-16', 'M', '2468367881', 13.59);
INSERT INTO public.cameriere VALUES (595713, '2018-08-14', 'Edoardo', 'Morelli', '1998-04-28', 'M', '5708692066', 14.09);
INSERT INTO public.cameriere VALUES (143204, '2020-02-11', 'Federico', 'Cattaneo', '1976-02-18', 'M', '0630163261', 11.50);
INSERT INTO public.cameriere VALUES (438956, '2018-11-13', 'Nicole', 'Agostino', '1997-09-29', 'F', '0812976196', 12.29);
INSERT INTO public.cameriere VALUES (270138, '2021-02-25', 'Bianca', 'Palumbo', '1976-12-23', 'F', '8675047341', 19.29);
INSERT INTO public.cameriere VALUES (956326, '2019-04-17', 'Mario', 'De Luca', '1952-06-26', 'M', '2929461492', 14.37);
INSERT INTO public.cameriere VALUES (354903, '2012-08-26', 'Sofia', 'Farina', '1951-08-07', 'F', '5929356979', 10.56);
INSERT INTO public.cameriere VALUES (754495, '2011-04-02', 'Nicole', 'Angelis', '1968-10-09', 'F', '2083054833', 7.63);
INSERT INTO public.cameriere VALUES (209826, '2012-09-02', 'Enea', 'Paola', '1985-12-01', 'M', '2434603338', 13.26);
INSERT INTO public.cameriere VALUES (668141, '2023-10-01', 'Antonio', 'Agostino', '1951-12-29', 'M', '9471327170', 14.70);
INSERT INTO public.cameriere VALUES (550905, '2015-08-10', 'Isabel', 'Rizzi', '1970-05-12', 'F', '8506827776', 17.98);
INSERT INTO public.cameriere VALUES (594866, '2014-07-29', 'Mia', 'Pellegrino', '1957-02-07', 'F', '2151476451', 10.34);
INSERT INTO public.cameriere VALUES (808430, '2017-01-15', 'Emma', 'Mazza', '1965-04-03', 'F', '4510385966', 18.17);
INSERT INTO public.cameriere VALUES (851409, '2016-11-08', 'Aurora', 'Farina', '1984-10-15', 'F', '8741752468', 10.67);
INSERT INTO public.cameriere VALUES (963027, '2018-10-18', 'Greta', 'Coppola', '1981-11-14', 'F', '2516691690', 12.27);
INSERT INTO public.cameriere VALUES (817527, '2023-01-27', 'Azzurra', 'Coppola', '1987-06-28', 'F', '6601769786', 12.85);
INSERT INTO public.cameriere VALUES (893535, '2012-05-15', 'Mattia', 'Piazza', '1972-08-31', 'M', '0310355908', 16.81);
INSERT INTO public.cameriere VALUES (320289, '2017-06-13', 'Diego', 'Monti', '1997-11-18', 'M', '1996701969', 9.69);
INSERT INTO public.cameriere VALUES (341442, '2017-12-22', 'Greta', 'Soc', '1973-04-21', 'F', '9112977435', 9.23);
INSERT INTO public.cameriere VALUES (993477, '2021-01-23', 'Alessandro', 'Paola', '1954-08-23', 'M', '6286321912', 10.13);
INSERT INTO public.cameriere VALUES (928749, '2013-07-16', 'Viola', 'Valentini', '1982-09-23', 'F', '9219400989', 17.59);
INSERT INTO public.cameriere VALUES (999100, '2013-12-19', 'Rebecca', 'Valentini', '1956-08-19', 'F', '9049751293', 18.55);
INSERT INTO public.cameriere VALUES (965649, '2013-07-27', 'Andrea', 'Testa', '1964-03-05', 'M', '1617821417', 7.84);
INSERT INTO public.cameriere VALUES (617402, '2020-11-13', 'Azzurra', 'Cattaneo', '1990-07-17', 'F', '7942848017', 7.80);
INSERT INTO public.cameriere VALUES (759925, '2014-01-10', 'Diego', 'Michele', '1971-05-22', 'M', '8481977192', 7.10);
INSERT INTO public.cameriere VALUES (599818, '2011-01-24', 'Giulia', 'Vitale', '1969-02-05', 'F', '1084430272', 11.13);
INSERT INTO public.cameriere VALUES (444387, '2022-11-08', 'Gabriel', 'Cattaneo', '2002-02-09', 'M', '4037850453', 13.43);
INSERT INTO public.cameriere VALUES (809661, '2017-03-27', 'Emma', 'Grassi', '1990-10-14', 'F', '7672657208', 16.89);
INSERT INTO public.cameriere VALUES (687438, '2022-11-05', 'Michele', 'Lombardi', '2003-09-27', 'M', '0217636811', 12.31);
INSERT INTO public.cameriere VALUES (759791, '2019-01-25', 'Greta', 'Rocca', '1956-12-24', 'F', '6040699506', 16.33);
INSERT INTO public.cameriere VALUES (852836, '2010-08-16', 'Rebecca', 'Testa', '1988-08-31', 'F', '8851653858', 13.44);
INSERT INTO public.cameriere VALUES (234912, '2011-07-29', 'Gaia', 'Vitale', '1984-10-27', 'F', '9871120202', 14.35);
INSERT INTO public.cameriere VALUES (757318, '2018-12-17', 'Giovanni', 'Sanna', '1965-10-05', 'M', '1293692313', 19.13);
INSERT INTO public.cameriere VALUES (134370, '2012-08-08', 'Gioele', 'Piazza', '1988-05-18', 'M', '2943399124', 12.61);
INSERT INTO public.cameriere VALUES (865126, '2019-07-20', 'Anna', 'Mazza', '1998-08-13', 'F', '2040373129', 13.55);
INSERT INTO public.cameriere VALUES (857610, '2010-03-24', 'Gioele', 'Testa', '1990-09-19', 'M', '5337514135', 12.97);


--
-- TOC entry 3409 (class 0 OID 16603)
-- Dependencies: 214
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cliente VALUES ('anita.fratelli@gmail.com', 'Anita', 'Fratelli', '2013-03-22', '4382587480');
INSERT INTO public.cliente VALUES ('marco.russo@gmail.com', 'Marco', 'Russo', '1955-10-10', '2705232007');
INSERT INTO public.cliente VALUES ('luca.moretti@hotmail.com', 'Luca', 'Moretti', '2016-01-06', '9844279064');
INSERT INTO public.cliente VALUES ('giorgio.franco@libero.it', 'Giorgio', 'Franco', '1964-08-11', '7894238958');
INSERT INTO public.cliente VALUES ('damiano.rossi@libero.it', 'Damiano', 'Rossi', '1961-11-05', '4163039574');
INSERT INTO public.cliente VALUES ('amelia.fontana@libero.it', 'Amelia', 'Fontana', '1984-07-11', '1667933616');
INSERT INTO public.cliente VALUES ('ambra.villa@gmail.com', 'Ambra', 'Villa', '1998-09-27', '0673785383');
INSERT INTO public.cliente VALUES ('diana.franco@hotmail.com', 'Diana', 'Franco', '1971-04-19', '0666419807');
INSERT INTO public.cliente VALUES ('nicola.giordano@hotmail.com', 'Nicola', 'Giordano', '1952-10-08', '4044905656');
INSERT INTO public.cliente VALUES ('marta.marino@gmail.com', 'Marta', 'Marino', '1973-03-10', '9345062304');
INSERT INTO public.cliente VALUES ('carlotta.rinaldi@hotmail.com', 'Carlotta', 'Rinaldi', '2013-11-12', '4439726165');
INSERT INTO public.cliente VALUES ('asia.bruno@hotmail.com', 'Asia', 'Bruno', '1991-11-17', '3061666942');
INSERT INTO public.cliente VALUES ('elia.conti@hotmail.com', 'Elia', 'Conti', '1968-12-23', '4561318125');
INSERT INTO public.cliente VALUES ('nathan.franco@hotmail.com', 'Nathan', 'Franco', '1971-07-14', '9294317513');
INSERT INTO public.cliente VALUES ('alessio.caruso@hotmail.com', 'Alessio', 'Caruso', '1964-06-07', '5791006517');
INSERT INTO public.cliente VALUES ('michele.mancini@libero.it', 'Michele', 'Mancini', '2006-08-26', '1710765403');
INSERT INTO public.cliente VALUES ('noah.villa@hotmail.com', 'Noah', 'Villa', '1969-03-14', '5690114082');
INSERT INTO public.cliente VALUES ('margherita.conti@gmail.com', 'Margherita', 'Conti', '1970-11-05', '3699794107');
INSERT INTO public.cliente VALUES ('gioia.gallo@hotmail.com', 'Gioia', 'Gallo', '1986-11-09', '2001145805');
INSERT INTO public.cliente VALUES ('jacopo.barbieri@libero.it', 'Jacopo', 'Barbieri', '1974-05-23', '1148326897');
INSERT INTO public.cliente VALUES ('alessia.villa@libero.it', 'Alessia', 'Villa', '1998-09-01', '1098656655');
INSERT INTO public.cliente VALUES ('miriam.gallo@gmail.com', 'Miriam', 'Gallo', '1971-10-02', '7832236631');
INSERT INTO public.cliente VALUES ('luigi.leone@gmail.com', 'Luigi', 'Leone', '1952-12-07', '4690261088');
INSERT INTO public.cliente VALUES ('ettore.caruso@hotmail.com', 'Ettore', 'Caruso', '1949-12-24', '7683628771');
INSERT INTO public.cliente VALUES ('daniele.moretti@hotmail.com', 'Daniele', 'Moretti', '1948-01-28', '6204312548');
INSERT INTO public.cliente VALUES ('ambra.villa@hotmail.com', 'Ambra', 'Villa', '2016-10-15', '9613003753');
INSERT INTO public.cliente VALUES ('luigi.mariani@libero.it', 'Luigi', 'Mariani', '1963-01-25', '0138015717');
INSERT INTO public.cliente VALUES ('anita.moretti@gmail.com', 'Anita', 'Moretti', '1957-11-15', '3001429832');
INSERT INTO public.cliente VALUES ('ambra.franco@libero.it', 'Ambra', 'Franco', '1937-02-15', '1288584924');
INSERT INTO public.cliente VALUES ('nina.leone@hotmail.com', 'Nina', 'Leone', '2009-01-19', '1931259947');
INSERT INTO public.cliente VALUES ('daniel.marino@hotmail.com', 'Daniel', 'Marino', '1984-12-02', '7827051905');
INSERT INTO public.cliente VALUES ('aurora.amato@hotmail.com', 'Aurora', 'Amato', '1938-12-20', '3610400438');
INSERT INTO public.cliente VALUES ('luigi.esposito@hotmail.com', 'Luigi', 'Esposito', '1977-06-03', '5607395534');
INSERT INTO public.cliente VALUES ('francesca.rizzo@hotmail.com', 'Francesca', 'Rizzo', '1943-01-12', '4321079384');
INSERT INTO public.cliente VALUES ('luca.romano@libero.it', 'Luca', 'Romano', '1937-08-05', '7508991658');
INSERT INTO public.cliente VALUES ('luca.russo@libero.it', 'Luca', 'Russo', '1934-07-20', '1486391219');
INSERT INTO public.cliente VALUES ('cecilia.ferrara@libero.it', 'Cecilia', 'Ferrara', '1992-02-04', '1933863803');
INSERT INTO public.cliente VALUES ('elena.ferrara@gmail.com', 'Elena', 'Ferrara', '1981-01-19', '9451492984');
INSERT INTO public.cliente VALUES ('liam.fontana@hotmail.com', 'Liam', 'Fontana', '1938-10-08', '6614234346');
INSERT INTO public.cliente VALUES ('thomas.franco@hotmail.com', 'Thomas', 'Franco', '1951-08-12', '4953353950');
INSERT INTO public.cliente VALUES ('francesca.bruno@libero.it', 'Francesca', 'Bruno', '1991-10-23', '5317300093');
INSERT INTO public.cliente VALUES ('diletta.amato@hotmail.com', 'Diletta', 'Amato', '1963-09-06', '4998059918');
INSERT INTO public.cliente VALUES ('maria.ricci@libero.it', 'Maria', 'Ricci', '1999-01-22', '9536904848');
INSERT INTO public.cliente VALUES ('diana.villa@gmail.com', 'Diana', 'Villa', '1982-05-27', '9564204359');
INSERT INTO public.cliente VALUES ('thomas.esposito@libero.it', 'Thomas', 'Esposito', '2012-11-03', '0818614861');
INSERT INTO public.cliente VALUES ('nathan.barbieri@gmail.com', 'Nathan', 'Barbieri', '2008-04-11', '0984479533');
INSERT INTO public.cliente VALUES ('manuel.conti@hotmail.com', 'Manuel', 'Conti', '1994-05-04', '0280302875');
INSERT INTO public.cliente VALUES ('asia.villa@libero.it', 'Asia', 'Villa', '1963-10-02', '5655032187');
INSERT INTO public.cliente VALUES ('anita.martino@libero.it', 'Anita', 'Martino', '1948-03-21', '2886720088');
INSERT INTO public.cliente VALUES ('alessia.rinaldi@libero.it', 'Alessia', 'Rinaldi', '1940-05-10', '6451849981');


--
-- TOC entry 3417 (class 0 OID 16680)
-- Dependencies: 222
-- Data for Name: contiene; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.contiene VALUES ('Marinara', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Marinara', 'Aglio');
INSERT INTO public.contiene VALUES ('Marinara', 'Origano');
INSERT INTO public.contiene VALUES ('Margherita', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Margherita', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Prosciutto', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Prosciutto', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Prosciutto', 'Prosciutto cotto');
INSERT INTO public.contiene VALUES ('Viennese', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Viennese', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Viennese', 'Wurstel');
INSERT INTO public.contiene VALUES ('Diavola', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Diavola', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Diavola', 'Salamino piccante');
INSERT INTO public.contiene VALUES ('Napoli', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Napoli', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Napoli', 'Acciughe');
INSERT INTO public.contiene VALUES ('Funghi', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Funghi', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Funghi', 'Funghi');
INSERT INTO public.contiene VALUES ('Pugliese', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Pugliese', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Pugliese', 'Cipolla');
INSERT INTO public.contiene VALUES ('Melanzane', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Melanzane', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Melanzane', 'Melanzane');
INSERT INTO public.contiene VALUES ('Zucchine', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Zucchine', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Zucchine', 'Zucchine');
INSERT INTO public.contiene VALUES ('Patatosa', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Patatosa', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Patatosa', 'Patatine fritte');
INSERT INTO public.contiene VALUES ('Gorgonzola', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Gorgonzola', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Gorgonzola', 'Gorgonzola');
INSERT INTO public.contiene VALUES ('Pomodorini', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Pomodorini', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Pomodorini', 'Pomodorini');
INSERT INTO public.contiene VALUES ('Asparagi', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Asparagi', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Asparagi', 'Asparagi');
INSERT INTO public.contiene VALUES ('Mais', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Mais', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Mais', 'Mais');
INSERT INTO public.contiene VALUES ('Radicchio', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Radicchio', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Radicchio', 'Radicchio');
INSERT INTO public.contiene VALUES ('Salsiccia', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Salsiccia', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Salsiccia', 'Salsiccia');
INSERT INTO public.contiene VALUES ('Ricotta e spinaci', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Ricotta e spinaci', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Ricotta e spinaci', 'Ricotta');
INSERT INTO public.contiene VALUES ('Ricotta e spinaci', 'Spinaci');
INSERT INTO public.contiene VALUES ('Prosciutto e funghi', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Prosciutto e funghi', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Prosciutto e funghi', 'Prosciutto cotto');
INSERT INTO public.contiene VALUES ('Prosciutto e funghi', 'Funghi');
INSERT INTO public.contiene VALUES ('Tonno e cipolla', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Tonno e cipolla', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Tonno e cipolla', 'Tonno');
INSERT INTO public.contiene VALUES ('Tonno e cipolla', 'Cipolla');
INSERT INTO public.contiene VALUES ('Porchetta', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Porchetta', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Porchetta', 'Porchetta');
INSERT INTO public.contiene VALUES ('Porcini', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Porcini', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Porcini', 'Funghi porcini');
INSERT INTO public.contiene VALUES ('Chiodini', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Chiodini', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Chiodini', 'Funghi chiodini');
INSERT INTO public.contiene VALUES ('Speck', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Speck', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Speck', 'Speck');
INSERT INTO public.contiene VALUES ('Crudo', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Crudo', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Crudo', 'Prosciutto crudo');
INSERT INTO public.contiene VALUES ('Bresaola', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Bresaola', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Bresaola', 'Bresaola');
INSERT INTO public.contiene VALUES ('Pancetta', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Pancetta', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Pancetta', 'Pancetta');
INSERT INTO public.contiene VALUES ('Wurstel e patatine', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Wurstel e patatine', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Wurstel e patatine', 'Patatine fritte');
INSERT INTO public.contiene VALUES ('Wurstel e patatine', 'Wurstel');
INSERT INTO public.contiene VALUES ('Capricciosa', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Capricciosa', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Capricciosa', 'Prosciutto cotto');
INSERT INTO public.contiene VALUES ('Capricciosa', 'Funghi');
INSERT INTO public.contiene VALUES ('Capricciosa', 'Carciofi');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Prosciutto cotto');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Funghi');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Carciofi');
INSERT INTO public.contiene VALUES ('Quattro stagioni', 'Olive nere');
INSERT INTO public.contiene VALUES ('Quattro formaggi', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Quattro formaggi', 'Formaggio stagionato');
INSERT INTO public.contiene VALUES ('Quattro formaggi', 'Pecorino');
INSERT INTO public.contiene VALUES ('Quattro formaggi', 'Ricotta');
INSERT INTO public.contiene VALUES ('Quattro formaggi', 'Gorgonzola');
INSERT INTO public.contiene VALUES ('Carbonara', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Carbonara', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Carbonara', 'Pancetta');
INSERT INTO public.contiene VALUES ('Carbonara', 'Grana');
INSERT INTO public.contiene VALUES ('Carbonara', 'Uova');
INSERT INTO public.contiene VALUES ('Parmigiana', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Parmigiana', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Parmigiana', 'Melanzane');
INSERT INTO public.contiene VALUES ('Parmigiana', 'Pancetta');
INSERT INTO public.contiene VALUES ('Parmigiana', 'Grana');
INSERT INTO public.contiene VALUES ('Sicilia', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Sicilia', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Sicilia', 'Capperi');
INSERT INTO public.contiene VALUES ('Sicilia', 'Acciughe');
INSERT INTO public.contiene VALUES ('Sicilia', 'Olive nere');
INSERT INTO public.contiene VALUES ('Leggera', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Leggera', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Leggera', 'Pomodorini');
INSERT INTO public.contiene VALUES ('Leggera', 'Rucola');
INSERT INTO public.contiene VALUES ('Leggera', 'Grana');
INSERT INTO public.contiene VALUES ('Delicata', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Delicata', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Delicata', 'Funghi chiodini');
INSERT INTO public.contiene VALUES ('Delicata', 'Carciofi');
INSERT INTO public.contiene VALUES ('Delicata', 'Brie');
INSERT INTO public.contiene VALUES ('Demonio', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Demonio', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Demonio', 'Salamino piccante');
INSERT INTO public.contiene VALUES ('Demonio', 'Acciughe');
INSERT INTO public.contiene VALUES ('Demonio', 'Olive nere');
INSERT INTO public.contiene VALUES ('Cortigiana', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Cortigiana', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Cortigiana', 'Melanzane');
INSERT INTO public.contiene VALUES ('Cortigiana', 'Salsiccia');
INSERT INTO public.contiene VALUES ('Cortigiana', 'Gorgonzola');
INSERT INTO public.contiene VALUES ('Prosciutto e mais', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Prosciutto e mais', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Prosciutto e mais', 'Prosciutto crudo');
INSERT INTO public.contiene VALUES ('Prosciutto e mais', 'Mais');
INSERT INTO public.contiene VALUES ('Valtellina', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Valtellina', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Valtellina', 'Bresaola');
INSERT INTO public.contiene VALUES ('Valtellina', 'Rucola');
INSERT INTO public.contiene VALUES ('Valtellina', 'Grana');
INSERT INTO public.contiene VALUES ('Contadina', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Contadina', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Contadina', 'Radicchio');
INSERT INTO public.contiene VALUES ('Contadina', 'Spinaci');
INSERT INTO public.contiene VALUES ('Contadina', 'Piselli');
INSERT INTO public.contiene VALUES ('Noci e gorgonzola', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Noci e gorgonzola', 'Noci');
INSERT INTO public.contiene VALUES ('Noci e gorgonzola', 'Gorgonzola');
INSERT INTO public.contiene VALUES ('Brie e speck', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Brie e speck', 'Brie');
INSERT INTO public.contiene VALUES ('Brie e speck', 'Speck');
INSERT INTO public.contiene VALUES ('Gamberetti', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Gamberetti', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Gamberetti', 'Gamberetti');
INSERT INTO public.contiene VALUES ('Misto mare', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Misto mare', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Misto mare', 'Misto mare');
INSERT INTO public.contiene VALUES ('Hawaiian', 'Pomodoro');
INSERT INTO public.contiene VALUES ('Hawaiian', 'Mozzarella');
INSERT INTO public.contiene VALUES ('Hawaiian', 'Ananas');


--
-- TOC entry 3412 (class 0 OID 16632)
-- Dependencies: 217
-- Data for Name: cuoco; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.cuoco VALUES (180811, '2016-11-05', 'Leonardo', 'Lombardo', '1966-05-06', 'M', '2226325234', 0.43, 27);
INSERT INTO public.cuoco VALUES (281631, '2017-07-27', 'Noemi', 'Pasquale', '1998-11-13', 'F', '8896282306', 1.06, 11);
INSERT INTO public.cuoco VALUES (134524, '2021-01-06', 'Giorgia', 'Angelis', '1972-07-08', 'F', '1103714930', 0.93, 15);
INSERT INTO public.cuoco VALUES (935000, '2016-06-29', 'Greta', 'Rizzi', '1958-07-29', 'F', '1983419750', 0.70, 24);
INSERT INTO public.cuoco VALUES (996539, '2020-11-02', 'Mia', 'Giorgi', '1964-07-09', 'F', '2205647695', 0.83, 24);
INSERT INTO public.cuoco VALUES (683217, '2020-08-31', 'Beatrice', 'Pellegrini', '1991-12-09', 'F', '9074585979', 0.25, 21);
INSERT INTO public.cuoco VALUES (310509, '2013-08-03', 'Nicola', 'Pellegrini', '1960-01-16', 'M', '0435868849', 1.24, 23);
INSERT INTO public.cuoco VALUES (986206, '2015-08-29', 'Ginevra', 'Piazza', '1987-04-19', 'F', '1606295449', 0.87, 26);
INSERT INTO public.cuoco VALUES (909700, '2020-09-04', 'Chiara', 'Pellegrino', '1991-11-24', 'F', '5018096493', 0.23, 18);
INSERT INTO public.cuoco VALUES (422047, '2010-05-31', 'Anna', 'Piazza', '1972-02-20', 'F', '1768477127', 0.97, 29);
INSERT INTO public.cuoco VALUES (799377, '2013-07-05', 'Lorenzo', 'Massimo', '1976-06-14', 'M', '8288065685', 1.11, 21);
INSERT INTO public.cuoco VALUES (598983, '2016-09-21', 'Anna', 'Mazza', '1977-02-07', 'F', '5094941630', 0.13, 16);
INSERT INTO public.cuoco VALUES (209713, '2012-10-13', 'Aurora', 'Grassi', '1973-01-08', 'F', '9296627523', 0.43, 15);
INSERT INTO public.cuoco VALUES (430270, '2013-05-10', 'Emma', 'Mazza', '1981-09-02', 'F', '4427006961', 1.65, 18);
INSERT INTO public.cuoco VALUES (747704, '2020-03-27', 'Camilla', 'Mazza', '2000-12-08', 'F', '2377630666', 0.55, 5);
INSERT INTO public.cuoco VALUES (919477, '2022-09-27', 'Isabel', 'Vitale', '1985-09-20', 'F', '3287056371', 0.84, 5);
INSERT INTO public.cuoco VALUES (679996, '2012-09-17', 'Nicole', 'Agostino', '1964-08-20', 'M', '4335345438', 1.08, 28);
INSERT INTO public.cuoco VALUES (426189, '2017-07-26', 'Bianca', 'Rocca', '1968-09-20', 'F', '1429755993', 0.60, 19);
INSERT INTO public.cuoco VALUES (263691, '2023-05-10', 'Tommaso', 'Bernardi', '1995-03-03', 'M', '4454061944', 1.41, 26);
INSERT INTO public.cuoco VALUES (251670, '2016-10-26', 'Matteo', 'Riva', '1952-08-02', 'M', '7319728253', 1.42, 18);
INSERT INTO public.cuoco VALUES (116864, '2012-10-25', 'Greta', 'Angelis', '1971-07-11', 'F', '9251888177', 0.48, 6);
INSERT INTO public.cuoco VALUES (417960, '2018-10-15', 'Andrea', 'Testa', '1962-06-29', 'M', '6671283693', 1.73, 28);
INSERT INTO public.cuoco VALUES (227297, '2012-08-23', 'Lorenzo', 'Cattaneo', '1974-06-23', 'M', '7478943322', 1.72, 10);
INSERT INTO public.cuoco VALUES (132366, '2010-12-16', 'Nicole', 'Massimo', '1962-09-11', 'F', '8763960820', 1.42, 10);
INSERT INTO public.cuoco VALUES (462956, '2020-08-08', 'Paolo', 'Silvestri', '2001-09-10', 'M', '0345627992', 1.51, 5);
INSERT INTO public.cuoco VALUES (610737, '2018-11-19', 'Giulia', 'Cattaneo', '1994-11-27', 'F', '9608534017', 0.53, 10);
INSERT INTO public.cuoco VALUES (502650, '2012-11-07', 'Francesca', 'Mazza', '1992-11-24', 'F', '0215490884', 2.00, 19);
INSERT INTO public.cuoco VALUES (117471, '2010-12-04', 'Tommaso', 'Pasquale', '1965-11-22', 'M', '5083231970', 0.67, 12);
INSERT INTO public.cuoco VALUES (310935, '2010-09-25', 'Sara', 'Ferraro', '1967-01-24', 'F', '7976529076', 0.33, 16);
INSERT INTO public.cuoco VALUES (751144, '2022-10-30', 'Chloe', 'Massimo', '1991-04-12', 'F', '5473639033', 0.62, 7);
INSERT INTO public.cuoco VALUES (833706, '2018-06-27', 'Lorenzo', 'Michele', '1979-09-16', 'M', '3594110794', 1.32, 19);
INSERT INTO public.cuoco VALUES (712187, '2015-11-10', 'Gabriele', 'Testa', '1970-02-12', 'M', '0822438838', 1.66, 6);
INSERT INTO public.cuoco VALUES (828852, '2021-09-24', 'Emma', 'Piazza', '1971-09-01', 'F', '7259422705', 1.91, 24);
INSERT INTO public.cuoco VALUES (411971, '2021-01-23', 'Marco', 'Benedetti', '1991-11-12', 'M', '1046349562', 1.07, 10);
INSERT INTO public.cuoco VALUES (512951, '2021-02-15', 'Chloe', 'Santis', '1972-02-24', 'F', '9832566189', 0.66, 28);
INSERT INTO public.cuoco VALUES (542541, '2020-03-12', 'Sofia', 'Palumbo', '1966-05-20', 'F', '5011716119', 1.55, 8);
INSERT INTO public.cuoco VALUES (153362, '2020-07-03', 'Andrea', 'Monti', '1984-10-27', 'M', '7060956292', 0.66, 29);
INSERT INTO public.cuoco VALUES (657146, '2017-07-07', 'Nicole', 'Angelis', '1958-06-09', 'F', '9769415608', 1.35, 30);
INSERT INTO public.cuoco VALUES (244945, '2020-05-29', 'Matteo', 'Poli', '1969-11-14', 'M', '6126817005', 0.93, 24);
INSERT INTO public.cuoco VALUES (496038, '2015-03-15', 'Alice', 'Bernardi', '1991-09-08', 'F', '1483746018', 1.07, 13);
INSERT INTO public.cuoco VALUES (612664, '2013-01-24', 'Federico', 'De Luca', '1992-05-12', 'M', '2449904925', 0.52, 29);
INSERT INTO public.cuoco VALUES (757956, '2020-10-26', 'Matilde', 'Michele', '1975-05-09', 'F', '0032547076', 0.84, 8);
INSERT INTO public.cuoco VALUES (234987, '2022-08-27', 'Vittoria', 'Giorgi', '1964-08-05', 'F', '8225528876', 1.89, 9);
INSERT INTO public.cuoco VALUES (257567, '2020-02-07', 'Martina', 'Silvestri', '1975-02-21', 'F', '4519812633', 1.07, 13);
INSERT INTO public.cuoco VALUES (778837, '2022-02-27', 'Rebecca', 'Pellegrini', '1960-04-28', 'F', '9432903786', 0.40, 25);
INSERT INTO public.cuoco VALUES (255348, '2015-12-12', 'Mia', 'Michele', '1991-03-30', 'F', '0652735990', 0.24, 19);
INSERT INTO public.cuoco VALUES (330511, '2013-01-14', 'Elena', 'Pellegrini', '1975-02-07', 'F', '8899367744', 0.82, 19);
INSERT INTO public.cuoco VALUES (964901, '2012-07-30', 'Giulia', 'Coppola', '1962-03-01', 'F', '9990797118', 0.93, 15);
INSERT INTO public.cuoco VALUES (748162, '2020-04-08', 'Matilde', 'Riva', '1953-10-20', 'F', '4167702111', 1.51, 12);
INSERT INTO public.cuoco VALUES (519828, '2013-02-13', 'Mattia', 'Morelli', '1957-06-12', 'M', '4706131769', 1.62, 27);


--
-- TOC entry 3415 (class 0 OID 16669)
-- Dependencies: 220
-- Data for Name: ingrediente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ingrediente VALUES ('Pomodoro', false, 4617, true);
INSERT INTO public.ingrediente VALUES ('Mozzarella', false, 800, true);
INSERT INTO public.ingrediente VALUES ('Aglio', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Origano', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Prosciutto crudo', false, 3045, true);
INSERT INTO public.ingrediente VALUES ('Prosciutto cotto', false, 3045, true);
INSERT INTO public.ingrediente VALUES ('Wurstel', false, 640, false);
INSERT INTO public.ingrediente VALUES ('Salamino piccante', false, 600, false);
INSERT INTO public.ingrediente VALUES ('Acciughe', false, 1111, true);
INSERT INTO public.ingrediente VALUES ('Funghi', false, 9725, true);
INSERT INTO public.ingrediente VALUES ('Cipolla', false, 8827, false);
INSERT INTO public.ingrediente VALUES ('Melanzane', true, 2622, false);
INSERT INTO public.ingrediente VALUES ('Zucchine', true, 6000, true);
INSERT INTO public.ingrediente VALUES ('Patatine fritte', true, 6000, true);
INSERT INTO public.ingrediente VALUES ('Gorgonzola', false, 600, false);
INSERT INTO public.ingrediente VALUES ('Pomodorini', false, 800, true);
INSERT INTO public.ingrediente VALUES ('Asparagi', false, 800, true);
INSERT INTO public.ingrediente VALUES ('Mais', false, 800, true);
INSERT INTO public.ingrediente VALUES ('Radicchio', true, 800, true);
INSERT INTO public.ingrediente VALUES ('Salsiccia', false, 4586, false);
INSERT INTO public.ingrediente VALUES ('Ricotta', false, 600, false);
INSERT INTO public.ingrediente VALUES ('Spinaci', true, 2934, false);
INSERT INTO public.ingrediente VALUES ('Tonno', false, 2622, false);
INSERT INTO public.ingrediente VALUES ('Porchetta', false, 2622, true);
INSERT INTO public.ingrediente VALUES ('Funghi porcini', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Funghi chiodini', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Speck', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Bresaola', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Pancetta', false, 300, true);
INSERT INTO public.ingrediente VALUES ('Carciofi', false, 300, false);
INSERT INTO public.ingrediente VALUES ('Olive nere', false, 9977, true);
INSERT INTO public.ingrediente VALUES ('Formaggio stagionato', false, 600, false);
INSERT INTO public.ingrediente VALUES ('Pecorino', false, 600, false);
INSERT INTO public.ingrediente VALUES ('Uova', false, 3922, true);
INSERT INTO public.ingrediente VALUES ('Grana', false, 3922, true);
INSERT INTO public.ingrediente VALUES ('Capperi', false, 2934, false);
INSERT INTO public.ingrediente VALUES ('Rucola', false, 30, true);
INSERT INTO public.ingrediente VALUES ('Brie', false, 30, false);
INSERT INTO public.ingrediente VALUES ('Piselli', true, 30, true);
INSERT INTO public.ingrediente VALUES ('Noci', false, 40, true);
INSERT INTO public.ingrediente VALUES ('Gamberetti', true, 842, true);
INSERT INTO public.ingrediente VALUES ('Misto mare', true, 2934, false);
INSERT INTO public.ingrediente VALUES ('Ananas', true, 300, true);


--
-- TOC entry 3418 (class 0 OID 16695)
-- Dependencies: 223
-- Data for Name: ordinazione; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ordinazione VALUES (1, '14:00:00', '2019-12-21', 'francesca.bruno@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (2, '22:15:00', '2020-12-03', 'ambra.villa@gmail.com', 422047);
INSERT INTO public.ordinazione VALUES (3, '20:45:00', '2017-06-01', 'anita.moretti@gmail.com', 799377);
INSERT INTO public.ordinazione VALUES (4, '18:00:00', '2017-01-11', 'daniel.marino@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (5, '15:30:00', '2018-09-22', 'miriam.gallo@gmail.com', 116864);
INSERT INTO public.ordinazione VALUES (6, '17:00:00', '2020-01-27', 'anita.fratelli@gmail.com', 180811);
INSERT INTO public.ordinazione VALUES (7, '11:45:00', '2019-08-06', 'nathan.franco@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (8, '22:30:00', '2019-11-18', 'carlotta.rinaldi@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (9, '18:00:00', '2018-09-17', 'nina.leone@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (10, '19:15:00', '2019-12-15', 'luca.romano@libero.it', 512951);
INSERT INTO public.ordinazione VALUES (11, '08:15:00', '2021-03-19', 'jacopo.barbieri@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (12, '16:30:00', '2017-05-05', 'amelia.fontana@libero.it', 255348);
INSERT INTO public.ordinazione VALUES (13, '05:00:00', '2019-11-03', 'luca.russo@libero.it', 909700);
INSERT INTO public.ordinazione VALUES (14, '02:00:00', '2020-07-05', 'marta.marino@gmail.com', 132366);
INSERT INTO public.ordinazione VALUES (15, '15:45:00', '2019-10-12', 'jacopo.barbieri@libero.it', 657146);
INSERT INTO public.ordinazione VALUES (16, '02:45:00', '2021-10-05', 'daniel.marino@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (17, '22:45:00', '2018-11-15', 'elia.conti@hotmail.com', 251670);
INSERT INTO public.ordinazione VALUES (18, '14:30:00', '2018-11-09', 'luca.russo@libero.it', 612664);
INSERT INTO public.ordinazione VALUES (19, '21:45:00', '2018-09-21', 'ettore.caruso@hotmail.com', 502650);
INSERT INTO public.ordinazione VALUES (20, '05:45:00', '2020-01-17', 'asia.bruno@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (21, '09:30:00', '2020-10-20', 'asia.bruno@hotmail.com', 263691);
INSERT INTO public.ordinazione VALUES (22, '00:45:00', '2019-06-13', 'asia.bruno@hotmail.com', 496038);
INSERT INTO public.ordinazione VALUES (23, '07:15:00', '2016-12-16', 'anita.fratelli@gmail.com', 180811);
INSERT INTO public.ordinazione VALUES (24, '12:30:00', '2020-02-10', 'marco.russo@gmail.com', 426189);
INSERT INTO public.ordinazione VALUES (25, '08:15:00', '2022-02-24', 'luca.russo@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (26, '09:30:00', '2017-05-23', 'thomas.esposito@libero.it', 153362);
INSERT INTO public.ordinazione VALUES (27, '05:30:00', '2019-12-28', 'cecilia.ferrara@libero.it', 519828);
INSERT INTO public.ordinazione VALUES (28, '16:00:00', '2019-10-12', 'liam.fontana@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (29, '16:45:00', '2016-12-25', 'marta.marino@gmail.com', 117471);
INSERT INTO public.ordinazione VALUES (30, '09:15:00', '2022-04-29', 'alessio.caruso@hotmail.com', 281631);
INSERT INTO public.ordinazione VALUES (31, '12:30:00', '2021-04-20', 'marta.marino@gmail.com', 598983);
INSERT INTO public.ordinazione VALUES (32, '18:15:00', '2020-06-02', 'nathan.barbieri@gmail.com', 935000);
INSERT INTO public.ordinazione VALUES (33, '12:30:00', '2021-04-30', 'elia.conti@hotmail.com', 255348);
INSERT INTO public.ordinazione VALUES (34, '11:45:00', '2021-10-04', 'alessia.rinaldi@libero.it', 542541);
INSERT INTO public.ordinazione VALUES (35, '13:30:00', '2020-10-20', 'nicola.giordano@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (36, '06:15:00', '2016-09-19', 'anita.moretti@gmail.com', 747704);
INSERT INTO public.ordinazione VALUES (37, '07:45:00', '2016-12-29', 'marta.marino@gmail.com', 263691);
INSERT INTO public.ordinazione VALUES (38, '13:15:00', '2019-11-10', 'jacopo.barbieri@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (39, '12:15:00', '2021-01-14', 'gioia.gallo@hotmail.com', 263691);
INSERT INTO public.ordinazione VALUES (40, '09:30:00', '2017-07-14', 'damiano.rossi@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (41, '22:30:00', '2017-07-27', 'giorgio.franco@libero.it', 799377);
INSERT INTO public.ordinazione VALUES (42, '22:00:00', '2020-04-25', 'anita.martino@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (43, '00:30:00', '2019-01-24', 'miriam.gallo@gmail.com', 496038);
INSERT INTO public.ordinazione VALUES (44, '00:30:00', '2020-06-02', 'luigi.esposito@hotmail.com', 244945);
INSERT INTO public.ordinazione VALUES (45, '01:30:00', '2021-11-22', 'diana.franco@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (46, '23:15:00', '2019-04-30', 'gioia.gallo@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (47, '23:00:00', '2020-02-24', 'elia.conti@hotmail.com', 519828);
INSERT INTO public.ordinazione VALUES (48, '22:15:00', '2019-12-02', 'nina.leone@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (49, '14:15:00', '2017-01-27', 'ambra.franco@libero.it', 180811);
INSERT INTO public.ordinazione VALUES (50, '02:00:00', '2020-05-02', 'noah.villa@hotmail.com', 679996);
INSERT INTO public.ordinazione VALUES (51, '17:45:00', '2017-10-12', 'ambra.villa@gmail.com', 757956);
INSERT INTO public.ordinazione VALUES (52, '04:30:00', '2019-08-24', 'liam.fontana@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (53, '03:45:00', '2017-01-17', 'alessio.caruso@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (54, '21:30:00', '2021-05-23', 'michele.mancini@libero.it', 757956);
INSERT INTO public.ordinazione VALUES (55, '19:30:00', '2021-10-02', 'nicola.giordano@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (56, '15:45:00', '2020-08-02', 'carlotta.rinaldi@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (57, '04:15:00', '2021-01-08', 'amelia.fontana@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (58, '01:15:00', '2019-09-26', 'amelia.fontana@libero.it', 964901);
INSERT INTO public.ordinazione VALUES (59, '19:45:00', '2018-08-01', 'anita.martino@libero.it', 310509);
INSERT INTO public.ordinazione VALUES (60, '16:30:00', '2017-12-23', 'francesca.rizzo@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (61, '15:00:00', '2018-09-08', 'luigi.esposito@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (62, '05:15:00', '2019-06-24', 'luca.russo@libero.it', 496038);
INSERT INTO public.ordinazione VALUES (63, '01:45:00', '2020-12-10', 'diana.villa@gmail.com', 833706);
INSERT INTO public.ordinazione VALUES (64, '11:15:00', '2020-03-06', 'ambra.villa@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (65, '19:30:00', '2019-02-04', 'marta.marino@gmail.com', 209713);
INSERT INTO public.ordinazione VALUES (66, '05:15:00', '2020-10-06', 'alessia.rinaldi@libero.it', 417960);
INSERT INTO public.ordinazione VALUES (67, '23:30:00', '2021-10-16', 'diletta.amato@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (68, '17:30:00', '2018-05-21', 'anita.moretti@gmail.com', 612664);
INSERT INTO public.ordinazione VALUES (69, '19:00:00', '2020-12-09', 'ambra.villa@gmail.com', 542541);
INSERT INTO public.ordinazione VALUES (70, '16:00:00', '2018-05-03', 'alessio.caruso@hotmail.com', 542541);
INSERT INTO public.ordinazione VALUES (71, '21:45:00', '2019-02-13', 'ettore.caruso@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (72, '12:15:00', '2017-11-15', 'manuel.conti@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (73, '18:15:00', '2022-08-26', 'amelia.fontana@libero.it', 683217);
INSERT INTO public.ordinazione VALUES (74, '01:45:00', '2020-05-29', 'diana.villa@gmail.com', 919477);
INSERT INTO public.ordinazione VALUES (75, '14:15:00', '2021-07-24', 'giorgio.franco@libero.it', 909700);
INSERT INTO public.ordinazione VALUES (76, '03:00:00', '2021-01-28', 'maria.ricci@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (77, '15:00:00', '2016-06-07', 'elena.ferrara@gmail.com', 251670);
INSERT INTO public.ordinazione VALUES (78, '13:30:00', '2020-02-23', 'thomas.franco@hotmail.com', 281631);
INSERT INTO public.ordinazione VALUES (79, '19:30:00', '2019-09-01', 'miriam.gallo@gmail.com', 251670);
INSERT INTO public.ordinazione VALUES (80, '20:30:00', '2016-07-15', 'nina.leone@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (81, '10:30:00', '2018-07-26', 'alessia.villa@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (82, '12:15:00', '2019-10-20', 'diletta.amato@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (83, '01:45:00', '2020-12-26', 'diana.franco@hotmail.com', 748162);
INSERT INTO public.ordinazione VALUES (84, '09:00:00', '2019-09-30', 'miriam.gallo@gmail.com', 751144);
INSERT INTO public.ordinazione VALUES (85, '16:45:00', '2018-03-06', 'ettore.caruso@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (86, '12:45:00', '2020-12-26', 'jacopo.barbieri@libero.it', 683217);
INSERT INTO public.ordinazione VALUES (87, '10:00:00', '2020-11-09', 'manuel.conti@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (88, '23:45:00', '2018-09-07', 'gioia.gallo@hotmail.com', 281631);
INSERT INTO public.ordinazione VALUES (89, '16:15:00', '2019-08-22', 'anita.martino@libero.it', 833706);
INSERT INTO public.ordinazione VALUES (90, '06:30:00', '2019-12-26', 'anita.moretti@gmail.com', 751144);
INSERT INTO public.ordinazione VALUES (91, '04:15:00', '2020-08-11', 'diana.franco@hotmail.com', 132366);
INSERT INTO public.ordinazione VALUES (92, '05:30:00', '2019-09-04', 'marta.marino@gmail.com', 757956);
INSERT INTO public.ordinazione VALUES (93, '06:45:00', '2019-04-15', 'margherita.conti@gmail.com', 134524);
INSERT INTO public.ordinazione VALUES (94, '04:15:00', '2018-10-20', 'luigi.mariani@libero.it', 234987);
INSERT INTO public.ordinazione VALUES (95, '10:45:00', '2020-04-10', 'anita.moretti@gmail.com', 757956);
INSERT INTO public.ordinazione VALUES (96, '18:45:00', '2017-09-24', 'damiano.rossi@libero.it', 542541);
INSERT INTO public.ordinazione VALUES (97, '00:30:00', '2019-09-05', 'margherita.conti@gmail.com', 610737);
INSERT INTO public.ordinazione VALUES (98, '14:30:00', '2021-05-01', 'gioia.gallo@hotmail.com', 281631);
INSERT INTO public.ordinazione VALUES (99, '14:15:00', '2021-10-29', 'ambra.franco@libero.it', 426189);
INSERT INTO public.ordinazione VALUES (100, '07:30:00', '2019-12-06', 'daniel.marino@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (101, '11:00:00', '2019-12-23', 'ettore.caruso@hotmail.com', 255348);
INSERT INTO public.ordinazione VALUES (102, '15:45:00', '2020-06-09', 'ambra.villa@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (103, '20:15:00', '2018-02-22', 'elia.conti@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (104, '12:00:00', '2019-01-20', 'luigi.esposito@hotmail.com', 757956);
INSERT INTO public.ordinazione VALUES (105, '06:45:00', '2019-02-11', 'marta.marino@gmail.com', 330511);
INSERT INTO public.ordinazione VALUES (106, '05:00:00', '2020-05-24', 'michele.mancini@libero.it', 426189);
INSERT INTO public.ordinazione VALUES (107, '13:00:00', '2022-12-01', 'luca.russo@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (108, '21:45:00', '2018-06-11', 'cecilia.ferrara@libero.it', 310935);
INSERT INTO public.ordinazione VALUES (109, '12:30:00', '2020-11-22', 'liam.fontana@hotmail.com', 612664);
INSERT INTO public.ordinazione VALUES (110, '08:00:00', '2019-11-27', 'luca.romano@libero.it', 964901);
INSERT INTO public.ordinazione VALUES (111, '17:45:00', '2019-06-07', 'luigi.mariani@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (112, '02:45:00', '2020-10-04', 'daniele.moretti@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (113, '07:45:00', '2020-09-09', 'luca.russo@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (114, '22:30:00', '2018-03-30', 'thomas.esposito@libero.it', 180811);
INSERT INTO public.ordinazione VALUES (115, '11:30:00', '2022-09-22', 'francesca.bruno@libero.it', 828852);
INSERT INTO public.ordinazione VALUES (116, '01:00:00', '2019-02-01', 'maria.ricci@libero.it', 657146);
INSERT INTO public.ordinazione VALUES (117, '07:45:00', '2020-04-28', 'ambra.villa@gmail.com', 919477);
INSERT INTO public.ordinazione VALUES (118, '17:00:00', '2018-03-31', 'amelia.fontana@libero.it', 263691);
INSERT INTO public.ordinazione VALUES (119, '11:30:00', '2021-05-16', 'cecilia.ferrara@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (120, '14:00:00', '2020-10-24', 'elena.ferrara@gmail.com', 281631);
INSERT INTO public.ordinazione VALUES (121, '23:00:00', '2020-09-30', 'nathan.barbieri@gmail.com', 909700);
INSERT INTO public.ordinazione VALUES (122, '07:00:00', '2019-03-13', 'francesca.rizzo@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (123, '22:45:00', '2021-01-02', 'asia.villa@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (124, '01:00:00', '2021-08-25', 'maria.ricci@libero.it', 610737);
INSERT INTO public.ordinazione VALUES (125, '06:30:00', '2022-10-28', 'cecilia.ferrara@libero.it', 751144);
INSERT INTO public.ordinazione VALUES (126, '12:15:00', '2020-04-12', 'francesca.bruno@libero.it', 134524);
INSERT INTO public.ordinazione VALUES (127, '09:45:00', '2020-02-13', 'luigi.esposito@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (128, '13:15:00', '2020-04-12', 'daniele.moretti@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (129, '20:00:00', '2019-04-15', 'liam.fontana@hotmail.com', 935000);
INSERT INTO public.ordinazione VALUES (130, '21:45:00', '2020-08-04', 'nicola.giordano@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (131, '03:15:00', '2018-06-30', 'thomas.esposito@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (132, '16:45:00', '2020-10-12', 'francesca.rizzo@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (133, '03:15:00', '2019-11-24', 'asia.villa@libero.it', 679996);
INSERT INTO public.ordinazione VALUES (134, '02:45:00', '2019-03-20', 'margherita.conti@gmail.com', 426189);
INSERT INTO public.ordinazione VALUES (135, '11:00:00', '2018-05-20', 'elia.conti@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (136, '08:15:00', '2018-06-15', 'daniele.moretti@hotmail.com', 426189);
INSERT INTO public.ordinazione VALUES (137, '17:15:00', '2020-11-27', 'nathan.franco@hotmail.com', 132366);
INSERT INTO public.ordinazione VALUES (138, '15:30:00', '2020-02-14', 'asia.bruno@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (139, '10:30:00', '2018-07-10', 'margherita.conti@gmail.com', 512951);
INSERT INTO public.ordinazione VALUES (140, '05:45:00', '2018-06-22', 'carlotta.rinaldi@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (141, '11:00:00', '2019-02-05', 'giorgio.franco@libero.it', 833706);
INSERT INTO public.ordinazione VALUES (142, '09:00:00', '2020-01-06', 'elia.conti@hotmail.com', 263691);
INSERT INTO public.ordinazione VALUES (143, '11:00:00', '2020-01-02', 'daniel.marino@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (144, '20:45:00', '2015-12-04', 'luigi.leone@gmail.com', 935000);
INSERT INTO public.ordinazione VALUES (145, '23:30:00', '2015-09-03', 'amelia.fontana@libero.it', 117471);
INSERT INTO public.ordinazione VALUES (146, '21:15:00', '2018-03-05', 'elia.conti@hotmail.com', 310935);
INSERT INTO public.ordinazione VALUES (147, '15:30:00', '2018-02-02', 'diana.franco@hotmail.com', 496038);
INSERT INTO public.ordinazione VALUES (148, '18:15:00', '2022-12-05', 'luca.russo@libero.it', 828852);
INSERT INTO public.ordinazione VALUES (149, '13:45:00', '2020-12-12', 'luigi.mariani@libero.it', 153362);
INSERT INTO public.ordinazione VALUES (150, '22:45:00', '2017-04-15', 'ambra.villa@hotmail.com', 748162);
INSERT INTO public.ordinazione VALUES (151, '15:30:00', '2020-01-29', 'jacopo.barbieri@libero.it', 426189);
INSERT INTO public.ordinazione VALUES (152, '01:45:00', '2018-12-22', 'marta.marino@gmail.com', 964901);
INSERT INTO public.ordinazione VALUES (153, '21:45:00', '2022-11-24', 'daniel.marino@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (154, '04:00:00', '2019-01-24', 'carlotta.rinaldi@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (155, '16:00:00', '2018-05-30', 'luca.romano@libero.it', 310509);
INSERT INTO public.ordinazione VALUES (156, '19:00:00', '2021-07-20', 'alessio.caruso@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (157, '20:45:00', '2020-12-30', 'elia.conti@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (158, '17:00:00', '2019-09-02', 'nina.leone@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (159, '14:30:00', '2020-11-29', 'daniele.moretti@hotmail.com', 757956);
INSERT INTO public.ordinazione VALUES (160, '11:00:00', '2021-07-18', 'alessia.rinaldi@libero.it', 512951);
INSERT INTO public.ordinazione VALUES (161, '07:30:00', '2022-08-26', 'anita.fratelli@gmail.com', 679996);
INSERT INTO public.ordinazione VALUES (162, '02:45:00', '2018-01-01', 'luca.moretti@hotmail.com', 935000);
INSERT INTO public.ordinazione VALUES (163, '20:15:00', '2021-09-13', 'gioia.gallo@hotmail.com', 519828);
INSERT INTO public.ordinazione VALUES (164, '14:00:00', '2021-10-02', 'carlotta.rinaldi@hotmail.com', 426189);
INSERT INTO public.ordinazione VALUES (165, '17:45:00', '2019-10-11', 'anita.moretti@gmail.com', 757956);
INSERT INTO public.ordinazione VALUES (166, '17:00:00', '2019-02-20', 'luca.romano@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (167, '06:15:00', '2019-04-18', 'marta.marino@gmail.com', 964901);
INSERT INTO public.ordinazione VALUES (168, '09:30:00', '2019-09-06', 'carlotta.rinaldi@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (169, '08:15:00', '2021-06-12', 'miriam.gallo@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (170, '15:15:00', '2017-10-08', 'nathan.barbieri@gmail.com', 519828);
INSERT INTO public.ordinazione VALUES (171, '18:45:00', '2020-12-02', 'ambra.villa@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (172, '16:15:00', '2020-08-16', 'ambra.franco@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (173, '12:30:00', '2019-02-10', 'marco.russo@gmail.com', 828852);
INSERT INTO public.ordinazione VALUES (174, '17:00:00', '2018-11-05', 'jacopo.barbieri@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (175, '12:15:00', '2017-05-27', 'francesca.rizzo@hotmail.com', 679996);
INSERT INTO public.ordinazione VALUES (176, '07:00:00', '2021-10-09', 'anita.martino@libero.it', 496038);
INSERT INTO public.ordinazione VALUES (177, '19:45:00', '2020-04-28', 'ambra.villa@hotmail.com', 799377);
INSERT INTO public.ordinazione VALUES (178, '23:15:00', '2020-11-01', 'damiano.rossi@libero.it', 964901);
INSERT INTO public.ordinazione VALUES (179, '07:00:00', '2021-06-22', 'daniel.marino@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (180, '13:45:00', '2021-07-01', 'daniele.moretti@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (181, '22:00:00', '2018-03-21', 'gioia.gallo@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (182, '07:45:00', '2021-12-12', 'marta.marino@gmail.com', 751144);
INSERT INTO public.ordinazione VALUES (183, '17:00:00', '2021-01-31', 'ambra.villa@gmail.com', 610737);
INSERT INTO public.ordinazione VALUES (184, '08:30:00', '2020-03-26', 'luca.romano@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (185, '16:00:00', '2020-06-13', 'thomas.franco@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (186, '06:15:00', '2018-08-31', 'noah.villa@hotmail.com', 909700);
INSERT INTO public.ordinazione VALUES (187, '06:30:00', '2021-03-31', 'luca.romano@libero.it', 310509);
INSERT INTO public.ordinazione VALUES (188, '22:30:00', '2019-04-19', 'diana.villa@gmail.com', 828852);
INSERT INTO public.ordinazione VALUES (189, '08:15:00', '2017-01-30', 'noah.villa@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (190, '12:15:00', '2019-03-15', 'anita.moretti@gmail.com', 496038);
INSERT INTO public.ordinazione VALUES (191, '02:45:00', '2020-08-07', 'anita.fratelli@gmail.com', 116864);
INSERT INTO public.ordinazione VALUES (192, '01:15:00', '2017-03-30', 'noah.villa@hotmail.com', 462956);
INSERT INTO public.ordinazione VALUES (193, '01:30:00', '2020-09-09', 'alessio.caruso@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (194, '14:00:00', '2019-12-20', 'diana.franco@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (195, '14:45:00', '2021-02-25', 'ambra.franco@libero.it', 417960);
INSERT INTO public.ordinazione VALUES (196, '22:30:00', '2017-06-23', 'cecilia.ferrara@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (197, '13:00:00', '2022-10-01', 'elia.conti@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (198, '09:15:00', '2020-04-25', 'elena.ferrara@gmail.com', 542541);
INSERT INTO public.ordinazione VALUES (199, '19:30:00', '2021-06-05', 'luigi.esposito@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (200, '09:45:00', '2021-10-28', 'elena.ferrara@gmail.com', 828852);
INSERT INTO public.ordinazione VALUES (201, '10:30:00', '2018-07-20', 'asia.villa@libero.it', 964901);
INSERT INTO public.ordinazione VALUES (202, '01:30:00', '2018-07-24', 'thomas.franco@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (203, '07:15:00', '2020-02-18', 'daniel.marino@hotmail.com', 462956);
INSERT INTO public.ordinazione VALUES (204, '11:45:00', '2020-02-14', 'michele.mancini@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (205, '02:15:00', '2020-12-30', 'asia.bruno@hotmail.com', 462956);
INSERT INTO public.ordinazione VALUES (206, '23:30:00', '2019-01-15', 'nina.leone@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (207, '07:00:00', '2018-08-09', 'ettore.caruso@hotmail.com', 496038);
INSERT INTO public.ordinazione VALUES (208, '11:45:00', '2019-12-01', 'anita.fratelli@gmail.com', 778837);
INSERT INTO public.ordinazione VALUES (209, '02:30:00', '2018-04-25', 'ambra.villa@hotmail.com', 964901);
INSERT INTO public.ordinazione VALUES (210, '01:00:00', '2020-08-24', 'luca.moretti@hotmail.com', 310935);
INSERT INTO public.ordinazione VALUES (211, '01:00:00', '2019-05-21', 'luca.russo@libero.it', 426189);
INSERT INTO public.ordinazione VALUES (212, '15:45:00', '2017-06-05', 'alessia.rinaldi@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (213, '17:30:00', '2018-01-10', 'luca.russo@libero.it', 712187);
INSERT INTO public.ordinazione VALUES (214, '02:00:00', '2019-11-14', 'aurora.amato@hotmail.com', 747704);
INSERT INTO public.ordinazione VALUES (215, '09:30:00', '2019-09-21', 'anita.fratelli@gmail.com', 422047);
INSERT INTO public.ordinazione VALUES (216, '07:15:00', '2020-10-05', 'aurora.amato@hotmail.com', 117471);
INSERT INTO public.ordinazione VALUES (217, '02:15:00', '2020-03-18', 'nathan.barbieri@gmail.com', 610737);
INSERT INTO public.ordinazione VALUES (218, '07:00:00', '2020-09-15', 'amelia.fontana@libero.it', 411971);
INSERT INTO public.ordinazione VALUES (219, '23:45:00', '2018-07-28', 'ettore.caruso@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (220, '14:15:00', '2017-06-25', 'amelia.fontana@libero.it', 612664);
INSERT INTO public.ordinazione VALUES (221, '10:15:00', '2020-08-18', 'luigi.leone@gmail.com', 411971);
INSERT INTO public.ordinazione VALUES (222, '06:00:00', '2020-12-05', 'luca.russo@libero.it', 430270);
INSERT INTO public.ordinazione VALUES (223, '00:30:00', '2020-09-18', 'alessia.rinaldi@libero.it', 411971);
INSERT INTO public.ordinazione VALUES (224, '18:45:00', '2017-01-11', 'diana.franco@hotmail.com', 251670);
INSERT INTO public.ordinazione VALUES (225, '12:15:00', '2018-09-07', 'aurora.amato@hotmail.com', 919477);
INSERT INTO public.ordinazione VALUES (226, '02:30:00', '2020-11-19', 'daniel.marino@hotmail.com', 679996);
INSERT INTO public.ordinazione VALUES (227, '05:45:00', '2019-11-17', 'alessio.caruso@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (228, '16:15:00', '2020-03-29', 'luca.moretti@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (229, '09:15:00', '2020-04-23', 'luigi.mariani@libero.it', 996539);
INSERT INTO public.ordinazione VALUES (230, '06:15:00', '2018-08-09', 'luca.romano@libero.it', 799377);
INSERT INTO public.ordinazione VALUES (231, '21:45:00', '2020-10-15', 'luigi.esposito@hotmail.com', 612664);
INSERT INTO public.ordinazione VALUES (232, '03:45:00', '2018-02-04', 'aurora.amato@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (233, '02:45:00', '2020-03-31', 'asia.bruno@hotmail.com', 833706);
INSERT INTO public.ordinazione VALUES (234, '03:15:00', '2017-03-15', 'michele.mancini@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (235, '07:45:00', '2020-10-01', 'ambra.villa@gmail.com', 134524);
INSERT INTO public.ordinazione VALUES (236, '22:15:00', '2017-11-21', 'margherita.conti@gmail.com', 117471);
INSERT INTO public.ordinazione VALUES (237, '06:30:00', '2019-12-08', 'diana.villa@gmail.com', 234987);
INSERT INTO public.ordinazione VALUES (238, '17:00:00', '2018-02-05', 'miriam.gallo@gmail.com', 683217);
INSERT INTO public.ordinazione VALUES (239, '08:15:00', '2017-11-26', 'ettore.caruso@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (240, '04:45:00', '2020-01-20', 'manuel.conti@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (241, '03:15:00', '2018-10-15', 'asia.bruno@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (242, '05:45:00', '2021-05-21', 'anita.moretti@gmail.com', 257567);
INSERT INTO public.ordinazione VALUES (243, '11:45:00', '2018-09-29', 'giorgio.franco@libero.it', 512951);
INSERT INTO public.ordinazione VALUES (244, '06:45:00', '2020-06-07', 'miriam.gallo@gmail.com', 512951);
INSERT INTO public.ordinazione VALUES (245, '22:15:00', '2020-07-01', 'anita.moretti@gmail.com', 116864);
INSERT INTO public.ordinazione VALUES (246, '22:15:00', '2018-10-07', 'luca.russo@libero.it', 833706);
INSERT INTO public.ordinazione VALUES (247, '14:00:00', '2018-06-16', 'thomas.esposito@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (248, '07:15:00', '2017-01-18', 'alessia.villa@libero.it', 422047);
INSERT INTO public.ordinazione VALUES (249, '15:00:00', '2019-05-27', 'cecilia.ferrara@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (250, '04:15:00', '2019-08-28', 'anita.moretti@gmail.com', 255348);
INSERT INTO public.ordinazione VALUES (251, '17:30:00', '2020-02-01', 'damiano.rossi@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (252, '07:15:00', '2018-08-30', 'luca.moretti@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (253, '11:00:00', '2018-12-12', 'luigi.leone@gmail.com', 683217);
INSERT INTO public.ordinazione VALUES (254, '21:30:00', '2019-04-07', 'maria.ricci@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (255, '10:45:00', '2019-05-30', 'anita.martino@libero.it', 227297);
INSERT INTO public.ordinazione VALUES (256, '09:00:00', '2013-01-09', 'thomas.esposito@libero.it', 430270);
INSERT INTO public.ordinazione VALUES (257, '06:15:00', '2013-11-23', 'marta.marino@gmail.com', 657146);
INSERT INTO public.ordinazione VALUES (258, '18:30:00', '2020-02-19', 'ambra.franco@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (259, '14:15:00', '2020-10-19', 'thomas.franco@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (260, '14:00:00', '2012-04-04', 'alessia.villa@libero.it', 310509);
INSERT INTO public.ordinazione VALUES (261, '01:15:00', '2011-07-05', 'miriam.gallo@gmail.com', 986206);
INSERT INTO public.ordinazione VALUES (262, '10:15:00', '2012-04-22', 'liam.fontana@hotmail.com', 244945);
INSERT INTO public.ordinazione VALUES (263, '13:15:00', '2013-07-30', 'gioia.gallo@hotmail.com', 134524);
INSERT INTO public.ordinazione VALUES (264, '19:00:00', '2011-01-24', 'miriam.gallo@gmail.com', 426189);
INSERT INTO public.ordinazione VALUES (265, '00:45:00', '2019-11-02', 'asia.villa@libero.it', 496038);
INSERT INTO public.ordinazione VALUES (266, '09:00:00', '2020-12-12', 'ambra.villa@gmail.com', 180811);
INSERT INTO public.ordinazione VALUES (267, '04:45:00', '2020-07-23', 'amelia.fontana@libero.it', 116864);
INSERT INTO public.ordinazione VALUES (268, '22:45:00', '2012-04-09', 'marta.marino@gmail.com', 310509);
INSERT INTO public.ordinazione VALUES (269, '20:15:00', '2013-09-18', 'ambra.franco@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (270, '12:30:00', '2020-02-14', 'alessio.caruso@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (271, '10:00:00', '2012-10-18', 'giorgio.franco@libero.it', 833706);
INSERT INTO public.ordinazione VALUES (272, '03:30:00', '2019-09-27', 'ambra.villa@gmail.com', 117471);
INSERT INTO public.ordinazione VALUES (273, '01:15:00', '2020-12-08', 'maria.ricci@libero.it', 712187);
INSERT INTO public.ordinazione VALUES (274, '05:30:00', '2020-12-03', 'luca.moretti@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (275, '23:30:00', '2021-01-15', 'jacopo.barbieri@libero.it', 610737);
INSERT INTO public.ordinazione VALUES (276, '13:00:00', '2013-09-13', 'noah.villa@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (277, '09:30:00', '2020-12-16', 'asia.villa@libero.it', 519828);
INSERT INTO public.ordinazione VALUES (278, '18:45:00', '2020-02-20', 'alessio.caruso@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (279, '10:45:00', '2019-11-03', 'alessia.villa@libero.it', 417960);
INSERT INTO public.ordinazione VALUES (280, '14:00:00', '2020-04-18', 'luca.romano@libero.it', 757956);
INSERT INTO public.ordinazione VALUES (281, '17:00:00', '2013-07-30', 'giorgio.franco@libero.it', 542541);
INSERT INTO public.ordinazione VALUES (282, '18:30:00', '2011-12-03', 'marta.marino@gmail.com', 657146);
INSERT INTO public.ordinazione VALUES (283, '22:30:00', '2011-01-14', 'anita.fratelli@gmail.com', 263691);
INSERT INTO public.ordinazione VALUES (284, '21:15:00', '2020-04-10', 'luigi.esposito@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (285, '05:45:00', '2021-06-18', 'diletta.amato@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (286, '23:45:00', '2011-11-10', 'michele.mancini@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (287, '23:45:00', '2011-09-24', 'amelia.fontana@libero.it', 417960);
INSERT INTO public.ordinazione VALUES (288, '05:15:00', '2011-04-13', 'michele.mancini@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (289, '22:45:00', '2022-03-26', 'luca.russo@libero.it', 657146);
INSERT INTO public.ordinazione VALUES (290, '13:30:00', '2018-10-29', 'asia.bruno@hotmail.com', 263691);
INSERT INTO public.ordinazione VALUES (291, '16:15:00', '2018-10-20', 'luigi.leone@gmail.com', 496038);
INSERT INTO public.ordinazione VALUES (292, '00:00:00', '2020-02-03', 'margherita.conti@gmail.com', 757956);
INSERT INTO public.ordinazione VALUES (293, '23:45:00', '2020-01-14', 'carlotta.rinaldi@hotmail.com', 751144);
INSERT INTO public.ordinazione VALUES (294, '19:00:00', '2020-03-09', 'thomas.esposito@libero.it', 542541);
INSERT INTO public.ordinazione VALUES (295, '06:00:00', '2010-04-02', 'michele.mancini@libero.it', 134524);
INSERT INTO public.ordinazione VALUES (296, '18:00:00', '2011-01-15', 'daniele.moretti@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (297, '01:15:00', '2010-05-02', 'marta.marino@gmail.com', 909700);
INSERT INTO public.ordinazione VALUES (298, '16:30:00', '2010-02-14', 'anita.fratelli@gmail.com', 116864);
INSERT INTO public.ordinazione VALUES (299, '17:15:00', '2021-10-17', 'amelia.fontana@libero.it', 747704);
INSERT INTO public.ordinazione VALUES (300, '04:30:00', '2020-05-09', 'diana.villa@gmail.com', 281631);
INSERT INTO public.ordinazione VALUES (301, '23:15:00', '2018-04-07', 'nathan.franco@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (302, '09:45:00', '2020-07-23', 'nathan.franco@hotmail.com', 426189);
INSERT INTO public.ordinazione VALUES (303, '09:15:00', '2018-03-05', 'daniel.marino@hotmail.com', 512951);
INSERT INTO public.ordinazione VALUES (304, '13:45:00', '2019-11-03', 'liam.fontana@hotmail.com', 426189);
INSERT INTO public.ordinazione VALUES (305, '20:00:00', '2019-11-20', 'luca.russo@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (306, '06:30:00', '2020-11-02', 'nicola.giordano@hotmail.com', 909700);
INSERT INTO public.ordinazione VALUES (307, '15:30:00', '2021-11-29', 'diana.franco@hotmail.com', 964901);
INSERT INTO public.ordinazione VALUES (308, '19:45:00', '2019-09-30', 'manuel.conti@hotmail.com', 986206);
INSERT INTO public.ordinazione VALUES (309, '00:00:00', '2021-10-11', 'cecilia.ferrara@libero.it', 153362);
INSERT INTO public.ordinazione VALUES (310, '21:00:00', '2019-02-23', 'maria.ricci@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (311, '22:15:00', '2019-10-27', 'maria.ricci@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (312, '11:00:00', '2020-01-20', 'daniele.moretti@hotmail.com', 244945);
INSERT INTO public.ordinazione VALUES (313, '08:00:00', '2022-12-14', 'anita.martino@libero.it', 828852);
INSERT INTO public.ordinazione VALUES (314, '20:00:00', '2020-04-11', 'diana.villa@gmail.com', 610737);
INSERT INTO public.ordinazione VALUES (315, '03:45:00', '2013-01-29', 'marta.marino@gmail.com', 422047);
INSERT INTO public.ordinazione VALUES (316, '04:30:00', '2021-03-14', 'cecilia.ferrara@libero.it', 828852);
INSERT INTO public.ordinazione VALUES (317, '10:15:00', '2020-08-12', 'luca.russo@libero.it', 281631);
INSERT INTO public.ordinazione VALUES (318, '13:15:00', '2021-02-21', 'francesca.rizzo@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (319, '23:45:00', '2015-04-11', 'luigi.esposito@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (320, '03:15:00', '2012-08-08', 'cecilia.ferrara@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (321, '04:00:00', '2017-01-01', 'liam.fontana@hotmail.com', 310935);
INSERT INTO public.ordinazione VALUES (322, '17:45:00', '2010-09-28', 'ambra.villa@gmail.com', 612664);
INSERT INTO public.ordinazione VALUES (323, '22:00:00', '2021-05-26', 'amelia.fontana@libero.it', 496038);
INSERT INTO public.ordinazione VALUES (324, '14:00:00', '2017-12-20', 'luca.moretti@hotmail.com', 757956);
INSERT INTO public.ordinazione VALUES (325, '03:45:00', '2010-08-09', 'margherita.conti@gmail.com', 153362);
INSERT INTO public.ordinazione VALUES (326, '06:15:00', '2016-09-28', 'diletta.amato@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (327, '04:00:00', '2021-01-27', 'ettore.caruso@hotmail.com', 747704);
INSERT INTO public.ordinazione VALUES (328, '11:00:00', '2010-07-15', 'giorgio.franco@libero.it', 512951);
INSERT INTO public.ordinazione VALUES (329, '03:30:00', '2010-08-22', 'jacopo.barbieri@libero.it', 180811);
INSERT INTO public.ordinazione VALUES (330, '16:45:00', '2015-03-20', 'alessio.caruso@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (331, '00:15:00', '2010-02-09', 'diana.villa@gmail.com', 257567);
INSERT INTO public.ordinazione VALUES (332, '17:45:00', '2018-08-04', 'alessia.rinaldi@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (333, '18:00:00', '2010-02-20', 'francesca.bruno@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (334, '00:30:00', '2010-02-16', 'damiano.rossi@libero.it', 310509);
INSERT INTO public.ordinazione VALUES (335, '23:00:00', '2016-01-25', 'luca.moretti@hotmail.com', 426189);
INSERT INTO public.ordinazione VALUES (336, '05:15:00', '2011-04-01', 'luigi.mariani@libero.it', 209713);
INSERT INTO public.ordinazione VALUES (337, '03:30:00', '2011-07-30', 'asia.bruno@hotmail.com', 751144);
INSERT INTO public.ordinazione VALUES (338, '12:15:00', '2010-11-12', 'amelia.fontana@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (339, '12:30:00', '2021-03-21', 'luca.romano@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (340, '18:00:00', '2020-01-14', 'carlotta.rinaldi@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (341, '16:15:00', '2015-05-13', 'ambra.villa@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (342, '00:45:00', '2010-12-05', 'nathan.barbieri@gmail.com', 683217);
INSERT INTO public.ordinazione VALUES (343, '00:45:00', '2010-02-28', 'carlotta.rinaldi@hotmail.com', 833706);
INSERT INTO public.ordinazione VALUES (344, '07:45:00', '2010-02-06', 'luigi.leone@gmail.com', 234987);
INSERT INTO public.ordinazione VALUES (345, '04:30:00', '2020-08-04', 'francesca.rizzo@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (346, '21:30:00', '2021-06-10', 'luca.moretti@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (347, '15:30:00', '2022-10-08', 'manuel.conti@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (348, '21:15:00', '2022-08-28', 'amelia.fontana@libero.it', 227297);
INSERT INTO public.ordinazione VALUES (349, '07:45:00', '2020-06-16', 'asia.villa@libero.it', 519828);
INSERT INTO public.ordinazione VALUES (350, '01:30:00', '2020-04-04', 'marta.marino@gmail.com', 833706);
INSERT INTO public.ordinazione VALUES (351, '05:00:00', '2020-02-04', 'margherita.conti@gmail.com', 996539);
INSERT INTO public.ordinazione VALUES (352, '23:15:00', '2019-07-21', 'diletta.amato@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (353, '22:00:00', '2020-03-05', 'ambra.villa@gmail.com', 542541);
INSERT INTO public.ordinazione VALUES (354, '03:00:00', '2021-12-24', 'michele.mancini@libero.it', 683217);
INSERT INTO public.ordinazione VALUES (355, '04:30:00', '2018-02-24', 'gioia.gallo@hotmail.com', 833706);
INSERT INTO public.ordinazione VALUES (356, '15:30:00', '2019-09-22', 'nina.leone@hotmail.com', 116864);
INSERT INTO public.ordinazione VALUES (357, '19:30:00', '2022-11-20', 'ambra.villa@gmail.com', 244945);
INSERT INTO public.ordinazione VALUES (358, '15:45:00', '2019-07-29', 'nathan.franco@hotmail.com', 757956);
INSERT INTO public.ordinazione VALUES (359, '23:30:00', '2020-08-13', 'thomas.franco@hotmail.com', 757956);
INSERT INTO public.ordinazione VALUES (360, '05:30:00', '2020-06-25', 'marco.russo@gmail.com', 209713);
INSERT INTO public.ordinazione VALUES (361, '01:30:00', '2021-08-02', 'cecilia.ferrara@libero.it', 255348);
INSERT INTO public.ordinazione VALUES (362, '13:00:00', '2020-04-05', 'anita.martino@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (363, '21:15:00', '2018-11-30', 'nathan.franco@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (364, '22:45:00', '2021-01-27', 'ambra.villa@gmail.com', 778837);
INSERT INTO public.ordinazione VALUES (365, '04:30:00', '2019-08-15', 'anita.martino@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (366, '19:30:00', '2020-12-07', 'francesca.rizzo@hotmail.com', 132366);
INSERT INTO public.ordinazione VALUES (367, '17:45:00', '2018-08-14', 'thomas.franco@hotmail.com', 512951);
INSERT INTO public.ordinazione VALUES (368, '07:00:00', '2019-05-06', 'ambra.villa@gmail.com', 598983);
INSERT INTO public.ordinazione VALUES (369, '17:45:00', '2022-07-29', 'daniele.moretti@hotmail.com', 612664);
INSERT INTO public.ordinazione VALUES (370, '10:30:00', '2017-12-08', 'elia.conti@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (371, '19:15:00', '2019-10-15', 'alessio.caruso@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (372, '12:15:00', '2020-01-04', 'ambra.villa@gmail.com', 153362);
INSERT INTO public.ordinazione VALUES (373, '22:00:00', '2017-04-22', 'giorgio.franco@libero.it', 430270);
INSERT INTO public.ordinazione VALUES (374, '04:00:00', '2020-03-16', 'luca.romano@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (375, '18:00:00', '2018-03-20', 'nicola.giordano@hotmail.com', 117471);
INSERT INTO public.ordinazione VALUES (376, '20:30:00', '2019-08-18', 'daniel.marino@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (377, '10:30:00', '2019-12-04', 'thomas.esposito@libero.it', 310935);
INSERT INTO public.ordinazione VALUES (378, '18:30:00', '2018-09-21', 'ambra.villa@hotmail.com', 833706);
INSERT INTO public.ordinazione VALUES (379, '19:45:00', '2020-06-13', 'ambra.villa@hotmail.com', 909700);
INSERT INTO public.ordinazione VALUES (380, '04:45:00', '2019-05-31', 'francesca.bruno@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (381, '14:30:00', '2019-08-13', 'nina.leone@hotmail.com', 986206);
INSERT INTO public.ordinazione VALUES (382, '02:30:00', '2021-12-29', 'damiano.rossi@libero.it', 227297);
INSERT INTO public.ordinazione VALUES (383, '01:00:00', '2018-07-31', 'luca.russo@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (384, '13:00:00', '2019-02-06', 'jacopo.barbieri@libero.it', 263691);
INSERT INTO public.ordinazione VALUES (385, '07:00:00', '2020-08-01', 'nathan.barbieri@gmail.com', 153362);
INSERT INTO public.ordinazione VALUES (386, '20:15:00', '2020-08-04', 'luca.russo@libero.it', 281631);
INSERT INTO public.ordinazione VALUES (387, '13:30:00', '2017-11-01', 'nicola.giordano@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (388, '21:15:00', '2017-10-19', 'noah.villa@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (389, '10:00:00', '2018-09-11', 'ambra.villa@gmail.com', 610737);
INSERT INTO public.ordinazione VALUES (390, '00:00:00', '2020-08-25', 'anita.martino@libero.it', 833706);
INSERT INTO public.ordinazione VALUES (391, '23:45:00', '2019-04-26', 'damiano.rossi@libero.it', 116864);
INSERT INTO public.ordinazione VALUES (392, '05:15:00', '2020-02-15', 'asia.villa@libero.it', 679996);
INSERT INTO public.ordinazione VALUES (393, '13:15:00', '2018-01-27', 'thomas.franco@hotmail.com', 462956);
INSERT INTO public.ordinazione VALUES (394, '17:45:00', '2019-02-11', 'miriam.gallo@gmail.com', 263691);
INSERT INTO public.ordinazione VALUES (395, '18:00:00', '2019-09-21', 'luca.russo@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (396, '02:45:00', '2019-06-10', 'alessio.caruso@hotmail.com', 542541);
INSERT INTO public.ordinazione VALUES (397, '15:00:00', '2021-01-04', 'luca.russo@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (398, '19:30:00', '2020-12-22', 'alessia.villa@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (399, '22:00:00', '2020-12-17', 'carlotta.rinaldi@hotmail.com', 747704);
INSERT INTO public.ordinazione VALUES (400, '22:45:00', '2020-04-20', 'anita.fratelli@gmail.com', 153362);
INSERT INTO public.ordinazione VALUES (401, '06:30:00', '2020-01-21', 'ambra.villa@hotmail.com', 935000);
INSERT INTO public.ordinazione VALUES (402, '18:45:00', '2018-06-16', 'marta.marino@gmail.com', 251670);
INSERT INTO public.ordinazione VALUES (403, '09:45:00', '2020-04-28', 'asia.bruno@hotmail.com', 462956);
INSERT INTO public.ordinazione VALUES (404, '10:15:00', '2020-10-15', 'luigi.esposito@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (405, '13:00:00', '2021-01-02', 'alessia.villa@libero.it', 426189);
INSERT INTO public.ordinazione VALUES (406, '09:45:00', '2019-06-09', 'carlotta.rinaldi@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (407, '06:45:00', '2020-11-05', 'luigi.mariani@libero.it', 610737);
INSERT INTO public.ordinazione VALUES (408, '08:45:00', '2017-07-31', 'nina.leone@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (409, '20:30:00', '2018-01-20', 'cecilia.ferrara@libero.it', 227297);
INSERT INTO public.ordinazione VALUES (410, '18:45:00', '2019-03-26', 'marta.marino@gmail.com', 964901);
INSERT INTO public.ordinazione VALUES (411, '05:45:00', '2020-05-21', 'daniele.moretti@hotmail.com', 251670);
INSERT INTO public.ordinazione VALUES (412, '23:00:00', '2018-12-10', 'ambra.villa@hotmail.com', 244945);
INSERT INTO public.ordinazione VALUES (413, '10:15:00', '2021-03-05', 'francesca.rizzo@hotmail.com', 964901);
INSERT INTO public.ordinazione VALUES (414, '16:15:00', '2019-08-05', 'jacopo.barbieri@libero.it', 519828);
INSERT INTO public.ordinazione VALUES (415, '11:00:00', '2018-03-28', 'anita.martino@libero.it', 542541);
INSERT INTO public.ordinazione VALUES (416, '04:45:00', '2021-09-01', 'miriam.gallo@gmail.com', 751144);
INSERT INTO public.ordinazione VALUES (417, '09:45:00', '2018-01-22', 'luca.russo@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (418, '07:30:00', '2020-03-10', 'diana.franco@hotmail.com', 986206);
INSERT INTO public.ordinazione VALUES (419, '18:45:00', '2019-03-25', 'francesca.bruno@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (420, '05:30:00', '2018-03-23', 'elia.conti@hotmail.com', 679996);
INSERT INTO public.ordinazione VALUES (421, '22:00:00', '2018-09-12', 'nicola.giordano@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (422, '14:15:00', '2019-03-27', 'nicola.giordano@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (423, '20:15:00', '2018-02-23', 'anita.moretti@gmail.com', 257567);
INSERT INTO public.ordinazione VALUES (424, '05:15:00', '2020-04-30', 'margherita.conti@gmail.com', 598983);
INSERT INTO public.ordinazione VALUES (425, '15:45:00', '2020-07-03', 'alessia.rinaldi@libero.it', 502650);
INSERT INTO public.ordinazione VALUES (426, '00:45:00', '2017-12-11', 'marta.marino@gmail.com', 263691);
INSERT INTO public.ordinazione VALUES (427, '16:15:00', '2019-03-26', 'gioia.gallo@hotmail.com', 986206);
INSERT INTO public.ordinazione VALUES (428, '18:00:00', '2020-01-09', 'jacopo.barbieri@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (429, '05:15:00', '2018-09-04', 'aurora.amato@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (430, '18:15:00', '2018-06-24', 'thomas.esposito@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (431, '12:30:00', '2019-01-14', 'anita.fratelli@gmail.com', 244945);
INSERT INTO public.ordinazione VALUES (432, '00:00:00', '2021-05-08', 'daniel.marino@hotmail.com', 117471);
INSERT INTO public.ordinazione VALUES (433, '03:30:00', '2020-08-30', 'elia.conti@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (434, '23:30:00', '2018-10-01', 'luca.romano@libero.it', 679996);
INSERT INTO public.ordinazione VALUES (435, '10:45:00', '2020-02-04', 'alessio.caruso@hotmail.com', 610737);
INSERT INTO public.ordinazione VALUES (436, '17:00:00', '2020-05-17', 'luca.moretti@hotmail.com', 657146);
INSERT INTO public.ordinazione VALUES (437, '02:15:00', '2021-04-11', 'nathan.barbieri@gmail.com', 751144);
INSERT INTO public.ordinazione VALUES (438, '18:45:00', '2020-10-20', 'diletta.amato@hotmail.com', 610737);
INSERT INTO public.ordinazione VALUES (439, '13:15:00', '2020-07-24', 'ambra.villa@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (440, '04:15:00', '2018-03-22', 'francesca.bruno@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (441, '10:45:00', '2020-07-14', 'alessia.rinaldi@libero.it', 748162);
INSERT INTO public.ordinazione VALUES (442, '19:45:00', '2019-04-30', 'anita.fratelli@gmail.com', 919477);
INSERT INTO public.ordinazione VALUES (443, '00:45:00', '2020-03-15', 'elena.ferrara@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (444, '05:45:00', '2018-05-12', 'cecilia.ferrara@libero.it', 117471);
INSERT INTO public.ordinazione VALUES (445, '16:15:00', '2019-11-09', 'asia.villa@libero.it', 598983);
INSERT INTO public.ordinazione VALUES (446, '09:45:00', '2018-04-05', 'diana.villa@gmail.com', 712187);
INSERT INTO public.ordinazione VALUES (447, '22:45:00', '2019-07-30', 'alessio.caruso@hotmail.com', 251670);
INSERT INTO public.ordinazione VALUES (448, '06:15:00', '2021-06-16', 'marta.marino@gmail.com', 799377);
INSERT INTO public.ordinazione VALUES (449, '15:45:00', '2018-01-07', 'francesca.rizzo@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (450, '15:30:00', '2019-09-13', 'nathan.barbieri@gmail.com', 935000);
INSERT INTO public.ordinazione VALUES (451, '20:45:00', '2020-03-18', 'daniele.moretti@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (452, '22:30:00', '2019-05-25', 'aurora.amato@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (453, '20:45:00', '2022-11-21', 'francesca.rizzo@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (454, '20:00:00', '2019-11-06', 'daniele.moretti@hotmail.com', 310935);
INSERT INTO public.ordinazione VALUES (455, '22:15:00', '2019-05-30', 'nathan.franco@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (456, '03:30:00', '2019-07-01', 'gioia.gallo@hotmail.com', 310935);
INSERT INTO public.ordinazione VALUES (457, '07:15:00', '2022-02-07', 'giorgio.franco@libero.it', 117471);
INSERT INTO public.ordinazione VALUES (458, '18:30:00', '2020-02-13', 'luca.moretti@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (459, '23:15:00', '2020-08-19', 'michele.mancini@libero.it', 134524);
INSERT INTO public.ordinazione VALUES (460, '11:45:00', '2019-01-21', 'giorgio.franco@libero.it', 257567);
INSERT INTO public.ordinazione VALUES (461, '23:00:00', '2021-12-28', 'francesca.bruno@libero.it', 180811);
INSERT INTO public.ordinazione VALUES (462, '14:00:00', '2020-08-01', 'damiano.rossi@libero.it', 422047);
INSERT INTO public.ordinazione VALUES (463, '19:15:00', '2020-10-20', 'luca.russo@libero.it', 134524);
INSERT INTO public.ordinazione VALUES (464, '07:30:00', '2019-02-12', 'manuel.conti@hotmail.com', 411971);
INSERT INTO public.ordinazione VALUES (465, '01:30:00', '2020-01-22', 'luca.romano@libero.it', 496038);
INSERT INTO public.ordinazione VALUES (466, '02:45:00', '2019-05-06', 'luca.russo@libero.it', 799377);
INSERT INTO public.ordinazione VALUES (467, '08:30:00', '2020-01-30', 'daniel.marino@hotmail.com', 519828);
INSERT INTO public.ordinazione VALUES (468, '00:45:00', '2020-12-14', 'luca.romano@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (469, '00:45:00', '2019-11-27', 'thomas.esposito@libero.it', 234987);
INSERT INTO public.ordinazione VALUES (470, '23:45:00', '2018-12-13', 'luca.russo@libero.it', 502650);
INSERT INTO public.ordinazione VALUES (471, '20:00:00', '2020-03-08', 'luigi.leone@gmail.com', 964901);
INSERT INTO public.ordinazione VALUES (472, '03:45:00', '2021-01-23', 'marta.marino@gmail.com', 833706);
INSERT INTO public.ordinazione VALUES (473, '02:15:00', '2020-09-09', 'liam.fontana@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (474, '12:00:00', '2019-05-10', 'luigi.esposito@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (475, '09:45:00', '2022-10-01', 'luca.moretti@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (476, '11:30:00', '2011-06-21', 'maria.ricci@libero.it', 502650);
INSERT INTO public.ordinazione VALUES (477, '15:00:00', '2020-02-21', 'ambra.villa@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (478, '15:45:00', '2018-06-20', 'noah.villa@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (479, '01:15:00', '2020-09-29', 'aurora.amato@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (480, '05:30:00', '2019-02-16', 'luca.romano@libero.it', 234987);
INSERT INTO public.ordinazione VALUES (481, '21:45:00', '2021-05-12', 'francesca.bruno@libero.it', 430270);
INSERT INTO public.ordinazione VALUES (482, '08:15:00', '2019-05-29', 'nina.leone@hotmail.com', 244945);
INSERT INTO public.ordinazione VALUES (483, '06:15:00', '2020-01-03', 'luca.romano@libero.it', 310935);
INSERT INTO public.ordinazione VALUES (484, '03:15:00', '2020-05-23', 'maria.ricci@libero.it', 422047);
INSERT INTO public.ordinazione VALUES (485, '22:00:00', '2019-03-18', 'daniele.moretti@hotmail.com', 935000);
INSERT INTO public.ordinazione VALUES (486, '19:45:00', '2018-10-12', 'anita.moretti@gmail.com', 502650);
INSERT INTO public.ordinazione VALUES (487, '03:30:00', '2020-07-28', 'daniele.moretti@hotmail.com', 330511);
INSERT INTO public.ordinazione VALUES (488, '06:15:00', '2018-10-22', 'ambra.villa@hotmail.com', 799377);
INSERT INTO public.ordinazione VALUES (489, '08:00:00', '2021-04-02', 'ettore.caruso@hotmail.com', 512951);
INSERT INTO public.ordinazione VALUES (490, '03:15:00', '2021-01-11', 'francesca.rizzo@hotmail.com', 612664);
INSERT INTO public.ordinazione VALUES (491, '09:45:00', '2021-10-01', 'luca.russo@libero.it', 116864);
INSERT INTO public.ordinazione VALUES (492, '23:00:00', '2020-04-19', 'nina.leone@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (493, '20:00:00', '2019-02-15', 'liam.fontana@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (494, '22:15:00', '2022-12-24', 'anita.fratelli@gmail.com', 134524);
INSERT INTO public.ordinazione VALUES (495, '04:15:00', '2019-06-05', 'alessia.rinaldi@libero.it', 116864);
INSERT INTO public.ordinazione VALUES (496, '01:30:00', '2018-05-27', 'asia.bruno@hotmail.com', 542541);
INSERT INTO public.ordinazione VALUES (497, '14:15:00', '2019-08-24', 'luca.moretti@hotmail.com', 828852);
INSERT INTO public.ordinazione VALUES (498, '07:30:00', '2021-08-28', 'nathan.barbieri@gmail.com', 227297);
INSERT INTO public.ordinazione VALUES (499, '04:45:00', '2020-03-19', 'diletta.amato@hotmail.com', 747704);
INSERT INTO public.ordinazione VALUES (500, '20:00:00', '2018-05-27', 'thomas.esposito@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (501, '07:30:00', '2020-03-08', 'diana.franco@hotmail.com', 153362);
INSERT INTO public.ordinazione VALUES (502, '14:15:00', '2019-07-14', 'francesca.rizzo@hotmail.com', 117471);
INSERT INTO public.ordinazione VALUES (503, '14:30:00', '2022-12-01', 'anita.fratelli@gmail.com', 244945);
INSERT INTO public.ordinazione VALUES (504, '11:00:00', '2018-07-15', 'gioia.gallo@hotmail.com', 512951);
INSERT INTO public.ordinazione VALUES (505, '18:00:00', '2022-12-10', 'luca.moretti@hotmail.com', 683217);
INSERT INTO public.ordinazione VALUES (506, '00:00:00', '2021-11-05', 'amelia.fontana@libero.it', 964901);
INSERT INTO public.ordinazione VALUES (507, '01:15:00', '2018-04-08', 'aurora.amato@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (508, '18:00:00', '2021-06-28', 'diletta.amato@hotmail.com', 610737);
INSERT INTO public.ordinazione VALUES (509, '20:00:00', '2022-11-23', 'francesca.rizzo@hotmail.com', 964901);
INSERT INTO public.ordinazione VALUES (510, '02:45:00', '2018-05-17', 'elia.conti@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (511, '00:15:00', '2021-09-16', 'francesca.bruno@libero.it', 263691);
INSERT INTO public.ordinazione VALUES (512, '21:15:00', '2018-08-10', 'elena.ferrara@gmail.com', 919477);
INSERT INTO public.ordinazione VALUES (513, '05:15:00', '2019-01-23', 'damiano.rossi@libero.it', 417960);
INSERT INTO public.ordinazione VALUES (514, '04:45:00', '2021-09-07', 'liam.fontana@hotmail.com', 748162);
INSERT INTO public.ordinazione VALUES (515, '18:30:00', '2018-08-13', 'diana.franco@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (516, '10:45:00', '2020-12-25', 'damiano.rossi@libero.it', 263691);
INSERT INTO public.ordinazione VALUES (517, '01:00:00', '2018-08-15', 'asia.villa@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (518, '05:15:00', '2019-12-24', 'nina.leone@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (519, '03:30:00', '2020-01-29', 'luca.romano@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (520, '00:00:00', '2020-04-10', 'alessio.caruso@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (521, '03:30:00', '2020-09-07', 'diana.villa@gmail.com', 683217);
INSERT INTO public.ordinazione VALUES (522, '16:15:00', '2018-05-02', 'luca.moretti@hotmail.com', 263691);
INSERT INTO public.ordinazione VALUES (523, '07:30:00', '2019-04-11', 'miriam.gallo@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (524, '09:45:00', '2019-08-20', 'luca.romano@libero.it', 330511);
INSERT INTO public.ordinazione VALUES (525, '13:45:00', '2019-05-23', 'asia.bruno@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (526, '13:30:00', '2021-11-19', 'nathan.barbieri@gmail.com', 519828);
INSERT INTO public.ordinazione VALUES (527, '11:00:00', '2021-06-19', 'thomas.franco@hotmail.com', 209713);
INSERT INTO public.ordinazione VALUES (528, '15:30:00', '2019-03-08', 'miriam.gallo@gmail.com', 257567);
INSERT INTO public.ordinazione VALUES (529, '19:00:00', '2019-10-23', 'liam.fontana@hotmail.com', 679996);
INSERT INTO public.ordinazione VALUES (530, '00:00:00', '2017-06-27', 'margherita.conti@gmail.com', 612664);
INSERT INTO public.ordinazione VALUES (531, '08:15:00', '2017-03-31', 'alessio.caruso@hotmail.com', 251670);
INSERT INTO public.ordinazione VALUES (532, '00:30:00', '2017-06-06', 'ambra.villa@gmail.com', 411971);
INSERT INTO public.ordinazione VALUES (533, '09:00:00', '2019-10-27', 'marta.marino@gmail.com', 255348);
INSERT INTO public.ordinazione VALUES (534, '12:30:00', '2017-03-29', 'giorgio.franco@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (535, '03:30:00', '2018-07-30', 'luigi.esposito@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (536, '08:00:00', '2019-03-28', 'luigi.mariani@libero.it', 909700);
INSERT INTO public.ordinazione VALUES (537, '11:00:00', '2018-08-23', 'luca.moretti@hotmail.com', 935000);
INSERT INTO public.ordinazione VALUES (538, '05:15:00', '2018-08-07', 'margherita.conti@gmail.com', 502650);
INSERT INTO public.ordinazione VALUES (539, '06:30:00', '2021-06-13', 'elena.ferrara@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (540, '02:15:00', '2020-06-05', 'thomas.esposito@libero.it', 919477);
INSERT INTO public.ordinazione VALUES (541, '18:00:00', '2021-08-21', 'alessia.rinaldi@libero.it', 778837);
INSERT INTO public.ordinazione VALUES (542, '18:30:00', '2019-06-06', 'ambra.villa@gmail.com', 919477);
INSERT INTO public.ordinazione VALUES (543, '06:15:00', '2019-04-28', 'thomas.franco@hotmail.com', 417960);
INSERT INTO public.ordinazione VALUES (544, '23:45:00', '2018-05-18', 'luigi.mariani@libero.it', 117471);
INSERT INTO public.ordinazione VALUES (545, '03:45:00', '2018-09-23', 'nathan.franco@hotmail.com', 234987);
INSERT INTO public.ordinazione VALUES (546, '16:30:00', '2021-03-09', 'luigi.mariani@libero.it', 996539);
INSERT INTO public.ordinazione VALUES (547, '08:15:00', '2020-11-23', 'marta.marino@gmail.com', 117471);
INSERT INTO public.ordinazione VALUES (548, '04:45:00', '2021-08-04', 'margherita.conti@gmail.com', 244945);
INSERT INTO public.ordinazione VALUES (549, '10:45:00', '2018-09-13', 'jacopo.barbieri@libero.it', 180811);
INSERT INTO public.ordinazione VALUES (550, '09:30:00', '2019-04-26', 'nathan.barbieri@gmail.com', 310935);
INSERT INTO public.ordinazione VALUES (551, '19:45:00', '2020-02-08', 'gioia.gallo@hotmail.com', 919477);
INSERT INTO public.ordinazione VALUES (552, '10:45:00', '2017-12-18', 'thomas.esposito@libero.it', 909700);
INSERT INTO public.ordinazione VALUES (553, '11:30:00', '2019-04-25', 'daniele.moretti@hotmail.com', 542541);
INSERT INTO public.ordinazione VALUES (554, '18:45:00', '2020-04-05', 'diana.franco@hotmail.com', 496038);
INSERT INTO public.ordinazione VALUES (555, '07:15:00', '2018-09-17', 'ambra.villa@hotmail.com', 502650);
INSERT INTO public.ordinazione VALUES (556, '09:45:00', '2020-06-19', 'ambra.franco@libero.it', 209713);
INSERT INTO public.ordinazione VALUES (557, '00:45:00', '2020-10-06', 'maria.ricci@libero.it', 462956);
INSERT INTO public.ordinazione VALUES (558, '08:45:00', '2017-07-21', 'ambra.villa@hotmail.com', 430270);
INSERT INTO public.ordinazione VALUES (559, '18:45:00', '2017-03-27', 'luigi.leone@gmail.com', 909700);
INSERT INTO public.ordinazione VALUES (560, '06:45:00', '2019-04-16', 'francesca.bruno@libero.it', 909700);
INSERT INTO public.ordinazione VALUES (561, '08:45:00', '2021-03-31', 'anita.martino@libero.it', 996539);
INSERT INTO public.ordinazione VALUES (562, '10:15:00', '2019-11-04', 'luca.moretti@hotmail.com', 778837);
INSERT INTO public.ordinazione VALUES (563, '10:45:00', '2019-10-13', 'ettore.caruso@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (564, '02:00:00', '2020-11-17', 'ambra.villa@hotmail.com', 502650);
INSERT INTO public.ordinazione VALUES (565, '03:15:00', '2018-03-12', 'nicola.giordano@hotmail.com', 598983);
INSERT INTO public.ordinazione VALUES (566, '04:00:00', '2020-02-20', 'diana.franco@hotmail.com', 255348);
INSERT INTO public.ordinazione VALUES (567, '21:45:00', '2020-04-13', 'anita.fratelli@gmail.com', 153362);
INSERT INTO public.ordinazione VALUES (568, '16:30:00', '2019-05-17', 'asia.villa@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (569, '04:30:00', '2018-04-29', 'amelia.fontana@libero.it', 612664);
INSERT INTO public.ordinazione VALUES (570, '01:30:00', '2021-12-08', 'margherita.conti@gmail.com', 180811);
INSERT INTO public.ordinazione VALUES (571, '12:15:00', '2017-01-18', 'ettore.caruso@hotmail.com', 799377);
INSERT INTO public.ordinazione VALUES (572, '08:30:00', '2020-04-30', 'luca.moretti@hotmail.com', 430270);
INSERT INTO public.ordinazione VALUES (573, '21:00:00', '2017-09-06', 'nicola.giordano@hotmail.com', 712187);
INSERT INTO public.ordinazione VALUES (574, '04:30:00', '2014-08-15', 'alessia.rinaldi@libero.it', 598983);
INSERT INTO public.ordinazione VALUES (575, '21:00:00', '2015-05-24', 'ambra.villa@gmail.com', 411971);
INSERT INTO public.ordinazione VALUES (576, '03:45:00', '2018-02-10', 'luca.russo@libero.it', 657146);
INSERT INTO public.ordinazione VALUES (577, '16:45:00', '2017-03-22', 'maria.ricci@libero.it', 610737);
INSERT INTO public.ordinazione VALUES (578, '04:15:00', '2020-10-25', 'diana.villa@gmail.com', 612664);
INSERT INTO public.ordinazione VALUES (579, '09:30:00', '2020-08-11', 'anita.martino@libero.it', 799377);
INSERT INTO public.ordinazione VALUES (580, '02:15:00', '2014-08-12', 'alessia.rinaldi@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (581, '10:45:00', '2021-04-30', 'liam.fontana@hotmail.com', 310509);
INSERT INTO public.ordinazione VALUES (582, '20:30:00', '2021-08-03', 'cecilia.ferrara@libero.it', 244945);
INSERT INTO public.ordinazione VALUES (583, '23:15:00', '2020-02-21', 'anita.moretti@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (584, '14:00:00', '2016-02-24', 'elena.ferrara@gmail.com', 134524);
INSERT INTO public.ordinazione VALUES (585, '02:00:00', '2015-09-25', 'jacopo.barbieri@libero.it', 430270);
INSERT INTO public.ordinazione VALUES (586, '05:00:00', '2021-11-21', 'luca.russo@libero.it', 683217);
INSERT INTO public.ordinazione VALUES (587, '07:15:00', '2018-07-25', 'ettore.caruso@hotmail.com', 996539);
INSERT INTO public.ordinazione VALUES (588, '11:15:00', '2019-02-10', 'luca.romano@libero.it', 612664);
INSERT INTO public.ordinazione VALUES (589, '20:45:00', '2020-09-29', 'cecilia.ferrara@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (590, '18:30:00', '2019-03-25', 'ettore.caruso@hotmail.com', 180811);
INSERT INTO public.ordinazione VALUES (591, '01:15:00', '2018-07-26', 'anita.fratelli@gmail.com', 417960);
INSERT INTO public.ordinazione VALUES (592, '18:45:00', '2020-10-27', 'anita.martino@libero.it', 935000);
INSERT INTO public.ordinazione VALUES (593, '05:30:00', '2018-06-20', 'aurora.amato@hotmail.com', 227297);
INSERT INTO public.ordinazione VALUES (594, '20:45:00', '2019-08-10', 'miriam.gallo@gmail.com', 180811);
INSERT INTO public.ordinazione VALUES (595, '10:30:00', '2019-05-22', 'francesca.bruno@libero.it', 134524);
INSERT INTO public.ordinazione VALUES (596, '00:15:00', '2018-07-22', 'liam.fontana@hotmail.com', 422047);
INSERT INTO public.ordinazione VALUES (597, '10:45:00', '2018-03-17', 'ettore.caruso@hotmail.com', 257567);
INSERT INTO public.ordinazione VALUES (598, '03:30:00', '2021-09-15', 'luigi.leone@gmail.com', 778837);
INSERT INTO public.ordinazione VALUES (599, '02:15:00', '2018-06-04', 'amelia.fontana@libero.it', 251670);
INSERT INTO public.ordinazione VALUES (600, '18:45:00', '2021-07-17', 'alessio.caruso@hotmail.com', 610737);
INSERT INTO public.ordinazione VALUES (601, '14:00:00', '2019-12-24', 'francesca.bruno@libero.it', 610737);
INSERT INTO public.ordinazione VALUES (602, '14:00:00', '2019-12-23', 'francesca.bruno@libero.it', 610737);


--
-- TOC entry 3416 (class 0 OID 16675)
-- Dependencies: 221
-- Data for Name: pizza; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.pizza VALUES ('Marinara', true, 3.50);
INSERT INTO public.pizza VALUES ('Margherita', true, 4.00);
INSERT INTO public.pizza VALUES ('Prosciutto', false, 5.00);
INSERT INTO public.pizza VALUES ('Viennese', false, 5.00);
INSERT INTO public.pizza VALUES ('Diavola', false, 5.00);
INSERT INTO public.pizza VALUES ('Napoli', false, 5.00);
INSERT INTO public.pizza VALUES ('Funghi', true, 5.00);
INSERT INTO public.pizza VALUES ('Pugliese', true, 5.00);
INSERT INTO public.pizza VALUES ('Melanzane', true, 5.00);
INSERT INTO public.pizza VALUES ('Zucchine', true, 5.00);
INSERT INTO public.pizza VALUES ('Patatosa', true, 5.50);
INSERT INTO public.pizza VALUES ('Gorgonzola', true, 5.00);
INSERT INTO public.pizza VALUES ('Pomodorini', true, 5.00);
INSERT INTO public.pizza VALUES ('Asparagi', true, 5.00);
INSERT INTO public.pizza VALUES ('Mais', true, 5.00);
INSERT INTO public.pizza VALUES ('Radicchio', true, 5.00);
INSERT INTO public.pizza VALUES ('Salsiccia', false, 5.00);
INSERT INTO public.pizza VALUES ('Ricotta e spinaci', true, 6.00);
INSERT INTO public.pizza VALUES ('Prosciutto e funghi', false, 6.00);
INSERT INTO public.pizza VALUES ('Tonno e cipolla', false, 6.00);
INSERT INTO public.pizza VALUES ('Porchetta', false, 6.00);
INSERT INTO public.pizza VALUES ('Porcini', true, 6.00);
INSERT INTO public.pizza VALUES ('Chiodini', true, 6.00);
INSERT INTO public.pizza VALUES ('Speck', false, 6.00);
INSERT INTO public.pizza VALUES ('Crudo', false, 6.00);
INSERT INTO public.pizza VALUES ('Bresaola', false, 6.00);
INSERT INTO public.pizza VALUES ('Pancetta', false, 6.00);
INSERT INTO public.pizza VALUES ('Wurstel e patatine', false, 6.50);
INSERT INTO public.pizza VALUES ('Capricciosa', false, 6.50);
INSERT INTO public.pizza VALUES ('Quattro stagioni', false, 7.00);
INSERT INTO public.pizza VALUES ('Quattro formaggi', true, 6.50);
INSERT INTO public.pizza VALUES ('Carbonara', false, 7.00);
INSERT INTO public.pizza VALUES ('Parmigiana', false, 7.00);
INSERT INTO public.pizza VALUES ('Sicilia', false, 6.50);
INSERT INTO public.pizza VALUES ('Leggera', true, 6.50);
INSERT INTO public.pizza VALUES ('Delicata', true, 7.00);
INSERT INTO public.pizza VALUES ('Demonio', false, 7.00);
INSERT INTO public.pizza VALUES ('Cortigiana', false, 7.00);
INSERT INTO public.pizza VALUES ('Prosciutto e mais', false, 6.00);
INSERT INTO public.pizza VALUES ('Valtellina', false, 8.00);
INSERT INTO public.pizza VALUES ('Contadina', true, 7.00);
INSERT INTO public.pizza VALUES ('Noci e gorgonzola', true, 6.50);
INSERT INTO public.pizza VALUES ('Brie e speck', false, 6.50);
INSERT INTO public.pizza VALUES ('Cracker', false, 7.00);
INSERT INTO public.pizza VALUES ('Gamberetti', false, 7.00);
INSERT INTO public.pizza VALUES ('Misto mare', false, 8.00);
INSERT INTO public.pizza VALUES ('Hawaiian', true, 12.00);


--
-- TOC entry 3414 (class 0 OID 16654)
-- Dependencies: 219
-- Data for Name: prenota; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.prenota VALUES ('14:00:00', '2019-12-24', 'francesca.bruno@libero.it', 38);
INSERT INTO public.prenota VALUES ('14:00:00', '2019-12-23', 'francesca.bruno@libero.it', 38);
INSERT INTO public.prenota VALUES ('14:00:00', '2019-12-21', 'francesca.bruno@libero.it', 309);
INSERT INTO public.prenota VALUES ('22:15:00', '2020-12-03', 'ambra.villa@gmail.com', 404);
INSERT INTO public.prenota VALUES ('20:45:00', '2017-06-01', 'anita.moretti@gmail.com', 405);
INSERT INTO public.prenota VALUES ('18:00:00', '2017-01-11', 'daniel.marino@hotmail.com', 417);
INSERT INTO public.prenota VALUES ('15:30:00', '2018-09-22', 'miriam.gallo@gmail.com', 452);
INSERT INTO public.prenota VALUES ('17:00:00', '2020-01-27', 'anita.fratelli@gmail.com', 313);
INSERT INTO public.prenota VALUES ('11:45:00', '2019-08-06', 'nathan.franco@hotmail.com', 225);
INSERT INTO public.prenota VALUES ('22:30:00', '2019-11-18', 'carlotta.rinaldi@hotmail.com', 78);
INSERT INTO public.prenota VALUES ('18:00:00', '2018-09-17', 'nina.leone@hotmail.com', 410);
INSERT INTO public.prenota VALUES ('19:15:00', '2019-12-15', 'luca.romano@libero.it', 417);
INSERT INTO public.prenota VALUES ('08:15:00', '2021-03-19', 'jacopo.barbieri@libero.it', 130);
INSERT INTO public.prenota VALUES ('16:30:00', '2017-05-05', 'amelia.fontana@libero.it', 416);
INSERT INTO public.prenota VALUES ('05:00:00', '2019-11-03', 'luca.russo@libero.it', 470);
INSERT INTO public.prenota VALUES ('02:00:00', '2020-07-05', 'marta.marino@gmail.com', 313);
INSERT INTO public.prenota VALUES ('15:45:00', '2019-10-12', 'jacopo.barbieri@libero.it', 277);
INSERT INTO public.prenota VALUES ('02:45:00', '2021-10-05', 'daniel.marino@hotmail.com', 31);
INSERT INTO public.prenota VALUES ('22:45:00', '2018-11-15', 'elia.conti@hotmail.com', 494);
INSERT INTO public.prenota VALUES ('14:30:00', '2018-11-09', 'luca.russo@libero.it', 73);
INSERT INTO public.prenota VALUES ('21:45:00', '2018-09-21', 'ettore.caruso@hotmail.com', 450);
INSERT INTO public.prenota VALUES ('05:45:00', '2020-01-17', 'asia.bruno@hotmail.com', 218);
INSERT INTO public.prenota VALUES ('09:30:00', '2020-10-20', 'asia.bruno@hotmail.com', 286);
INSERT INTO public.prenota VALUES ('00:45:00', '2019-06-13', 'asia.bruno@hotmail.com', 390);
INSERT INTO public.prenota VALUES ('07:15:00', '2016-12-16', 'anita.fratelli@gmail.com', 125);
INSERT INTO public.prenota VALUES ('12:30:00', '2020-02-10', 'marco.russo@gmail.com', 197);
INSERT INTO public.prenota VALUES ('08:15:00', '2022-02-24', 'luca.russo@libero.it', 179);
INSERT INTO public.prenota VALUES ('09:30:00', '2017-05-23', 'thomas.esposito@libero.it', 63);
INSERT INTO public.prenota VALUES ('05:30:00', '2019-12-28', 'cecilia.ferrara@libero.it', 326);
INSERT INTO public.prenota VALUES ('16:00:00', '2019-10-12', 'liam.fontana@hotmail.com', 436);
INSERT INTO public.prenota VALUES ('16:45:00', '2016-12-25', 'marta.marino@gmail.com', 174);
INSERT INTO public.prenota VALUES ('09:15:00', '2022-04-29', 'alessio.caruso@hotmail.com', 51);
INSERT INTO public.prenota VALUES ('12:30:00', '2021-04-20', 'marta.marino@gmail.com', 209);
INSERT INTO public.prenota VALUES ('18:15:00', '2020-06-02', 'nathan.barbieri@gmail.com', 96);
INSERT INTO public.prenota VALUES ('12:30:00', '2021-04-30', 'elia.conti@hotmail.com', 31);
INSERT INTO public.prenota VALUES ('11:45:00', '2021-10-04', 'alessia.rinaldi@libero.it', 452);
INSERT INTO public.prenota VALUES ('13:30:00', '2020-10-20', 'nicola.giordano@hotmail.com', 460);
INSERT INTO public.prenota VALUES ('06:15:00', '2016-09-19', 'anita.moretti@gmail.com', 477);
INSERT INTO public.prenota VALUES ('07:45:00', '2016-12-29', 'marta.marino@gmail.com', 433);
INSERT INTO public.prenota VALUES ('13:15:00', '2019-11-10', 'jacopo.barbieri@libero.it', 358);
INSERT INTO public.prenota VALUES ('12:15:00', '2021-01-14', 'gioia.gallo@hotmail.com', 110);
INSERT INTO public.prenota VALUES ('09:30:00', '2017-07-14', 'damiano.rossi@libero.it', 305);
INSERT INTO public.prenota VALUES ('22:30:00', '2017-07-27', 'giorgio.franco@libero.it', 46);
INSERT INTO public.prenota VALUES ('22:00:00', '2020-04-25', 'anita.martino@libero.it', 88);
INSERT INTO public.prenota VALUES ('00:30:00', '2019-01-24', 'miriam.gallo@gmail.com', 151);
INSERT INTO public.prenota VALUES ('00:30:00', '2020-06-02', 'luigi.esposito@hotmail.com', 184);
INSERT INTO public.prenota VALUES ('01:30:00', '2021-11-22', 'diana.franco@hotmail.com', 206);
INSERT INTO public.prenota VALUES ('23:15:00', '2019-04-30', 'gioia.gallo@hotmail.com', 232);
INSERT INTO public.prenota VALUES ('23:00:00', '2020-02-24', 'elia.conti@hotmail.com', 127);
INSERT INTO public.prenota VALUES ('22:15:00', '2019-12-02', 'nina.leone@hotmail.com', 346);
INSERT INTO public.prenota VALUES ('14:15:00', '2017-01-27', 'ambra.franco@libero.it', 325);
INSERT INTO public.prenota VALUES ('02:00:00', '2020-05-02', 'noah.villa@hotmail.com', 484);
INSERT INTO public.prenota VALUES ('17:45:00', '2017-10-12', 'ambra.villa@gmail.com', 379);
INSERT INTO public.prenota VALUES ('04:30:00', '2019-08-24', 'liam.fontana@hotmail.com', 395);
INSERT INTO public.prenota VALUES ('03:45:00', '2017-01-17', 'alessio.caruso@hotmail.com', 483);
INSERT INTO public.prenota VALUES ('21:30:00', '2021-05-23', 'michele.mancini@libero.it', 449);
INSERT INTO public.prenota VALUES ('19:30:00', '2021-10-02', 'nicola.giordano@hotmail.com', 162);
INSERT INTO public.prenota VALUES ('15:45:00', '2020-08-02', 'carlotta.rinaldi@hotmail.com', 49);
INSERT INTO public.prenota VALUES ('04:15:00', '2021-01-08', 'amelia.fontana@libero.it', 211);
INSERT INTO public.prenota VALUES ('01:15:00', '2019-09-26', 'amelia.fontana@libero.it', 404);
INSERT INTO public.prenota VALUES ('19:45:00', '2018-08-01', 'anita.martino@libero.it', 269);
INSERT INTO public.prenota VALUES ('16:30:00', '2017-12-23', 'francesca.rizzo@hotmail.com', 430);
INSERT INTO public.prenota VALUES ('15:00:00', '2018-09-08', 'luigi.esposito@hotmail.com', 174);
INSERT INTO public.prenota VALUES ('05:15:00', '2019-06-24', 'luca.russo@libero.it', 433);
INSERT INTO public.prenota VALUES ('01:45:00', '2020-12-10', 'diana.villa@gmail.com', 192);
INSERT INTO public.prenota VALUES ('11:15:00', '2020-03-06', 'ambra.villa@hotmail.com', 280);
INSERT INTO public.prenota VALUES ('19:30:00', '2019-02-04', 'marta.marino@gmail.com', 380);
INSERT INTO public.prenota VALUES ('05:15:00', '2020-10-06', 'alessia.rinaldi@libero.it', 428);
INSERT INTO public.prenota VALUES ('23:30:00', '2021-10-16', 'diletta.amato@hotmail.com', 145);
INSERT INTO public.prenota VALUES ('17:30:00', '2018-05-21', 'anita.moretti@gmail.com', 169);
INSERT INTO public.prenota VALUES ('19:00:00', '2020-12-09', 'ambra.villa@gmail.com', 121);
INSERT INTO public.prenota VALUES ('16:00:00', '2018-05-03', 'alessio.caruso@hotmail.com', 339);
INSERT INTO public.prenota VALUES ('21:45:00', '2019-02-13', 'ettore.caruso@hotmail.com', 436);
INSERT INTO public.prenota VALUES ('12:15:00', '2017-11-15', 'manuel.conti@hotmail.com', 189);
INSERT INTO public.prenota VALUES ('18:15:00', '2022-08-26', 'amelia.fontana@libero.it', 458);
INSERT INTO public.prenota VALUES ('01:45:00', '2020-05-29', 'diana.villa@gmail.com', 202);
INSERT INTO public.prenota VALUES ('14:15:00', '2021-07-24', 'giorgio.franco@libero.it', 267);
INSERT INTO public.prenota VALUES ('03:00:00', '2021-01-28', 'maria.ricci@libero.it', 67);
INSERT INTO public.prenota VALUES ('15:00:00', '2016-06-07', 'elena.ferrara@gmail.com', 474);
INSERT INTO public.prenota VALUES ('13:30:00', '2020-02-23', 'thomas.franco@hotmail.com', 342);
INSERT INTO public.prenota VALUES ('19:30:00', '2019-09-01', 'miriam.gallo@gmail.com', 153);
INSERT INTO public.prenota VALUES ('20:30:00', '2016-07-15', 'nina.leone@hotmail.com', 114);
INSERT INTO public.prenota VALUES ('10:30:00', '2018-07-26', 'alessia.villa@libero.it', 82);
INSERT INTO public.prenota VALUES ('12:15:00', '2019-10-20', 'diletta.amato@hotmail.com', 421);
INSERT INTO public.prenota VALUES ('01:45:00', '2020-12-26', 'diana.franco@hotmail.com', 482);
INSERT INTO public.prenota VALUES ('09:00:00', '2019-09-30', 'miriam.gallo@gmail.com', 102);
INSERT INTO public.prenota VALUES ('16:45:00', '2018-03-06', 'ettore.caruso@hotmail.com', 38);
INSERT INTO public.prenota VALUES ('12:45:00', '2020-12-26', 'jacopo.barbieri@libero.it', 117);
INSERT INTO public.prenota VALUES ('10:00:00', '2020-11-09', 'manuel.conti@hotmail.com', 452);
INSERT INTO public.prenota VALUES ('23:45:00', '2018-09-07', 'gioia.gallo@hotmail.com', 46);
INSERT INTO public.prenota VALUES ('16:15:00', '2019-08-22', 'anita.martino@libero.it', 363);
INSERT INTO public.prenota VALUES ('06:30:00', '2019-12-26', 'anita.moretti@gmail.com', 48);
INSERT INTO public.prenota VALUES ('04:15:00', '2020-08-11', 'diana.franco@hotmail.com', 308);
INSERT INTO public.prenota VALUES ('05:30:00', '2019-09-04', 'marta.marino@gmail.com', 327);
INSERT INTO public.prenota VALUES ('06:45:00', '2019-04-15', 'margherita.conti@gmail.com', 334);
INSERT INTO public.prenota VALUES ('04:15:00', '2018-10-20', 'luigi.mariani@libero.it', 467);
INSERT INTO public.prenota VALUES ('10:45:00', '2020-04-10', 'anita.moretti@gmail.com', 350);
INSERT INTO public.prenota VALUES ('18:45:00', '2017-09-24', 'damiano.rossi@libero.it', 135);
INSERT INTO public.prenota VALUES ('00:30:00', '2019-09-05', 'margherita.conti@gmail.com', 213);
INSERT INTO public.prenota VALUES ('14:30:00', '2021-05-01', 'gioia.gallo@hotmail.com', 93);
INSERT INTO public.prenota VALUES ('14:15:00', '2021-10-29', 'ambra.franco@libero.it', 166);
INSERT INTO public.prenota VALUES ('07:30:00', '2019-12-06', 'daniel.marino@hotmail.com', 129);


--
-- TOC entry 3413 (class 0 OID 16643)
-- Dependencies: 218
-- Data for Name: tavolo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tavolo VALUES (1, 13, 'blu', 757318);
INSERT INTO public.tavolo VALUES (2, 15, 'verde', 207600);
INSERT INTO public.tavolo VALUES (3, 8, 'nero', 209826);
INSERT INTO public.tavolo VALUES (4, 18, 'grigia', 944410);
INSERT INTO public.tavolo VALUES (5, 12, 'blu', 594866);
INSERT INTO public.tavolo VALUES (6, 6, 'rossa', 438956);
INSERT INTO public.tavolo VALUES (7, 9, 'arancione', 444387);
INSERT INTO public.tavolo VALUES (8, 4, 'rosa', 817527);
INSERT INTO public.tavolo VALUES (9, 6, 'verde', 852836);
INSERT INTO public.tavolo VALUES (10, 13, 'giallo', 354903);
INSERT INTO public.tavolo VALUES (11, 6, 'verde', 963027);
INSERT INTO public.tavolo VALUES (12, 19, 'blu', 566818);
INSERT INTO public.tavolo VALUES (13, 8, 'arancione', 849113);
INSERT INTO public.tavolo VALUES (14, 18, 'rossa', 444387);
INSERT INTO public.tavolo VALUES (15, 20, 'rossa', 849113);
INSERT INTO public.tavolo VALUES (16, 3, 'grigia', 851409);
INSERT INTO public.tavolo VALUES (17, 14, 'rossa', 594866);
INSERT INTO public.tavolo VALUES (18, 20, 'blu', 354903);
INSERT INTO public.tavolo VALUES (19, 4, 'rossa', 999100);
INSERT INTO public.tavolo VALUES (20, 5, 'rosa', 354903);
INSERT INTO public.tavolo VALUES (21, 11, 'blu', 865126);
INSERT INTO public.tavolo VALUES (22, 13, 'rossa', 595713);
INSERT INTO public.tavolo VALUES (23, 20, 'verde', 857610);
INSERT INTO public.tavolo VALUES (24, 5, 'rossa', 809661);
INSERT INTO public.tavolo VALUES (25, 3, 'giallo', 852836);
INSERT INTO public.tavolo VALUES (26, 19, 'bianca', 341442);
INSERT INTO public.tavolo VALUES (27, 7, 'grigia', 851409);
INSERT INTO public.tavolo VALUES (28, 3, 'rossa', 849113);
INSERT INTO public.tavolo VALUES (29, 7, 'verde', 320289);
INSERT INTO public.tavolo VALUES (30, 2, 'rossa', 155572);
INSERT INTO public.tavolo VALUES (31, 14, 'rossa', 599818);
INSERT INTO public.tavolo VALUES (32, 20, 'blu', 857610);
INSERT INTO public.tavolo VALUES (33, 13, 'rossa', 857610);
INSERT INTO public.tavolo VALUES (34, 3, 'grigia', 853886);
INSERT INTO public.tavolo VALUES (35, 3, 'rosa', 999100);
INSERT INTO public.tavolo VALUES (36, 8, 'verde', 320289);
INSERT INTO public.tavolo VALUES (37, 8, 'blu', 853886);
INSERT INTO public.tavolo VALUES (38, 14, 'grigia', 893535);
INSERT INTO public.tavolo VALUES (39, 14, 'giallo', 857610);
INSERT INTO public.tavolo VALUES (40, 9, 'bianca', 809661);
INSERT INTO public.tavolo VALUES (41, 4, 'verde', 922478);
INSERT INTO public.tavolo VALUES (42, 7, 'blu', 617402);
INSERT INTO public.tavolo VALUES (43, 3, 'verde', 209826);
INSERT INTO public.tavolo VALUES (44, 12, 'verde', 965649);
INSERT INTO public.tavolo VALUES (45, 12, 'giallo', 155572);
INSERT INTO public.tavolo VALUES (46, 19, 'giallo', 963027);
INSERT INTO public.tavolo VALUES (47, 7, 'nero', 859817);
INSERT INTO public.tavolo VALUES (48, 5, 'verde', 444387);
INSERT INTO public.tavolo VALUES (49, 18, 'giallo', 759791);
INSERT INTO public.tavolo VALUES (50, 19, 'rossa', 963027);
INSERT INTO public.tavolo VALUES (51, 20, 'arancione', 965649);
INSERT INTO public.tavolo VALUES (52, 2, 'grigia', 550905);
INSERT INTO public.tavolo VALUES (53, 12, 'rossa', 270138);
INSERT INTO public.tavolo VALUES (54, 19, 'arancione', 808430);
INSERT INTO public.tavolo VALUES (55, 16, 'blu', 528689);
INSERT INTO public.tavolo VALUES (56, 6, 'blu', 992375);
INSERT INTO public.tavolo VALUES (57, 3, 'blu', 997257);
INSERT INTO public.tavolo VALUES (58, 2, 'blu', 849113);
INSERT INTO public.tavolo VALUES (59, 14, 'bianca', 354903);
INSERT INTO public.tavolo VALUES (60, 6, 'bianca', 992375);
INSERT INTO public.tavolo VALUES (61, 20, 'verde', 906613);
INSERT INTO public.tavolo VALUES (62, 3, 'verde', 965649);
INSERT INTO public.tavolo VALUES (63, 8, 'rosa', 438956);
INSERT INTO public.tavolo VALUES (64, 12, 'verde', 965649);
INSERT INTO public.tavolo VALUES (65, 15, 'verde', 170147);
INSERT INTO public.tavolo VALUES (66, 6, 'giallo', 617402);
INSERT INTO public.tavolo VALUES (67, 6, 'grigia', 893535);
INSERT INTO public.tavolo VALUES (68, 14, 'blu', 809661);
INSERT INTO public.tavolo VALUES (69, 2, 'grigia', 857610);
INSERT INTO public.tavolo VALUES (70, 14, 'nero', 320289);
INSERT INTO public.tavolo VALUES (71, 2, 'giallo', 859817);
INSERT INTO public.tavolo VALUES (72, 20, 'rosa', 617402);
INSERT INTO public.tavolo VALUES (73, 16, 'giallo', 893535);
INSERT INTO public.tavolo VALUES (74, 15, 'giallo', 993477);
INSERT INTO public.tavolo VALUES (75, 10, 'arancione', 668141);
INSERT INTO public.tavolo VALUES (76, 16, 'verde', 341442);
INSERT INTO public.tavolo VALUES (77, 12, 'rosa', 599818);
INSERT INTO public.tavolo VALUES (78, 2, 'blu', 550905);
INSERT INTO public.tavolo VALUES (79, 16, 'blu', 865126);
INSERT INTO public.tavolo VALUES (80, 12, 'verde', 170147);
INSERT INTO public.tavolo VALUES (81, 4, 'grigia', 853886);
INSERT INTO public.tavolo VALUES (82, 12, 'rossa', 281137);
INSERT INTO public.tavolo VALUES (83, 9, 'grigia', 853886);
INSERT INTO public.tavolo VALUES (84, 14, 'rossa', 893535);
INSERT INTO public.tavolo VALUES (85, 18, 'arancione', 808430);
INSERT INTO public.tavolo VALUES (86, 10, 'rosa', 757318);
INSERT INTO public.tavolo VALUES (87, 17, 'nero', 759791);
INSERT INTO public.tavolo VALUES (88, 4, 'arancione', 817527);
INSERT INTO public.tavolo VALUES (89, 5, 'verde', 617402);
INSERT INTO public.tavolo VALUES (90, 12, 'arancione', 438956);
INSERT INTO public.tavolo VALUES (91, 9, 'rossa', 170147);
INSERT INTO public.tavolo VALUES (92, 4, 'verde', 207600);
INSERT INTO public.tavolo VALUES (93, 3, 'arancione', 817527);
INSERT INTO public.tavolo VALUES (94, 12, 'giallo', 566818);
INSERT INTO public.tavolo VALUES (95, 12, 'bianca', 341442);
INSERT INTO public.tavolo VALUES (96, 13, 'verde', 906613);
INSERT INTO public.tavolo VALUES (97, 19, 'blu', 922478);
INSERT INTO public.tavolo VALUES (98, 8, 'bianca', 354903);
INSERT INTO public.tavolo VALUES (99, 8, 'rossa', 928749);
INSERT INTO public.tavolo VALUES (100, 3, 'grigia', 944410);
INSERT INTO public.tavolo VALUES (101, 16, 'arancione', 207600);
INSERT INTO public.tavolo VALUES (102, 9, 'giallo', 963027);
INSERT INTO public.tavolo VALUES (103, 4, 'rosa', 808430);
INSERT INTO public.tavolo VALUES (104, 2, 'rosa', 956326);
INSERT INTO public.tavolo VALUES (105, 20, 'grigia', 922478);
INSERT INTO public.tavolo VALUES (106, 6, 'rosa', 574865);
INSERT INTO public.tavolo VALUES (107, 11, 'rosa', 444387);
INSERT INTO public.tavolo VALUES (108, 19, 'giallo', 809661);
INSERT INTO public.tavolo VALUES (109, 15, 'blu', 853886);
INSERT INTO public.tavolo VALUES (110, 2, 'giallo', 817527);
INSERT INTO public.tavolo VALUES (111, 14, 'bianca', 754495);
INSERT INTO public.tavolo VALUES (112, 6, 'rossa', 599818);
INSERT INTO public.tavolo VALUES (113, 8, 'blu', 550905);
INSERT INTO public.tavolo VALUES (114, 16, 'nero', 992375);
INSERT INTO public.tavolo VALUES (115, 5, 'giallo', 944410);
INSERT INTO public.tavolo VALUES (116, 5, 'nero', 759925);
INSERT INTO public.tavolo VALUES (117, 12, 'rosa', 893535);
INSERT INTO public.tavolo VALUES (118, 15, 'rossa', 270138);
INSERT INTO public.tavolo VALUES (119, 8, 'verde', 857610);
INSERT INTO public.tavolo VALUES (120, 9, 'verde', 668141);
INSERT INTO public.tavolo VALUES (121, 16, 'blu', 687438);
INSERT INTO public.tavolo VALUES (122, 6, 'giallo', 922478);
INSERT INTO public.tavolo VALUES (123, 6, 'verde', 759925);
INSERT INTO public.tavolo VALUES (124, 14, 'bianca', 817527);
INSERT INTO public.tavolo VALUES (125, 16, 'verde', 438956);
INSERT INTO public.tavolo VALUES (126, 15, 'grigia', 993477);
INSERT INTO public.tavolo VALUES (127, 11, 'bianca', 906613);
INSERT INTO public.tavolo VALUES (128, 4, 'bianca', 759925);
INSERT INTO public.tavolo VALUES (129, 14, 'giallo', 853886);
INSERT INTO public.tavolo VALUES (130, 11, 'nero', 444387);
INSERT INTO public.tavolo VALUES (131, 13, 'rosa', 759925);
INSERT INTO public.tavolo VALUES (132, 5, 'nero', 270138);
INSERT INTO public.tavolo VALUES (133, 15, 'verde', 550905);
INSERT INTO public.tavolo VALUES (134, 2, 'nero', 857610);
INSERT INTO public.tavolo VALUES (135, 11, 'arancione', 808430);
INSERT INTO public.tavolo VALUES (136, 18, 'nero', 207600);
INSERT INTO public.tavolo VALUES (137, 18, 'rosa', 944410);
INSERT INTO public.tavolo VALUES (138, 13, 'arancione', 999100);
INSERT INTO public.tavolo VALUES (139, 9, 'rossa', 595713);
INSERT INTO public.tavolo VALUES (140, 18, 'arancione', 668141);
INSERT INTO public.tavolo VALUES (141, 10, 'rossa', 849113);
INSERT INTO public.tavolo VALUES (142, 16, 'rosa', 668141);
INSERT INTO public.tavolo VALUES (143, 9, 'grigia', 757318);
INSERT INTO public.tavolo VALUES (144, 13, 'giallo', 595713);
INSERT INTO public.tavolo VALUES (145, 12, 'verde', 687438);
INSERT INTO public.tavolo VALUES (146, 16, 'rossa', 209826);
INSERT INTO public.tavolo VALUES (147, 9, 'rossa', 574865);
INSERT INTO public.tavolo VALUES (148, 17, 'grigia', 170147);
INSERT INTO public.tavolo VALUES (149, 10, 'verde', 599818);
INSERT INTO public.tavolo VALUES (150, 3, 'rosa', 999100);
INSERT INTO public.tavolo VALUES (151, 4, 'verde', 928749);
INSERT INTO public.tavolo VALUES (152, 2, 'grigia', 550905);
INSERT INTO public.tavolo VALUES (153, 9, 'arancione', 997257);
INSERT INTO public.tavolo VALUES (154, 7, 'grigia', 857610);
INSERT INTO public.tavolo VALUES (155, 11, 'rosa', 209826);
INSERT INTO public.tavolo VALUES (156, 7, 'verde', 963027);
INSERT INTO public.tavolo VALUES (157, 5, 'giallo', 759925);
INSERT INTO public.tavolo VALUES (158, 5, 'verde', 965649);
INSERT INTO public.tavolo VALUES (159, 4, 'blu', 550905);
INSERT INTO public.tavolo VALUES (160, 14, 'bianca', 143204);
INSERT INTO public.tavolo VALUES (161, 13, 'bianca', 865126);
INSERT INTO public.tavolo VALUES (162, 17, 'giallo', 992375);
INSERT INTO public.tavolo VALUES (163, 8, 'rossa', 965649);
INSERT INTO public.tavolo VALUES (164, 7, 'giallo', 759791);
INSERT INTO public.tavolo VALUES (165, 17, 'bianca', 155572);
INSERT INTO public.tavolo VALUES (166, 12, 'grigia', 687438);
INSERT INTO public.tavolo VALUES (167, 13, 'rosa', 209826);
INSERT INTO public.tavolo VALUES (168, 10, 'bianca', 809661);
INSERT INTO public.tavolo VALUES (169, 19, 'bianca', 320289);
INSERT INTO public.tavolo VALUES (170, 4, 'bianca', 956326);
INSERT INTO public.tavolo VALUES (171, 7, 'verde', 851409);
INSERT INTO public.tavolo VALUES (172, 10, 'verde', 687438);
INSERT INTO public.tavolo VALUES (173, 17, 'grigia', 992375);
INSERT INTO public.tavolo VALUES (174, 9, 'giallo', 852836);
INSERT INTO public.tavolo VALUES (175, 16, 'blu', 687438);
INSERT INTO public.tavolo VALUES (176, 17, 'blu', 595713);
INSERT INTO public.tavolo VALUES (177, 2, 'bianca', 928749);
INSERT INTO public.tavolo VALUES (178, 15, 'rosa', 170147);
INSERT INTO public.tavolo VALUES (179, 6, 'arancione', 668141);
INSERT INTO public.tavolo VALUES (180, 5, 'grigia', 155572);
INSERT INTO public.tavolo VALUES (181, 15, 'blu', 965649);
INSERT INTO public.tavolo VALUES (182, 6, 'bianca', 170147);
INSERT INTO public.tavolo VALUES (183, 16, 'nero', 354903);
INSERT INTO public.tavolo VALUES (184, 5, 'rosa', 757318);
INSERT INTO public.tavolo VALUES (185, 16, 'rosa', 270138);
INSERT INTO public.tavolo VALUES (186, 9, 'grigia', 594866);
INSERT INTO public.tavolo VALUES (187, 10, 'bianca', 599818);
INSERT INTO public.tavolo VALUES (188, 4, 'verde', 234912);
INSERT INTO public.tavolo VALUES (189, 18, 'giallo', 320289);
INSERT INTO public.tavolo VALUES (190, 9, 'rosa', 759791);
INSERT INTO public.tavolo VALUES (191, 14, 'verde', 207600);
INSERT INTO public.tavolo VALUES (192, 14, 'nero', 963027);
INSERT INTO public.tavolo VALUES (193, 17, 'nero', 992375);
INSERT INTO public.tavolo VALUES (194, 15, 'rossa', 754495);
INSERT INTO public.tavolo VALUES (195, 9, 'giallo', 687438);
INSERT INTO public.tavolo VALUES (196, 6, 'blu', 209826);
INSERT INTO public.tavolo VALUES (197, 6, 'rossa', 992375);
INSERT INTO public.tavolo VALUES (198, 15, 'arancione', 595713);
INSERT INTO public.tavolo VALUES (199, 11, 'rossa', 234912);
INSERT INTO public.tavolo VALUES (200, 3, 'rosa', 965649);
INSERT INTO public.tavolo VALUES (201, 10, 'bianca', 928749);
INSERT INTO public.tavolo VALUES (202, 5, 'grigia', 906613);
INSERT INTO public.tavolo VALUES (203, 13, 'arancione', 341442);
INSERT INTO public.tavolo VALUES (204, 11, 'arancione', 134370);
INSERT INTO public.tavolo VALUES (205, 9, 'bianca', 859817);
INSERT INTO public.tavolo VALUES (206, 13, 'rossa', 808430);
INSERT INTO public.tavolo VALUES (207, 3, 'rossa', 566818);
INSERT INTO public.tavolo VALUES (208, 3, 'arancione', 999100);
INSERT INTO public.tavolo VALUES (209, 4, 'nero', 134370);
INSERT INTO public.tavolo VALUES (210, 19, 'rosa', 234912);
INSERT INTO public.tavolo VALUES (211, 6, 'rossa', 754495);
INSERT INTO public.tavolo VALUES (212, 8, 'nero', 859817);
INSERT INTO public.tavolo VALUES (213, 20, 'rosa', 857610);
INSERT INTO public.tavolo VALUES (214, 14, 'blu', 528689);
INSERT INTO public.tavolo VALUES (215, 5, 'grigia', 999100);
INSERT INTO public.tavolo VALUES (216, 6, 'arancione', 594866);
INSERT INTO public.tavolo VALUES (217, 20, 'rossa', 444387);
INSERT INTO public.tavolo VALUES (218, 20, 'grigia', 170147);
INSERT INTO public.tavolo VALUES (219, 10, 'arancione', 134370);
INSERT INTO public.tavolo VALUES (220, 13, 'giallo', 928749);
INSERT INTO public.tavolo VALUES (221, 10, 'arancione', 234912);
INSERT INTO public.tavolo VALUES (222, 20, 'grigia', 857610);
INSERT INTO public.tavolo VALUES (223, 16, 'rosa', 965649);
INSERT INTO public.tavolo VALUES (224, 12, 'nero', 170147);
INSERT INTO public.tavolo VALUES (225, 4, 'bianca', 852836);
INSERT INTO public.tavolo VALUES (226, 4, 'giallo', 809661);
INSERT INTO public.tavolo VALUES (227, 19, 'grigia', 354903);
INSERT INTO public.tavolo VALUES (228, 3, 'verde', 808430);
INSERT INTO public.tavolo VALUES (229, 14, 'rosa', 550905);
INSERT INTO public.tavolo VALUES (230, 3, 'grigia', 143204);
INSERT INTO public.tavolo VALUES (231, 10, 'arancione', 209826);
INSERT INTO public.tavolo VALUES (232, 9, 'bianca', 993477);
INSERT INTO public.tavolo VALUES (233, 2, 'rosa', 906613);
INSERT INTO public.tavolo VALUES (234, 14, 'blu', 993477);
INSERT INTO public.tavolo VALUES (235, 15, 'verde', 209826);
INSERT INTO public.tavolo VALUES (236, 7, 'verde', 928749);
INSERT INTO public.tavolo VALUES (237, 9, 'arancione', 687438);
INSERT INTO public.tavolo VALUES (238, 19, 'giallo', 865126);
INSERT INTO public.tavolo VALUES (239, 8, 'blu', 922478);
INSERT INTO public.tavolo VALUES (240, 16, 'bianca', 944410);
INSERT INTO public.tavolo VALUES (241, 15, 'rossa', 857610);
INSERT INTO public.tavolo VALUES (242, 6, 'verde', 155572);
INSERT INTO public.tavolo VALUES (243, 6, 'arancione', 956326);
INSERT INTO public.tavolo VALUES (244, 2, 'giallo', 993477);
INSERT INTO public.tavolo VALUES (245, 9, 'blu', 759791);
INSERT INTO public.tavolo VALUES (246, 9, 'rosa', 852836);
INSERT INTO public.tavolo VALUES (247, 3, 'arancione', 963027);
INSERT INTO public.tavolo VALUES (248, 11, 'rosa', 893535);
INSERT INTO public.tavolo VALUES (249, 13, 'nero', 341442);
INSERT INTO public.tavolo VALUES (250, 8, 'giallo', 320289);
INSERT INTO public.tavolo VALUES (251, 5, 'blu', 594866);
INSERT INTO public.tavolo VALUES (252, 20, 'rossa', 170147);
INSERT INTO public.tavolo VALUES (253, 11, 'bianca', 594866);
INSERT INTO public.tavolo VALUES (254, 15, 'giallo', 759791);
INSERT INTO public.tavolo VALUES (255, 13, 'verde', 817527);
INSERT INTO public.tavolo VALUES (256, 4, 'verde', 599818);
INSERT INTO public.tavolo VALUES (257, 2, 'bianca', 320289);
INSERT INTO public.tavolo VALUES (258, 16, 'nero', 922478);
INSERT INTO public.tavolo VALUES (259, 19, 'rossa', 759925);
INSERT INTO public.tavolo VALUES (260, 2, 'rosa', 354903);
INSERT INTO public.tavolo VALUES (261, 19, 'bianca', 963027);
INSERT INTO public.tavolo VALUES (262, 4, 'arancione', 594866);
INSERT INTO public.tavolo VALUES (263, 11, 'nero', 143204);
INSERT INTO public.tavolo VALUES (264, 13, 'rossa', 270138);
INSERT INTO public.tavolo VALUES (265, 3, 'rosa', 999100);
INSERT INTO public.tavolo VALUES (266, 4, 'bianca', 893535);
INSERT INTO public.tavolo VALUES (267, 2, 'giallo', 963027);
INSERT INTO public.tavolo VALUES (268, 10, 'verde', 668141);
INSERT INTO public.tavolo VALUES (269, 3, 'rossa', 956326);
INSERT INTO public.tavolo VALUES (270, 17, 'rossa', 857610);
INSERT INTO public.tavolo VALUES (271, 4, 'blu', 207600);
INSERT INTO public.tavolo VALUES (272, 17, 'rosa', 234912);
INSERT INTO public.tavolo VALUES (273, 12, 'rossa', 853886);
INSERT INTO public.tavolo VALUES (274, 16, 'rosa', 143204);
INSERT INTO public.tavolo VALUES (275, 15, 'arancione', 865126);
INSERT INTO public.tavolo VALUES (276, 13, 'rossa', 849113);
INSERT INTO public.tavolo VALUES (277, 9, 'arancione', 209826);
INSERT INTO public.tavolo VALUES (278, 13, 'rosa', 857610);
INSERT INTO public.tavolo VALUES (279, 8, 'blu', 992375);
INSERT INTO public.tavolo VALUES (280, 2, 'verde', 992375);
INSERT INTO public.tavolo VALUES (281, 16, 'rosa', 617402);
INSERT INTO public.tavolo VALUES (282, 5, 'rosa', 754495);
INSERT INTO public.tavolo VALUES (283, 17, 'rossa', 956326);
INSERT INTO public.tavolo VALUES (284, 12, 'giallo', 438956);
INSERT INTO public.tavolo VALUES (285, 10, 'nero', 759791);
INSERT INTO public.tavolo VALUES (286, 9, 'blu', 963027);
INSERT INTO public.tavolo VALUES (287, 12, 'grigia', 668141);
INSERT INTO public.tavolo VALUES (288, 8, 'blu', 859817);
INSERT INTO public.tavolo VALUES (289, 4, 'rossa', 594866);
INSERT INTO public.tavolo VALUES (290, 9, 'giallo', 757318);
INSERT INTO public.tavolo VALUES (291, 10, 'arancione', 444387);
INSERT INTO public.tavolo VALUES (292, 18, 'giallo', 234912);
INSERT INTO public.tavolo VALUES (293, 17, 'verde', 851409);
INSERT INTO public.tavolo VALUES (294, 14, 'verde', 134370);
INSERT INTO public.tavolo VALUES (295, 12, 'verde', 444387);
INSERT INTO public.tavolo VALUES (296, 10, 'verde', 997257);
INSERT INTO public.tavolo VALUES (297, 14, 'rosa', 134370);
INSERT INTO public.tavolo VALUES (298, 2, 'giallo', 143204);
INSERT INTO public.tavolo VALUES (299, 2, 'rossa', 270138);
INSERT INTO public.tavolo VALUES (300, 6, 'grigia', 209826);
INSERT INTO public.tavolo VALUES (301, 2, 'rosa', 963027);
INSERT INTO public.tavolo VALUES (302, 6, 'rosa', 759925);
INSERT INTO public.tavolo VALUES (303, 19, 'arancione', 270138);
INSERT INTO public.tavolo VALUES (304, 20, 'rosa', 234912);
INSERT INTO public.tavolo VALUES (305, 4, 'nero', 566818);
INSERT INTO public.tavolo VALUES (306, 5, 'verde', 754495);
INSERT INTO public.tavolo VALUES (307, 2, 'grigia', 849113);
INSERT INTO public.tavolo VALUES (308, 8, 'bianca', 759925);
INSERT INTO public.tavolo VALUES (309, 20, 'arancione', 594866);
INSERT INTO public.tavolo VALUES (310, 20, 'grigia', 809661);
INSERT INTO public.tavolo VALUES (311, 3, 'bianca', 668141);
INSERT INTO public.tavolo VALUES (312, 4, 'rosa', 594866);
INSERT INTO public.tavolo VALUES (313, 13, 'arancione', 134370);
INSERT INTO public.tavolo VALUES (314, 5, 'giallo', 993477);
INSERT INTO public.tavolo VALUES (315, 2, 'nero', 594866);
INSERT INTO public.tavolo VALUES (316, 17, 'giallo', 354903);
INSERT INTO public.tavolo VALUES (317, 4, 'rosa', 852836);
INSERT INTO public.tavolo VALUES (318, 5, 'blu', 759791);
INSERT INTO public.tavolo VALUES (319, 18, 'giallo', 595713);
INSERT INTO public.tavolo VALUES (320, 18, 'rossa', 566818);
INSERT INTO public.tavolo VALUES (321, 15, 'arancione', 281137);
INSERT INTO public.tavolo VALUES (322, 14, 'bianca', 992375);
INSERT INTO public.tavolo VALUES (323, 17, 'grigia', 320289);
INSERT INTO public.tavolo VALUES (324, 15, 'blu', 922478);
INSERT INTO public.tavolo VALUES (325, 7, 'bianca', 849113);
INSERT INTO public.tavolo VALUES (326, 5, 'blu', 209826);
INSERT INTO public.tavolo VALUES (327, 14, 'bianca', 595713);
INSERT INTO public.tavolo VALUES (328, 13, 'rossa', 965649);
INSERT INTO public.tavolo VALUES (329, 19, 'verde', 852836);
INSERT INTO public.tavolo VALUES (330, 13, 'verde', 928749);
INSERT INTO public.tavolo VALUES (331, 2, 'rosa', 809661);
INSERT INTO public.tavolo VALUES (332, 7, 'giallo', 999100);
INSERT INTO public.tavolo VALUES (333, 14, 'nero', 906613);
INSERT INTO public.tavolo VALUES (334, 11, 'bianca', 270138);
INSERT INTO public.tavolo VALUES (335, 10, 'arancione', 687438);
INSERT INTO public.tavolo VALUES (336, 7, 'arancione', 944410);
INSERT INTO public.tavolo VALUES (337, 5, 'blu', 444387);
INSERT INTO public.tavolo VALUES (338, 3, 'bianca', 944410);
INSERT INTO public.tavolo VALUES (339, 15, 'grigia', 906613);
INSERT INTO public.tavolo VALUES (340, 20, 'bianca', 528689);
INSERT INTO public.tavolo VALUES (341, 11, 'rosa', 997257);
INSERT INTO public.tavolo VALUES (342, 11, 'bianca', 170147);
INSERT INTO public.tavolo VALUES (343, 20, 'giallo', 922478);
INSERT INTO public.tavolo VALUES (344, 14, 'nero', 270138);
INSERT INTO public.tavolo VALUES (345, 15, 'giallo', 857610);
INSERT INTO public.tavolo VALUES (346, 20, 'blu', 893535);
INSERT INTO public.tavolo VALUES (347, 9, 'rossa', 234912);
INSERT INTO public.tavolo VALUES (348, 18, 'giallo', 209826);
INSERT INTO public.tavolo VALUES (349, 4, 'arancione', 852836);
INSERT INTO public.tavolo VALUES (350, 16, 'verde', 341442);
INSERT INTO public.tavolo VALUES (351, 18, 'grigia', 341442);
INSERT INTO public.tavolo VALUES (352, 10, 'grigia', 170147);
INSERT INTO public.tavolo VALUES (353, 10, 'grigia', 438956);
INSERT INTO public.tavolo VALUES (354, 14, 'grigia', 209826);
INSERT INTO public.tavolo VALUES (355, 15, 'bianca', 997257);
INSERT INTO public.tavolo VALUES (356, 8, 'bianca', 857610);
INSERT INTO public.tavolo VALUES (357, 19, 'blu', 956326);
INSERT INTO public.tavolo VALUES (358, 2, 'giallo', 965649);
INSERT INTO public.tavolo VALUES (359, 7, 'nero', 281137);
INSERT INTO public.tavolo VALUES (360, 8, 'verde', 857610);
INSERT INTO public.tavolo VALUES (361, 16, 'rossa', 281137);
INSERT INTO public.tavolo VALUES (362, 8, 'rosa', 595713);
INSERT INTO public.tavolo VALUES (363, 14, 'verde', 857610);
INSERT INTO public.tavolo VALUES (364, 7, 'giallo', 851409);
INSERT INTO public.tavolo VALUES (365, 10, 'verde', 857610);
INSERT INTO public.tavolo VALUES (366, 12, 'verde', 893535);
INSERT INTO public.tavolo VALUES (367, 18, 'blu', 808430);
INSERT INTO public.tavolo VALUES (368, 9, 'bianca', 143204);
INSERT INTO public.tavolo VALUES (369, 19, 'nero', 944410);
INSERT INTO public.tavolo VALUES (370, 19, 'arancione', 853886);
INSERT INTO public.tavolo VALUES (371, 11, 'arancione', 754495);
INSERT INTO public.tavolo VALUES (372, 9, 'bianca', 270138);
INSERT INTO public.tavolo VALUES (373, 19, 'grigia', 759791);
INSERT INTO public.tavolo VALUES (374, 20, 'arancione', 757318);
INSERT INTO public.tavolo VALUES (375, 13, 'rossa', 574865);
INSERT INTO public.tavolo VALUES (376, 6, 'rosa', 134370);
INSERT INTO public.tavolo VALUES (377, 10, 'verde', 234912);
INSERT INTO public.tavolo VALUES (378, 4, 'nero', 574865);
INSERT INTO public.tavolo VALUES (379, 8, 'arancione', 574865);
INSERT INTO public.tavolo VALUES (380, 5, 'grigia', 817527);
INSERT INTO public.tavolo VALUES (381, 3, 'arancione', 550905);
INSERT INTO public.tavolo VALUES (382, 4, 'bianca', 594866);
INSERT INTO public.tavolo VALUES (383, 8, 'nero', 574865);
INSERT INTO public.tavolo VALUES (384, 5, 'bianca', 906613);
INSERT INTO public.tavolo VALUES (385, 6, 'giallo', 754495);
INSERT INTO public.tavolo VALUES (386, 7, 'bianca', 341442);
INSERT INTO public.tavolo VALUES (387, 10, 'arancione', 893535);
INSERT INTO public.tavolo VALUES (388, 3, 'bianca', 993477);
INSERT INTO public.tavolo VALUES (389, 13, 'nero', 859817);
INSERT INTO public.tavolo VALUES (390, 13, 'grigia', 809661);
INSERT INTO public.tavolo VALUES (391, 18, 'bianca', 209826);
INSERT INTO public.tavolo VALUES (392, 16, 'verde', 992375);
INSERT INTO public.tavolo VALUES (393, 10, 'rosa', 851409);
INSERT INTO public.tavolo VALUES (394, 2, 'grigia', 595713);
INSERT INTO public.tavolo VALUES (395, 20, 'rossa', 852836);
INSERT INTO public.tavolo VALUES (396, 5, 'arancione', 859817);
INSERT INTO public.tavolo VALUES (397, 17, 'bianca', 354903);
INSERT INTO public.tavolo VALUES (398, 9, 'grigia', 859817);
INSERT INTO public.tavolo VALUES (399, 20, 'arancione', 550905);
INSERT INTO public.tavolo VALUES (400, 19, 'arancione', 817527);
INSERT INTO public.tavolo VALUES (401, 7, 'grigia', 817527);
INSERT INTO public.tavolo VALUES (402, 20, 'verde', 759925);
INSERT INTO public.tavolo VALUES (403, 6, 'verde', 759925);
INSERT INTO public.tavolo VALUES (404, 9, 'arancione', 754495);
INSERT INTO public.tavolo VALUES (405, 5, 'bianca', 594866);
INSERT INTO public.tavolo VALUES (406, 6, 'arancione', 808430);
INSERT INTO public.tavolo VALUES (407, 14, 'blu', 857610);
INSERT INTO public.tavolo VALUES (408, 5, 'blu', 550905);
INSERT INTO public.tavolo VALUES (409, 9, 'verde', 754495);
INSERT INTO public.tavolo VALUES (410, 3, 'rossa', 143204);
INSERT INTO public.tavolo VALUES (411, 20, 'arancione', 922478);
INSERT INTO public.tavolo VALUES (412, 19, 'rosa', 852836);
INSERT INTO public.tavolo VALUES (413, 15, 'arancione', 566818);
INSERT INTO public.tavolo VALUES (414, 10, 'rosa', 808430);
INSERT INTO public.tavolo VALUES (415, 6, 'nero', 963027);
INSERT INTO public.tavolo VALUES (416, 2, 'bianca', 906613);
INSERT INTO public.tavolo VALUES (417, 12, 'grigia', 155572);
INSERT INTO public.tavolo VALUES (418, 17, 'rosa', 354903);
INSERT INTO public.tavolo VALUES (419, 14, 'arancione', 997257);
INSERT INTO public.tavolo VALUES (420, 8, 'bianca', 170147);
INSERT INTO public.tavolo VALUES (421, 6, 'rossa', 320289);
INSERT INTO public.tavolo VALUES (422, 10, 'bianca', 687438);
INSERT INTO public.tavolo VALUES (423, 20, 'arancione', 993477);
INSERT INTO public.tavolo VALUES (424, 3, 'verde', 207600);
INSERT INTO public.tavolo VALUES (425, 19, 'nero', 956326);
INSERT INTO public.tavolo VALUES (426, 12, 'giallo', 956326);
INSERT INTO public.tavolo VALUES (427, 2, 'grigia', 999100);
INSERT INTO public.tavolo VALUES (428, 2, 'verde', 893535);
INSERT INTO public.tavolo VALUES (429, 12, 'blu', 574865);
INSERT INTO public.tavolo VALUES (430, 9, 'rossa', 341442);
INSERT INTO public.tavolo VALUES (431, 14, 'verde', 759791);
INSERT INTO public.tavolo VALUES (432, 18, 'rossa', 209826);
INSERT INTO public.tavolo VALUES (433, 18, 'bianca', 906613);
INSERT INTO public.tavolo VALUES (434, 11, 'arancione', 853886);
INSERT INTO public.tavolo VALUES (435, 12, 'rossa', 270138);
INSERT INTO public.tavolo VALUES (436, 10, 'verde', 668141);
INSERT INTO public.tavolo VALUES (437, 2, 'rosa', 207600);
INSERT INTO public.tavolo VALUES (438, 9, 'giallo', 341442);
INSERT INTO public.tavolo VALUES (439, 2, 'nero', 759791);
INSERT INTO public.tavolo VALUES (440, 12, 'bianca', 341442);
INSERT INTO public.tavolo VALUES (441, 4, 'verde', 143204);
INSERT INTO public.tavolo VALUES (442, 11, 'bianca', 207600);
INSERT INTO public.tavolo VALUES (443, 6, 'nero', 944410);
INSERT INTO public.tavolo VALUES (444, 16, 'giallo', 759791);
INSERT INTO public.tavolo VALUES (445, 18, 'bianca', 944410);
INSERT INTO public.tavolo VALUES (446, 16, 'rosa', 528689);
INSERT INTO public.tavolo VALUES (447, 16, 'bianca', 853886);
INSERT INTO public.tavolo VALUES (448, 16, 'giallo', 341442);
INSERT INTO public.tavolo VALUES (449, 3, 'rossa', 859817);
INSERT INTO public.tavolo VALUES (450, 6, 'blu', 438956);
INSERT INTO public.tavolo VALUES (451, 3, 'rossa', 341442);
INSERT INTO public.tavolo VALUES (452, 8, 'rossa', 759925);
INSERT INTO public.tavolo VALUES (453, 9, 'blu', 993477);
INSERT INTO public.tavolo VALUES (454, 19, 'bianca', 444387);
INSERT INTO public.tavolo VALUES (455, 7, 'rossa', 143204);
INSERT INTO public.tavolo VALUES (456, 20, 'giallo', 759791);
INSERT INTO public.tavolo VALUES (457, 7, 'blu', 270138);
INSERT INTO public.tavolo VALUES (458, 5, 'arancione', 668141);
INSERT INTO public.tavolo VALUES (459, 12, 'verde', 817527);
INSERT INTO public.tavolo VALUES (460, 7, 'grigia', 993477);
INSERT INTO public.tavolo VALUES (461, 4, 'grigia', 852836);
INSERT INTO public.tavolo VALUES (462, 6, 'giallo', 281137);
INSERT INTO public.tavolo VALUES (463, 18, 'nero', 906613);
INSERT INTO public.tavolo VALUES (464, 4, 'verde', 852836);
INSERT INTO public.tavolo VALUES (465, 8, 'verde', 320289);
INSERT INTO public.tavolo VALUES (466, 14, 'blu', 759791);
INSERT INTO public.tavolo VALUES (467, 15, 'blu', 808430);
INSERT INTO public.tavolo VALUES (468, 10, 'rosa', 893535);
INSERT INTO public.tavolo VALUES (469, 2, 'rossa', 944410);
INSERT INTO public.tavolo VALUES (470, 5, 'verde', 134370);
INSERT INTO public.tavolo VALUES (471, 5, 'arancione', 893535);
INSERT INTO public.tavolo VALUES (472, 14, 'giallo', 320289);
INSERT INTO public.tavolo VALUES (473, 9, 'verde', 853886);
INSERT INTO public.tavolo VALUES (474, 5, 'arancione', 550905);
INSERT INTO public.tavolo VALUES (475, 18, 'giallo', 594866);
INSERT INTO public.tavolo VALUES (476, 19, 'verde', 759791);
INSERT INTO public.tavolo VALUES (477, 13, 'grigia', 155572);
INSERT INTO public.tavolo VALUES (478, 12, 'blu', 754495);
INSERT INTO public.tavolo VALUES (479, 18, 'giallo', 170147);
INSERT INTO public.tavolo VALUES (480, 4, 'rosa', 354903);
INSERT INTO public.tavolo VALUES (481, 12, 'rossa', 754495);
INSERT INTO public.tavolo VALUES (482, 9, 'rosa', 759791);
INSERT INTO public.tavolo VALUES (483, 17, 'giallo', 155572);
INSERT INTO public.tavolo VALUES (484, 20, 'giallo', 281137);
INSERT INTO public.tavolo VALUES (485, 5, 'arancione', 134370);
INSERT INTO public.tavolo VALUES (486, 3, 'nero', 759925);
INSERT INTO public.tavolo VALUES (487, 7, 'giallo', 170147);
INSERT INTO public.tavolo VALUES (488, 9, 'arancione', 993477);
INSERT INTO public.tavolo VALUES (489, 3, 'verde', 817527);
INSERT INTO public.tavolo VALUES (490, 17, 'verde', 341442);
INSERT INTO public.tavolo VALUES (491, 11, 'grigia', 956326);
INSERT INTO public.tavolo VALUES (492, 6, 'giallo', 906613);
INSERT INTO public.tavolo VALUES (493, 10, 'grigia', 754495);
INSERT INTO public.tavolo VALUES (494, 16, 'rossa', 944410);
INSERT INTO public.tavolo VALUES (495, 4, 'arancione', 759925);
INSERT INTO public.tavolo VALUES (496, 18, 'blu', 865126);
INSERT INTO public.tavolo VALUES (497, 10, 'giallo', 808430);
INSERT INTO public.tavolo VALUES (498, 13, 'rossa', 234912);
INSERT INTO public.tavolo VALUES (499, 18, 'blu', 759791);
INSERT INTO public.tavolo VALUES (500, 5, 'rosa', 859817);


--
-- TOC entry 3410 (class 0 OID 16610)
-- Dependencies: 215
-- Data for Name: tessera; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tessera VALUES ('giorgio.franco@libero.it', '2018-04-07', 951);
INSERT INTO public.tessera VALUES ('damiano.rossi@libero.it', '2011-03-10', 693);
INSERT INTO public.tessera VALUES ('amelia.fontana@libero.it', '2019-01-18', 208);
INSERT INTO public.tessera VALUES ('ambra.villa@gmail.com', '2015-02-01', 204);
INSERT INTO public.tessera VALUES ('diana.franco@hotmail.com', '2017-12-10', 795);
INSERT INTO public.tessera VALUES ('nicola.giordano@hotmail.com', '2016-04-22', 878);
INSERT INTO public.tessera VALUES ('marta.marino@gmail.com', '2022-09-12', 392);
INSERT INTO public.tessera VALUES ('carlotta.rinaldi@hotmail.com', '2011-03-29', 144);
INSERT INTO public.tessera VALUES ('asia.bruno@hotmail.com', '2012-09-19', 528);
INSERT INTO public.tessera VALUES ('elia.conti@hotmail.com', '2021-09-24', 14);
INSERT INTO public.tessera VALUES ('nathan.franco@hotmail.com', '2022-04-29', 646);
INSERT INTO public.tessera VALUES ('alessio.caruso@hotmail.com', '2014-03-26', 25);
INSERT INTO public.tessera VALUES ('michele.mancini@libero.it', '2014-11-11', 863);
INSERT INTO public.tessera VALUES ('noah.villa@hotmail.com', '2020-08-24', 266);
INSERT INTO public.tessera VALUES ('margherita.conti@gmail.com', '2019-12-22', 883);
INSERT INTO public.tessera VALUES ('gioia.gallo@hotmail.com', '2018-10-29', 702);
INSERT INTO public.tessera VALUES ('jacopo.barbieri@libero.it', '2021-01-19', 992);
INSERT INTO public.tessera VALUES ('alessia.villa@libero.it', '2019-09-24', 712);
INSERT INTO public.tessera VALUES ('miriam.gallo@gmail.com', '2015-06-04', 368);
INSERT INTO public.tessera VALUES ('luigi.leone@gmail.com', '2020-10-19', 303);
INSERT INTO public.tessera VALUES ('ettore.caruso@hotmail.com', '2014-11-18', 266);
INSERT INTO public.tessera VALUES ('daniele.moretti@hotmail.com', '2022-10-10', 165);
INSERT INTO public.tessera VALUES ('ambra.villa@hotmail.com', '2019-02-09', 263);
INSERT INTO public.tessera VALUES ('luigi.mariani@libero.it', '2015-11-08', 622);
INSERT INTO public.tessera VALUES ('anita.moretti@gmail.com', '2020-10-17', 443);
INSERT INTO public.tessera VALUES ('ambra.franco@libero.it', '2011-09-25', 796);
INSERT INTO public.tessera VALUES ('nina.leone@hotmail.com', '2021-09-13', 346);
INSERT INTO public.tessera VALUES ('daniel.marino@hotmail.com', '2017-06-07', 528);
INSERT INTO public.tessera VALUES ('aurora.amato@hotmail.com', '2011-03-23', 659);
INSERT INTO public.tessera VALUES ('luigi.esposito@hotmail.com', '2010-02-21', 863);
INSERT INTO public.tessera VALUES ('francesca.rizzo@hotmail.com', '2015-11-13', 379);
INSERT INTO public.tessera VALUES ('maria.ricci@libero.it', '2011-08-30', 886);
INSERT INTO public.tessera VALUES ('diana.villa@gmail.com', '2022-05-21', 349);
INSERT INTO public.tessera VALUES ('thomas.esposito@libero.it', '2016-06-09', 388);
INSERT INTO public.tessera VALUES ('nathan.barbieri@gmail.com', '2018-11-07', 769);
INSERT INTO public.tessera VALUES ('manuel.conti@hotmail.com', '2010-02-05', 642);
INSERT INTO public.tessera VALUES ('asia.villa@libero.it', '2013-11-21', 471);
INSERT INTO public.tessera VALUES ('anita.martino@libero.it', '2018-08-07', 340);
INSERT INTO public.tessera VALUES ('alessia.rinaldi@libero.it', '2017-07-13', 124);
INSERT INTO public.tessera VALUES ('anita.fratelli@gmail.com', '2014-09-16', 0);
INSERT INTO public.tessera VALUES ('marco.russo@gmail.com', '2020-12-01', 0);
INSERT INTO public.tessera VALUES ('luca.moretti@hotmail.com', '2016-03-08', 0);


--
-- TOC entry 3254 (class 2606 OID 16715)
-- Name: appartiene appartiene_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appartiene
    ADD CONSTRAINT appartiene_pkey PRIMARY KEY (nomepizza, idordinazione);


--
-- TOC entry 3233 (class 2606 OID 16629)
-- Name: cameriere cameriere_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cameriere
    ADD CONSTRAINT cameriere_pkey PRIMARY KEY (idcameriere);


--
-- TOC entry 3235 (class 2606 OID 16631)
-- Name: cameriere cameriere_telefono_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cameriere
    ADD CONSTRAINT cameriere_telefono_key UNIQUE (telefono);


--
-- TOC entry 3227 (class 2606 OID 16609)
-- Name: cliente cliente_numerotelefono_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_numerotelefono_key UNIQUE (numerotelefono);


--
-- TOC entry 3229 (class 2606 OID 16607)
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (mail);


--
-- TOC entry 3249 (class 2606 OID 16684)
-- Name: contiene contiene_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contiene
    ADD CONSTRAINT contiene_pkey PRIMARY KEY (nomepizza, nomeingrediente);


--
-- TOC entry 3237 (class 2606 OID 16640)
-- Name: cuoco cuoco_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuoco
    ADD CONSTRAINT cuoco_pkey PRIMARY KEY (idcuoco);


--
-- TOC entry 3239 (class 2606 OID 16642)
-- Name: cuoco cuoco_telefono_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuoco
    ADD CONSTRAINT cuoco_telefono_key UNIQUE (telefono);


--
-- TOC entry 3245 (class 2606 OID 16674)
-- Name: ingrediente ingrediente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ingrediente
    ADD CONSTRAINT ingrediente_pkey PRIMARY KEY (nomeingrediente);


--
-- TOC entry 3252 (class 2606 OID 16699)
-- Name: ordinazione ordinazione_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordinazione
    ADD CONSTRAINT ordinazione_pkey PRIMARY KEY (idordinazione);


--
-- TOC entry 3247 (class 2606 OID 16679)
-- Name: pizza pizza_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pizza
    ADD CONSTRAINT pizza_pkey PRIMARY KEY (nomepizza);


--
-- TOC entry 3243 (class 2606 OID 16658)
-- Name: prenota prenota_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenota
    ADD CONSTRAINT prenota_pkey PRIMARY KEY (ora, datap, numerotavolo);


--
-- TOC entry 3241 (class 2606 OID 16648)
-- Name: tavolo tavolo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tavolo
    ADD CONSTRAINT tavolo_pkey PRIMARY KEY (numerotavolo);


--
-- TOC entry 3231 (class 2606 OID 16616)
-- Name: tessera tessera_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_pkey PRIMARY KEY (cliente);


--
-- TOC entry 3250 (class 1259 OID 16726)
-- Name: indiceordinazione; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX indiceordinazione ON public.ordinazione USING btree (dataordinazione);


--
-- TOC entry 3265 (class 2620 OID 16728)
-- Name: prenota date_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER date_check BEFORE INSERT ON public.prenota FOR EACH ROW EXECUTE FUNCTION public.check_prenotazioni();


--
-- TOC entry 3266 (class 2620 OID 16730)
-- Name: appartiene ingredienti_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ingredienti_check BEFORE INSERT ON public.appartiene FOR EACH ROW EXECUTE FUNCTION public.check_ingredienti_pizza();


--
-- TOC entry 3263 (class 2606 OID 16721)
-- Name: appartiene appartiene_idordinazione_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appartiene
    ADD CONSTRAINT appartiene_idordinazione_fkey FOREIGN KEY (idordinazione) REFERENCES public.ordinazione(idordinazione) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3264 (class 2606 OID 16716)
-- Name: appartiene appartiene_nomepizza_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appartiene
    ADD CONSTRAINT appartiene_nomepizza_fkey FOREIGN KEY (nomepizza) REFERENCES public.pizza(nomepizza) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3259 (class 2606 OID 16690)
-- Name: contiene contiene_nomeingrediente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contiene
    ADD CONSTRAINT contiene_nomeingrediente_fkey FOREIGN KEY (nomeingrediente) REFERENCES public.ingrediente(nomeingrediente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3260 (class 2606 OID 16685)
-- Name: contiene contiene_nomepizza_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contiene
    ADD CONSTRAINT contiene_nomepizza_fkey FOREIGN KEY (nomepizza) REFERENCES public.pizza(nomepizza) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3261 (class 2606 OID 16700)
-- Name: ordinazione ordinazione_cuoco_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordinazione
    ADD CONSTRAINT ordinazione_cuoco_fkey FOREIGN KEY (cuoco) REFERENCES public.cuoco(idcuoco) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3262 (class 2606 OID 16705)
-- Name: ordinazione ordinazione_mail_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordinazione
    ADD CONSTRAINT ordinazione_mail_cliente_fkey FOREIGN KEY (mail_cliente) REFERENCES public.cliente(mail) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3257 (class 2606 OID 16659)
-- Name: prenota prenota_mail_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenota
    ADD CONSTRAINT prenota_mail_cliente_fkey FOREIGN KEY (mail_cliente) REFERENCES public.cliente(mail) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3258 (class 2606 OID 16664)
-- Name: prenota prenota_numerotavolo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenota
    ADD CONSTRAINT prenota_numerotavolo_fkey FOREIGN KEY (numerotavolo) REFERENCES public.tavolo(numerotavolo) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3256 (class 2606 OID 16649)
-- Name: tavolo tavolo_cameriere_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tavolo
    ADD CONSTRAINT tavolo_cameriere_fkey FOREIGN KEY (cameriere) REFERENCES public.cameriere(idcameriere) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- TOC entry 3255 (class 2606 OID 16617)
-- Name: tessera tessera_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tessera
    ADD CONSTRAINT tessera_cliente_fkey FOREIGN KEY (cliente) REFERENCES public.cliente(mail) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2023-08-20 14:18:05

--
-- PostgreSQL database dump complete
--


--QUERIES

--Restituire il cameriere e la cameriera con il massimo numero di tavoli assegnati

SELECT IdCameriere,Sesso, Nome, Cognome, NumeroTavoliServiti
FROM (
    SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(Tavolo.NumeroTavolo) AS NumeroTavoliServiti, 'M' AS Sesso
    FROM Cameriere
    JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere
    WHERE Cameriere.Sesso = 'M'
    GROUP BY Cameriere.IdCameriere
    UNION ALL
    SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(Tavolo.NumeroTavolo) AS NumeroTavoliServiti, 'F' AS Sesso
    FROM Cameriere
    JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere
    WHERE Cameriere.Sesso = 'F'
    GROUP BY Cameriere.IdCameriere
) AS subquery
ORDER BY NumeroTavoliServiti DESC
LIMIT 2;



-- Restituisci il nome di tutte le pizze che possono essere preparate in base agli ingredienti disponibili

SELECT DISTINCT Pizza.NomePizza
FROM Pizza
JOIN Contiene ON Pizza.NomePizza = Contiene.NomePizza
JOIN Ingrediente ON Contiene.NomeIngrediente = Ingrediente.NomeIngrediente
WHERE Ingrediente.Disponibile = true
GROUP BY Pizza.NomePizza
HAVING COUNT(*) = (
    SELECT COUNT(*)
    FROM Contiene AS C
    WHERE C.NomePizza = Pizza.NomePizza
);



--Restituire i primi 5 clienti che hanno speso in totale piu soldi nel ristorante

SELECT Cliente.Mail, Cliente.Nome, Cliente.Cognome, SUM(Pizza.Prezzo * Appartiene.quantita) AS TotaleSpeso
FROM Cliente
JOIN Ordinazione ON Cliente.Mail = Ordinazione.Mail_Cliente
JOIN Appartiene ON Ordinazione.IdOrdinazione = Appartiene.IdOrdinazione
JOIN Pizza ON Appartiene.NomePizza = Pizza.NomePizza
GROUP BY Cliente.Mail
ORDER BY TotaleSpeso DESC
LIMIT 5;

-- Restituire il nome, cognome e ID dei camerieri che hanno gestito più di 5 Prenotazioni

SELECT Cameriere.IdCameriere, Cameriere.Nome, Cameriere.Cognome, COUNT(*) as NumeroPrenotazioni
FROM Cameriere
JOIN Tavolo ON Cameriere.IdCameriere = Tavolo.Cameriere
JOIN Prenota ON Tavolo.NumeroTavolo = Prenota.NumeroTavolo
GROUP BY Cameriere.IdCameriere
HAVING COUNT(*) > 5
ORDER BY NumeroPrenotazioni ASC;


-- Trovare i cuochi che hanno preparato più di 60 pizze

SELECT C.IdCuoco, C.Nome, C.Cognome, SUM(A.quantita) AS NumeroPizza
FROM Cuoco C
JOIN Ordinazione O ON C.IdCuoco = O.Cuoco
JOIN Appartiene A ON O.IdOrdinazione = A.IdOrdinazione
GROUP BY C.IdCuoco
HAVING SUM(A.quantita) > 60
ORDER BY NumeroPizza DESC;


--Ottenere i 5 clienti con più punti nella tessera

SELECT Cliente.Mail, Cliente.Nome, Cliente.Cognome, Tessera.Punti
FROM Cliente
JOIN Tessera ON Cliente.Mail = Tessera.Cliente
ORDER BY Tessera.Punti DESC
LIMIT 5;

--Restituire gli ingredienti presenti e se sono surgelati di una determinata pizza (Query parametrica, come esempio abbiamo
-- messo la pizza 'Contadina')

SELECT Ingrediente.NomeIngrediente, 
       CASE WHEN Ingrediente.Surgelato THEN 'si' ELSE 'no' END AS Surgelato
FROM Pizza
JOIN Contiene ON Pizza.NomePizza = Contiene.NomePizza
JOIN Ingrediente ON Contiene.NomeIngrediente = Ingrediente.NomeIngrediente
WHERE Pizza.NomePizza = 'Contadina';

--Determinare il numero di clienti che hanno consumato per asporto o al ristorante
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Prenota T
            WHERE O.OraOrdinazione = T.Ora AND O.DataOrdinazione = T.DataP AND O.Mail_Cliente = T.Mail_Cliente
        ) THEN 'Ristorante'
        ELSE 'Asporto'
    END AS Modalita,
    COUNT(*) AS Quantita
FROM Ordinazione O
JOIN Cliente C ON O.Mail_Cliente = C.Mail
GROUP BY Modalita;

--Mostrare il ricavo complessivo nell'anno 2022
SELECT SUM(OrdinazioneImporto.ImportoTotale) AS RicavoComplessivo
FROM (
    SELECT O.IdOrdinazione, SUM(P.Prezzo * AO.quantita) AS ImportoTotale
    FROM Ordinazione AS O
    JOIN Appartiene AS AO ON O.IdOrdinazione = AO.IdOrdinazione
    JOIN Pizza AS P ON AO.NomePizza = P.NomePizza
    WHERE EXTRACT(YEAR FROM O.DataOrdinazione) = 2022
    GROUP BY O.IdOrdinazione
) AS OrdinazioneImporto;
