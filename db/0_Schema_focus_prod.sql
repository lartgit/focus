--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.24

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
-- Name: log; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA log;


--
-- Name: tmp; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tmp;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: addbandarg; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.addbandarg AS (
	index integer,
	pixeltype text,
	initialvalue double precision,
	nodataval double precision
);


--
-- Name: TYPE addbandarg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.addbandarg IS 'postgis raster type: A composite type used as input into the ST_AddBand function defining the attributes and initial value of the new band.';


--
-- Name: agg_count; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.agg_count AS (
	count bigint,
	nband integer,
	exclude_nodata_value boolean,
	sample_percent double precision
);


--
-- Name: raster; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE public.raster;


--
-- Name: raster_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_in(cstring) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_in';


--
-- Name: raster_out(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_out(public.raster) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_out';


--
-- Name: raster; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.raster (
    INTERNALLENGTH = variable,
    INPUT = public.raster_in,
    OUTPUT = public.raster_out,
    ALIGNMENT = double,
    STORAGE = extended
);


--
-- Name: TYPE raster; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.raster IS 'postgis raster type: raster spatial data type.';


--
-- Name: agg_samealignment; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.agg_samealignment AS (
	refraster public.raster,
	aligned boolean
);


--
-- Name: geomval; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.geomval AS (
	geom public.geometry,
	val double precision
);


--
-- Name: TYPE geomval; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.geomval IS 'postgis raster type: A spatial datatype with two fields - geom (holding a geometry object) and val (holding a double precision pixel value from a raster band).';


--
-- Name: rastbandarg; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rastbandarg AS (
	rast public.raster,
	nband integer
);


--
-- Name: TYPE rastbandarg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.rastbandarg IS 'postgis raster type: A composite type for use when needing to express a raster and a band index of that raster.';


--
-- Name: reclassarg; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reclassarg AS (
	nband integer,
	reclassexpr text,
	pixeltype text,
	nodataval double precision
);


--
-- Name: TYPE reclassarg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.reclassarg IS 'postgis raster type: A composite type used as input into the ST_Reclass function defining the behavior of reclassification.';


--
-- Name: summarystats; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.summarystats AS (
	count bigint,
	sum double precision,
	mean double precision,
	stddev double precision,
	min double precision,
	max double precision
);


--
-- Name: TYPE summarystats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.summarystats IS 'postgis raster type: A composite type returned by the ST_SummaryStats and ST_SummaryStatsAgg functions.';


--
-- Name: unionarg; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unionarg AS (
	nband integer,
	uniontype text
);


--
-- Name: TYPE unionarg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.unionarg IS 'postgis raster type: A composite type used as input into the ST_Union function defining the bands to be processed and behavior of the UNION operation.';


--
-- Name: debug(); Type: FUNCTION; Schema: log; Owner: -
--

CREATE FUNCTION log.debug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO log.trigger_logs (
				activity,
				tg_name,
				new_data,
				old_data
			) VALUES (
				(SELECT to_json(json_agg(pg_stat_activity)) FROM pg_stat_activity),
				TG_NAME,
				row_to_json(NEW),
				row_to_json(OLD)
			);
		RETURN NEW;
    END;
$$;


--
-- Name: __st_countagg_transfn(public.agg_count, public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.__st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1) RETURNS public.agg_count
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_count bigint;
		rtn_agg agg_count;
	BEGIN

		-- only process parameter args once
		IF agg IS NULL THEN
			rtn_agg.count := 0;

			IF nband < 1 THEN
				RAISE EXCEPTION 'Band index must be greater than zero (1-based)';
			ELSE
				rtn_agg.nband := nband;
			END IF;

			IF exclude_nodata_value IS FALSE THEN
				rtn_agg.exclude_nodata_value := FALSE;
			ELSE
				rtn_agg.exclude_nodata_value := TRUE;
			END IF;

			IF sample_percent < 0. OR sample_percent > 1. THEN
				RAISE EXCEPTION 'Sample percent must be between zero and one';
			ELSE
				rtn_agg.sample_percent := sample_percent;
			END IF;
		ELSE
			rtn_agg := agg;
		END IF;

		IF rast IS NOT NULL THEN
			IF rtn_agg.exclude_nodata_value IS FALSE THEN
				SELECT width * height INTO _count FROM public.ST_Metadata(rast);
			ELSE
				SELECT count INTO _count FROM public._ST_summarystats(
					rast,
				 	rtn_agg.nband, rtn_agg.exclude_nodata_value,
					rtn_agg.sample_percent
				);
			END IF;
		END IF;

		rtn_agg.count := rtn_agg.count + _count;
		RETURN rtn_agg;
	END;
	$$;


--
-- Name: _add_overview_constraint(name, name, name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_overview_constraint(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, factor integer) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_overview_' || $3;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK ( public._overview_constraint(' || quote_ident($3)
			|| ',' || $7
			|| ',' || quote_literal($4)
			|| ',' || quote_literal($5)
			|| ',' || quote_literal($6)
			|| '))';

		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint(name, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint(cn name, sql text) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $$
	BEGIN
		BEGIN
			EXECUTE sql;
		EXCEPTION
			WHEN duplicate_object THEN
				RAISE NOTICE 'The constraint "%" already exists.  To replace the existing constraint, delete the constraint and call ApplyRasterConstraints again', cn;
			WHEN OTHERS THEN
				RAISE NOTICE 'Unable to add constraint: %', cn;
				RAISE NOTICE 'SQL used for failed constraint: %', sql;
				RAISE NOTICE 'Returned error message: % (%)', SQLERRM, SQLSTATE;
				RETURN FALSE;
		END;

		RETURN TRUE;
	END;
	$$;


--
-- Name: _add_raster_constraint_alignment(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr text;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_same_alignment_' || $3;

		sql := 'SELECT public.st_makeemptyraster(1, 1, upperleftx, upperlefty, scalex, scaley, skewx, skewy, srid) FROM public.st_metadata((SELECT '
			|| quote_ident($3)
			|| ' FROM ' || fqtn || ' LIMIT 1))';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the alignment of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn ||
			' ADD CONSTRAINT ' || quote_ident(cn) ||
			' CHECK (st_samealignment(' || quote_ident($3) || ', ''' || attr || '''::raster))';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_blocksize(name, name, name, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attrset integer[];
		attr integer;
	BEGIN
		IF lower($4) != 'width' AND lower($4) != 'height' THEN
			RAISE EXCEPTION 'axis must be either "width" or "height"';
			RETURN FALSE;
		END IF;

		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_' || $4 || '_' || $3;

		sql := 'SELECT st_' || $4 || '('
			|| quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' GROUP BY 1 ORDER BY count(*) DESC';
		BEGIN
			attrset := ARRAY[]::integer[];
			FOR attr IN EXECUTE sql LOOP
				attrset := attrset || attr;
			END LOOP;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the % of a sample raster: % (%)',
        $4, SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (st_' || $4 || '('
			|| quote_ident($3)
			|| ') IN (' || array_to_string(attrset, ',') || '))';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_coverage_tile(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;

		_scalex double precision;
		_scaley double precision;
		_skewx double precision;
		_skewy double precision;
		_tilewidth integer;
		_tileheight integer;
		_alignment boolean;

		_covextent geometry;
		_covrast raster;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_coverage_tile_' || $3;

		-- metadata
		BEGIN
			sql := 'WITH foo AS (SELECT public.ST_Metadata(' || quote_ident($3) || ') AS meta, public.ST_ConvexHull(' || quote_ident($3) || ') AS hull FROM ' || fqtn || ') SELECT max((meta).scalex), max((meta).scaley), max((meta).skewx), max((meta).skewy), max((meta).width), max((meta).height), public.ST_Union(hull) FROM foo';
			EXECUTE sql INTO _scalex, _scaley, _skewx, _skewy, _tilewidth, _tileheight, _covextent;
		EXCEPTION WHEN OTHERS THEN
			RAISE DEBUG 'Unable to get coverage metadata for %.%: % (%)',
        fqtn, quote_ident($3), SQLERRM, SQLSTATE;
      -- TODO: Why not return false here ?
		END;

		-- rasterize extent
		BEGIN
			_covrast := public.ST_AsRaster(_covextent, _scalex, _scaley, '8BUI', 1, 0, NULL, NULL, _skewx, _skewy);
			IF _covrast IS NULL THEN
				RAISE NOTICE 'Unable to create coverage raster. Cannot add coverage tile constraint: % (%)',
          SQLERRM, SQLSTATE;
				RETURN FALSE;
			END IF;

			-- remove band
			_covrast := ST_MakeEmptyRaster(_covrast);
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to create coverage raster. Cannot add coverage tile constraint: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn ||
			' ADD CONSTRAINT ' || quote_ident(cn) ||
			' CHECK (st_iscoveragetile(' || quote_ident($3) || ', ''' || _covrast || '''::raster, ' || _tilewidth || ', ' || _tileheight || '))';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_extent(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT COST 9000
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr text; srid integer;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		sql := 'SELECT MAX(public.ST_SRID('
            || quote_ident($3)
      || ') ) FROM '
            || fqtn
            || ' HAVING COUNT(DISTINCT public.ST_SRID('
            || quote_ident($3)
      || ') ) = 1';
    EXECUTE sql INTO srid;
    
		cn := 'enforce_max_extent_' || $3;

		IF srid > -1 THEN
      sql := 'SELECT public.st_ashexewkb( public.st_setsrid( public.st_extent( public.st_envelope('
        || quote_ident($3)
        || ')), ' || srid || ')) FROM '
        || fqtn;
      EXECUTE sql INTO attr;
  
      sql := 'ALTER TABLE ' || fqtn
        || ' ADD CONSTRAINT ' || quote_ident(cn)
        || ' CHECK ( public.st_envelope('
        || quote_ident($3)
        || ') @ ''' || attr || '''::geometry) ';
      RETURN  public._add_raster_constraint(cn, sql);
    ELSE 
      -- no valid srid therefore doesn't make sense to set extent
      RETURN false;
    END IF;
	END;
	$_$;


--
-- Name: _add_raster_constraint_nodata_values(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr numeric[];
		max int;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_nodata_values_' || $3;

		sql := 'SELECT public._raster_constraint_nodata_values(' || quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the nodata values of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;
		max := array_length(attr, 1);
		IF max < 1 OR max IS NULL THEN
			RAISE NOTICE 'Unable to get the nodata values of a sample raster (max < 1 or null)';
			RETURN FALSE;
		END IF;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (_raster_constraint_nodata_values(' || quote_ident($3)
			|| ')::numeric[] = ''{';
		FOR x in 1..max LOOP
			IF attr[x] IS NULL THEN
				sql := sql || 'NULL';
			ELSE
				sql := sql || attr[x];
			END IF;
			IF x < max THEN
				sql := sql || ',';
			END IF;
		END LOOP;
		sql := sql || '}''::numeric[])';

		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_num_bands(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr int;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_num_bands_' || $3;

		sql := 'SELECT public.st_numbands(' || quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the number of bands of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (public.st_numbands(' || quote_ident($3)
			|| ') = ' || attr
			|| ')';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_out_db(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr boolean[];
		max int;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_out_db_' || $3;

		sql := 'SELECT public._raster_constraint_out_db(' || quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the out-of-database bands of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;
		max := array_length(attr, 1);
		IF max < 1 OR max IS NULL THEN
			RAISE NOTICE 'Unable to get the out-of-database bands of a sample raster (max < 1 or null)';
			RETURN FALSE;
		END IF;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK ( public._raster_constraint_out_db(' || quote_ident($3)
			|| ') = ''{';
		FOR x in 1..max LOOP
			IF attr[x] IS FALSE THEN
				sql := sql || 'FALSE';
			ELSE
				sql := sql || 'TRUE';
			END IF;
			IF x < max THEN
				sql := sql || ',';
			END IF;
		END LOOP;
		sql := sql || '}''::boolean[])';

		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_pixel_types(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr text[];
		max int;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_pixel_types_' || $3;

		sql := 'SELECT public._raster_constraint_pixel_types(' || quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the pixel types of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;
		max := array_length(attr, 1);
		IF max < 1 OR max IS NULL THEN
			RAISE NOTICE 'Unable to get the pixel types of a sample raster (max < 1 or null)';
			RETURN FALSE;
		END IF;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (_raster_constraint_pixel_types(' || quote_ident($3)
			|| ') = ''{';
		FOR x in 1..max LOOP
			sql := sql || '"' || attr[x] || '"';
			IF x < max THEN
				sql := sql || ',';
			END IF;
		END LOOP;
		sql := sql || '}''::text[])';

		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_scale(name, name, name, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr double precision;
	BEGIN
		IF lower($4) != 'x' AND lower($4) != 'y' THEN
			RAISE EXCEPTION 'axis must be either "x" or "y"';
			RETURN FALSE;
		END IF;

		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_scale' || $4 || '_' || $3;

		sql := 'SELECT st_scale' || $4 || '('
			|| quote_ident($3)
			|| ') FROM '
			|| fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the %-scale of a sample raster: % (%)',
        upper($4), SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (round(st_scale' || $4 || '('
			|| quote_ident($3)
			|| ')::numeric, 10) = round(' || text(attr) || '::numeric, 10))';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_spatially_unique(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr text;
		meta record;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_spatially_unique_' || quote_ident($2) || '_'|| $3;

		sql := 'ALTER TABLE ' || fqtn ||
			' ADD CONSTRAINT ' || quote_ident(cn) ||
			' EXCLUDE ((' || quote_ident($3) || '::geometry) WITH =)';
		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _add_raster_constraint_srid(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._add_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
		cn name;
		sql text;
		attr int;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		cn := 'enforce_srid_' || $3;

		sql := 'SELECT st_srid('
			|| quote_ident($3)
			|| ') FROM ' || fqtn
			|| ' LIMIT 1';
		BEGIN
			EXECUTE sql INTO attr;
		EXCEPTION WHEN OTHERS THEN
			RAISE NOTICE 'Unable to get the SRID of a sample raster: % (%)',
        SQLERRM, SQLSTATE;
			RETURN FALSE;
		END;

		sql := 'ALTER TABLE ' || fqtn
			|| ' ADD CONSTRAINT ' || quote_ident(cn)
			|| ' CHECK (st_srid('
			|| quote_ident($3)
			|| ') = ' || attr || ')';

		RETURN  public._add_raster_constraint(cn, sql);
	END;
	$_$;


--
-- Name: _drop_overview_constraint(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_overview_constraint(ovschema name, ovtable name, ovcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_overview_' || $3) $_$;


--
-- Name: _drop_raster_constraint(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint(rastschema name, rasttable name, cn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		fqtn text;
	BEGIN
		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		BEGIN
			EXECUTE 'ALTER TABLE '
				|| fqtn
				|| ' DROP CONSTRAINT '
				|| quote_ident(cn);
			RETURN TRUE;
		EXCEPTION
			WHEN undefined_object THEN
				RAISE NOTICE 'The constraint "%" does not exist.  Skipping', cn;
			WHEN OTHERS THEN
				RAISE NOTICE 'Unable to drop constraint "%": % (%)',
          cn, SQLERRM, SQLSTATE;
				RETURN FALSE;
		END;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: _drop_raster_constraint_alignment(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_same_alignment_' || $3) $_$;


--
-- Name: _drop_raster_constraint_blocksize(name, name, name, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	BEGIN
		IF lower($4) != 'width' AND lower($4) != 'height' THEN
			RAISE EXCEPTION 'axis must be either "width" or "height"';
			RETURN FALSE;
		END IF;

		RETURN  public._drop_raster_constraint($1, $2, 'enforce_' || $4 || '_' || $3);
	END;
	$_$;


--
-- Name: _drop_raster_constraint_coverage_tile(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_coverage_tile_' || $3) $_$;


--
-- Name: _drop_raster_constraint_extent(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_max_extent_' || $3) $_$;


--
-- Name: _drop_raster_constraint_nodata_values(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_nodata_values_' || $3) $_$;


--
-- Name: _drop_raster_constraint_num_bands(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_num_bands_' || $3) $_$;


--
-- Name: _drop_raster_constraint_out_db(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_out_db_' || $3) $_$;


--
-- Name: _drop_raster_constraint_pixel_types(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_pixel_types_' || $3) $_$;


--
-- Name: _drop_raster_constraint_regular_blocking(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_regular_blocking(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT public._drop_raster_constraint($1, $2, 'enforce_regular_blocking_' || $3) $_$;


--
-- Name: _drop_raster_constraint_scale(name, name, name, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	BEGIN
		IF lower($4) != 'x' AND lower($4) != 'y' THEN
			RAISE EXCEPTION 'axis must be either "x" or "y"';
			RETURN FALSE;
		END IF;

		RETURN  public._drop_raster_constraint($1, $2, 'enforce_scale' || $4 || '_' || $3);
	END;
	$_$;


--
-- Name: _drop_raster_constraint_spatially_unique(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		cn text;
	BEGIN
		SELECT
			s.conname INTO cn
		FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s, pg_index idx, pg_operator op
		WHERE n.nspname = $1
			AND c.relname = $2
			AND a.attname = $3
			AND a.attrelid = c.oid
			AND s.connamespace = n.oid
			AND s.conrelid = c.oid
			AND s.contype = 'x'
			AND 0::smallint = ANY (s.conkey)
			AND idx.indexrelid = s.conindid
			AND pg_get_indexdef(idx.indexrelid, 1, true) LIKE '(' || quote_ident($3) || '::geometry)'
			AND s.conexclop[1] = op.oid
			AND op.oprname = '=';

		RETURN  public._drop_raster_constraint($1, $2, cn); 
	END;
	$_$;


--
-- Name: _drop_raster_constraint_srid(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._drop_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_srid_' || $3) $_$;


--
-- Name: _overview_constraint(public.raster, integer, name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._overview_constraint(ov public.raster, factor integer, refschema name, reftable name, refcolumn name) RETURNS boolean
    LANGUAGE sql STABLE
    AS $_$ SELECT COALESCE((SELECT TRUE FROM public.raster_columns WHERE r_table_catalog = current_database() AND r_table_schema = $3 AND r_table_name = $4 AND r_raster_column = $5), FALSE) $_$;


--
-- Name: _overview_constraint_info(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._overview_constraint_info(ovschema name, ovtable name, ovcolumn name, OUT refschema name, OUT reftable name, OUT refcolumn name, OUT factor integer) RETURNS record
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		split_part(split_part(s.consrc, '''::name', 1), '''', 2)::name,
		split_part(split_part(s.consrc, '''::name', 2), '''', 2)::name,
		split_part(split_part(s.consrc, '''::name', 3), '''', 2)::name,
		trim(both from split_part(s.consrc, ',', 2))::integer
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%_overview_constraint(%'
	$_$;


--
-- Name: _raster_constraint_info_alignment(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_alignment(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		TRUE
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_samealignment(%';
	$_$;


--
-- Name: _raster_constraint_info_blocksize(name, name, name, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		CASE
			WHEN strpos(s.consrc, 'ANY (ARRAY[') > 0 THEN
				split_part((regexp_matches(s.consrc, E'ARRAY\\[(.*?){1}\\]'))[1], ',', 1)::integer
			ELSE
				regexp_replace(
					split_part(s.consrc, '= ', 2),
					'[\(\)]', '', 'g'
				)::integer
			END
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_' || $4 || '(%= %';
	$_$;


--
-- Name: _raster_constraint_info_coverage_tile(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_coverage_tile(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		TRUE
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_iscoveragetile(%';
	$_$;


--
-- Name: _raster_constraint_info_extent(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_extent(rastschema name, rasttable name, rastcolumn name) RETURNS public.geometry
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		trim(both '''' from split_part(trim(split_part(s.consrc, ' @ ', 2)), '::', 1))::geometry
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_envelope(% @ %';
	$_$;


--
-- Name: _raster_constraint_info_index(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_index(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
		SELECT
			TRUE
		FROM pg_catalog.pg_class c
		JOIN pg_catalog.pg_index i
			ON i.indexrelid = c.oid
		JOIN pg_catalog.pg_class c2
			ON i.indrelid = c2.oid
		JOIN pg_catalog.pg_namespace n
			ON n.oid = c.relnamespace
		JOIN pg_am am
			ON c.relam = am.oid
		JOIN pg_attribute att
			ON att.attrelid = c2.oid
				AND pg_catalog.format_type(att.atttypid, att.atttypmod) = 'raster'
		WHERE c.relkind IN ('i')
			AND n.nspname = $1
			AND c2.relname = $2
			AND att.attname = $3
			AND am.amname = 'gist'
			AND strpos(pg_catalog.pg_get_expr(i.indexprs, i.indrelid), att.attname) > 0;
	$_$;


--
-- Name: _raster_constraint_info_nodata_values(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_nodata_values(rastschema name, rasttable name, rastcolumn name) RETURNS double precision[]
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		trim(both '''' from
			split_part(
				regexp_replace(
					split_part(s.consrc, ' = ', 2),
					'[\(\)]', '', 'g'
				),
				'::', 1
			)
		)::double precision[]
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%_raster_constraint_nodata_values(%';
	$_$;


--
-- Name: _raster_constraint_info_num_bands(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_num_bands(rastschema name, rasttable name, rastcolumn name) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		regexp_replace(
			split_part(s.consrc, ' = ', 2),
			'[\(\)]', '', 'g'
		)::integer
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_numbands(%';
	$_$;


--
-- Name: _raster_constraint_info_out_db(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_out_db(rastschema name, rasttable name, rastcolumn name) RETURNS boolean[]
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		trim(
			both '''' from split_part(
				regexp_replace(
					split_part(s.consrc, ' = ', 2),
					'[\(\)]', '', 'g'
				),
				'::', 1
			)
		)::boolean[]
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%_raster_constraint_out_db(%';
	$_$;


--
-- Name: _raster_constraint_info_pixel_types(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_pixel_types(rastschema name, rasttable name, rastcolumn name) RETURNS text[]
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		trim(
			both '''' from split_part(
				regexp_replace(
					split_part(s.consrc, ' = ', 2),
					'[\(\)]', '', 'g'
				),
				'::', 1
			)
		)::text[]
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%_raster_constraint_pixel_types(%';
	$_$;


--
-- Name: _raster_constraint_info_regular_blocking(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_regular_blocking(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		covtile boolean;
		spunique boolean;
	BEGIN
		-- check existance of constraints
		-- coverage tile constraint
		covtile := COALESCE( public._raster_constraint_info_coverage_tile($1, $2, $3), FALSE);

		-- spatially unique constraint
		spunique := COALESCE( public._raster_constraint_info_spatially_unique($1, $2, $3), FALSE);

		RETURN (covtile AND spunique);
	END;
	$_$;


--
-- Name: _raster_constraint_info_scale(name, name, name, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_scale(rastschema name, rasttable name, rastcolumn name, axis character) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$
	WITH c AS (SELECT
		regexp_replace(
			replace(
				split_part(
					split_part(s.consrc, ' = ', 2),
					'::', 1
				),
				'round(', ''
			),
			'[ ''''\(\)]', '', 'g'
		)::text AS val
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_scale' || $4 || '(% = %') 
-- if it is a comma separated list of two numbers then need to use round
   SELECT CASE WHEN split_part(c.val,',', 2) > '' 
        THEN round( split_part(c.val, ',',1)::numeric, split_part(c.val,',',2)::integer )::float8 
        ELSE c.val::float8 END
        FROM c;
	$_$;


--
-- Name: _raster_constraint_info_spatially_unique(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_spatially_unique(rastschema name, rasttable name, rastcolumn name) RETURNS boolean
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		TRUE
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s, pg_index idx, pg_operator op
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND s.contype = 'x'
		AND 0::smallint = ANY (s.conkey)
		AND idx.indexrelid = s.conindid
		AND pg_get_indexdef(idx.indexrelid, 1, true) LIKE '(' || quote_ident($3) || '::geometry)'
		AND s.conexclop[1] = op.oid
		AND op.oprname = '=';
	$_$;


--
-- Name: _raster_constraint_info_srid(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_info_srid(rastschema name, rasttable name, rastcolumn name) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$
	SELECT
		regexp_replace(
			split_part(s.consrc, ' = ', 2),
			'[\(\)]', '', 'g'
		)::integer
	FROM pg_class c, pg_namespace n, pg_attribute a, pg_constraint s
	WHERE n.nspname = $1
		AND c.relname = $2
		AND a.attname = $3
		AND a.attrelid = c.oid
		AND s.connamespace = n.oid
		AND s.conrelid = c.oid
		AND a.attnum = ANY (s.conkey)
		AND s.consrc LIKE '%st_srid(% = %';
	$_$;


--
-- Name: _raster_constraint_nodata_values(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_nodata_values(rast public.raster) RETURNS numeric[]
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT array_agg(round(nodatavalue::numeric, 10))::numeric[] FROM public.ST_BandMetaData($1, ARRAY[]::int[]); $_$;


--
-- Name: _raster_constraint_out_db(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_out_db(rast public.raster) RETURNS boolean[]
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT array_agg(isoutdb)::boolean[] FROM public.ST_BandMetaData($1, ARRAY[]::int[]); $_$;


--
-- Name: _raster_constraint_pixel_types(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._raster_constraint_pixel_types(rast public.raster) RETURNS text[]
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT array_agg(pixeltype)::text[] FROM  public.ST_BandMetaData($1, ARRAY[]::int[]); $_$;


--
-- Name: _st_aspect4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_aspect4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		x integer;
		y integer;
		z integer;

		_width double precision;
		_height double precision;
		_units text;

		dz_dx double precision;
		dz_dy double precision;
		aspect double precision;
		halfpi double precision;

		_value double precision[][][];
		ndims int;
	BEGIN
		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		IF array_length(userargs, 1) < 3 THEN
			RAISE EXCEPTION 'At least three elements must be provided for the third parameter';
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		_width := userargs[1]::double precision;
		_height := userargs[2]::double precision;
		_units := userargs[3];

		
		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		dz_dy := ((_value[z][3][1] + _value[z][3][2] + _value[z][3][2] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][1][2] + _value[z][1][2] + _value[z][1][3]));
		dz_dx := ((_value[z][1][3] + _value[z][2][3] + _value[z][2][3] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][2][1] + _value[z][2][1] + _value[z][3][1]));

		-- aspect is flat
		IF abs(dz_dx) = 0::double precision AND abs(dz_dy) = 0::double precision THEN
			RETURN -1;
		END IF;

		-- aspect is in radians
		aspect := atan2(dz_dy, -dz_dx);

		-- north = 0, pi/2 = east, 3pi/2 = west
		halfpi := pi() / 2.0;
		IF aspect > halfpi THEN
			aspect := (5.0 * halfpi) - aspect;
		ELSE
			aspect := halfpi - aspect;
		END IF;

		IF aspect = 2 * pi() THEN
			aspect := 0.;
		END IF;

		-- output depends on user preference
		CASE substring(upper(trim(leading from _units)) for 3)
			-- radians
			WHEN 'rad' THEN
				RETURN aspect;
			-- degrees (default)
			ELSE
				RETURN degrees(aspect);
		END CASE;

	END;
	$$;


--
-- Name: _st_asraster(public.geometry, double precision, double precision, integer, integer, text[], double precision[], double precision[], double precision, double precision, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_asraster(geom public.geometry, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, width integer DEFAULT 0, height integer DEFAULT 0, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_asRaster';


--
-- Name: _st_clip(public.raster, integer[], public.geometry, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_clip(rast public.raster, nband integer[], geom public.geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_clip';


--
-- Name: _st_colormap(public.raster, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_colormap(rast public.raster, nband integer, colormap text, method text DEFAULT 'INTERPOLATE'::text) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_colorMap';


--
-- Name: _st_contains(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000
    AS '$libdir/rtpostgis-2.3', 'RASTER_contains';


--
-- Name: _st_containsproperly(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_containsProperly';


--
-- Name: _st_convertarray4ma(double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_convertarray4ma(value double precision[]) RETURNS double precision[]
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		x int;
		y int;
	BEGIN
		IF array_ndims(value) != 2 THEN
			RAISE EXCEPTION 'Function parameter must be a 2-dimension array';
		END IF;

		_value := array_fill(NULL::double precision, ARRAY[1, array_length(value, 1), array_length(value, 2)]::int[], ARRAY[1, array_lower(value, 1), array_lower(value, 2)]::int[]);

		-- row
		FOR y IN array_lower(value, 1)..array_upper(value, 1) LOOP
			-- column
			FOR x IN array_lower(value, 2)..array_upper(value, 2) LOOP
				_value[1][y][x] = value[y][x];
			END LOOP;
		END LOOP;

		RETURN _value;
	END;
	$$;


--
-- Name: _st_count(public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_count(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		rtn bigint;
	BEGIN
		IF exclude_nodata_value IS FALSE THEN
			SELECT width * height INTO rtn FROM public.ST_Metadata(rast);
		ELSE
			SELECT count INTO rtn FROM public._ST_summarystats($1, $2, $3, $4);
		END IF;

		RETURN rtn;
	END;
	$_$;


--
-- Name: _st_count(text, text, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_count(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1) RETURNS bigint
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		count bigint;
	BEGIN
		EXECUTE 'SELECT public.ST_CountAgg('
			|| quote_ident($2) || ', '
			|| $3 || ', '
			|| $4 || ', '
			|| $5 || ') '
			|| 'FROM ' || quote_ident($1)
	 	INTO count;
		RETURN count;
	END;
 	$_$;


--
-- Name: _st_countagg_finalfn(public.agg_count); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_countagg_finalfn(agg public.agg_count) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	BEGIN
		IF agg IS NULL THEN
			RAISE EXCEPTION 'Cannot count coverage';
		END IF;

		RETURN agg.count;
	END;
	$$;


--
-- Name: _st_countagg_transfn(public.agg_count, public.raster, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, exclude_nodata_value boolean) RETURNS public.agg_count
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		rtn_agg agg_count;
	BEGIN
		rtn_agg :=  public.__ST_countagg_transfn(
			agg,
			rast,
			1, exclude_nodata_value,
			1
		);
		RETURN rtn_agg;
	END;
	$$;


--
-- Name: _st_countagg_transfn(public.agg_count, public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer, exclude_nodata_value boolean) RETURNS public.agg_count
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		rtn_agg agg_count;
	BEGIN
		rtn_agg :=  public.__ST_countagg_transfn(
			agg,
			rast,
			nband, exclude_nodata_value,
			1
		);
		RETURN rtn_agg;
	END;
	$$;


--
-- Name: _st_countagg_transfn(public.agg_count, public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_countagg_transfn(agg public.agg_count, rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) RETURNS public.agg_count
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		rtn_agg agg_count;
	BEGIN
		rtn_agg :=  public.__st_countagg_transfn(
			agg,
			rast,
			nband, exclude_nodata_value,
			sample_percent
		);
		RETURN rtn_agg;
	END;
	$$;


--
-- Name: _st_coveredby(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_coveredby';


--
-- Name: _st_covers(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_covers';


--
-- Name: _st_dfullywithin(public.raster, integer, public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_dfullywithin';


--
-- Name: _st_dwithin(public.raster, integer, public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_dwithin';


--
-- Name: _st_gdalwarp(public.raster, text, double precision, integer, double precision, double precision, double precision, double precision, double precision, double precision, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_gdalwarp(rast public.raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, srid integer DEFAULT NULL::integer, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, width integer DEFAULT NULL::integer, height integer DEFAULT NULL::integer) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_GDALWarp';


--
-- Name: _st_hillshade4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_hillshade4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_pixwidth double precision;
		_pixheight double precision;
		_width double precision;
		_height double precision;
		_azimuth double precision;
		_altitude double precision;
		_bright double precision;
		_scale double precision;

		dz_dx double precision;
		dz_dy double precision;
		azimuth double precision;
		zenith double precision;
		slope double precision;
		aspect double precision;
		shade double precision;

		_value double precision[][][];
		ndims int;
		z int;
	BEGIN
		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		IF array_length(userargs, 1) < 8 THEN
			RAISE EXCEPTION 'At least eight elements must be provided for the third parameter';
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		_pixwidth := userargs[1]::double precision;
		_pixheight := userargs[2]::double precision;
		_width := userargs[3]::double precision;
		_height := userargs[4]::double precision;
		_azimuth := userargs[5]::double precision;
		_altitude := userargs[6]::double precision;
		_bright := userargs[7]::double precision;
		_scale := userargs[8]::double precision;

		-- check that pixel is not edge pixel
		IF (pos[1][1] = 1 OR pos[1][2] = 1) OR (pos[1][1] = _width OR pos[1][2] = _height) THEN
			RETURN NULL;
		END IF;

		-- clamp azimuth
		IF _azimuth < 0. THEN
			RAISE NOTICE 'Clamping provided azimuth value % to 0', _azimuth;
			_azimuth := 0.;
		ELSEIF _azimuth >= 360. THEN
			RAISE NOTICE 'Converting provided azimuth value % to be between 0 and 360', _azimuth;
			_azimuth := _azimuth - (360. * floor(_azimuth / 360.));
		END IF;
		azimuth := 360. - _azimuth + 90.;
		IF azimuth >= 360. THEN
			azimuth := azimuth - 360.;
		END IF;
		azimuth := radians(azimuth);
		--RAISE NOTICE 'azimuth = %', azimuth;

		-- clamp altitude
		IF _altitude < 0. THEN
			RAISE NOTICE 'Clamping provided altitude value % to 0', _altitude;
			_altitude := 0.;
		ELSEIF _altitude > 90. THEN
			RAISE NOTICE 'Clamping provided altitude value % to 90', _altitude;
			_altitude := 90.;
		END IF;
		zenith := radians(90. - _altitude);
		--RAISE NOTICE 'zenith = %', zenith;

		-- clamp bright
		IF _bright < 0. THEN
			RAISE NOTICE 'Clamping provided bright value % to 0', _bright;
			_bright := 0.;
		ELSEIF _bright > 255. THEN
			RAISE NOTICE 'Clamping provided bright value % to 255', _bright;
			_bright := 255.;
		END IF;

		dz_dy := ((_value[z][3][1] + _value[z][3][2] + _value[z][3][2] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][1][2] + _value[z][1][2] + _value[z][1][3])) / (8 * _pixheight);
		dz_dx := ((_value[z][1][3] + _value[z][2][3] + _value[z][2][3] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][2][1] + _value[z][2][1] + _value[z][3][1])) / (8 * _pixwidth);

		slope := atan(sqrt(dz_dx * dz_dx + dz_dy * dz_dy) / _scale);

		IF dz_dx != 0. THEN
			aspect := atan2(dz_dy, -dz_dx);

			IF aspect < 0. THEN
				aspect := aspect + (2.0 * pi());
			END IF;
		ELSE
			IF dz_dy > 0. THEN
				aspect := pi() / 2.;
			ELSEIF dz_dy < 0. THEN
				aspect := (2. * pi()) - (pi() / 2.);
			-- set to pi as that is the expected PostgreSQL answer in Linux
			ELSE
				aspect := pi();
			END IF;
		END IF;

		shade := _bright * ((cos(zenith) * cos(slope)) + (sin(zenith) * sin(slope) * cos(azimuth - aspect)));

		IF shade < 0. THEN
			shade := 0;
		END IF;

		RETURN shade;
	END;
	$$;


--
-- Name: _st_histogram(text, text, integer, boolean, double precision, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_histogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_histogramCoverage';


--
-- Name: _st_histogram(public.raster, integer, boolean, double precision, integer, double precision[], boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_histogram(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, min double precision DEFAULT NULL::double precision, max double precision DEFAULT NULL::double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_histogram';


--
-- Name: _st_intersects(public.geometry, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_intersects(geom public.geometry, rast public.raster, nband integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $$
	DECLARE
		hasnodata boolean := TRUE;
		_geom geometry;
	BEGIN
		IF ST_SRID(rast) != ST_SRID(geom) THEN
			RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
		END IF;

		_geom := ST_ConvexHull(rast);
		IF nband IS NOT NULL THEN
			SELECT CASE WHEN bmd.nodatavalue IS NULL THEN FALSE ELSE NULL END INTO hasnodata FROM public.ST_BandMetaData(rast, nband) AS bmd;
		END IF;

		IF ST_Intersects(geom, _geom) IS NOT TRUE THEN
			RETURN FALSE;
		ELSEIF nband IS NULL OR hasnodata IS FALSE THEN
			RETURN TRUE;
		END IF;

		SELECT public.ST_Collect(t.geom) INTO _geom FROM public.ST_PixelAsPolygons(rast, nband) AS t;
		RETURN public.ST_Intersects(geom, _geom);
	END;
	$$;


--
-- Name: _st_intersects(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_intersects(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_intersects';


--
-- Name: _st_mapalgebra(public.rastbandarg[], text, text, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_mapalgebra(rastbandargset public.rastbandarg[], expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_nMapAlgebraExpr';


--
-- Name: _st_mapalgebra(public.rastbandarg[], regprocedure, text, integer, integer, text, public.raster, double precision[], boolean, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_mapalgebra(rastbandargset public.rastbandarg[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, distancex integer DEFAULT 0, distancey integer DEFAULT 0, extenttype text DEFAULT 'INTERSECTION'::text, customextent public.raster DEFAULT NULL::public.raster, mask double precision[] DEFAULT NULL::double precision[], weighted boolean DEFAULT NULL::boolean, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_nMapAlgebra';


--
-- Name: _st_neighborhood(public.raster, integer, integer, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_neighborhood';


--
-- Name: _st_overlaps(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000
    AS '$libdir/rtpostgis-2.3', 'RASTER_overlaps';


--
-- Name: _st_pixelaspolygons(public.raster, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_pixelaspolygons(rast public.raster, band integer DEFAULT 1, columnx integer DEFAULT NULL::integer, rowy integer DEFAULT NULL::integer, exclude_nodata_value boolean DEFAULT true, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getPixelPolygons';


--
-- Name: _st_quantile(public.raster, integer, boolean, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_quantile(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_quantile';


--
-- Name: _st_quantile(text, text, integer, boolean, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_quantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_quantileCoverage';


--
-- Name: _st_rastertoworldcoord(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_rastertoworldcoord(rast public.raster, columnx integer DEFAULT NULL::integer, rowy integer DEFAULT NULL::integer, OUT longitude double precision, OUT latitude double precision) RETURNS record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_rasterToWorldCoord';


--
-- Name: _st_reclass(public.raster, public.reclassarg[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_reclass(rast public.raster, VARIADIC reclassargset public.reclassarg[]) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_reclass';


--
-- Name: _st_roughness4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_roughness4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		x integer;
		y integer;
		z integer;

		minimum double precision;
		maximum double precision;

		_value double precision[][][];
		ndims int;
	BEGIN

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		minimum := _value[z][1][1];
		maximum := _value[z][1][1];

		FOR Y IN 1..3 LOOP
		    FOR X IN 1..3 LOOP
		    	 IF _value[z][y][x] < minimum THEN
			    minimum := _value[z][y][x];
			 ELSIF _value[z][y][x] > maximum THEN
			    maximum := _value[z][y][x];
			 END IF;
		    END LOOP;
		END LOOP;

		RETURN maximum - minimum;
	END;
	$$;


--
-- Name: _st_samealignment_finalfn(public.agg_samealignment); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_samealignment_finalfn(agg public.agg_samealignment) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT $1.aligned $_$;


--
-- Name: _st_samealignment_transfn(public.agg_samealignment, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_samealignment_transfn(agg public.agg_samealignment, rast public.raster) RETURNS public.agg_samealignment
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		m record;
		aligned boolean;
	BEGIN
		IF agg IS NULL THEN
			agg.refraster := NULL;
			agg.aligned := NULL;
		END IF;

		IF rast IS NULL THEN
			agg.aligned := NULL;
		ELSE
			IF agg.refraster IS NULL THEN
				m := ST_Metadata(rast);
				agg.refraster := ST_MakeEmptyRaster(1, 1, m.upperleftx, m.upperlefty, m.scalex, m.scaley, m.skewx, m.skewy, m.srid);
				agg.aligned := TRUE;
			ELSE IF agg.aligned IS TRUE THEN
					agg.aligned := ST_SameAlignment(agg.refraster, rast);
				END IF;
			END IF;
		END IF;
		RETURN agg;
	END;
	$$;


--
-- Name: _st_setvalues(public.raster, integer, integer, integer, double precision[], boolean[], boolean, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[] DEFAULT NULL::boolean[], hasnosetvalue boolean DEFAULT false, nosetvalue double precision DEFAULT NULL::double precision, keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setPixelValuesArray';


--
-- Name: _st_slope4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_slope4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		x integer;
		y integer;
		z integer;

		_pixwidth double precision;
		_pixheight double precision;
		_width double precision;
		_height double precision;
		_units text;
		_scale double precision;

		dz_dx double precision;
		dz_dy double precision;

		slope double precision;

		_value double precision[][][];
		ndims int;
	BEGIN

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		IF array_length(userargs, 1) < 6 THEN
			RAISE EXCEPTION 'At least six elements must be provided for the third parameter';
		END IF;

		_pixwidth := userargs[1]::double precision;
		_pixheight := userargs[2]::double precision;
		_width := userargs[3]::double precision;
		_height := userargs[4]::double precision;
		_units := userargs[5];
		_scale := userargs[6]::double precision;

		
		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		dz_dy := ((_value[z][3][1] + _value[z][3][2] + _value[z][3][2] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][1][2] + _value[z][1][2] + _value[z][1][3])) / _pixheight;
		dz_dx := ((_value[z][1][3] + _value[z][2][3] + _value[z][2][3] + _value[z][3][3]) -
			(_value[z][1][1] + _value[z][2][1] + _value[z][2][1] + _value[z][3][1])) / _pixwidth;

		slope := sqrt(dz_dx * dz_dx + dz_dy * dz_dy) / (8 * _scale);

		-- output depends on user preference
		CASE substring(upper(trim(leading from _units)) for 3)
			-- percentages
			WHEN 'PER' THEN
				slope := 100.0 * slope;
			-- radians
			WHEN 'rad' THEN
				slope := atan(slope);
			-- degrees (default)
			ELSE
				slope := degrees(atan(slope));
		END CASE;

		RETURN slope;
	END;
	$$;


--
-- Name: _st_summarystats(public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1) RETURNS public.summarystats
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_summaryStats';


--
-- Name: _st_summarystats(text, text, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1) RETURNS public.summarystats
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$ 
	DECLARE
		stats summarystats;
	BEGIN
		EXECUTE 'SELECT (stats).* FROM (SELECT public.ST_SummaryStatsAgg('
			|| quote_ident($2) || ', '
			|| $3 || ', '
			|| $4 || ', '
			|| $5 || ') AS stats '
			|| 'FROM ' || quote_ident($1)
			|| ') foo'
			INTO stats;
		RETURN stats;
	END;
	$_$;


--
-- Name: _st_summarystats_finalfn(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats_finalfn(internal) RETURNS public.summarystats
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_summaryStats_finalfn';


--
-- Name: _st_summarystats_transfn(internal, public.raster, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats_transfn(internal, public.raster, boolean, double precision) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_summaryStats_transfn';


--
-- Name: _st_summarystats_transfn(internal, public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats_transfn(internal, public.raster, integer, boolean) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_summaryStats_transfn';


--
-- Name: _st_summarystats_transfn(internal, public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_summarystats_transfn(internal, public.raster, integer, boolean, double precision) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_summaryStats_transfn';


--
-- Name: _st_tile(public.raster, integer, integer, integer[], boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_tile(rast public.raster, width integer, height integer, nband integer[] DEFAULT NULL::integer[], padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision) RETURNS SETOF public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_tile';


--
-- Name: _st_touches(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT COST 1000 PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_touches';


--
-- Name: _st_tpi4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_tpi4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		x integer;
		y integer;
		z integer;

		Z1 double precision;
		Z2 double precision;
		Z3 double precision;
		Z4 double precision;
		Z5 double precision;
		Z6 double precision;
		Z7 double precision;
		Z8 double precision;
		Z9 double precision;

		tpi double precision;
		mean double precision;
		_value double precision[][][];
		ndims int;
	BEGIN
		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		-------------------------------------------------
		--|   Z1= Z(-1,1) |  Z2= Z(0,1)	| Z3= Z(1,1)  |--
		-------------------------------------------------
		--|   Z4= Z(-1,0) |  Z5= Z(0,0) | Z6= Z(1,0)  |--
		-------------------------------------------------
		--|   Z7= Z(-1,-1)|  Z8= Z(0,-1)|  Z9= Z(1,-1)|--
		-------------------------------------------------

		Z1 := _value[z][1][1];
		Z2 := _value[z][2][1];
		Z3 := _value[z][3][1];
		Z4 := _value[z][1][2];
		Z5 := _value[z][2][2];
		Z6 := _value[z][3][2];
		Z7 := _value[z][1][3];
		Z8 := _value[z][2][3];
		Z9 := _value[z][3][3];

		mean := (Z1 + Z2 + Z3 + Z4 + Z6 + Z7 + Z8 + Z9)/8;
		tpi := Z5-mean;
		
		return tpi;
	END;
	$$;


--
-- Name: _st_tri4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_tri4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		x integer;
		y integer;
		z integer;

		Z1 double precision;
		Z2 double precision;
		Z3 double precision;
		Z4 double precision;
		Z5 double precision;
		Z6 double precision;
		Z7 double precision;
		Z8 double precision;
		Z9 double precision;

		tri double precision;
		_value double precision[][][];
		ndims int;
	BEGIN
		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		IF (
			array_lower(_value, 2) != 1 OR array_upper(_value, 2) != 3 OR
			array_lower(_value, 3) != 1 OR array_upper(_value, 3) != 3
		) THEN
			RAISE EXCEPTION 'First parameter of function must be a 1x3x3 array with each of the lower bounds starting from 1';
		END IF;

		-- check that center pixel isn't NODATA
		IF _value[z][2][2] IS NULL THEN
			RETURN NULL;
		-- substitute center pixel for any neighbor pixels that are NODATA
		ELSE
			FOR y IN 1..3 LOOP
				FOR x IN 1..3 LOOP
					IF _value[z][y][x] IS NULL THEN
						_value[z][y][x] = _value[z][2][2];
					END IF;
				END LOOP;
			END LOOP;
		END IF;

		-------------------------------------------------
		--|   Z1= Z(-1,1) |  Z2= Z(0,1)	| Z3= Z(1,1)  |--
		-------------------------------------------------
		--|   Z4= Z(-1,0) |  Z5= Z(0,0) | Z6= Z(1,0)  |--
		-------------------------------------------------
		--|   Z7= Z(-1,-1)|  Z8= Z(0,-1)|  Z9= Z(1,-1)|--
		-------------------------------------------------

		-- _scale width and height units / z units to make z units equal to height width units
		Z1 := _value[z][1][1];
		Z2 := _value[z][2][1];
		Z3 := _value[z][3][1];
		Z4 := _value[z][1][2];
		Z5 := _value[z][2][2];
		Z6 := _value[z][3][2];
		Z7 := _value[z][1][3];
		Z8 := _value[z][2][3];
		Z9 := _value[z][3][3];

		tri := ( abs(Z1 - Z5 ) + abs( Z2 - Z5 ) + abs( Z3 - Z5 ) + abs( Z4 - Z5 ) + abs( Z6 - Z5 ) + abs( Z7 - Z5 ) + abs( Z8 - Z5 ) + abs ( Z9 - Z5 )) / 8;
		
		return tri;  
	END;
	$$;


--
-- Name: _st_union_finalfn(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_finalfn(internal) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_finalfn';


--
-- Name: _st_union_transfn(internal, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_transfn(internal, public.raster) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_transfn';


--
-- Name: _st_union_transfn(internal, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_transfn(internal, public.raster, integer) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_transfn';


--
-- Name: _st_union_transfn(internal, public.raster, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_transfn(internal, public.raster, text) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_transfn';


--
-- Name: _st_union_transfn(internal, public.raster, public.unionarg[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_transfn(internal, public.raster, public.unionarg[]) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_transfn';


--
-- Name: _st_union_transfn(internal, public.raster, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_union_transfn(internal, public.raster, integer, text) RETURNS internal
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_union_transfn';


--
-- Name: _st_valuecount(public.raster, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_valuecount(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer, OUT percent double precision) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_valueCount';


--
-- Name: _st_valuecount(text, text, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_valuecount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer, OUT percent double precision) RETURNS SETOF record
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_valueCountCoverage';


--
-- Name: _st_within(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public._st_contains($3, $4, $1, $2) $_$;


--
-- Name: _st_worldtorastercoord(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._st_worldtorastercoord(rast public.raster, longitude double precision DEFAULT NULL::double precision, latitude double precision DEFAULT NULL::double precision, OUT columnx integer, OUT rowy integer) RETURNS record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_worldToRasterCoord';


--
-- Name: _updaterastersrid(name, name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		fqtn text;
		schema name;
		sql text;
		srid integer;
		ct boolean;
	BEGIN
		-- validate schema
		schema := NULL;
		IF length($1) > 0 THEN
			sql := 'SELECT nspname FROM pg_namespace '
				|| 'WHERE nspname = ' || quote_literal($1)
				|| 'LIMIT 1';
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The value provided for schema is invalid';
				RETURN FALSE;
			END IF;
		END IF;

		IF schema IS NULL THEN
			sql := 'SELECT n.nspname AS schemaname '
				|| 'FROM pg_catalog.pg_class c '
				|| 'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace '
				|| 'WHERE c.relkind = ' || quote_literal('r')
				|| ' AND n.nspname NOT IN (' || quote_literal('pg_catalog')
				|| ', ' || quote_literal('pg_toast')
				|| ') AND pg_catalog.pg_table_is_visible(c.oid)'
				|| ' AND c.relname = ' || quote_literal($2);
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The table % does not occur in the search_path', quote_literal($2);
				RETURN FALSE;
			END IF;
		END IF;

		-- clamp SRID
		IF new_srid < 0 THEN
			srid :=  public.ST_SRID('POINT EMPTY'::public.geometry);
			RAISE NOTICE 'SRID % converted to the officially unknown SRID %', new_srid, srid;
		ELSE
			srid := new_srid;
		END IF;

		-- drop coverage tile constraint
		-- done separately just in case constraint doesn't exist
		ct := public._raster_constraint_info_coverage_tile(schema, $2, $3);
		IF ct IS TRUE THEN
			PERFORM  public._drop_raster_constraint_coverage_tile(schema, $2, $3);
		END IF;

		-- drop SRID, extent, alignment constraints
		PERFORM  public.DropRasterConstraints(schema, $2, $3, 'extent', 'alignment', 'srid');

		fqtn := '';
		IF length($1) > 0 THEN
			fqtn := quote_ident($1) || '.';
		END IF;
		fqtn := fqtn || quote_ident($2);

		-- update SRID
		sql := 'UPDATE ' || fqtn ||
			' SET ' || quote_ident($3) ||
			' =  public.ST_SetSRID(' || quote_ident($3) ||
			'::raster, ' || srid || ')';
		RAISE NOTICE 'sql = %', sql;
		EXECUTE sql;

		-- add SRID constraint
		PERFORM  public.AddRasterConstraints(schema, $2, $3, 'srid', 'extent', 'alignment');

		-- add coverage tile constraint if needed
		IF ct IS TRUE THEN
			PERFORM  public._add_raster_constraint_coverage_tile(schema, $2, $3);
		END IF;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: addoverviewconstraints(name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public.AddOverviewConstraints('', $1, $2, '', $3, $4, $5) $_$;


--
-- Name: FUNCTION addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer) IS 'args: ovtable, ovcolumn, reftable, refcolumn, ovfactor - Tag a raster column as being an overview of another.';


--
-- Name: addoverviewconstraints(name, name, name, name, name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		x int;
		s name;
		t name;
		oschema name;
		rschema name;
		sql text;
		rtn boolean;
	BEGIN
		FOR x IN 1..2 LOOP
			s := '';

			IF x = 1 THEN
				s := $1;
				t := $2;
			ELSE
				s := $4;
				t := $5;
			END IF;

			-- validate user-provided schema
			IF length(s) > 0 THEN
				sql := 'SELECT nspname FROM pg_namespace '
					|| 'WHERE nspname = ' || quote_literal(s)
					|| 'LIMIT 1';
				EXECUTE sql INTO s;

				IF s IS NULL THEN
					RAISE EXCEPTION 'The value % is not a valid schema', quote_literal(s);
					RETURN FALSE;
				END IF;
			END IF;

			-- no schema, determine what it could be using the table
			IF length(s) < 1 THEN
				sql := 'SELECT n.nspname AS schemaname '
					|| 'FROM pg_catalog.pg_class c '
					|| 'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace '
					|| 'WHERE c.relkind = ' || quote_literal('r')
					|| ' AND n.nspname NOT IN (' || quote_literal('pg_catalog')
					|| ', ' || quote_literal('pg_toast')
					|| ') AND pg_catalog.pg_table_is_visible(c.oid)'
					|| ' AND c.relname = ' || quote_literal(t);
				EXECUTE sql INTO s;

				IF s IS NULL THEN
					RAISE EXCEPTION 'The table % does not occur in the search_path', quote_literal(t);
					RETURN FALSE;
				END IF;
			END IF;

			IF x = 1 THEN
				oschema := s;
			ELSE
				rschema := s;
			END IF;
		END LOOP;

		-- reference raster
		rtn :=  public._add_overview_constraint(oschema, $2, $3, rschema, $5, $6, $7);
		IF rtn IS FALSE THEN
			RAISE EXCEPTION 'Unable to add the overview constraint.  Is the schema name, table name or column name incorrect?';
			RETURN FALSE;
		END IF;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: FUNCTION addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer) IS 'args: ovschema, ovtable, ovcolumn, refschema, reftable, refcolumn, ovfactor - Tag a raster column as being an overview of another.';


--
-- Name: addrasterconstraints(name, name, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT public.AddRasterConstraints('', $1, $2, VARIADIC $3) $_$;


--
-- Name: FUNCTION addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) IS 'args: rasttable, rastcolumn, VARIADIC constraints - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.';


--
-- Name: addrasterconstraints(name, name, name, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		max int;
		cnt int;
		sql text;
		schema name;
		x int;
		kw text;
		rtn boolean;
	BEGIN
		cnt := 0;
		max := array_length(constraints, 1);
		IF max < 1 THEN
			RAISE NOTICE 'No constraints indicated to be added.  Doing nothing';
			RETURN TRUE;
		END IF;

		-- validate schema
		schema := NULL;
		IF length($1) > 0 THEN
			sql := 'SELECT nspname FROM pg_namespace '
				|| 'WHERE nspname = ' || quote_literal($1)
				|| 'LIMIT 1';
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The value provided for schema is invalid';
				RETURN FALSE;
			END IF;
		END IF;

		IF schema IS NULL THEN
			sql := 'SELECT n.nspname AS schemaname '
				|| 'FROM pg_catalog.pg_class c '
				|| 'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace '
				|| 'WHERE c.relkind = ' || quote_literal('r')
				|| ' AND n.nspname NOT IN (' || quote_literal('pg_catalog')
				|| ', ' || quote_literal('pg_toast')
				|| ') AND pg_catalog.pg_table_is_visible(c.oid)'
				|| ' AND c.relname = ' || quote_literal($2);
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The table % does not occur in the search_path', quote_literal($2);
				RETURN FALSE;
			END IF;
		END IF;

		<<kwloop>>
		FOR x in 1..max LOOP
			kw := trim(both from lower(constraints[x]));

			BEGIN
				CASE
					WHEN kw = 'srid' THEN
						RAISE NOTICE 'Adding SRID constraint';
						rtn :=  public._add_raster_constraint_srid(schema, $2, $3);
					WHEN kw IN ('scale_x', 'scalex') THEN
						RAISE NOTICE 'Adding scale-X constraint';
						rtn :=  public._add_raster_constraint_scale(schema, $2, $3, 'x');
					WHEN kw IN ('scale_y', 'scaley') THEN
						RAISE NOTICE 'Adding scale-Y constraint';
						rtn :=  public._add_raster_constraint_scale(schema, $2, $3, 'y');
					WHEN kw = 'scale' THEN
						RAISE NOTICE 'Adding scale-X constraint';
						rtn :=  public._add_raster_constraint_scale(schema, $2, $3, 'x');
						RAISE NOTICE 'Adding scale-Y constraint';
						rtn :=  public._add_raster_constraint_scale(schema, $2, $3, 'y');
					WHEN kw IN ('blocksize_x', 'blocksizex', 'width') THEN
						RAISE NOTICE 'Adding blocksize-X constraint';
						rtn :=  public._add_raster_constraint_blocksize(schema, $2, $3, 'width');
					WHEN kw IN ('blocksize_y', 'blocksizey', 'height') THEN
						RAISE NOTICE 'Adding blocksize-Y constraint';
						rtn :=  public._add_raster_constraint_blocksize(schema, $2, $3, 'height');
					WHEN kw = 'blocksize' THEN
						RAISE NOTICE 'Adding blocksize-X constraint';
						rtn :=  public._add_raster_constraint_blocksize(schema, $2, $3, 'width');
						RAISE NOTICE 'Adding blocksize-Y constraint';
						rtn :=  public._add_raster_constraint_blocksize(schema, $2, $3, 'height');
					WHEN kw IN ('same_alignment', 'samealignment', 'alignment') THEN
						RAISE NOTICE 'Adding alignment constraint';
						rtn :=  public._add_raster_constraint_alignment(schema, $2, $3);
					WHEN kw IN ('regular_blocking', 'regularblocking') THEN
						RAISE NOTICE 'Adding coverage tile constraint required for regular blocking';
						rtn :=  public._add_raster_constraint_coverage_tile(schema, $2, $3);
						IF rtn IS NOT FALSE THEN
							RAISE NOTICE 'Adding spatially unique constraint required for regular blocking';
							rtn :=  public._add_raster_constraint_spatially_unique(schema, $2, $3);
						END IF;
					WHEN kw IN ('num_bands', 'numbands') THEN
						RAISE NOTICE 'Adding number of bands constraint';
						rtn :=  public._add_raster_constraint_num_bands(schema, $2, $3);
					WHEN kw IN ('pixel_types', 'pixeltypes') THEN
						RAISE NOTICE 'Adding pixel type constraint';
						rtn :=  public._add_raster_constraint_pixel_types(schema, $2, $3);
					WHEN kw IN ('nodata_values', 'nodatavalues', 'nodata') THEN
						RAISE NOTICE 'Adding nodata value constraint';
						rtn :=  public._add_raster_constraint_nodata_values(schema, $2, $3);
					WHEN kw IN ('out_db', 'outdb') THEN
						RAISE NOTICE 'Adding out-of-database constraint';
						rtn :=  public._add_raster_constraint_out_db(schema, $2, $3);
					WHEN kw = 'extent' THEN
						RAISE NOTICE 'Adding maximum extent constraint';
						rtn :=  public._add_raster_constraint_extent(schema, $2, $3);
					ELSE
						RAISE NOTICE 'Unknown constraint: %.  Skipping', quote_literal(constraints[x]);
						CONTINUE kwloop;
				END CASE;
			END;

			IF rtn IS FALSE THEN
				cnt := cnt + 1;
				RAISE WARNING 'Unable to add constraint: %.  Skipping', quote_literal(constraints[x]);
			END IF;

		END LOOP kwloop;

		IF cnt = max THEN
			RAISE EXCEPTION 'None of the constraints specified could be added.  Is the schema name, table name or column name incorrect?';
			RETURN FALSE;
		END IF;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: FUNCTION addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) IS 'args: rastschema, rasttable, rastcolumn, VARIADIC constraints - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.';


--
-- Name: addrasterconstraints(name, name, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT false, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT public.AddRasterConstraints('', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) $_$;


--
-- Name: FUNCTION addrasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) IS 'args: rasttable, rastcolumn, srid, scale_x, scale_y, blocksize_x, blocksize_y, same_alignment, regular_blocking, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.';


--
-- Name: addrasterconstraints(name, name, name, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT false, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		constraints text[];
	BEGIN
		IF srid IS TRUE THEN
			constraints := constraints || 'srid'::text;
		END IF;

		IF scale_x IS TRUE THEN
			constraints := constraints || 'scale_x'::text;
		END IF;

		IF scale_y IS TRUE THEN
			constraints := constraints || 'scale_y'::text;
		END IF;

		IF blocksize_x IS TRUE THEN
			constraints := constraints || 'blocksize_x'::text;
		END IF;

		IF blocksize_y IS TRUE THEN
			constraints := constraints || 'blocksize_y'::text;
		END IF;

		IF same_alignment IS TRUE THEN
			constraints := constraints || 'same_alignment'::text;
		END IF;

		IF regular_blocking IS TRUE THEN
			constraints := constraints || 'regular_blocking'::text;
		END IF;

		IF num_bands IS TRUE THEN
			constraints := constraints || 'num_bands'::text;
		END IF;

		IF pixel_types IS TRUE THEN
			constraints := constraints || 'pixel_types'::text;
		END IF;

		IF nodata_values IS TRUE THEN
			constraints := constraints || 'nodata_values'::text;
		END IF;

		IF out_db IS TRUE THEN
			constraints := constraints || 'out_db'::text;
		END IF;

		IF extent IS TRUE THEN
			constraints := constraints || 'extent'::text;
		END IF;

		RETURN public.AddRasterConstraints($1, $2, $3, VARIADIC constraints);
	END;
	$_$;


--
-- Name: FUNCTION addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) IS 'args: rastschema, rasttable, rastcolumn, srid=true, scale_x=true, scale_y=true, blocksize_x=true, blocksize_y=true, same_alignment=true, regular_blocking=false, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.';


--
-- Name: box3d(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.box3d(public.raster) RETURNS public.box3d
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select box3d( public.ST_convexhull($1))$_$;


--
-- Name: bytea(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bytea(public.raster) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_to_bytea';


--
-- Name: dropoverviewconstraints(name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dropoverviewconstraints(ovtable name, ovcolumn name) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public.DropOverviewConstraints('', $1, $2) $_$;


--
-- Name: FUNCTION dropoverviewconstraints(ovtable name, ovcolumn name); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.dropoverviewconstraints(ovtable name, ovcolumn name) IS 'args: ovtable, ovcolumn - Untag a raster column from being an overview of another.';


--
-- Name: dropoverviewconstraints(name, name, name); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		schema name;
		sql text;
		rtn boolean;
	BEGIN
		-- validate schema
		schema := NULL;
		IF length($1) > 0 THEN
			sql := 'SELECT nspname FROM pg_namespace '
				|| 'WHERE nspname = ' || quote_literal($1)
				|| 'LIMIT 1';
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The value provided for schema is invalid';
				RETURN FALSE;
			END IF;
		END IF;

		IF schema IS NULL THEN
			sql := 'SELECT n.nspname AS schemaname '
				|| 'FROM pg_catalog.pg_class c '
				|| 'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace '
				|| 'WHERE c.relkind = ' || quote_literal('r')
				|| ' AND n.nspname NOT IN (' || quote_literal('pg_catalog')
				|| ', ' || quote_literal('pg_toast')
				|| ') AND pg_catalog.pg_table_is_visible(c.oid)'
				|| ' AND c.relname = ' || quote_literal($2);
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The table % does not occur in the search_path', quote_literal($2);
				RETURN FALSE;
			END IF;
		END IF;

		rtn :=  public._drop_overview_constraint(schema, $2, $3);
		IF rtn IS FALSE THEN
			RAISE EXCEPTION 'Unable to drop the overview constraint .  Is the schema name, table name or column name incorrect?';
			RETURN FALSE;
		END IF;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: FUNCTION dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name) IS 'args: ovschema, ovtable, ovcolumn - Untag a raster column from being an overview of another.';


--
-- Name: droprasterconstraints(name, name, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public.DropRasterConstraints('', $1, $2, VARIADIC $3) $_$;


--
-- Name: droprasterconstraints(name, name, name, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		max int;
		x int;
		schema name;
		sql text;
		kw text;
		rtn boolean;
		cnt int;
	BEGIN
		cnt := 0;
		max := array_length(constraints, 1);
		IF max < 1 THEN
			RAISE NOTICE 'No constraints indicated to be dropped.  Doing nothing';
			RETURN TRUE;
		END IF;

		-- validate schema
		schema := NULL;
		IF length($1) > 0 THEN
			sql := 'SELECT nspname FROM pg_namespace '
				|| 'WHERE nspname = ' || quote_literal($1)
				|| 'LIMIT 1';
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The value provided for schema is invalid';
				RETURN FALSE;
			END IF;
		END IF;

		IF schema IS NULL THEN
			sql := 'SELECT n.nspname AS schemaname '
				|| 'FROM pg_catalog.pg_class c '
				|| 'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace '
				|| 'WHERE c.relkind = ' || quote_literal('r')
				|| ' AND n.nspname NOT IN (' || quote_literal('pg_catalog')
				|| ', ' || quote_literal('pg_toast')
				|| ') AND pg_catalog.pg_table_is_visible(c.oid)'
				|| ' AND c.relname = ' || quote_literal($2);
			EXECUTE sql INTO schema;

			IF schema IS NULL THEN
				RAISE EXCEPTION 'The table % does not occur in the search_path', quote_literal($2);
				RETURN FALSE;
			END IF;
		END IF;

		<<kwloop>>
		FOR x in 1..max LOOP
			kw := trim(both from lower(constraints[x]));

			BEGIN
				CASE
					WHEN kw = 'srid' THEN
						RAISE NOTICE 'Dropping SRID constraint';
						rtn :=  public._drop_raster_constraint_srid(schema, $2, $3);
					WHEN kw IN ('scale_x', 'scalex') THEN
						RAISE NOTICE 'Dropping scale-X constraint';
						rtn :=  public._drop_raster_constraint_scale(schema, $2, $3, 'x');
					WHEN kw IN ('scale_y', 'scaley') THEN
						RAISE NOTICE 'Dropping scale-Y constraint';
						rtn :=  public._drop_raster_constraint_scale(schema, $2, $3, 'y');
					WHEN kw = 'scale' THEN
						RAISE NOTICE 'Dropping scale-X constraint';
						rtn :=  public._drop_raster_constraint_scale(schema, $2, $3, 'x');
						RAISE NOTICE 'Dropping scale-Y constraint';
						rtn :=  public._drop_raster_constraint_scale(schema, $2, $3, 'y');
					WHEN kw IN ('blocksize_x', 'blocksizex', 'width') THEN
						RAISE NOTICE 'Dropping blocksize-X constraint';
						rtn :=  public._drop_raster_constraint_blocksize(schema, $2, $3, 'width');
					WHEN kw IN ('blocksize_y', 'blocksizey', 'height') THEN
						RAISE NOTICE 'Dropping blocksize-Y constraint';
						rtn :=  public._drop_raster_constraint_blocksize(schema, $2, $3, 'height');
					WHEN kw = 'blocksize' THEN
						RAISE NOTICE 'Dropping blocksize-X constraint';
						rtn :=  public._drop_raster_constraint_blocksize(schema, $2, $3, 'width');
						RAISE NOTICE 'Dropping blocksize-Y constraint';
						rtn :=  public._drop_raster_constraint_blocksize(schema, $2, $3, 'height');
					WHEN kw IN ('same_alignment', 'samealignment', 'alignment') THEN
						RAISE NOTICE 'Dropping alignment constraint';
						rtn :=  public._drop_raster_constraint_alignment(schema, $2, $3);
					WHEN kw IN ('regular_blocking', 'regularblocking') THEN
						rtn :=  public._drop_raster_constraint_regular_blocking(schema, $2, $3);

						RAISE NOTICE 'Dropping coverage tile constraint required for regular blocking';
						rtn :=  public._drop_raster_constraint_coverage_tile(schema, $2, $3);

						IF rtn IS NOT FALSE THEN
							RAISE NOTICE 'Dropping spatially unique constraint required for regular blocking';
							rtn :=  public._drop_raster_constraint_spatially_unique(schema, $2, $3);
						END IF;
					WHEN kw IN ('num_bands', 'numbands') THEN
						RAISE NOTICE 'Dropping number of bands constraint';
						rtn :=  public._drop_raster_constraint_num_bands(schema, $2, $3);
					WHEN kw IN ('pixel_types', 'pixeltypes') THEN
						RAISE NOTICE 'Dropping pixel type constraint';
						rtn :=  public._drop_raster_constraint_pixel_types(schema, $2, $3);
					WHEN kw IN ('nodata_values', 'nodatavalues', 'nodata') THEN
						RAISE NOTICE 'Dropping nodata value constraint';
						rtn :=  public._drop_raster_constraint_nodata_values(schema, $2, $3);
					WHEN kw IN ('out_db', 'outdb') THEN
						RAISE NOTICE 'Dropping out-of-database constraint';
						rtn :=  public._drop_raster_constraint_out_db(schema, $2, $3);
					WHEN kw = 'extent' THEN
						RAISE NOTICE 'Dropping maximum extent constraint';
						rtn :=  public._drop_raster_constraint_extent(schema, $2, $3);
					ELSE
						RAISE NOTICE 'Unknown constraint: %.  Skipping', quote_literal(constraints[x]);
						CONTINUE kwloop;
				END CASE;
			END;

			IF rtn IS FALSE THEN
				cnt := cnt + 1;
				RAISE WARNING 'Unable to drop constraint: %.  Skipping', quote_literal(constraints[x]);
			END IF;

		END LOOP kwloop;

		IF cnt = max THEN
			RAISE EXCEPTION 'None of the constraints specified could be dropped.  Is the schema name, table name or column name incorrect?';
			RETURN FALSE;
		END IF;

		RETURN TRUE;
	END;
	$_$;


--
-- Name: FUNCTION droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) IS 'args: rastschema, rasttable, rastcolumn, constraints - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.';


--
-- Name: droprasterconstraints(name, name, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT true, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT DropRasterConstraints('', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) $_$;


--
-- Name: FUNCTION droprasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) IS 'args: rasttable, rastcolumn, srid, scale_x, scale_y, blocksize_x, blocksize_y, same_alignment, regular_blocking, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.';


--
-- Name: droprasterconstraints(name, name, name, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT true, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql STRICT
    AS $_$
	DECLARE
		constraints text[];
	BEGIN
		IF srid IS TRUE THEN
			constraints := constraints || 'srid'::text;
		END IF;

		IF scale_x IS TRUE THEN
			constraints := constraints || 'scale_x'::text;
		END IF;

		IF scale_y IS TRUE THEN
			constraints := constraints || 'scale_y'::text;
		END IF;

		IF blocksize_x IS TRUE THEN
			constraints := constraints || 'blocksize_x'::text;
		END IF;

		IF blocksize_y IS TRUE THEN
			constraints := constraints || 'blocksize_y'::text;
		END IF;

		IF same_alignment IS TRUE THEN
			constraints := constraints || 'same_alignment'::text;
		END IF;

		IF regular_blocking IS TRUE THEN
			constraints := constraints || 'regular_blocking'::text;
		END IF;

		IF num_bands IS TRUE THEN
			constraints := constraints || 'num_bands'::text;
		END IF;

		IF pixel_types IS TRUE THEN
			constraints := constraints || 'pixel_types'::text;
		END IF;

		IF nodata_values IS TRUE THEN
			constraints := constraints || 'nodata_values'::text;
		END IF;

		IF out_db IS TRUE THEN
			constraints := constraints || 'out_db'::text;
		END IF;

		IF extent IS TRUE THEN
			constraints := constraints || 'extent'::text;
		END IF;

		RETURN DropRasterConstraints($1, $2, $3, VARIADIC constraints);
	END;
	$_$;


--
-- Name: FUNCTION droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) IS 'args: rastschema, rasttable, rastcolumn, srid=true, scale_x=true, scale_y=true, blocksize_x=true, blocksize_y=true, same_alignment=true, regular_blocking=false, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.';


--
-- Name: extract_days(daterange); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extract_days(daterange) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT UPPER($1) - LOWER($1);
$_$;


--
-- Name: extract_days(tsrange); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.extract_days(tsrange) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT (date_trunc('day',UPPER($1))::DATE - date_trunc('day',LOWER($1))::DATE) + 1;
$_$;


--
-- Name: focus_abs_diff(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_abs_diff(image_date date, query_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
var_new_date date;
BEGIN
	var_new_date := query_date;
	IF EXTRACT('YEAR' FROM image_date) = 1970
	THEN
		var_new_date := query_date - ((EXTRACT('YEAR' FROM query_date) - 1970) || ' years')::INTERVAL;
	END IF;

	IF ((image_date - var_new_date) < 0)
	THEN
		RETURN (var_new_date - image_date);
	ELSE
		RETURN (image_date - var_new_date);
	END IF;
END;
$$;


--
-- Name: focus_cast_to_double(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_cast_to_double(v_input text) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE v_int_value DOUBLE PRECISION DEFAULT NULL;
BEGIN
    BEGIN
        v_int_value := v_input::double precision;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid double precision value: "%".  Returning NULL.', v_input;
        -- IF v_retzero THEN
            RETURN 0;
        -- ELSE
            -- RETURN v_input;
        -- END IF;
    END;
RETURN v_int_value;
END;
$$;


--
-- Name: focus_garbagetodouble(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_garbagetodouble(arg_garbage character varying) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
ret double precision;
BEGIN
	begin
		ret = replace(arg_garbage, ',', '.');
		RETURN cast(ret as double precision);
	exception when others then 
	return 0;
	end;
END;
$$;


--
-- Name: focus_get_evi_quality(integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_evi_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet double precision;

var_evi_layer_id INTEGER;

var_date_value timestamp;
var_evi_value double precision;
var_accepted BOOLEAN;

var_date_value_prev timestamp;
var_evi_value_prev double precision;
var_accepted_prev BOOLEAN;

var_date_value_next timestamp;
var_evi_value_next double precision;
var_accepted_next BOOLEAN;

var_date_value_prev_2 timestamp;
var_evi_value_prev_2 double precision;
var_accepted_prev_2 BOOLEAN;

var_date_value_next_2 timestamp;
var_evi_value_next_2 double precision;
var_accepted_next_2 BOOLEAN;

BEGIN
    SELECT id INTO var_evi_layer_id FROM layer_types WHERE name = '250m 16 days EVI';

    SELECT image_date, value, accepted
      INTO var_date_value, var_evi_value, var_accepted
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, arg_date) 
      AS (image_date timestamp, value double precision, accepted boolean);

    RAISE NOTICE 'var_date_value %', var_date_value;
    RAISE NOTICE 'var_evi_value %', var_evi_value;
    RAISE NOTICE 'var_accepted %', var_accepted;

    -- Si la calidad me dice que el evi esta bien, devuelvo el valor y listo.
    IF var_accepted THEN
       RETURN var_evi_value;
    END IF;

    -- Caso contrario, busco el dato anterior...
    SELECT
        rl.image_date INTO var_date_value_prev
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
        WHERE image_date < var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date DESC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_prev, var_evi_value_prev, var_accepted_prev
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_prev IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_prev %', var_date_value_prev;
    RAISE NOTICE 'var_evi_value_prev %', var_evi_value_prev;
    RAISE NOTICE 'var_accepted_prev %', var_accepted_prev;

    -- ...y el siguiente
    SELECT
        rl.image_date INTO var_date_value_next
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
        WHERE image_date > var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date ASC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_next, var_evi_value_next, var_accepted_next
    FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_next IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_next %', var_date_value_next;
    RAISE NOTICE 'var_evi_value_next %', var_evi_value_next;
    RAISE NOTICE 'var_accepted_next %', var_accepted_next;

    -- Si el anterior y siguiente fueron aceptados, los promedio, los devuelvo, y listo.
    IF var_accepted_prev AND var_accepted_next THEN
        RETURN (var_evi_value_prev + var_evi_value_next) / 2;
    END IF;

    -- Si los 2 fueron rechazados, no puedo hacer nada.
    IF NOT var_accepted_prev AND NOT var_accepted_next THEN
        RETURN 'NAN';
    END IF;

    -- Si solo fallo el prev, me fijo el anterior
    IF NOT var_accepted_prev THEN
        SELECT
            rl.image_date INTO var_date_value_prev_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE image_date < var_date_value_prev AND pixel_id = arg_pixel_id
            ORDER BY image_date DESC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_prev_2, var_evi_value_prev_2, var_accepted_prev_2
        FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_prev_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_prev_2 %', var_date_value_prev_2;
        RAISE NOTICE 'var_evi_value_prev_2 %', var_evi_value_prev_2;
        RAISE NOTICE 'var_accepted_prev_2 %', var_accepted_prev_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_prev_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_evi_value_next * 0.66 + var_evi_value_prev_2 * 0.33;
    ELSE
        SELECT
            rl.image_date INTO var_date_value_next_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE image_date > var_date_value_next AND pixel_id = arg_pixel_id
            ORDER BY image_date ASC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_next_2, var_evi_value_next_2, var_accepted_next_2
        FROM focus_get_evi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_next_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_next_2 %', var_date_value_next_2;
        RAISE NOTICE 'var_evi_value_next_2 %', var_evi_value_next_2;
        RAISE NOTICE 'var_accepted_next_2 %', var_accepted_next_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_next_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_evi_value_prev * 0.66 + var_evi_value_next_2 * 0.33;
    END IF;

    RETURN NULL;
END;
$$;


--
-- Name: focus_get_evi_quality_raw(integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_evi_quality_raw(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet RECORD;

var_evi_layer_id integer;
var_accepted BOOLEAN;

var_evi_value double precision;
var_date_value timestamp;

BEGIN
    /* Esta funcion sirve para obtener el dato de evi y aceptacion de calidad de la base de datos, sin filtro por calidad.
     * Argumentos:
     *   arg_map_id integer Id de mapa para pasarle los parametros de calidad
     *   arg_pixel_id integer Id de pixel que se quiere obtener los datos
     *   arg_date timestamp Fecha para la cual obtener los datos (se selecciona la la imagen mas cercana a la fecha)
     *
     * Retorna:
     *   Record:
     *     1. timestamp: Fecha de imagen seleccionada, NULL si no hay datos.
     *     2. double precision: evi del pixel seleccionado, NULL si no hay datos.
     *     3. boolean: salida de la funcion de calidad para el pixel dado, false si no hay datos.
     */


    SELECT id INTO var_evi_layer_id FROM layer_types WHERE name = '250m 16 days EVI';

    --RAISE NOTICE 'var_evi_layer_id %', var_evi_layer_id;

    SELECT
        value, image_date
        INTO
        var_evi_value, var_date_value
    FROM (
        SELECT
            value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_evi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    IF var_date_value IS NULL THEN
    SELECT NULL, NULL, f INTO paramRet;
        RETURN paramRet;
    END IF;

    IF var_evi_value > 1 THEN
        var_evi_value = var_evi_value / 100000000;
    END IF;

    --RAISE NOTICE 'var_evi_value %', var_evi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    SELECT accepted
    INTO var_accepted
    FROM focus_get_quality(arg_map_id, arg_use_id, arg_pixel_id, arg_date) AS (
        date_value timestamp,
        accepted boolean
    );

    --RAISE NOTICE 'var_accepted %', var_accepted;

    SELECT var_date_value, var_evi_value, var_accepted INTO paramRet;
    RETURN paramRet;
END;
$$;


--
-- Name: focus_get_ndvi_quality(integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_ndvi_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet double precision;

var_ndvi_layer_id INTEGER;

var_date_value timestamp;
var_ndvi_value double precision;
var_accepted BOOLEAN;

var_date_value_prev timestamp;
var_ndvi_value_prev double precision;
var_accepted_prev BOOLEAN;

var_date_value_next timestamp;
var_ndvi_value_next double precision;
var_accepted_next BOOLEAN;

var_date_value_prev_2 timestamp;
var_ndvi_value_prev_2 double precision;
var_accepted_prev_2 BOOLEAN;

var_date_value_next_2 timestamp;
var_ndvi_value_next_2 double precision;
var_accepted_next_2 BOOLEAN;

BEGIN
    SELECT id INTO var_ndvi_layer_id FROM layer_types WHERE name = '250m 16 days NDVI';

    SELECT image_date, value, accepted
      INTO var_date_value, var_ndvi_value, var_accepted
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, arg_date) 
      AS (image_date timestamp, value double precision, accepted boolean);

    RAISE NOTICE 'var_date_value %', var_date_value;
    RAISE NOTICE 'var_ndvi_value %', var_ndvi_value;
    RAISE NOTICE 'var_accepted %', var_accepted;

    -- Si la calidad me dice que el NDVI esta bien, devuelvo el valor y listo.
    IF var_accepted THEN
       RETURN var_ndvi_value;
    END IF;

    -- Caso contrario, busco el dato anterior...
    SELECT
        rl.image_date INTO var_date_value_prev
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
        WHERE image_date < var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date DESC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_prev, var_ndvi_value_prev, var_accepted_prev
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_prev IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_prev %', var_date_value_prev;
    RAISE NOTICE 'var_ndvi_value_prev %', var_ndvi_value_prev;
    RAISE NOTICE 'var_accepted_prev %', var_accepted_prev;

    -- ...y el siguiente
    SELECT
        rl.image_date INTO var_date_value_next
        FROM pixel_values
        JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
        WHERE image_date > var_date_value AND pixel_id = arg_pixel_id
        ORDER BY image_date ASC LIMIT 1;

    SELECT image_date, value, accepted
      INTO var_date_value_next, var_ndvi_value_next, var_accepted_next
    FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next) 
      AS (image_date timestamp, value double precision, accepted boolean);

    IF var_date_value_next IS NULL THEN
        RETURN 'NaN';
    END IF;

    RAISE NOTICE 'var_date_value_next %', var_date_value_next;
    RAISE NOTICE 'var_ndvi_value_next %', var_ndvi_value_next;
    RAISE NOTICE 'var_accepted_next %', var_accepted_next;

    -- Si el anterior y siguiente fueron aceptados, los promedio, los devuelvo, y listo.
    IF var_accepted_prev AND var_accepted_next THEN
        RETURN (var_ndvi_value_prev + var_ndvi_value_next) / 2;
    END IF;

    -- Si los 2 fueron rechazados, no puedo hacer nada.
    IF NOT var_accepted_prev AND NOT var_accepted_next THEN
        RETURN 'NaN';
    END IF;

    -- Si solo fallo el prev, me fijo el anterior
    IF NOT var_accepted_prev THEN
        SELECT
            rl.image_date INTO var_date_value_prev_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE image_date < var_date_value_prev AND pixel_id = arg_pixel_id
            ORDER BY image_date DESC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_prev_2, var_ndvi_value_prev_2, var_accepted_prev_2
        FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_prev_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_prev_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_prev_2 %', var_date_value_prev_2;
        RAISE NOTICE 'var_ndvi_value_prev_2 %', var_ndvi_value_prev_2;
        RAISE NOTICE 'var_accepted_prev_2 %', var_accepted_prev_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_prev_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_ndvi_value_next * 0.66 + var_ndvi_value_prev_2 * 0.33;
    ELSE
        SELECT
            rl.image_date INTO var_date_value_next_2
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE image_date > var_date_value_next AND pixel_id = arg_pixel_id
            ORDER BY image_date ASC LIMIT 1;

        SELECT image_date, value, accepted
          INTO var_date_value_next_2, var_ndvi_value_next_2, var_accepted_next_2
        FROM focus_get_ndvi_quality_raw(arg_map_id, arg_use_id, arg_pixel_id, var_date_value_next_2) 
          AS (image_date timestamp, value double precision, accepted boolean);

        IF var_date_value_next_2 IS NULL THEN
            RETURN 'NaN';
        END IF;

        RAISE NOTICE 'var_date_value_next_2 %', var_date_value_next_2;
        RAISE NOTICE 'var_ndvi_value_next_2 %', var_ndvi_value_next_2;
        RAISE NOTICE 'var_accepted_next_2 %', var_accepted_next_2;

        -- Si falla aca, no puedo hacer nada.
        IF NOT var_accepted_next_2 THEN
            RETURN 'NaN';
        END IF;

        -- Pondero el dato
        RETURN var_ndvi_value_prev * 0.66 + var_ndvi_value_next_2 * 0.33;
    END IF;

    RETURN NULL;
END;
$$;


--
-- Name: focus_get_ndvi_quality_raw(integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_ndvi_quality_raw(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet RECORD;

var_ndvi_layer_id integer;
var_accepted BOOLEAN;

var_ndvi_value double precision;
var_date_value timestamp;

BEGIN
    /* Esta funcion sirve para obtener el dato de ndvi y aceptacion de calidad de la base de datos, sin filtro por calidad.
     * Argumentos:
     *   arg_map_id integer Id de mapa para pasarle los parametros de calidad
     *   arg_pixel_id integer Id de pixel que se quiere obtener los datos
     *   arg_date timestamp Fecha para la cual obtener los datos (se selecciona la la imagen mas cercana a la fecha)
     *
     * Retorna:
     *   Record:
     *     1. timestamp: Fecha de imagen seleccionada, NULL si no hay datos.
     *     2. double precision: NDVI del pixel seleccionado, NULL si no hay datos.
     *     3. boolean: salida de la funcion de calidad para el pixel dado, false si no hay datos.
     */


    SELECT id INTO var_ndvi_layer_id FROM layer_types WHERE name = '250m 16 days NDVI';

    --RAISE NOTICE 'var_ndvi_layer_id %', var_ndvi_layer_id;

    SELECT
        value, image_date
        INTO
        var_ndvi_value, var_date_value
    FROM (
        SELECT
            value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_ndvi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    IF var_date_value IS NULL THEN
	SELECT NULL, NULL, f INTO paramRet;
        RETURN paramRet;
    END IF;

    IF var_ndvi_value > 1 THEN
        var_ndvi_value = var_ndvi_value / 100000000;
    END IF;

    --RAISE NOTICE 'var_ndvi_value %', var_ndvi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    SELECT accepted
    INTO var_accepted
    FROM focus_get_quality(arg_map_id, arg_use_id, arg_pixel_id, arg_date) AS (
        date_value timestamp,
        accepted boolean
    );

    --RAISE NOTICE 'var_accepted %', var_accepted;

    SELECT var_date_value, var_ndvi_value, var_accepted INTO paramRet;
    RETURN paramRet;
END;
$$;


--
-- Name: focus_get_parameter(text, date, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_parameter(arg_parameter_name text, pixel_date date, param_use_id integer, param_region_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet character varying;

BEGIN
    SELECT value into paramRet
    FROM parameters
    JOIN parameter_types ON parameter_types.id = parameter_type_id
    WHERE region_id = param_region_id 
      AND parameter_types.name = arg_parameter_name
      AND (month is null or month = 0 or month = extract('month' from pixel_date))
      AND (use_id is null or use_id = param_use_id)
    ORDER BY priority DESC;

    IF paramRet IS NULL THEN 
        RETURN NULL;
    ELSE
        RETURN paramRet;
    END IF;
END;
$$;


--
-- Name: focus_get_quality(integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_get_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet RECORD;

var_qi_layer_id integer;
var_qi_value integer;
var_date_value timestamp;

var_modland_qa integer;
var_vi_usefulness integer;
var_aerosol_quantity integer;
var_adjacent_cloud_detected integer;
var_brdf_correction integer;
var_mixed_clouds integer;
var_land_water integer;
var_snow integer;
var_shadow integer;

var_tmp_modland_qa text;
var_tmp_aerosol_quantity text;
var_tmp_mixed_clouds text;
var_tmp_land_water text;
var_tmp_snow text;
var_tmp_shadow text;

var_region_id integer;

var_accepted boolean;
BEGIN
    SELECT id INTO var_qi_layer_id FROM layer_types WHERE name = '250m 16 days VI Quality';

    SELECT
        image_date, value
        INTO
        var_date_value, var_qi_value
    FROM (
        SELECT
            ROUND(value::numeric, 0) as value, rl.image_date as image_date,
            CASE WHEN ((rl.image_date - arg_date) < INTERVAL '0') THEN (arg_date - rl.image_date) ELSE (rl.image_date - arg_date) END as abs_diff
            FROM pixel_values
            JOIN raster_layers rl ON raster_layer_id = rl.id and rl.layer_type_id = var_qi_layer_id
            WHERE pixel_id = arg_pixel_id
            ORDER BY 3 ASC LIMIT 1
    ) a;

    --RAISE NOTICE 'var_qi_value %', var_qi_value;
    --RAISE NOTICE 'var_date_value %', var_date_value;

    var_modland_qa :=               var_qi_value        & 3;
    var_vi_usefulness :=           (var_qi_value >> 2)  & 15;
    var_aerosol_quantity :=        (var_qi_value >> 6)  & 3;
    var_adjacent_cloud_detected := (var_qi_value >> 8)  & 1;
    var_brdf_correction :=         (var_qi_value >> 9)  & 1;
    var_mixed_clouds :=            (var_qi_value >> 10) & 1;
    var_land_water :=              (var_qi_value >> 11) & 7;
    var_snow :=                    (var_qi_value >> 14) & 1;
    var_shadow :=                  (var_qi_value >> 15) & 1;

    SELECT r.id INTO var_region_id
    FROM regions r JOIN pixel p ON st_intersects(r.the_geom, p.the_geom)
    WHERE map_id = arg_map_id AND p.id = arg_pixel_id
    order by ST_Area(ST_Intersection(r.the_geom, p.the_geom))/ST_Area(p.the_geom) DESC
    LIMIT 1;

    IF var_region_id IS NOT NULL THEN
	select focus_get_parameter('modland_qa'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_modland_qa;
	select focus_get_parameter('aerosol_quantity'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_aerosol_quantity;
	select focus_get_parameter('mixed_clouds'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_mixed_clouds;
	select focus_get_parameter('land_water'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_land_water;
	select focus_get_parameter('snow'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_snow;
	select focus_get_parameter('shadow'::text, var_date_value::date, arg_use_id, var_region_id) INTO var_tmp_shadow;
    END IF;

    BEGIN
        IF ((SELECT bool_or(var_modland_qa = opts::integer::bit(2)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_modland_qa, '00,01')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_aerosol_quantity = opts::integer::bit(2)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_aerosol_quantity, '00,01')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_mixed_clouds = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_mixed_clouds, '0')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_land_water = opts::integer::bit(3)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_land_water, '001')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_snow = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_snow, '0')||'}')::text[]) as opts) AND
            (SELECT bool_or(var_shadow = opts::integer::bit(1)::integer)
                FROM unnest(('{'||COALESCE(var_tmp_shadow, '0')||'}')::text[]) as opts)) THEN

            var_accepted := true;
        ELSE
            var_accepted := false;
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE '% %', SQLERRM, SQLSTATE;
            var_accepted := false;
    END; 

    SELECT var_date_value as date_value,
           var_accepted as accepted
    INTO paramRet;

    RETURN paramRet;
END;
$$;


--
-- Name: focus_process_raster(character varying, regclass, integer, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_process_raster(arg_rast character varying, arg_tmp_table regclass, arg_raster_layer_id integer, arg_s_srid integer DEFAULT 9001, arg_scale_factor double precision DEFAULT 1.0, arg_offset_value double precision DEFAULT 0.0) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN

        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect)
               SELECT p.id AS pixel_id, %s, r.val * %s + %s, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area 
               FROM ST_PixelAsPolygons(''%s''::raster) r 
               JOIN pixel p on St_intersects(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)
                           AND              (ST_Transform(St_SetSRID(r.geom, %s), 4326) && p.the_geom);', arg_tmp_table, arg_raster_layer_id, arg_scale_factor, arg_offset_value, arg_s_srid, arg_rast, arg_s_srid, arg_s_srid);

    RETURN 'Processed pixels';
END;
$$;


--
-- Name: focus_process_raster_modis(character varying, regclass, integer, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_process_raster_modis(arg_rast character varying, arg_tmp_table regclass, arg_raster_layer_id integer, arg_s_srid integer DEFAULT 9001, arg_scale_factor double precision DEFAULT 1.0, arg_offset_value double precision DEFAULT 0.0) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect) SELECT p.id AS pixel_id, %s, r.val * %s + %s, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area 
  FROM ST_PixelAsPolygons(''%s''::raster) r 
               JOIN pixel p on St_intersects(ST_Centroid(ST_Transform(St_SetSRID(r.geom, %s), 4326)), p.the_geom)
                           AND              (ST_Centroid(ST_Transform(St_SetSRID(r.geom, %s), 4326)) && p.the_geom);', arg_tmp_table, arg_raster_layer_id, arg_scale_factor, arg_offset_value, arg_s_srid, arg_rast, arg_s_srid, arg_s_srid);
  
    RETURN 'Processed pixels';
END;
$$;


--
-- Name: focus_upsert_result2(character varying, integer, integer, character varying, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.focus_upsert_result2(param_key character varying, param_process_result_id integer, param_process_focus_2_id integer, param_value character varying, param_date timestamp without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
varId integer;
-- Esta funcion tiene como objetivo realizar el update o el insert de un resultado en focus 2
-- Si bien no es posible actualmente reiniar un proceso de resultado focus 2 lo podriamos utilzar para debug o en un futuro podriamos permitirlo.
BEGIN

    SELECT id into varId FROM results_f2 WHERE key = param_key AND process_result_id = param_process_result_id AND process_focus_id = param_process_focus_2_id AND "date" = param_date; 

    IF varId IS NULL THEN 
        INSERT INTO results_f2 (key, value, process_result_id, process_focus_id, "date") VALUES (param_key, param_value, param_process_result_id, param_process_focus_2_id, param_date );
        return 'Inserted';
    ELSE
        UPDATE results_f2 SET value = param_value WHERE id =  varId;
        return 'Updated';
    END IF;
END;
$$;


--
-- Name: geometry_contained_by_raster(public.geometry, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.geometry_contained_by_raster(public.geometry, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1 @ $2::geometry$_$;


--
-- Name: geometry_raster_contain(public.geometry, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.geometry_raster_contain(public.geometry, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1 ~ $2::geometry$_$;


--
-- Name: geometry_raster_overlap(public.geometry, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.geometry_raster_overlap(public.geometry, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1 OPERATOR(public.&&) $2::geometry$_$;


--
-- Name: get_parameter(text, date, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_parameter(arg_parameter_name text, pixel_date date, param_use_id integer, param_region_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
paramRet character varying;

BEGIN
    SELECT value into paramRet
    FROM parameters
    JOIN parameter_types ON parameter_types.id = parameter_type_id
    WHERE region_id = param_region_id 
      AND parameter_types.name = arg_parameter_name
      AND (month is null or month = extract('month' from pixel_date))
      AND (use_id is null or use_id = param_use_id)
    ORDER BY priority DESC;

    IF paramRet IS NULL THEN 
        RETURN NULL;
    ELSE
        RETURN paramRet;
    END IF;
END;
$$;


--
-- Name: postgis_gdal_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.postgis_gdal_version() RETURNS text
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_gdal_version';


--
-- Name: FUNCTION postgis_gdal_version(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.postgis_gdal_version() IS 'Reports the version of the GDAL library in use by PostGIS.';


--
-- Name: postgis_noop(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.postgis_noop(public.raster) RETURNS public.geometry
    LANGUAGE c STRICT
    AS '$libdir/rtpostgis-2.3', 'RASTER_noop';


--
-- Name: postgis_raster_lib_build_date(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.postgis_raster_lib_build_date() RETURNS text
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_lib_build_date';


--
-- Name: FUNCTION postgis_raster_lib_build_date(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.postgis_raster_lib_build_date() IS 'Reports full raster library build date.';


--
-- Name: postgis_raster_lib_version(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.postgis_raster_lib_version() RETURNS text
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_lib_version';


--
-- Name: FUNCTION postgis_raster_lib_version(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.postgis_raster_lib_version() IS 'Reports full raster version and build configuration infos.';


--
-- Name: postgis_raster_scripts_installed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.postgis_raster_scripts_installed() RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$ SELECT '2.3.1'::text || ' r' || 15264::text AS version $$;


--
-- Name: r2_geomcollection_to_multipolygon_by_area(public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.r2_geomcollection_to_multipolygon_by_area(geom public.geometry) RETURNS public.geometry
    LANGUAGE plpgsql STRICT
    AS $$
	DECLARE
		x int;
		ret geometry;
	BEGIN

		SELECT CASE WHEN st_geometrytype(geom) = 'ST_MultiPolygon' THEN geom ELSE ST_GeometryN(geom, n) END
		INTO ret
		FROM generate_series(1, ST_NumGeometries(geom)) n
		ORDER BY ST_Area(ST_GeometryN(geom, n)) DESC
		LIMIT 1;

		RETURN ret;
	END;
	$$;


--
-- Name: r2_multipolygon_to_polygon_by_area(public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.r2_multipolygon_to_polygon_by_area(geom public.geometry) RETURNS public.geometry
    LANGUAGE plpgsql STRICT
    AS $$
	DECLARE
		x int;
		ret geometry;
	BEGIN

		SELECT ST_GeometryN(geom, n)
		INTO ret
		FROM generate_series(1, ST_NumGeometries(geom)) n
		ORDER BY ST_Area(ST_GeometryN(geom, n)) DESC
		LIMIT 1;

		IF GeometryType(ret) = 'MULTIPOLYGON'::text THEN
			SELECT public.r2_multipolygon_to_polygon_by_area(ret) INTO ret;
		END IF;

		RETURN ret;
	END;
	$$;


--
-- Name: raster_above(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_above(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry |>> $2::geometry$_$;


--
-- Name: raster_below(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_below(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry <<| $2::geometry$_$;


--
-- Name: raster_contain(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_contain(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry ~ $2::geometry$_$;


--
-- Name: raster_contained(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_contained(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry @ $2::geometry$_$;


--
-- Name: raster_contained_by_geometry(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_contained_by_geometry(public.raster, public.geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry @ $2$_$;


--
-- Name: raster_eq(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_eq(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.raster_hash($1) = public.raster_hash($2) $_$;


--
-- Name: raster_geometry_contain(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_geometry_contain(public.raster, public.geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry ~ $2$_$;


--
-- Name: raster_geometry_overlap(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_geometry_overlap(public.raster, public.geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry OPERATOR(public.&&) $2$_$;


--
-- Name: raster_hash(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_hash(public.raster) RETURNS integer
    LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE
    AS $$hashvarlena$$;


--
-- Name: raster_left(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_left(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry << $2::geometry$_$;


--
-- Name: raster_overabove(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_overabove(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry |&> $2::geometry$_$;


--
-- Name: raster_overbelow(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_overbelow(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry &<| $2::geometry$_$;


--
-- Name: raster_overlap(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_overlap(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry OPERATOR(public.&&) $2::geometry$_$;


--
-- Name: raster_overleft(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_overleft(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::public.geometry &< $2::public.geometry$_$;


--
-- Name: raster_overright(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_overright(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::public.geometry &> $2::public.geometry$_$;


--
-- Name: raster_right(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_right(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry >> $2::geometry$_$;


--
-- Name: raster_same(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raster_same(public.raster, public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$select $1::geometry ~= $2::geometry$_$;


--
-- Name: st_addband(public.raster, public.addbandarg[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(rast public.raster, addbandargset public.addbandarg[]) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_addBand';


--
-- Name: FUNCTION st_addband(rast public.raster, addbandargset public.addbandarg[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(rast public.raster, addbandargset public.addbandarg[]) IS 'args: rast, addbandargset - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(rast public.raster, pixeltype text, initialvalue double precision DEFAULT '0'::numeric, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT  public.ST_addband($1, ARRAY[ROW(NULL, $2, $3, $4)]::addbandarg[]) $_$;


--
-- Name: FUNCTION st_addband(rast public.raster, pixeltype text, initialvalue double precision, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(rast public.raster, pixeltype text, initialvalue double precision, nodataval double precision) IS 'args: rast, pixeltype, initialvalue=0, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, public.raster[], integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(torast public.raster, fromrasts public.raster[], fromband integer DEFAULT 1, torastindex integer DEFAULT NULL::integer) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_addBandRasterArray';


--
-- Name: FUNCTION st_addband(torast public.raster, fromrasts public.raster[], fromband integer, torastindex integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(torast public.raster, fromrasts public.raster[], fromband integer, torastindex integer) IS 'args: torast, fromrasts, fromband=1, torastindex=at_end - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(torast public.raster, fromrast public.raster, fromband integer DEFAULT 1, torastindex integer DEFAULT NULL::integer) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_copyBand';


--
-- Name: FUNCTION st_addband(torast public.raster, fromrast public.raster, fromband integer, torastindex integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(torast public.raster, fromrast public.raster, fromband integer, torastindex integer) IS 'args: torast, fromrast, fromband=1, torastindex=at_end - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, integer, text, integer[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(rast public.raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_addBandOutDB';


--
-- Name: FUNCTION st_addband(rast public.raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(rast public.raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision) IS 'args: rast, index, outdbfile, outdbindex, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, integer, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(rast public.raster, index integer, pixeltype text, initialvalue double precision DEFAULT '0'::numeric, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT  public.ST_addband($1, ARRAY[ROW($2, $3, $4, $5)]::addbandarg[]) $_$;


--
-- Name: FUNCTION st_addband(rast public.raster, index integer, pixeltype text, initialvalue double precision, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(rast public.raster, index integer, pixeltype text, initialvalue double precision, nodataval double precision) IS 'args: rast, index, pixeltype, initialvalue=0, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_addband(public.raster, text, integer[], integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_addband(rast public.raster, outdbfile text, outdbindex integer[], index integer DEFAULT NULL::integer, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_AddBand($1, $4, $2, $3, $5) $_$;


--
-- Name: FUNCTION st_addband(rast public.raster, outdbfile text, outdbindex integer[], index integer, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_addband(rast public.raster, outdbfile text, outdbindex integer[], index integer, nodataval double precision) IS 'args: rast, outdbfile, outdbindex, index=at_end, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.';


--
-- Name: st_approxcount(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rast public.raster, sample_percent double precision) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, 1, TRUE, $2) $_$;


--
-- Name: st_approxcount(text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, sample_percent double precision) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, 1, TRUE, $3) $_$;


--
-- Name: st_approxcount(public.raster, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rast public.raster, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, 1, $2, $3) $_$;


--
-- Name: st_approxcount(public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rast public.raster, nband integer, sample_percent double precision) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, $2, TRUE, $3) $_$;


--
-- Name: st_approxcount(text, text, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, 1, $3, $4) $_$;


--
-- Name: st_approxcount(text, text, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, nband integer, sample_percent double precision) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, $3, TRUE, $4) $_$;


--
-- Name: st_approxcount(public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, $2, $3, $4) $_$;


--
-- Name: st_approxcount(text, text, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, $3, $4, $5) $_$;


--
-- Name: st_approxhistogram(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, 1, TRUE, $2, 0, NULL, FALSE) $_$;


--
-- Name: st_approxhistogram(text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, 1, TRUE, $3, 0, NULL, FALSE) $_$;


--
-- Name: st_approxhistogram(public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, nband integer, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, 0, NULL, FALSE) $_$;


--
-- Name: st_approxhistogram(text, text, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, 0, NULL, FALSE) $_$;


--
-- Name: st_approxhistogram(public.raster, integer, double precision, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, nband integer, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, $4, NULL, $5) $_$;


--
-- Name: st_approxhistogram(text, text, integer, double precision, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, $5, NULL, $6) $_$;


--
-- Name: st_approxhistogram(public.raster, integer, boolean, double precision, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, $4, $5, NULL, $6) $_$;


--
-- Name: st_approxhistogram(public.raster, integer, double precision, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, nband integer, sample_percent double precision, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, $4, $5, $6) $_$;


--
-- Name: st_approxhistogram(text, text, integer, boolean, double precision, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, $4, $5, $6, NULL, $7) $_$;


--
-- Name: st_approxhistogram(text, text, integer, double precision, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, $5, $6, $7) $_$;


--
-- Name: st_approxhistogram(public.raster, integer, boolean, double precision, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, $4, $5, $6, $7) $_$;


--
-- Name: st_approxhistogram(text, text, integer, boolean, double precision, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_histogram($1, $2, $3, $4, $5, $6, $7, $8) $_$;


--
-- Name: st_approxquantile(public.raster, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, 1, TRUE, 0.1, $2) $_$;


--
-- Name: st_approxquantile(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, 1, TRUE, 0.1, ARRAY[$2]::double precision[])).value $_$;


--
-- Name: st_approxquantile(text, text, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_quantile($1, $2, 1, TRUE, 0.1, $3) $_$;


--
-- Name: st_approxquantile(text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, 0.1, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: st_approxquantile(public.raster, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, 1, $2, 0.1, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: st_approxquantile(public.raster, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, 1, TRUE, $2, $3) $_$;


--
-- Name: st_approxquantile(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, 1, TRUE, $2, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: st_approxquantile(text, text, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$ SELECT ( public._ST_quantile($1, $2, 1, $3, 0.1, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: st_approxquantile(text, text, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_quantile($1, $2, 1, TRUE, $3, $4) $_$;


--
-- Name: st_approxquantile(text, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, $3, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: st_approxquantile(public.raster, integer, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, nband integer, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, $2, TRUE, $3, $4) $_$;


--
-- Name: st_approxquantile(public.raster, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, nband integer, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, $2, TRUE, $3, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: st_approxquantile(text, text, integer, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_quantile($1, $2, $3, TRUE, $4, $5) $_$;


--
-- Name: st_approxquantile(text, text, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, TRUE, $4, ARRAY[$5]::double precision[])).value $_$;


--
-- Name: st_approxquantile(public.raster, integer, boolean, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, $2, $3, $4, $5) $_$;


--
-- Name: st_approxquantile(public.raster, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rast public.raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, $4, ARRAY[$5]::double precision[])).value $_$;


--
-- Name: st_approxquantile(text, text, integer, boolean, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_quantile($1, $2, $3, $4, $5, $6) $_$;


--
-- Name: st_approxquantile(text, text, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, $4, $5, ARRAY[$6]::double precision[])).value $_$;


--
-- Name: st_approxsummarystats(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rast public.raster, sample_percent double precision) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, 1, TRUE, $2) $_$;


--
-- Name: st_approxsummarystats(text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, 1, $3, 0.1) $_$;


--
-- Name: st_approxsummarystats(text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, sample_percent double precision) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, 1, TRUE, $3) $_$;


--
-- Name: st_approxsummarystats(public.raster, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rast public.raster, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, 1, $2, $3) $_$;


--
-- Name: st_approxsummarystats(public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rast public.raster, nband integer, sample_percent double precision) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, $2, TRUE, $3) $_$;


--
-- Name: st_approxsummarystats(text, text, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, nband integer, sample_percent double precision) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, $3, TRUE, $4) $_$;


--
-- Name: st_approxsummarystats(public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, $2, $3, $4) $_$;


--
-- Name: st_approxsummarystats(text, text, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, $3, $4, $5) $_$;


--
-- Name: st_asbinary(public.raster, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asbinary(public.raster, outasin boolean DEFAULT false) RETURNS bytea
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_to_binary';


--
-- Name: FUNCTION st_asbinary(public.raster, outasin boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asbinary(public.raster, outasin boolean) IS 'args: rast, outasin=FALSE - Return the Well-Known Binary (WKB) representation of the raster without SRID meta data.';


--
-- Name: st_asgdalraster(public.raster, text, text[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asgdalraster(rast public.raster, format text, options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer) RETURNS bytea
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_asGDALRaster';


--
-- Name: FUNCTION st_asgdalraster(rast public.raster, format text, options text[], srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asgdalraster(rast public.raster, format text, options text[], srid integer) IS 'args: rast, format, options=NULL, srid=sameassource - Return the raster tile in the designated GDAL Raster format. Raster formats are one of those supported by your compiled library. Use ST_GDALRasters() to get a list of formats supported by your library.';


--
-- Name: st_asjpeg(public.raster, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asjpeg(rast public.raster, options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	DECLARE
		rast2 raster;
		num_bands int;
		i int;
	BEGIN
		IF rast IS NULL THEN
			RETURN NULL;
		END IF;

		num_bands := st_numbands($1);

		-- JPEG allows 1 or 3 bands
		IF num_bands <> 1 AND num_bands <> 3 THEN
			RAISE NOTICE 'The JPEG format only permits one or three bands.  The first band will be used.';
			rast2 := st_band(rast, ARRAY[1]);
			num_bands := st_numbands(rast);
		ELSE
			rast2 := rast;
		END IF;

		-- JPEG only supports 8BUI pixeltype
		FOR i IN 1..num_bands LOOP
			IF st_bandpixeltype(rast, i) != '8BUI' THEN
				RAISE EXCEPTION 'The pixel type of band % in the raster is not 8BUI.  The JPEG format can only be used with the 8BUI pixel type.', i;
			END IF;
		END LOOP;

		RETURN st_asgdalraster(rast2, 'JPEG', $2, NULL);
	END;
	$_$;


--
-- Name: FUNCTION st_asjpeg(rast public.raster, options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asjpeg(rast public.raster, options text[]) IS 'args: rast, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.';


--
-- Name: st_asjpeg(public.raster, integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_asjpeg(st_band($1, $2), $3) $_$;


--
-- Name: FUNCTION st_asjpeg(rast public.raster, nbands integer[], options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], options text[]) IS 'args: rast, nbands, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.';


--
-- Name: st_asjpeg(public.raster, integer[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], quality integer) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		quality2 int;
		options text[];
	BEGIN
		IF quality IS NOT NULL THEN
			IF quality > 100 THEN
				quality2 := 100;
			ELSEIF quality < 10 THEN
				quality2 := 10;
			ELSE
				quality2 := quality;
			END IF;

			options := array_append(options, 'QUALITY=' || quality2);
		END IF;

		RETURN st_asjpeg(st_band($1, $2), options);
	END;
	$_$;


--
-- Name: FUNCTION st_asjpeg(rast public.raster, nbands integer[], quality integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asjpeg(rast public.raster, nbands integer[], quality integer) IS 'args: rast, nbands, quality - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.';


--
-- Name: st_asjpeg(public.raster, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asjpeg(rast public.raster, nband integer, options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_asjpeg(st_band($1, $2), $3) $_$;


--
-- Name: FUNCTION st_asjpeg(rast public.raster, nband integer, options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asjpeg(rast public.raster, nband integer, options text[]) IS 'args: rast, nband, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.';


--
-- Name: st_asjpeg(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asjpeg(rast public.raster, nband integer, quality integer) RETURNS bytea
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_asjpeg($1, ARRAY[$2], $3) $_$;


--
-- Name: FUNCTION st_asjpeg(rast public.raster, nband integer, quality integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asjpeg(rast public.raster, nband integer, quality integer) IS 'args: rast, nband, quality - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.';


--
-- Name: st_aspect(public.raster, integer, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspect(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_aspect($1, $2, NULL::raster, $3, $4, $5) $_$;


--
-- Name: st_aspect(public.raster, integer, public.raster, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspect(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		-- get properties
		SELECT width, height INTO _width, _height FROM public.ST_Metadata(_rast);

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_aspect4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1,
			_width::text, _height::text,
			units::text
		);
	END;
	$$;


--
-- Name: st_aspng(public.raster, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspng(rast public.raster, options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	DECLARE
		rast2 raster;
		num_bands int;
		i int;
		pt text;
	BEGIN
		IF rast IS NULL THEN
			RETURN NULL;
		END IF;

		num_bands := st_numbands($1);

		-- PNG allows 1, 3 or 4 bands
		IF num_bands <> 1 AND num_bands <> 3 AND num_bands <> 4 THEN
			RAISE NOTICE 'The PNG format only permits one, three or four bands.  The first band will be used.';
			rast2 := st_band($1, ARRAY[1]);
			num_bands := st_numbands(rast2);
		ELSE
			rast2 := rast;
		END IF;

		-- PNG only supports 8BUI and 16BUI pixeltype
		FOR i IN 1..num_bands LOOP
			pt = st_bandpixeltype(rast, i);
			IF pt != '8BUI' AND pt != '16BUI' THEN
				RAISE EXCEPTION 'The pixel type of band % in the raster is not 8BUI or 16BUI.  The PNG format can only be used with 8BUI and 16BUI pixel types.', i;
			END IF;
		END LOOP;

		RETURN st_asgdalraster(rast2, 'PNG', $2, NULL);
	END;
	$_$;


--
-- Name: FUNCTION st_aspng(rast public.raster, options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_aspng(rast public.raster, options text[]) IS 'args: rast, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.';


--
-- Name: st_aspng(public.raster, integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspng(rast public.raster, nbands integer[], options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_aspng(st_band($1, $2), $3) $_$;


--
-- Name: FUNCTION st_aspng(rast public.raster, nbands integer[], options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_aspng(rast public.raster, nbands integer[], options text[]) IS 'args: rast, nbands, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.';


--
-- Name: st_aspng(public.raster, integer[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspng(rast public.raster, nbands integer[], compression integer) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		compression2 int;
		options text[];
	BEGIN
		IF compression IS NOT NULL THEN
			IF compression > 9 THEN
				compression2 := 9;
			ELSEIF compression < 1 THEN
				compression2 := 1;
			ELSE
				compression2 := compression;
			END IF;

			options := array_append(options, 'ZLEVEL=' || compression2);
		END IF;

		RETURN st_aspng(st_band($1, $2), options);
	END;
	$_$;


--
-- Name: FUNCTION st_aspng(rast public.raster, nbands integer[], compression integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_aspng(rast public.raster, nbands integer[], compression integer) IS 'args: rast, nbands, compression - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.';


--
-- Name: st_aspng(public.raster, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspng(rast public.raster, nband integer, options text[] DEFAULT NULL::text[]) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_aspng(st_band($1, $2), $3) $_$;


--
-- Name: FUNCTION st_aspng(rast public.raster, nband integer, options text[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_aspng(rast public.raster, nband integer, options text[]) IS 'args: rast, nband, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.';


--
-- Name: st_aspng(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_aspng(rast public.raster, nband integer, compression integer) RETURNS bytea
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_aspng($1, ARRAY[$2], $3) $_$;


--
-- Name: FUNCTION st_aspng(rast public.raster, nband integer, compression integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_aspng(rast public.raster, nband integer, compression integer) IS 'args: rast, nband, compression - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.';


--
-- Name: st_asraster(public.geometry, public.raster, text[], double precision[], double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql STABLE
    AS $_$
	DECLARE
		g geometry;
		g_srid integer;

		ul_x double precision;
		ul_y double precision;
		scale_x double precision;
		scale_y double precision;
		skew_x double precision;
		skew_y double precision;
		sr_id integer;
	BEGIN
		SELECT upperleftx, upperlefty, scalex, scaley, skewx, skewy, srid INTO ul_x, ul_y, scale_x, scale_y, skew_x, skew_y, sr_id FROM public.ST_Metadata(ref);
		--RAISE NOTICE '%, %, %, %, %, %, %', ul_x, ul_y, scale_x, scale_y, skew_x, skew_y, sr_id;

		-- geometry and raster has different SRID
		g_srid := public.ST_SRID(geom);
		IF g_srid != sr_id THEN
			RAISE NOTICE 'The geometry''s SRID (%) is not the same as the raster''s SRID (%).  The geometry will be transformed to the raster''s projection', g_srid, sr_id;
			g := public.ST_Transform(geom, sr_id);
		ELSE
			g := geom;
		END IF;

		RETURN public._ST_asraster(g, scale_x, scale_y, NULL, NULL, $3, $4, $5, NULL, NULL, ul_x, ul_y, skew_x, skew_y, $6);
	END;
	$_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, ref public.raster, pixeltype text[], value double precision[], nodataval double precision[], touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text[], value double precision[], nodataval double precision[], touched boolean) IS 'args: geom, ref, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, public.raster, text, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT  public.ST_AsRaster($1, $2, ARRAY[$3]::text[], ARRAY[$4]::double precision[], ARRAY[$5]::double precision[], $6) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, ref public.raster, pixeltype text, value double precision, nodataval double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, ref public.raster, pixeltype text, value double precision, nodataval double precision, touched boolean) IS 'args: geom, ref, pixeltype, value=1, nodataval=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, double precision, double precision, text[], double precision[], double precision[], double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, $4, $5, $6, $7, $8, NULL, NULL,	$9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, scalex, scaley, pixeltype, value=ARRAY[1], nodataval=ARRAY[0], upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, double precision, double precision, double precision, double precision, text[], double precision[], double precision[], double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, $6, $7, $8, NULL, NULL, $4, $5, $9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) IS 'args: geom, scalex, scaley, gridx=NULL, gridy=NULL, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, double precision, double precision, double precision, double precision, text, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, ARRAY[$6]::text[], ARRAY[$7]::double precision[], ARRAY[$8]::double precision[], NULL, NULL, $4, $5, $9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, scalex, scaley, gridx, gridy, pixeltype, value=1, nodataval=0, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, double precision, double precision, text, double precision, double precision, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, ARRAY[$4]::text[], ARRAY[$5]::double precision[], ARRAY[$6]::double precision[], $7, $8, NULL, NULL, $9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, scalex double precision, scaley double precision, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, scalex, scaley, pixeltype, value=1, nodataval=0, upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, integer, integer, text[], double precision[], double precision[], double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text[], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, $4, $5, $6, $7, $8, NULL, NULL,	$9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, width integer, height integer, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, width, height, pixeltype, value=ARRAY[1], nodataval=ARRAY[0], upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, integer, integer, double precision, double precision, text[], double precision[], double precision[], double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, $6, $7, $8, NULL, NULL, $4, $5, $9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) IS 'args: geom, width, height, gridx=NULL, gridy=NULL, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, integer, integer, double precision, double precision, text, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, ARRAY[$6]::text[], ARRAY[$7]::double precision[], ARRAY[$8]::double precision[], NULL, NULL, $4, $5, $9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, width, height, gridx, gridy, pixeltype, value=1, nodataval=0, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_asraster(public.geometry, integer, integer, text, double precision, double precision, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, ARRAY[$4]::text[], ARRAY[$5]::double precision[], ARRAY[$6]::double precision[], $7, $8, NULL, NULL,$9, $10, $11) $_$;


--
-- Name: FUNCTION st_asraster(geom public.geometry, width integer, height integer, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_asraster(geom public.geometry, width integer, height integer, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) IS 'args: geom, width, height, pixeltype, value=1, nodataval=0, upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.';


--
-- Name: st_astiff(public.raster, text[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_astiff(rast public.raster, options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	DECLARE
		i int;
		num_bands int;
		nodata double precision;
		last_nodata double precision;
	BEGIN
		IF rast IS NULL THEN
			RETURN NULL;
		END IF;

		num_bands := st_numbands($1);

		-- TIFF only allows one NODATA value for ALL bands
		FOR i IN 1..num_bands LOOP
			nodata := st_bandnodatavalue($1, i);
			IF last_nodata IS NULL THEN
				last_nodata := nodata;
			ELSEIF nodata != last_nodata THEN
				RAISE NOTICE 'The TIFF format only permits one NODATA value for all bands.  The value used will be the last band with a NODATA value.';
			END IF;
		END LOOP;

		RETURN st_asgdalraster($1, 'GTiff', $2, $3);
	END;
	$_$;


--
-- Name: FUNCTION st_astiff(rast public.raster, options text[], srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_astiff(rast public.raster, options text[], srid integer) IS 'args: rast, options='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.';


--
-- Name: st_astiff(public.raster, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_astiff(rast public.raster, compression text, srid integer DEFAULT NULL::integer) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	DECLARE
		compression2 text;
		c_type text;
		c_level int;
		i int;
		num_bands int;
		options text[];
	BEGIN
		IF rast IS NULL THEN
			RETURN NULL;
		END IF;

		compression2 := trim(both from upper(compression));

		IF length(compression2) > 0 THEN
			-- JPEG
			IF position('JPEG' in compression2) != 0 THEN
				c_type := 'JPEG';
				c_level := substring(compression2 from '[0-9]+$');

				IF c_level IS NOT NULL THEN
					IF c_level > 100 THEN
						c_level := 100;
					ELSEIF c_level < 1 THEN
						c_level := 1;
					END IF;

					options := array_append(options, 'JPEG_QUALITY=' || c_level);
				END IF;

				-- per band pixel type check
				num_bands := st_numbands($1);
				FOR i IN 1..num_bands LOOP
					IF st_bandpixeltype($1, i) != '8BUI' THEN
						RAISE EXCEPTION 'The pixel type of band % in the raster is not 8BUI.  JPEG compression can only be used with the 8BUI pixel type.', i;
					END IF;
				END LOOP;

			-- DEFLATE
			ELSEIF position('DEFLATE' in compression2) != 0 THEN
				c_type := 'DEFLATE';
				c_level := substring(compression2 from '[0-9]+$');

				IF c_level IS NOT NULL THEN
					IF c_level > 9 THEN
						c_level := 9;
					ELSEIF c_level < 1 THEN
						c_level := 1;
					END IF;

					options := array_append(options, 'ZLEVEL=' || c_level);
				END IF;

			ELSE
				c_type := compression2;

				-- CCITT
				IF position('CCITT' in compression2) THEN
					-- per band pixel type check
					num_bands := st_numbands($1);
					FOR i IN 1..num_bands LOOP
						IF st_bandpixeltype($1, i) != '1BB' THEN
							RAISE EXCEPTION 'The pixel type of band % in the raster is not 1BB.  CCITT compression can only be used with the 1BB pixel type.', i;
						END IF;
					END LOOP;
				END IF;

			END IF;

			-- compression type check
			IF ARRAY[c_type] <@ ARRAY['JPEG', 'LZW', 'PACKBITS', 'DEFLATE', 'CCITTRLE', 'CCITTFAX3', 'CCITTFAX4', 'NONE'] THEN
				options := array_append(options, 'COMPRESS=' || c_type);
			ELSE
				RAISE NOTICE 'Unknown compression type: %.  The outputted TIFF will not be COMPRESSED.', c_type;
			END IF;
		END IF;

		RETURN st_astiff($1, options, $3);
	END;
	$_$;


--
-- Name: FUNCTION st_astiff(rast public.raster, compression text, srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_astiff(rast public.raster, compression text, srid integer) IS 'args: rast, compression='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.';


--
-- Name: st_astiff(public.raster, integer[], text[], integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_astiff(rast public.raster, nbands integer[], options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_astiff(st_band($1, $2), $3, $4) $_$;


--
-- Name: FUNCTION st_astiff(rast public.raster, nbands integer[], options text[], srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_astiff(rast public.raster, nbands integer[], options text[], srid integer) IS 'args: rast, nbands, options, srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.';


--
-- Name: st_astiff(public.raster, integer[], text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_astiff(rast public.raster, nbands integer[], compression text, srid integer DEFAULT NULL::integer) RETURNS bytea
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_astiff(st_band($1, $2), $3, $4) $_$;


--
-- Name: FUNCTION st_astiff(rast public.raster, nbands integer[], compression text, srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_astiff(rast public.raster, nbands integer[], compression text, srid integer) IS 'args: rast, nbands, compression='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.';


--
-- Name: st_band(public.raster, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_band(rast public.raster, nbands integer[] DEFAULT ARRAY[1]) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_band';


--
-- Name: FUNCTION st_band(rast public.raster, nbands integer[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_band(rast public.raster, nbands integer[]) IS 'args: rast, nbands = ARRAY[1] - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.';


--
-- Name: st_band(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_band(rast public.raster, nband integer) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT  public.ST_band($1, ARRAY[$2]) $_$;


--
-- Name: FUNCTION st_band(rast public.raster, nband integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_band(rast public.raster, nband integer) IS 'args: rast, nband - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.';


--
-- Name: st_band(public.raster, text, character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_band(rast public.raster, nbands text, delimiter character DEFAULT ','::bpchar) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT  public.ST_band($1, regexp_split_to_array(regexp_replace($2, '[[:space:]]', '', 'g'), E'\\' || array_to_string(regexp_split_to_array($3, ''), E'\\'))::int[]) $_$;


--
-- Name: FUNCTION st_band(rast public.raster, nbands text, delimiter character); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_band(rast public.raster, nbands text, delimiter character) IS 'args: rast, nbands, delimiter=, - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.';


--
-- Name: st_bandisnodata(public.raster, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandisnodata(rast public.raster, forcechecking boolean) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_bandisnodata($1, 1, $2) $_$;


--
-- Name: FUNCTION st_bandisnodata(rast public.raster, forcechecking boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandisnodata(rast public.raster, forcechecking boolean) IS 'args: rast, forceChecking=true - Returns true if the band is filled with only nodata values.';


--
-- Name: st_bandisnodata(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandisnodata(rast public.raster, band integer DEFAULT 1, forcechecking boolean DEFAULT false) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_bandIsNoData';


--
-- Name: FUNCTION st_bandisnodata(rast public.raster, band integer, forcechecking boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandisnodata(rast public.raster, band integer, forcechecking boolean) IS 'args: rast, band, forceChecking=true - Returns true if the band is filled with only nodata values.';


--
-- Name: st_bandmetadata(public.raster, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandmetadata(rast public.raster, band integer[], OUT bandnum integer, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text) RETURNS record
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_bandmetadata';


--
-- Name: st_bandmetadata(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandmetadata(rast public.raster, band integer DEFAULT 1, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text) RETURNS record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT pixeltype, nodatavalue, isoutdb, path FROM public.ST_BandMetaData($1, ARRAY[$2]::int[]) LIMIT 1 $_$;


--
-- Name: FUNCTION st_bandmetadata(rast public.raster, band integer, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandmetadata(rast public.raster, band integer, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text) IS 'args: rast, bandnum=1 - Returns basic meta data for a specific raster band. band num 1 is assumed if none-specified.';


--
-- Name: st_bandnodatavalue(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandnodatavalue(rast public.raster, band integer DEFAULT 1) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getBandNoDataValue';


--
-- Name: FUNCTION st_bandnodatavalue(rast public.raster, band integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandnodatavalue(rast public.raster, band integer) IS 'args: rast, bandnum=1 - Returns the value in a given band that represents no data. If no band num 1 is assumed.';


--
-- Name: st_bandpath(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandpath(rast public.raster, band integer DEFAULT 1) RETURNS text
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getBandPath';


--
-- Name: FUNCTION st_bandpath(rast public.raster, band integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandpath(rast public.raster, band integer) IS 'args: rast, bandnum=1 - Returns system file path to a band stored in file system. If no bandnum specified, 1 is assumed.';


--
-- Name: st_bandpixeltype(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_bandpixeltype(rast public.raster, band integer DEFAULT 1) RETURNS text
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getBandPixelTypeName';


--
-- Name: FUNCTION st_bandpixeltype(rast public.raster, band integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_bandpixeltype(rast public.raster, band integer) IS 'args: rast, bandnum=1 - Returns the type of pixel for given band. If no bandnum specified, 1 is assumed.';


--
-- Name: st_clip(public.raster, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, geom public.geometry, crop boolean) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ST_Clip($1, NULL, $2, null::double precision[], $3) $_$;


--
-- Name: st_clip(public.raster, integer, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, nband integer, geom public.geometry, crop boolean) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ST_Clip($1, ARRAY[$2]::integer[], $3, null::double precision[], $4) $_$;


--
-- Name: st_clip(public.raster, public.geometry, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, geom public.geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ST_Clip($1, NULL, $2, $3, $4) $_$;


--
-- Name: st_clip(public.raster, public.geometry, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, geom public.geometry, nodataval double precision, crop boolean DEFAULT true) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ST_Clip($1, NULL, $2, ARRAY[$3]::double precision[], $4) $_$;


--
-- Name: st_clip(public.raster, integer[], public.geometry, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, nband integer[], geom public.geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	BEGIN
		-- short-cut if geometry's extent fully contains raster's extent
		IF (nodataval IS NULL OR array_length(nodataval, 1) < 1) AND geom ~ ST_Envelope(rast) THEN
			RETURN rast;
		END IF;

		RETURN public._ST_Clip($1, $2, $3, $4, $5);
	END;
	$_$;


--
-- Name: st_clip(public.raster, integer, public.geometry, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_clip(rast public.raster, nband integer, geom public.geometry, nodataval double precision, crop boolean DEFAULT true) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ST_Clip($1, ARRAY[$2]::integer[], $3, ARRAY[$4]::double precision[], $5) $_$;


--
-- Name: st_colormap(public.raster, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_colormap(rast public.raster, colormap text, method text DEFAULT 'INTERPOLATE'::text) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_ColorMap($1, 1, $2, $3) $_$;


--
-- Name: st_colormap(public.raster, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_colormap(rast public.raster, nband integer DEFAULT 1, colormap text DEFAULT 'grayscale'::text, method text DEFAULT 'INTERPOLATE'::text) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		_ismap boolean;
		_colormap text;
		_element text[];
	BEGIN
		_ismap := TRUE;

		-- clean colormap to see what it is
		_colormap := split_part(colormap, E'\n', 1);
		_colormap := regexp_replace(_colormap, E':+', ' ', 'g');
		_colormap := regexp_replace(_colormap, E',+', ' ', 'g');
		_colormap := regexp_replace(_colormap, E'\\t+', ' ', 'g');
		_colormap := regexp_replace(_colormap, E' +', ' ', 'g');
		_element := regexp_split_to_array(_colormap, ' ');

		-- treat as colormap
		IF (array_length(_element, 1) > 1) THEN
			_colormap := colormap;
		-- treat as keyword
		ELSE
			method := 'INTERPOLATE';
			CASE lower(trim(both from _colormap))
				WHEN 'grayscale', 'greyscale' THEN
					_colormap := '
100%   0
  0% 254
  nv 255 
					';
				WHEN 'pseudocolor' THEN
					_colormap := '
100% 255   0   0 255
 50%   0 255   0 255
  0%   0   0 255 255
  nv   0   0   0   0
					';
				WHEN 'fire' THEN
					_colormap := '
  100% 243 255 221 255
93.75% 242 255 178 255
 87.5% 255 255 135 255
81.25% 255 228  96 255
   75% 255 187  53 255
68.75% 255 131   7 255
 62.5% 255  84   0 255
56.25% 255  42   0 255
   50% 255   0   0 255
43.75% 255  42   0 255
 37.5% 224  74   0 255
31.25% 183  91   0 255
   25% 140  93   0 255
18.75%  99  82   0 255
 12.5%  58  58   1 255
 6.25%  12  15   0 255
    0%   0   0   0 255
    nv   0   0   0   0
					';
				WHEN 'bluered' THEN
					_colormap := '
100.00% 165   0  33 255
 94.12% 216  21  47 255
 88.24% 247  39  53 255
 82.35% 255  61  61 255
 76.47% 255 120  86 255
 70.59% 255 172 117 255
 64.71% 255 214 153 255
 58.82% 255 241 188 255
 52.94% 255 255 234 255
 47.06% 234 255 255 255
 41.18% 188 249 255 255
 35.29% 153 234 255 255
 29.41% 117 211 255 255
 23.53%  86 176 255 255
 17.65%  61 135 255 255
 11.76%  40  87 255 255
  5.88%  24  28 247 255
  0.00%  36   0 216 255
     nv   0   0   0   0
					';
				ELSE
					RAISE EXCEPTION 'Unknown colormap keyword: %', colormap;
			END CASE;
		END IF;

		RETURN public._ST_colormap($1, $2, _colormap, $4);
	END;
	$_$;


--
-- Name: st_contains(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_contains(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_contains($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_contains(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_contains(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if no points of raster rastB lie in the exterior of raster rastA and at least one point of the interior of rastB lies in the interior of rastA.';


--
-- Name: st_contains(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_contains(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_contains($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_contains(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastB lie in the exterior of raster rastA and at least one point of the interior of rastB lies in the interior of rastA.';


--
-- Name: st_containsproperly(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_containsproperly(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_containsproperly($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_containsproperly(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_containsproperly(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if rastB intersects the interior of rastA but not the boundary or exterior of rastA.';


--
-- Name: st_containsproperly(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_containsproperly(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_containsproperly($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_containsproperly(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if rastB intersects the interior of rastA but not the boundary or exterior of rastA.';


--
-- Name: st_convexhull(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_convexhull(public.raster) RETURNS public.geometry
    LANGUAGE c IMMUTABLE STRICT COST 300
    AS '$libdir/rtpostgis-2.3', 'RASTER_convex_hull';


--
-- Name: st_count(public.raster, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_count(rast public.raster, exclude_nodata_value boolean) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, 1, $2, 1) $_$;


--
-- Name: FUNCTION st_count(rast public.raster, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_count(rast public.raster, exclude_nodata_value boolean) IS 'args: rast, exclude_nodata_value - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.';


--
-- Name: st_count(text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_count(rastertable text, rastercolumn text, exclude_nodata_value boolean) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, 1, $3, 1) $_$;


--
-- Name: FUNCTION st_count(rastertable text, rastercolumn text, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_count(rastertable text, rastercolumn text, exclude_nodata_value boolean) IS 'args: rastertable, rastercolumn, exclude_nodata_value - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.';


--
-- Name: st_count(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_count(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true) RETURNS bigint
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_count($1, $2, $3, 1) $_$;


--
-- Name: FUNCTION st_count(rast public.raster, nband integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_count(rast public.raster, nband integer, exclude_nodata_value boolean) IS 'args: rast, nband=1, exclude_nodata_value=true - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.';


--
-- Name: st_count(text, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_count(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true) RETURNS bigint
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_count($1, $2, $3, $4, 1) $_$;


--
-- Name: FUNCTION st_count(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_count(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.';


--
-- Name: st_coveredby(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_coveredby(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_coveredby($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_coveredby(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_coveredby(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if no points of raster rastA lie outside raster rastB.';


--
-- Name: st_coveredby(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_coveredby(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_coveredby($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_coveredby(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastA lie outside raster rastB.';


--
-- Name: st_covers(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_covers(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_covers($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_covers(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_covers(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if no points of raster rastB lie outside raster rastA.';


--
-- Name: st_covers(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_covers(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_covers($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_covers(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastB lie outside raster rastA.';


--
-- Name: st_createoverview(regclass, name, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_createoverview(tab regclass, col name, factor integer, algo text DEFAULT 'NearestNeighbour'::text) RETURNS regclass
    LANGUAGE plpgsql STRICT
    AS $_$
DECLARE
  sinfo RECORD; -- source info
  sql TEXT;
  ttab TEXT;
BEGIN

  -- 0. Check arguments, we need to ensure:
  --    a. Source table has a raster column with given name
  --    b. Source table has a fixed scale (or "factor" would have no meaning)
  --    c. Source table has a known extent ? (we could actually compute it)
  --    d. Source table has a fixed tile size (or "factor" would have no meaning?)
  -- # all of the above can be checked with a query to raster_columns
  sql := 'SELECT r.r_table_schema sch, r.r_table_name tab, '
      || 'r.scale_x sfx, r.scale_y sfy, r.blocksize_x tw, '
      || 'r.blocksize_y th, r.extent ext, r.srid FROM public.raster_columns r, '
      || 'pg_class c, pg_namespace n WHERE r.r_table_schema = n.nspname '
      || 'AND r.r_table_name = c.relname AND r_raster_column = $2 AND '
      || ' c.relnamespace = n.oid AND c.oid = $1'
  ;
  EXECUTE sql INTO sinfo USING tab, col;
  IF sinfo IS NULL THEN
      RAISE EXCEPTION '%.% raster column does not exist', tab::text, col;
  END IF;
  IF sinfo.sfx IS NULL or sinfo.sfy IS NULL THEN
    RAISE EXCEPTION 'cannot create overview without scale constraint, try select AddRasterConstraints(''%'', ''%'');', tab::text, col;
  END IF;
  IF sinfo.tw IS NULL or sinfo.tw IS NULL THEN
    RAISE EXCEPTION 'cannot create overview without tilesize constraint, try select AddRasterConstraints(''%'', ''%'');', tab::text, col;
  END IF;
  IF sinfo.ext IS NULL THEN
    RAISE EXCEPTION 'cannot create overview without extent constraint, try select AddRasterConstraints(''%'', ''%'');', tab::text, col;
  END IF;

  -- TODO: lookup in raster_overviews to see if there's any
  --       lower-resolution table to start from

  ttab := 'o_' || factor || '_' || sinfo.tab;
  sql := 'CREATE TABLE ' || quote_ident(sinfo.sch)
      || '.' || quote_ident(ttab)
      || ' AS SELECT ST_Retile($1, $2, $3, $4, $5, $6, $7) '
      || quote_ident(col);
  EXECUTE sql USING tab, col, sinfo.ext,
                    sinfo.sfx * factor, sinfo.sfy * factor,
                    sinfo.tw, sinfo.th, algo;

  -- TODO: optimize this using knowledge we have about
  --       the characteristics of the target column ?
  PERFORM public.AddRasterConstraints(sinfo.sch, ttab, col);

  PERFORM  public.AddOverviewConstraints(sinfo.sch, ttab, col,
                                 sinfo.sch, sinfo.tab, col, factor);

    -- return the schema as well as the table
  RETURN sinfo.sch||'.'||ttab;
END;
$_$;


--
-- Name: FUNCTION st_createoverview(tab regclass, col name, factor integer, algo text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_createoverview(tab regclass, col name, factor integer, algo text) IS 'args: tab, col, factor, algo=''NearestNeighbor'' - Create an reduced resolution version of a given raster coverage.';


--
-- Name: st_dfullywithin(public.raster, public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dfullywithin(rast1 public.raster, rast2 public.raster, distance double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT st_dfullywithin($1, NULL::integer, $2, NULL::integer, $3) $_$;


--
-- Name: FUNCTION st_dfullywithin(rast1 public.raster, rast2 public.raster, distance double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dfullywithin(rast1 public.raster, rast2 public.raster, distance double precision) IS 'args: rastA, rastB, distance_of_srid - Return true if rasters rastA and rastB are fully within the specified distance of each other.';


--
-- Name: st_dfullywithin(public.raster, integer, public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($3), $5) AND $3::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($1), $5) AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._ST_dfullywithin(st_convexhull($1), st_convexhull($3), $5) ELSE public._ST_dfullywithin($1, $2, $3, $4, $5) END $_$;


--
-- Name: FUNCTION st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dfullywithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) IS 'args: rastA, nbandA, rastB, nbandB, distance_of_srid - Return true if rasters rastA and rastB are fully within the specified distance of each other.';


--
-- Name: st_disjoint(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_disjoint(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT st_disjoint($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_disjoint(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_disjoint(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if raster rastA does not spatially intersect rastB.';


--
-- Name: st_disjoint(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_disjoint(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT CASE WHEN $2 IS NULL OR $4 IS NULL THEN st_disjoint(st_convexhull($1), st_convexhull($3)) ELSE NOT public._ST_intersects($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_disjoint(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_disjoint(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA does not spatially intersect rastB.';


--
-- Name: st_distinct4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_distinct4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT COUNT(DISTINCT unnest)::double precision FROM unnest($1) $_$;


--
-- Name: st_distinct4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_distinct4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT COUNT(DISTINCT unnest)::float FROM unnest($1) $_$;


--
-- Name: st_dumpaspolygons(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dumpaspolygons(rast public.raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true) RETURNS SETOF public.geomval
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_dumpAsPolygons';


--
-- Name: st_dumpvalues(public.raster, integer[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dumpvalues(rast public.raster, nband integer[] DEFAULT NULL::integer[], exclude_nodata_value boolean DEFAULT true, OUT nband integer, OUT valarray double precision[]) RETURNS SETOF record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_dumpValues';


--
-- Name: FUNCTION st_dumpvalues(rast public.raster, nband integer[], exclude_nodata_value boolean, OUT nband integer, OUT valarray double precision[]); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dumpvalues(rast public.raster, nband integer[], exclude_nodata_value boolean, OUT nband integer, OUT valarray double precision[]) IS 'args: rast, nband=NULL, exclude_nodata_value=true - Get the values of the specified band as a 2-dimension array.';


--
-- Name: st_dumpvalues(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dumpvalues(rast public.raster, nband integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT valarray FROM public.ST_dumpvalues($1, ARRAY[$2]::integer[], $3) $_$;


--
-- Name: FUNCTION st_dumpvalues(rast public.raster, nband integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dumpvalues(rast public.raster, nband integer, exclude_nodata_value boolean) IS 'args: rast, nband, exclude_nodata_value=true - Get the values of the specified band as a 2-dimension array.';


--
-- Name: st_dwithin(public.raster, public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dwithin(rast1 public.raster, rast2 public.raster, distance double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_dwithin($1, NULL::integer, $2, NULL::integer, $3) $_$;


--
-- Name: FUNCTION st_dwithin(rast1 public.raster, rast2 public.raster, distance double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dwithin(rast1 public.raster, rast2 public.raster, distance double precision) IS 'args: rastA, rastB, distance_of_srid - Return true if rasters rastA and rastB are within the specified distance of each other.';


--
-- Name: st_dwithin(public.raster, integer, public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($3), $5) AND $3::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($1), $5) AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._ST_dwithin(st_convexhull($1), st_convexhull($3), $5) ELSE public._ST_dwithin($1, $2, $3, $4, $5) END $_$;


--
-- Name: FUNCTION st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_dwithin(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, distance double precision) IS 'args: rastA, nbandA, rastB, nbandB, distance_of_srid - Return true if rasters rastA and rastB are within the specified distance of each other.';


--
-- Name: st_envelope(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_envelope(public.raster) RETURNS public.geometry
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_envelope';


--
-- Name: st_fromgdalraster(bytea, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_fromgdalraster(gdaldata bytea, srid integer DEFAULT NULL::integer) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_fromGDALRaster';


--
-- Name: FUNCTION st_fromgdalraster(gdaldata bytea, srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_fromgdalraster(gdaldata bytea, srid integer) IS 'args: gdaldata, srid=NULL - Returns a raster from a supported GDAL raster file.';


--
-- Name: st_gdaldrivers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT create_options text) RETURNS SETOF record
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getGDALDrivers';


--
-- Name: FUNCTION st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT create_options text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT create_options text) IS 'args: OUT idx, OUT short_name, OUT long_name, OUT create_options - Returns a list of raster formats supported by your lib gdal. These are the formats you can output your raster using ST_AsGDALRaster.';


--
-- Name: st_georeference(public.raster, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_georeference(rast public.raster, format text DEFAULT 'GDAL'::text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
    DECLARE
				scale_x numeric;
				scale_y numeric;
				skew_x numeric;
				skew_y numeric;
				ul_x numeric;
				ul_y numeric;

        result text;
    BEGIN
			SELECT scalex::numeric, scaley::numeric, skewx::numeric, skewy::numeric, upperleftx::numeric, upperlefty::numeric
				INTO scale_x, scale_y, skew_x, skew_y, ul_x, ul_y FROM public.ST_Metadata(rast);

						-- scale x
            result := trunc(scale_x, 10) || E'\n';

						-- skew y
            result := result || trunc(skew_y, 10) || E'\n';

						-- skew x
            result := result || trunc(skew_x, 10) || E'\n';

						-- scale y
            result := result || trunc(scale_y, 10) || E'\n';

        IF format = 'ESRI' THEN
						-- upper left x
            result := result || trunc((ul_x + scale_x * 0.5), 10) || E'\n';

						-- upper left y
            result = result || trunc((ul_y + scale_y * 0.5), 10) || E'\n';
        ELSE -- IF format = 'GDAL' THEN
						-- upper left x
            result := result || trunc(ul_x, 10) || E'\n';

						-- upper left y
            result := result || trunc(ul_y, 10) || E'\n';
        END IF;

        RETURN result;
    END;
    $$;


--
-- Name: FUNCTION st_georeference(rast public.raster, format text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_georeference(rast public.raster, format text) IS 'args: rast, format=GDAL - Returns the georeference meta data in GDAL or ESRI format as commonly seen in a world file. Default is GDAL.';


--
-- Name: st_geotransform(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_geotransform(public.raster, OUT imag double precision, OUT jmag double precision, OUT theta_i double precision, OUT theta_ij double precision, OUT xoffset double precision, OUT yoffset double precision) RETURNS record
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getGeotransform';


--
-- Name: st_hasnoband(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_hasnoband(rast public.raster, nband integer DEFAULT 1) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_hasNoBand';


--
-- Name: FUNCTION st_hasnoband(rast public.raster, nband integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_hasnoband(rast public.raster, nband integer) IS 'args: rast, bandnum=1 - Returns true if there is no band with given band number. If no band number is specified, then band number 1 is assumed.';


--
-- Name: st_height(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_height(public.raster) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getHeight';


--
-- Name: FUNCTION st_height(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_height(public.raster) IS 'args: rast - Returns the height of the raster in pixels.';


--
-- Name: st_hillshade(public.raster, integer, text, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_hillshade(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, azimuth double precision DEFAULT 315.0, altitude double precision DEFAULT 45.0, max_bright double precision DEFAULT 255.0, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_hillshade($1, $2, NULL::raster, $3, $4, $5, $6, $7, $8) $_$;


--
-- Name: st_hillshade(public.raster, integer, public.raster, text, double precision, double precision, double precision, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_hillshade(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, azimuth double precision DEFAULT 315.0, altitude double precision DEFAULT 45.0, max_bright double precision DEFAULT 255.0, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_pixwidth double precision;
		_pixheight double precision;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		-- get properties
		_pixwidth := public.ST_PixelWidth(_rast);
		_pixheight := public.ST_PixelHeight(_rast);
		SELECT width, height, scalex INTO _width, _height FROM public.ST_Metadata(_rast);

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_hillshade4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1,
			_pixwidth::text, _pixheight::text,
			_width::text, _height::text,
			$5::text, $6::text,
			$7::text, $8::text
		);
	END;
	$_$;


--
-- Name: st_histogram(public.raster, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rast public.raster, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, 1, $3, NULL, $4) $_$;


--
-- Name: FUNCTION st_histogram(rast public.raster, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rast public.raster, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rast, nband, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(text, text, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, TRUE, 1, $4, NULL, $5) $_$;


--
-- Name: FUNCTION st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rastertable, rastercolumn, nband, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(public.raster, integer, boolean, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rast public.raster, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, 1, $4, NULL, $5) $_$;


--
-- Name: FUNCTION st_histogram(rast public.raster, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rast public.raster, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rast, nband, exclude_nodata_value, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(public.raster, integer, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rast public.raster, nband integer, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, 1, $3, $4, $5) $_$;


--
-- Name: FUNCTION st_histogram(rast public.raster, nband integer, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rast public.raster, nband integer, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rast, nband, bins, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(text, text, integer, boolean, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_histogram($1, $2, $3, $4, 1, $5, NULL, $6) $_$;


--
-- Name: FUNCTION st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rastertable, rastercolumn, nband, exclude_nodata_value, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(text, text, integer, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_histogram($1, $2, $3, TRUE, 1, $4, $5, $6) $_$;


--
-- Name: FUNCTION st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rastertable, rastercolumn, nband=1, bins, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(public.raster, integer, boolean, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, 1, $4, $5, $6) $_$;


--
-- Name: FUNCTION st_histogram(rast public.raster, nband integer, exclude_nodata_value boolean, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rast public.raster, nband integer, exclude_nodata_value boolean, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rast, nband=1, exclude_nodata_value=true, bins=autocomputed, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_histogram(text, text, integer, boolean, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_histogram($1, $2, $3, $4, 1, $5, $6, $7) $_$;


--
-- Name: FUNCTION st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, bins=autocomputed, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.';


--
-- Name: st_intersection(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast public.raster, geomin public.geometry) RETURNS SETOF public.geomval
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($2, $1, 1) $_$;


--
-- Name: st_intersection(public.geometry, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(geomin public.geometry, rast public.raster, band integer DEFAULT 1) RETURNS SETOF public.geomval
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		intersects boolean := FALSE;
	BEGIN
		intersects := ST_Intersects(geomin, rast, band);
		IF intersects THEN
			-- Return the intersections of the geometry with the vectorized parts of
			-- the raster and the values associated with those parts, if really their
			-- intersection is not empty.
			RETURN QUERY
				SELECT
					intgeom,
					val
				FROM (
					SELECT
						ST_Intersection((gv).geom, geomin) AS intgeom,
						(gv).val
					FROM ST_DumpAsPolygons(rast, band) gv
					WHERE ST_Intersects((gv).geom, geomin)
				) foo
				WHERE NOT ST_IsEmpty(intgeom);
		ELSE
			-- If the geometry does not intersect with the raster, return an empty
			-- geometry and a null value
			RETURN QUERY
				SELECT
					emptygeom,
					NULL::float8
				FROM ST_GeomCollFromText('GEOMETRYCOLLECTION EMPTY', ST_SRID($1)) emptygeom;
		END IF;
	END;
	$_$;


--
-- Name: st_intersection(public.raster, integer, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast public.raster, band integer, geomin public.geometry) RETURNS SETOF public.geomval
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($3, $1, $2) $_$;


--
-- Name: st_intersection(public.raster, public.raster, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, nodataval double precision[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, 1, $2, 1, 'BOTH', $3) $_$;


--
-- Name: st_intersection(public.raster, public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, nodataval double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, 1, $2, 1, 'BOTH', ARRAY[$3, $3]) $_$;


--
-- Name: st_intersection(public.raster, public.raster, text, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, returnband text DEFAULT 'BOTH'::text, nodataval double precision[] DEFAULT NULL::double precision[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, 1, $2, 1, $3, $4) $_$;


--
-- Name: st_intersection(public.raster, public.raster, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, rast2 public.raster, returnband text, nodataval double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, 1, $2, 1, $3, ARRAY[$4, $4]) $_$;


--
-- Name: st_intersection(public.raster, integer, public.raster, integer, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, nodataval double precision[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, $2, $3, $4, 'BOTH', $5) $_$;


--
-- Name: st_intersection(public.raster, integer, public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, nodataval double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, $2, $3, $4, 'BOTH', ARRAY[$5, $5]) $_$;


--
-- Name: st_intersection(public.raster, integer, public.raster, integer, text, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, returnband text DEFAULT 'BOTH'::text, nodataval double precision[] DEFAULT NULL::double precision[]) RETURNS public.raster
    LANGUAGE plpgsql STABLE PARALLEL SAFE
    AS $$
	DECLARE
		rtn raster;
		_returnband text;
		newnodata1 float8;
		newnodata2 float8;
	BEGIN
		IF ST_SRID(rast1) != ST_SRID(rast2) THEN
			RAISE EXCEPTION 'The two rasters do not have the same SRID';
		END IF;

		newnodata1 := coalesce(nodataval[1], ST_BandNodataValue(rast1, band1), ST_MinPossibleValue(ST_BandPixelType(rast1, band1)));
		newnodata2 := coalesce(nodataval[2], ST_BandNodataValue(rast2, band2), ST_MinPossibleValue(ST_BandPixelType(rast2, band2)));
		
		_returnband := upper(returnband);

		rtn := NULL;
		CASE
			WHEN _returnband = 'BAND1' THEN
				rtn := ST_MapAlgebraExpr(rast1, band1, rast2, band2, '[rast1.val]', ST_BandPixelType(rast1, band1), 'INTERSECTION', newnodata1::text, newnodata1::text, newnodata1);
				rtn := ST_SetBandNodataValue(rtn, 1, newnodata1);
			WHEN _returnband = 'BAND2' THEN
				rtn := ST_MapAlgebraExpr(rast1, band1, rast2, band2, '[rast2.val]', ST_BandPixelType(rast2, band2), 'INTERSECTION', newnodata2::text, newnodata2::text, newnodata2);
				rtn := ST_SetBandNodataValue(rtn, 1, newnodata2);
			WHEN _returnband = 'BOTH' THEN
				rtn := ST_MapAlgebraExpr(rast1, band1, rast2, band2, '[rast1.val]', ST_BandPixelType(rast1, band1), 'INTERSECTION', newnodata1::text, newnodata1::text, newnodata1);
				rtn := ST_SetBandNodataValue(rtn, 1, newnodata1);
				rtn := ST_AddBand(rtn, ST_MapAlgebraExpr(rast1, band1, rast2, band2, '[rast2.val]', ST_BandPixelType(rast2, band2), 'INTERSECTION', newnodata2::text, newnodata2::text, newnodata2));
				rtn := ST_SetBandNodataValue(rtn, 2, newnodata2);
			ELSE
				RAISE EXCEPTION 'Unknown value provided for returnband: %', returnband;
				RETURN NULL;
		END CASE;

		RETURN rtn;
	END;
	$$;


--
-- Name: st_intersection(public.raster, integer, public.raster, integer, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersection(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, returnband text, nodataval double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT st_intersection($1, $2, $3, $4, $5, ARRAY[$6, $6]) $_$;


--
-- Name: st_intersects(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersects(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_intersects($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_intersects(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_intersects(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if raster rastA spatially intersects raster rastB.';


--
-- Name: st_intersects(public.geometry, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersects(geom public.geometry, rast public.raster, nband integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $2::geometry AND public._st_intersects($1, $2, $3); $_$;


--
-- Name: FUNCTION st_intersects(geom public.geometry, rast public.raster, nband integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_intersects(geom public.geometry, rast public.raster, nband integer) IS 'args: geommin, rast, nband=NULL - Return true if raster rastA spatially intersects raster rastB.';


--
-- Name: st_intersects(public.raster, integer, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersects(rast public.raster, nband integer, geom public.geometry) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1::geometry OPERATOR(public.&&) $3 AND public._st_intersects($3, $1, $2) $_$;


--
-- Name: FUNCTION st_intersects(rast public.raster, nband integer, geom public.geometry); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_intersects(rast public.raster, nband integer, geom public.geometry) IS 'args: rast, nband, geommin - Return true if raster rastA spatially intersects raster rastB.';


--
-- Name: st_intersects(public.raster, public.geometry, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersects(rast public.raster, geom public.geometry, nband integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1::geometry OPERATOR(public.&&) $2 AND public._st_intersects($2, $1, $3) $_$;


--
-- Name: FUNCTION st_intersects(rast public.raster, geom public.geometry, nband integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_intersects(rast public.raster, geom public.geometry, nband integer) IS 'args: rast, geommin, nband=NULL - Return true if raster rastA spatially intersects raster rastB.';


--
-- Name: st_intersects(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_intersects(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_intersects(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_intersects($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_intersects(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_intersects(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA spatially intersects raster rastB.';


--
-- Name: st_invdistweight4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_invdistweight4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		ndims int;

		k double precision DEFAULT 1.;
		_k double precision DEFAULT 1.;
		z double precision[];
		d double precision[];
		_d double precision;
		z0 double precision;

		_z integer;
		x integer;
		y integer;

		cx integer;
		cy integer;
		cv double precision;
		cw double precision DEFAULT NULL;

		w integer;
		h integer;
		max_dx double precision;
		max_dy double precision;
	BEGIN
--		RAISE NOTICE 'value = %', value;
--		RAISE NOTICE 'userargs = %', userargs;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		_z := array_lower(_value, 1);

		-- width and height (0-based)
		h := array_upper(_value, 2) - array_lower(_value, 2);
		w := array_upper(_value, 3) - array_lower(_value, 3);

		-- max distance from center pixel
		max_dx := w / 2;
		max_dy := h / 2;
--		RAISE NOTICE 'max_dx, max_dy = %, %', max_dx, max_dy;

		-- correct width and height (1-based)
		w := w + 1;
		h := h + 1;
--		RAISE NOTICE 'w, h = %, %', w, h;

		-- width and height should be odd numbers
		IF w % 2. != 1 THEN
			RAISE EXCEPTION 'Width of neighborhood array does not permit for a center pixel';
		END IF;
		IF h % 2. != 1 THEN
			RAISE EXCEPTION 'Height of neighborhood array does not permit for a center pixel';
		END IF;

		-- center pixel's coordinates
		cy := max_dy + array_lower(_value, 2);
		cx := max_dx + array_lower(_value, 3);
--		RAISE NOTICE 'cx, cy = %, %', cx, cy;

		-- if userargs provided, only use the first two args
		IF userargs IS NOT NULL AND array_ndims(userargs) = 1 THEN
			-- first arg is power factor
			k := userargs[array_lower(userargs, 1)]::double precision;
			IF k IS NULL THEN
				k := _k;
			ELSEIF k < 0. THEN
				RAISE NOTICE 'Power factor (< 0) must be between 0 and 1.  Defaulting to 0';
				k := 0.;
			ELSEIF k > 1. THEN
				RAISE NOTICE 'Power factor (> 1) must be between 0 and 1.  Defaulting to 1';
				k := 1.;
			END IF;

			-- second arg is what to do if center pixel has a value
			-- this will be a weight to apply for the center pixel
			IF array_length(userargs, 1) > 1 THEN
				cw := abs(userargs[array_lower(userargs, 1) + 1]::double precision);
				IF cw IS NOT NULL THEN
					IF cw < 0. THEN
						RAISE NOTICE 'Weight (< 0) of center pixel value must be between 0 and 1.  Defaulting to 0';
						cw := 0.;
					ELSEIF cw > 1 THEN
						RAISE NOTICE 'Weight (> 1) of center pixel value must be between 0 and 1.  Defaulting to 1';
						cw := 1.;
					END IF;
				END IF;
			END IF;
		END IF;
--		RAISE NOTICE 'k = %', k;
		k = abs(k) * -1;

		-- center pixel value
		cv := _value[_z][cy][cx];

		-- check to see if center pixel has value
--		RAISE NOTICE 'cw = %', cw;
		IF cw IS NULL AND cv IS NOT NULL THEN
			RETURN cv;
		END IF;

		FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
			FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
--				RAISE NOTICE 'value[%][%][%] = %', _z, y, x, _value[_z][y][x];

				-- skip NODATA values and center pixel
				IF _value[_z][y][x] IS NULL OR (x = cx AND y = cy) THEN
					CONTINUE;
				END IF;

				z := z || _value[_z][y][x];

				-- use pythagorean theorem
				_d := sqrt(power(cx - x, 2) + power(cy - y, 2));
--				RAISE NOTICE 'distance = %', _d;

				d := d || _d;
			END LOOP;
		END LOOP;
--		RAISE NOTICE 'z = %', z;
--		RAISE NOTICE 'd = %', d;

		-- neighborhood is NODATA
		IF z IS NULL OR array_length(z, 1) < 1 THEN
			-- center pixel has value
			IF cv IS NOT NULL THEN
				RETURN cv;
			ELSE
				RETURN NULL;
			END IF;
		END IF;

		z0 := 0;
		_d := 0;
		FOR x IN array_lower(z, 1)..array_upper(z, 1) LOOP
			d[x] := power(d[x], k);
			z[x] := z[x] * d[x];
			_d := _d + d[x];
			z0 := z0 + z[x];
		END LOOP;
		z0 := z0 / _d;
--		RAISE NOTICE 'z0 = %', z0;

		-- apply weight for center pixel if center pixel has value
		IF cv IS NOT NULL THEN
			z0 := (cw * cv) + ((1 - cw) * z0);
--			RAISE NOTICE '*z0 = %', z0;
		END IF;

		RETURN z0;
	END;
	$$;


--
-- Name: st_iscoveragetile(public.raster, public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_iscoveragetile(rast public.raster, coverage public.raster, tilewidth integer, tileheight integer) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
	DECLARE
		_rastmeta record;
		_covmeta record;
		cr record;
		max integer[];
		tile integer[];
		edge integer[];
	BEGIN
		IF NOT ST_SameAlignment(rast, coverage) THEN
			RAISE NOTICE 'Raster and coverage are not aligned';
			RETURN FALSE;
		END IF;

		_rastmeta := ST_Metadata(rast);
		_covmeta := ST_Metadata(coverage);

		-- get coverage grid coordinates of upper-left of rast
		cr := ST_WorldToRasterCoord(coverage, _rastmeta.upperleftx, _rastmeta.upperlefty);

		-- rast is not part of coverage
		IF
			(cr.columnx < 1 OR cr.columnx > _covmeta.width) OR
			(cr.rowy < 1 OR cr.rowy > _covmeta.height)
		THEN
			RAISE NOTICE 'Raster is not in the coverage';
			RETURN FALSE;
		END IF;

		-- rast isn't on the coverage's grid
		IF
			((cr.columnx - 1) % tilewidth != 0) OR
			((cr.rowy - 1) % tileheight != 0)
		THEN
			RAISE NOTICE 'Raster is not aligned to tile grid of coverage';
			RETURN FALSE;
		END IF;

		-- max # of tiles on X and Y for coverage
		max[0] := ceil(_covmeta.width::double precision / tilewidth::double precision)::integer;
		max[1] := ceil(_covmeta.height::double precision / tileheight::double precision)::integer;

		-- tile # of rast in coverge
		tile[0] := (cr.columnx / tilewidth) + 1;
		tile[1] := (cr.rowy / tileheight) + 1;

		-- inner tile
		IF tile[0] < max[0] AND tile[1] < max[1] THEN
			IF
				(_rastmeta.width != tilewidth) OR
				(_rastmeta.height != tileheight)
			THEN
				RAISE NOTICE 'Raster width/height is invalid for interior tile of coverage';
				RETURN FALSE;
			ELSE
				RETURN TRUE;
			END IF;
		END IF;

		-- edge tile

		-- edge tile may have same size as inner tile
		IF 
			(_rastmeta.width = tilewidth) AND
			(_rastmeta.height = tileheight)
		THEN
			RETURN TRUE;
		END IF;

		-- get edge tile width and height
		edge[0] := _covmeta.width - ((max[0] - 1) * tilewidth);
		edge[1] := _covmeta.height - ((max[1] - 1) * tileheight);

		-- edge tile not of expected tile size
		-- right and bottom
		IF tile[0] = max[0] AND tile[1] = max[1] THEN
			IF
				_rastmeta.width != edge[0] OR
				_rastmeta.height != edge[1]
			THEN
				RAISE NOTICE 'Raster width/height is invalid for right-most AND bottom-most tile of coverage';
				RETURN FALSE;
			END IF;
		ELSEIF tile[0] = max[0] THEN
			IF
				_rastmeta.width != edge[0] OR
				_rastmeta.height != tileheight
			THEN
				RAISE NOTICE 'Raster width/height is invalid for right-most tile of coverage';
				RETURN FALSE;
			END IF;
		ELSE
			IF
				_rastmeta.width != tilewidth OR
				_rastmeta.height != edge[1]
			THEN
				RAISE NOTICE 'Raster width/height is invalid for bottom-most tile of coverage';
				RETURN FALSE;
			END IF;
		END IF;

		RETURN TRUE;
	END;
	$$;


--
-- Name: st_isempty(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_isempty(rast public.raster) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_isEmpty';


--
-- Name: FUNCTION st_isempty(rast public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_isempty(rast public.raster) IS 'args: rast - Returns true if the raster is empty (width = 0 and height = 0). Otherwise, returns false.';


--
-- Name: st_makeemptyraster(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_makeemptyraster(rast public.raster) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
		DECLARE
			w int;
			h int;
			ul_x double precision;
			ul_y double precision;
			scale_x double precision;
			scale_y double precision;
			skew_x double precision;
			skew_y double precision;
			sr_id int;
		BEGIN
			SELECT width, height, upperleftx, upperlefty, scalex, scaley, skewx, skewy, srid INTO w, h, ul_x, ul_y, scale_x, scale_y, skew_x, skew_y, sr_id FROM public.ST_Metadata(rast);
			RETURN  public.ST_makeemptyraster(w, h, ul_x, ul_y, scale_x, scale_y, skew_x, skew_y, sr_id);
		END;
    $$;


--
-- Name: FUNCTION st_makeemptyraster(rast public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_makeemptyraster(rast public.raster) IS 'args: rast - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).';


--
-- Name: st_makeemptyraster(integer, integer, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT  public.ST_makeemptyraster($1, $2, $3, $4, $5, -($5), 0, 0, public.ST_SRID('POINT(0 0)'::geometry)) $_$;


--
-- Name: FUNCTION st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision) IS 'args: width, height, upperleftx, upperlefty, pixelsize - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).';


--
-- Name: st_makeemptyraster(integer, integer, double precision, double precision, double precision, double precision, double precision, double precision, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer DEFAULT 0) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_makeEmpty';


--
-- Name: FUNCTION st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer) IS 'args: width, height, upperleftx, upperlefty, scalex, scaley, skewx, skewy, srid=unknown - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).';


--
-- Name: st_mapalgebra(public.raster, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast public.raster, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public.ST_mapalgebra($1, 1, $2, $3, $4) $_$;


--
-- Name: st_mapalgebra(public.raster, integer, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast public.raster, nband integer, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_mapalgebra(ARRAY[ROW($1, $2)]::rastbandarg[], $4, $3, 'FIRST', $5::text) $_$;


--
-- Name: st_mapalgebra(public.rastbandarg[], regprocedure, text, text, public.raster, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rastbandargset public.rastbandarg[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent public.raster DEFAULT NULL::public.raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_MapAlgebra($1, $2, $3, $6, $7, $4, $5,NULL::double precision [],NULL::boolean, VARIADIC $8) $_$;


--
-- Name: st_mapalgebra(public.raster, public.raster, text, text, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast1 public.raster, rast2 public.raster, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public.ST_mapalgebra($1, 1, $2, 1, $3, $4, $5, $6, $7, $8) $_$;


--
-- Name: st_mapalgebra(public.raster, integer[], regprocedure, text, text, public.raster, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast public.raster, nband integer[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'FIRST'::text, customextent public.raster DEFAULT NULL::public.raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE plpgsql STABLE
    AS $_$
	DECLARE
		x int;
		argset rastbandarg[];
	BEGIN
		IF $2 IS NULL OR array_ndims($2) < 1 OR array_length($2, 1) < 1 THEN
			RAISE EXCEPTION 'Populated 1D array must be provided for nband';
			RETURN NULL;
		END IF;

		FOR x IN array_lower($2, 1)..array_upper($2, 1) LOOP
			IF $2[x] IS NULL THEN
				CONTINUE;
			END IF;

			argset := argset || ROW($1, $2[x])::rastbandarg;
		END LOOP;

		IF array_length(argset, 1) < 1 THEN
			RAISE EXCEPTION 'Populated 1D array must be provided for nband';
			RETURN NULL;
		END IF;

		RETURN public._ST_MapAlgebra(argset, $3, $4, $7, $8, $5, $6,NULL::double precision [],NULL::boolean, VARIADIC $9);
	END;
	$_$;


--
-- Name: st_mapalgebra(public.raster, integer, regprocedure, double precision[], boolean, text, text, public.raster, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast public.raster, nband integer, callbackfunc regprocedure, mask double precision[], weighted boolean, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent public.raster DEFAULT NULL::public.raster, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$
	select public._ST_mapalgebra(ARRAY[ROW($1,$2)]::rastbandarg[],$3,$6,NULL::integer,NULL::integer,$7,$8,$4,$5,VARIADIC $9)
	$_$;


--
-- Name: st_mapalgebra(public.raster, integer, regprocedure, text, text, public.raster, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast public.raster, nband integer, callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'FIRST'::text, customextent public.raster DEFAULT NULL::public.raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_MapAlgebra(ARRAY[ROW($1, $2)]::rastbandarg[], $3, $4, $7, $8, $5, $6,NULL::double precision [],NULL::boolean, VARIADIC $9) $_$;


--
-- Name: st_mapalgebra(public.raster, integer, public.raster, integer, text, text, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_mapalgebra(ARRAY[ROW($1, $2), ROW($3, $4)]::rastbandarg[], $5, $6, $7, $8, $9, $10) $_$;


--
-- Name: st_mapalgebra(public.raster, integer, public.raster, integer, regprocedure, text, text, public.raster, integer, integer, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebra(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer, callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent public.raster DEFAULT NULL::public.raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_MapAlgebra(ARRAY[ROW($1, $2), ROW($3, $4)]::rastbandarg[], $5, $6, $9, $10, $7, $8,NULL::double precision [],NULL::boolean, VARIADIC $11) $_$;


--
-- Name: st_mapalgebraexpr(public.raster, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebraexpr(rast public.raster, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebraexpr($1, 1, $2, $3, $4) $_$;


--
-- Name: st_mapalgebraexpr(public.raster, integer, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebraexpr(rast public.raster, band integer, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_mapAlgebraExpr';


--
-- Name: st_mapalgebraexpr(public.raster, public.raster, text, text, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebraexpr(rast1 public.raster, rast2 public.raster, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public.ST_mapalgebraexpr($1, 1, $2, 1, $3, $4, $5, $6, $7, $8) $_$;


--
-- Name: st_mapalgebraexpr(public.raster, integer, public.raster, integer, text, text, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebraexpr(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_mapAlgebra2';


--
-- Name: st_mapalgebrafct(public.raster, regprocedure); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, onerastuserfunc regprocedure) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, 1, NULL, $2, NULL) $_$;


--
-- Name: st_mapalgebrafct(public.raster, integer, regprocedure); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, band integer, onerastuserfunc regprocedure) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, $2, NULL, $3, NULL) $_$;


--
-- Name: st_mapalgebrafct(public.raster, regprocedure, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, onerastuserfunc regprocedure, VARIADIC args text[]) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, 1, NULL, $2, VARIADIC $3) $_$;


--
-- Name: st_mapalgebrafct(public.raster, text, regprocedure); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, pixeltype text, onerastuserfunc regprocedure) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, 1, $2, $3, NULL) $_$;


--
-- Name: st_mapalgebrafct(public.raster, integer, regprocedure, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, band integer, onerastuserfunc regprocedure, VARIADIC args text[]) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, $2, NULL, $3, VARIADIC $4) $_$;


--
-- Name: st_mapalgebrafct(public.raster, integer, text, regprocedure); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, band integer, pixeltype text, onerastuserfunc regprocedure) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, $2, $3, $4, NULL) $_$;


--
-- Name: st_mapalgebrafct(public.raster, text, regprocedure, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[]) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_mapalgebrafct($1, 1, $2, $3, VARIADIC $4) $_$;


--
-- Name: st_mapalgebrafct(public.raster, integer, text, regprocedure, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast public.raster, band integer, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[]) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_mapAlgebraFct';


--
-- Name: st_mapalgebrafct(public.raster, public.raster, regprocedure, text, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast1 public.raster, rast2 public.raster, tworastuserfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public.ST_mapalgebrafct($1, 1, $2, 1, $3, $4, $5, VARIADIC $6) $_$;


--
-- Name: st_mapalgebrafct(public.raster, integer, public.raster, integer, regprocedure, text, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafct(rast1 public.raster, band1 integer, rast2 public.raster, band2 integer, tworastuserfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS public.raster
    LANGUAGE c STABLE
    AS '$libdir/rtpostgis-2.3', 'RASTER_mapAlgebra2';


--
-- Name: st_mapalgebrafctngb(public.raster, integer, text, integer, integer, regprocedure, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mapalgebrafctngb(rast public.raster, band integer, pixeltype text, ngbwidth integer, ngbheight integer, onerastngbuserfunc regprocedure, nodatamode text, VARIADIC args text[]) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_mapAlgebraFctNgb';


--
-- Name: st_max4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_max4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		max double precision;
		x int;
		y int;
		z int;
		ndims int;
	BEGIN
		max := '-Infinity'::double precision;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- raster
		FOR z IN array_lower(_value, 1)..array_upper(_value, 1) LOOP
			-- row
			FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
				-- column
				FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
					IF _value[z][y][x] IS NULL THEN
						IF array_length(userargs, 1) > 0 THEN
							_value[z][y][x] = userargs[array_lower(userargs, 1)]::double precision;
						ELSE
							CONTINUE;
						END IF;
					END IF;

					IF _value[z][y][x] > max THEN
						max := _value[z][y][x];
					END IF;
				END LOOP;
			END LOOP;
		END LOOP;

		IF max = '-Infinity'::double precision THEN
			RETURN NULL;
		END IF;

		RETURN max;
	END;
	$$;


--
-- Name: st_max4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_max4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
    DECLARE
        _matrix float[][];
        max float;
    BEGIN
        _matrix := matrix;
        max := '-Infinity'::float;
        FOR x in array_lower(_matrix, 1)..array_upper(_matrix, 1) LOOP
            FOR y in array_lower(_matrix, 2)..array_upper(_matrix, 2) LOOP
                IF _matrix[x][y] IS NULL THEN
                    IF NOT nodatamode = 'ignore' THEN
                        _matrix[x][y] := nodatamode::float;
                    END IF;
                END IF;
                IF max < _matrix[x][y] THEN
                    max := _matrix[x][y];
                END IF;
            END LOOP;
        END LOOP;
        RETURN max;
    END;
    $$;


--
-- Name: st_mean4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mean4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		sum double precision;
		count int;
		x int;
		y int;
		z int;
		ndims int;
	BEGIN
		sum := 0;
		count := 0;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- raster
		FOR z IN array_lower(_value, 1)..array_upper(_value, 1) LOOP
			-- row
			FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
				-- column
				FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
					IF _value[z][y][x] IS NULL THEN
						IF array_length(userargs, 1) > 0 THEN
							_value[z][y][x] = userargs[array_lower(userargs, 1)]::double precision;
						ELSE
							CONTINUE;
						END IF;
					END IF;

					sum := sum + _value[z][y][x];
					count := count + 1;
				END LOOP;
			END LOOP;
		END LOOP;

		IF count < 1 THEN
			RETURN NULL;
		END IF;

		RETURN sum / count::double precision;
	END;
	$$;


--
-- Name: st_mean4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mean4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
    DECLARE
        _matrix float[][];
        sum float;
        count float;
    BEGIN
        _matrix := matrix;
        sum := 0;
        count := 0;
        FOR x in array_lower(matrix, 1)..array_upper(matrix, 1) LOOP
            FOR y in array_lower(matrix, 2)..array_upper(matrix, 2) LOOP
                IF _matrix[x][y] IS NULL THEN
                    IF nodatamode = 'ignore' THEN
                        _matrix[x][y] := 0;
                    ELSE
                        _matrix[x][y] := nodatamode::float;
                        count := count + 1;
                    END IF;
                ELSE
                    count := count + 1;
                END IF;
                sum := sum + _matrix[x][y];
            END LOOP;
        END LOOP;
        IF count = 0 THEN
            RETURN NULL;
        END IF;
        RETURN sum / count;
    END;
    $$;


--
-- Name: st_memsize(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_memsize(public.raster) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_memsize';


--
-- Name: FUNCTION st_memsize(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_memsize(public.raster) IS 'args: rast - Returns the amount of space (in bytes) the raster takes.';


--
-- Name: st_metadata(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_metadata(rast public.raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer) RETURNS record
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_metadata';


--
-- Name: FUNCTION st_metadata(rast public.raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_metadata(rast public.raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer) IS 'args: rast - Returns basic meta data about a raster object such as pixel size, rotation (skew), upper, lower left, etc.';


--
-- Name: st_min4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_min4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		min double precision;
		x int;
		y int;
		z int;
		ndims int;
	BEGIN
		min := 'Infinity'::double precision;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- raster
		FOR z IN array_lower(_value, 1)..array_upper(_value, 1) LOOP
			-- row
			FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
				-- column
				FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
					IF _value[z][y][x] IS NULL THEN
						IF array_length(userargs, 1) > 0 THEN
							_value[z][y][x] = userargs[array_lower(userargs, 1)]::double precision;
						ELSE
							CONTINUE;
						END IF;
					END IF;

					IF _value[z][y][x] < min THEN
						min := _value[z][y][x];
					END IF;
				END LOOP;
			END LOOP;
		END LOOP;

		IF min = 'Infinity'::double precision THEN
			RETURN NULL;
		END IF;

		RETURN min;
	END;
	$$;


--
-- Name: st_min4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_min4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
    DECLARE
        _matrix float[][];
        min float;
    BEGIN
        _matrix := matrix;
        min := 'Infinity'::float;
        FOR x in array_lower(_matrix, 1)..array_upper(_matrix, 1) LOOP
            FOR y in array_lower(_matrix, 2)..array_upper(_matrix, 2) LOOP
                IF _matrix[x][y] IS NULL THEN
                    IF NOT nodatamode = 'ignore' THEN
                        _matrix[x][y] := nodatamode::float;
                    END IF;
                END IF;
                IF min > _matrix[x][y] THEN
                    min := _matrix[x][y];
                END IF;
            END LOOP;
        END LOOP;
        RETURN min;
    END;
    $$;


--
-- Name: st_minconvexhull(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_minconvexhull(rast public.raster, nband integer DEFAULT NULL::integer) RETURNS public.geometry
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_convex_hull';


--
-- Name: st_mindist4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_mindist4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		ndims int;

		d double precision DEFAULT NULL;
		_d double precision;

		z integer;
		x integer;
		y integer;

		cx integer;
		cy integer;
		cv double precision;

		w integer;
		h integer;
		max_dx double precision;
		max_dy double precision;
	BEGIN

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- only use the first raster passed to this function
		IF array_length(_value, 1) > 1 THEN
			RAISE NOTICE 'Only using the values from the first raster';
		END IF;
		z := array_lower(_value, 1);

		-- width and height (0-based)
		h := array_upper(_value, 2) - array_lower(_value, 2);
		w := array_upper(_value, 3) - array_lower(_value, 3);

		-- max distance from center pixel
		max_dx := w / 2;
		max_dy := h / 2;

		-- correct width and height (1-based)
		w := w + 1;
		h := h + 1;

		-- width and height should be odd numbers
		IF w % 2. != 1 THEN
			RAISE EXCEPTION 'Width of neighborhood array does not permit for a center pixel';
		END IF;
		IF h % 2. != 1 THEN
			RAISE EXCEPTION 'Height of neighborhood array does not permit for a center pixel';
		END IF;

		-- center pixel's coordinates
		cy := max_dy + array_lower(_value, 2);
		cx := max_dx + array_lower(_value, 3);

		-- center pixel value
		cv := _value[z][cy][cx];

		-- check to see if center pixel has value
		IF cv IS NOT NULL THEN
			RETURN 0.;
		END IF;

		FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
			FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP

				-- skip NODATA values and center pixel
				IF _value[z][y][x] IS NULL OR (x = cx AND y = cy) THEN
					CONTINUE;
				END IF;

				-- use pythagorean theorem
				_d := sqrt(power(cx - x, 2) + power(cy - y, 2));
--				RAISE NOTICE 'distance = %', _d;

				IF d IS NULL OR _d < d THEN
					d := _d;
				END IF;
			END LOOP;
		END LOOP;
--		RAISE NOTICE 'd = %', d;

		RETURN d;
	END;
	$$;


--
-- Name: st_minpossiblevalue(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_minpossiblevalue(pixeltype text) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_minPossibleValue';


--
-- Name: st_nearestvalue(public.raster, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_nearestvalue(rast public.raster, pt public.geometry, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_nearestvalue($1, 1, $2, $3) $_$;


--
-- Name: FUNCTION st_nearestvalue(rast public.raster, pt public.geometry, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_nearestvalue(rast public.raster, pt public.geometry, exclude_nodata_value boolean) IS 'args: rast, pt, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_nearestvalue(public.raster, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_nearestvalue(rast public.raster, columnx integer, rowy integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_nearestvalue($1, 1, st_setsrid(st_makepoint(st_rastertoworldcoordx($1, $2, $3), st_rastertoworldcoordy($1, $2, $3)), st_srid($1)), $4) $_$;


--
-- Name: FUNCTION st_nearestvalue(rast public.raster, columnx integer, rowy integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_nearestvalue(rast public.raster, columnx integer, rowy integer, exclude_nodata_value boolean) IS 'args: rast, columnx, rowy, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_nearestvalue(public.raster, integer, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_nearestvalue(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_nearestValue';


--
-- Name: FUNCTION st_nearestvalue(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_nearestvalue(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean) IS 'args: rast, bandnum, pt, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_nearestvalue(public.raster, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_nearestvalue(rast public.raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_nearestvalue($1, $2, st_setsrid(st_makepoint(st_rastertoworldcoordx($1, $3, $4), st_rastertoworldcoordy($1, $3, $4)), st_srid($1)), $5) $_$;


--
-- Name: FUNCTION st_nearestvalue(rast public.raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_nearestvalue(rast public.raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean) IS 'args: rast, bandnum, columnx, rowy, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_neighborhood(public.raster, public.geometry, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_neighborhood(rast public.raster, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_neighborhood($1, 1, $2, $3, $4, $5) $_$;


--
-- Name: FUNCTION st_neighborhood(rast public.raster, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_neighborhood(rast public.raster, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean) IS 'args: rast, pt, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_neighborhood(public.raster, integer, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_neighborhood(rast public.raster, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_neighborhood($1, 1, $2, $3, $4, $5, $6) $_$;


--
-- Name: FUNCTION st_neighborhood(rast public.raster, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_neighborhood(rast public.raster, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) IS 'args: rast, columnX, rowY, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_neighborhood(public.raster, integer, public.geometry, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_neighborhood(rast public.raster, band integer, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		wx double precision;
		wy double precision;
		rtn double precision[][];
	BEGIN
		IF (st_geometrytype($3) != 'ST_Point') THEN
			RAISE EXCEPTION 'Attempting to get the neighbor of a pixel with a non-point geometry';
		END IF;

		IF ST_SRID(rast) != ST_SRID(pt) THEN
			RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
		END IF;

		wx := st_x($3);
		wy := st_y($3);

		SELECT public._ST_neighborhood(
			$1, $2,
			st_worldtorastercoordx(rast, wx, wy),
			st_worldtorastercoordy(rast, wx, wy),
			$4, $5,
			$6
		) INTO rtn;
		RETURN rtn;
	END;
	$_$;


--
-- Name: FUNCTION st_neighborhood(rast public.raster, band integer, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_neighborhood(rast public.raster, band integer, pt public.geometry, distancex integer, distancey integer, exclude_nodata_value boolean) IS 'args: rast, bandnum, pt, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_neighborhood(public.raster, integer, integer, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision[]
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_neighborhood($1, $2, $3, $4, $5, $6, $7) $_$;


--
-- Name: FUNCTION st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_neighborhood(rast public.raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) IS 'args: rast, bandnum, columnX, rowY, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.';


--
-- Name: st_notsamealignmentreason(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_notsamealignmentreason(rast1 public.raster, rast2 public.raster) RETURNS text
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_notSameAlignmentReason';


--
-- Name: FUNCTION st_notsamealignmentreason(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_notsamealignmentreason(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Returns text stating if rasters are aligned and if not aligned, a reason why.';


--
-- Name: st_numbands(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_numbands(public.raster) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getNumBands';


--
-- Name: FUNCTION st_numbands(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_numbands(public.raster) IS 'args: rast - Returns the number of bands in the raster object.';


--
-- Name: st_overlaps(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_overlaps(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_overlaps($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_overlaps(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_overlaps(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if raster rastA and rastB intersect but one does not completely contain the other.';


--
-- Name: st_overlaps(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_overlaps(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._ST_overlaps($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_overlaps(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA and rastB intersect but one does not completely contain the other.';


--
-- Name: st_pixelascentroid(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelascentroid(rast public.raster, x integer, y integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_Centroid(geom) FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $_$;


--
-- Name: FUNCTION st_pixelascentroid(rast public.raster, x integer, y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelascentroid(rast public.raster, x integer, y integer) IS 'args: rast, x, y - Returns the centroid (point geometry) of the area represented by a pixel.';


--
-- Name: st_pixelascentroids(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelascentroids(rast public.raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_Centroid(geom), val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $_$;


--
-- Name: FUNCTION st_pixelascentroids(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelascentroids(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns the centroid (point geometry) for each pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel. The point geometry is the centroid of the area represented by a pixel.';


--
-- Name: st_pixelaspoint(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelaspoint(rast public.raster, x integer, y integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ST_PointN(ST_ExteriorRing(geom), 1) FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $_$;


--
-- Name: FUNCTION st_pixelaspoint(rast public.raster, x integer, y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelaspoint(rast public.raster, x integer, y integer) IS 'args: rast, columnx, rowy - Returns a point geometry of the pixels upper-left corner.';


--
-- Name: st_pixelaspoints(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelaspoints(rast public.raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_PointN(  public.ST_ExteriorRing(geom), 1), val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $_$;


--
-- Name: FUNCTION st_pixelaspoints(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelaspoints(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns a point geometry for each pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel. The coordinates of the point geometry are of the pixels upper-left corner.';


--
-- Name: st_pixelaspolygon(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelaspolygon(rast public.raster, x integer, y integer) RETURNS public.geometry
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT geom FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $_$;


--
-- Name: FUNCTION st_pixelaspolygon(rast public.raster, x integer, y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelaspolygon(rast public.raster, x integer, y integer) IS 'args: rast, columnx, rowy - Returns the polygon geometry that bounds the pixel for a particular row and column.';


--
-- Name: st_pixelaspolygons(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelaspolygons(rast public.raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT geom, val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $_$;


--
-- Name: FUNCTION st_pixelaspolygons(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelaspolygons(rast public.raster, band integer, exclude_nodata_value boolean, OUT geom public.geometry, OUT val double precision, OUT x integer, OUT y integer) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns the polygon geometry that bounds every pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel.';


--
-- Name: st_pixelheight(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelheight(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getPixelHeight';


--
-- Name: FUNCTION st_pixelheight(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelheight(public.raster) IS 'args: rast - Returns the pixel height in geometric units of the spatial reference system.';


--
-- Name: st_pixelofvalue(public.raster, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelofvalue(rast public.raster, search double precision[], exclude_nodata_value boolean DEFAULT true, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT val, x, y FROM public.ST_pixelofvalue($1, 1, $2, $3) $_$;


--
-- Name: FUNCTION st_pixelofvalue(rast public.raster, search double precision[], exclude_nodata_value boolean, OUT val double precision, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelofvalue(rast public.raster, search double precision[], exclude_nodata_value boolean, OUT val double precision, OUT x integer, OUT y integer) IS 'args: rast, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.';


--
-- Name: st_pixelofvalue(public.raster, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelofvalue(rast public.raster, search double precision, exclude_nodata_value boolean DEFAULT true, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT x, y FROM public.ST_pixelofvalue($1, 1, ARRAY[$2], $3) $_$;


--
-- Name: FUNCTION st_pixelofvalue(rast public.raster, search double precision, exclude_nodata_value boolean, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelofvalue(rast public.raster, search double precision, exclude_nodata_value boolean, OUT x integer, OUT y integer) IS 'args: rast, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.';


--
-- Name: st_pixelofvalue(public.raster, integer, double precision[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision[], exclude_nodata_value boolean DEFAULT true, OUT val double precision, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_pixelOfValue';


--
-- Name: FUNCTION st_pixelofvalue(rast public.raster, nband integer, search double precision[], exclude_nodata_value boolean, OUT val double precision, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision[], exclude_nodata_value boolean, OUT val double precision, OUT x integer, OUT y integer) IS 'args: rast, nband, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.';


--
-- Name: st_pixelofvalue(public.raster, integer, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision, exclude_nodata_value boolean DEFAULT true, OUT x integer, OUT y integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT x, y FROM public.ST_pixelofvalue($1, $2, ARRAY[$3], $4) $_$;


--
-- Name: FUNCTION st_pixelofvalue(rast public.raster, nband integer, search double precision, exclude_nodata_value boolean, OUT x integer, OUT y integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelofvalue(rast public.raster, nband integer, search double precision, exclude_nodata_value boolean, OUT x integer, OUT y integer) IS 'args: rast, nband, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.';


--
-- Name: st_pixelwidth(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_pixelwidth(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getPixelWidth';


--
-- Name: FUNCTION st_pixelwidth(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_pixelwidth(public.raster) IS 'args: rast - Returns the pixel width in geometric units of the spatial reference system.';


--
-- Name: st_polygon(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_polygon(rast public.raster, band integer DEFAULT 1) RETURNS public.geometry
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getPolygon';


--
-- Name: st_quantile(public.raster, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, 1, TRUE, 1, $2) $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, quantiles double precision[], OUT quantile double precision, OUT value double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, quantiles double precision[], OUT quantile double precision, OUT value double precision) IS 'args: rast, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, 1, TRUE, 1, ARRAY[$2]::double precision[])).value $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, quantile double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, quantile double precision) IS 'args: rast, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(text, text, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_quantile($1, $2, 1, TRUE, 1, $3) $_$;


--
-- Name: st_quantile(text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, 1, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: st_quantile(public.raster, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, 1, $2, 1, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, exclude_nodata_value boolean, quantile double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, exclude_nodata_value boolean, quantile double precision) IS 'args: rast, exclude_nodata_value, quantile=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(public.raster, integer, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, $2, TRUE, 1, $3) $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision) IS 'args: rast, nband, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(public.raster, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, nband integer, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, $2, TRUE, 1, ARRAY[$3]::double precision[])).value $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, nband integer, quantile double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, nband integer, quantile double precision) IS 'args: rast, nband, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(text, text, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision) RETURNS double precision
    LANGUAGE sql STABLE
    AS $_$ SELECT ( public._ST_quantile($1, $2, 1, $3, 1, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: st_quantile(text, text, integer, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_quantile($1, $2, $3, TRUE, 1, $4) $_$;


--
-- Name: FUNCTION st_quantile(rastertable text, rastercolumn text, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision) IS 'args: rastertable, rastercolumn, nband, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(text, text, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, TRUE, 1, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: st_quantile(public.raster, integer, boolean, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_quantile($1, $2, $3, 1, $4) $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantiles double precision[], OUT quantile double precision, OUT value double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantiles double precision[], OUT quantile double precision, OUT value double precision) IS 'args: rast, nband=1, exclude_nodata_value=true, quantiles=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(public.raster, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantile double precision) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, 1, ARRAY[$4]::double precision[])).value $_$;


--
-- Name: FUNCTION st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantile double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rast public.raster, nband integer, exclude_nodata_value boolean, quantile double precision) IS 'args: rast, nband, exclude_nodata_value, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(text, text, integer, boolean, double precision[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_quantile($1, $2, $3, $4, 1, $5) $_$;


--
-- Name: FUNCTION st_quantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, quantiles double precision[], OUT quantile double precision, OUT value double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, quantiles double precision[], OUT quantile double precision, OUT value double precision) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, quantiles=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.';


--
-- Name: st_quantile(text, text, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, quantile double precision) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_quantile($1, $2, $3, $4, 1, ARRAY[$5]::double precision[])).value $_$;


--
-- Name: st_range4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_range4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		min double precision;
		max double precision;
		x int;
		y int;
		z int;
		ndims int;
	BEGIN
		min := 'Infinity'::double precision;
		max := '-Infinity'::double precision;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- raster
		FOR z IN array_lower(_value, 1)..array_upper(_value, 1) LOOP
			-- row
			FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
				-- column
				FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
					IF _value[z][y][x] IS NULL THEN
						IF array_length(userargs, 1) > 0 THEN
							_value[z][y][x] = userargs[array_lower(userargs, 1)]::double precision;
						ELSE
							CONTINUE;
						END IF;
					END IF;

					IF _value[z][y][x] < min THEN
						min := _value[z][y][x];
					END IF;
					IF _value[z][y][x] > max THEN
						max := _value[z][y][x];
					END IF;
				END LOOP;
			END LOOP;
		END LOOP;

		IF max = '-Infinity'::double precision OR min = 'Infinity'::double precision THEN
			RETURN NULL;
		END IF;

		RETURN max - min;
	END;
	$$;


--
-- Name: st_range4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_range4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
    DECLARE
        _matrix float[][];
        min float;
        max float;
    BEGIN
        _matrix := matrix;
        min := 'Infinity'::float;
        max := '-Infinity'::float;
        FOR x in array_lower(matrix, 1)..array_upper(matrix, 1) LOOP
            FOR y in array_lower(matrix, 2)..array_upper(matrix, 2) LOOP
                IF _matrix[x][y] IS NULL THEN
                    IF NOT nodatamode = 'ignore' THEN
                        _matrix[x][y] := nodatamode::float;
                    END IF;
                END IF;
                IF min > _matrix[x][y] THEN
                    min = _matrix[x][y];
                END IF;
                IF max < _matrix[x][y] THEN
                    max = _matrix[x][y];
                END IF;
            END LOOP;
        END LOOP;
        IF max = '-Infinity'::float OR min = 'Infinity'::float THEN
            RETURN NULL;
        END IF;
        RETURN max - min;
    END;
    $$;


--
-- Name: st_rastertoworldcoord(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rastertoworldcoord(rast public.raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) RETURNS record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT longitude, latitude FROM public._ST_rastertoworldcoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_rastertoworldcoord(rast public.raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rastertoworldcoord(rast public.raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) IS 'args: rast, xcolumn, yrow - Returns the rasters upper left corner as geometric X and Y (longitude and latitude) given a column and row. Column and row starts at 1.';


--
-- Name: st_rastertoworldcoordx(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT longitude FROM public._ST_rastertoworldcoord($1, $2, NULL) $_$;


--
-- Name: FUNCTION st_rastertoworldcoordx(rast public.raster, xr integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer) IS 'args: rast, xcolumn - Returns the geometric X coordinate upper left of a raster, column and row. Numbering of columns and rows starts at 1.';


--
-- Name: st_rastertoworldcoordx(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer, yr integer) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT longitude FROM public._ST_rastertoworldcoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_rastertoworldcoordx(rast public.raster, xr integer, yr integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rastertoworldcoordx(rast public.raster, xr integer, yr integer) IS 'args: rast, xcolumn, yrow - Returns the geometric X coordinate upper left of a raster, column and row. Numbering of columns and rows starts at 1.';


--
-- Name: st_rastertoworldcoordy(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rastertoworldcoordy(rast public.raster, yr integer) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT latitude FROM public._ST_rastertoworldcoord($1, NULL, $2) $_$;


--
-- Name: FUNCTION st_rastertoworldcoordy(rast public.raster, yr integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rastertoworldcoordy(rast public.raster, yr integer) IS 'args: rast, yrow - Returns the geometric Y coordinate upper left corner of a raster, column and row. Numbering of columns and rows starts at 1.';


--
-- Name: st_rastertoworldcoordy(public.raster, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rastertoworldcoordy(rast public.raster, xr integer, yr integer) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT latitude FROM public._ST_rastertoworldcoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_rastertoworldcoordy(rast public.raster, xr integer, yr integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rastertoworldcoordy(rast public.raster, xr integer, yr integer) IS 'args: rast, xcolumn, yrow - Returns the geometric Y coordinate upper left corner of a raster, column and row. Numbering of columns and rows starts at 1.';


--
-- Name: st_reclass(public.raster, public.reclassarg[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_reclass(rast public.raster, VARIADIC reclassargset public.reclassarg[]) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		i int;
		expr text;
	BEGIN
		-- for each reclassarg, validate elements as all except nodataval cannot be NULL
		FOR i IN SELECT * FROM generate_subscripts($2, 1) LOOP
			IF $2[i].nband IS NULL OR $2[i].reclassexpr IS NULL OR $2[i].pixeltype IS NULL THEN
				RAISE WARNING 'Values are required for the nband, reclassexpr and pixeltype attributes.';
				RETURN rast;
			END IF;
		END LOOP;

		RETURN public._ST_reclass($1, VARIADIC $2);
	END;
	$_$;


--
-- Name: st_reclass(public.raster, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_reclass(rast public.raster, reclassexpr text, pixeltype text) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_reclass($1, ROW(1, $2, $3, NULL)) $_$;


--
-- Name: st_reclass(public.raster, integer, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_reclass(rast public.raster, nband integer, reclassexpr text, pixeltype text, nodataval double precision DEFAULT NULL::double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT st_reclass($1, ROW($2, $3, $4, $5)) $_$;


--
-- Name: st_resample(public.raster, public.raster, boolean, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resample(rast public.raster, ref public.raster, usescale boolean, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT st_resample($1, $2, $4, $5, $3) $_$;


--
-- Name: FUNCTION st_resample(rast public.raster, ref public.raster, usescale boolean, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resample(rast public.raster, ref public.raster, usescale boolean, algorithm text, maxerr double precision) IS 'args: rast, ref, usescale, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.';


--
-- Name: st_resample(public.raster, public.raster, text, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resample(rast public.raster, ref public.raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, usescale boolean DEFAULT true) RETURNS public.raster
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		rastsrid int;

		_srid int;
		_dimx int;
		_dimy int;
		_scalex double precision;
		_scaley double precision;
		_gridx double precision;
		_gridy double precision;
		_skewx double precision;
		_skewy double precision;
	BEGIN
		SELECT srid, width, height, scalex, scaley, upperleftx, upperlefty, skewx, skewy INTO _srid, _dimx, _dimy, _scalex, _scaley, _gridx, _gridy, _skewx, _skewy FROM st_metadata($2);

		rastsrid := public.ST_SRID($1);

		-- both rasters must have the same SRID
		IF (rastsrid != _srid) THEN
			RAISE EXCEPTION 'The raster to be resampled has a different SRID from the reference raster';
			RETURN NULL;
		END IF;

		IF usescale IS TRUE THEN
			_dimx := NULL;
			_dimy := NULL;
		ELSE
			_scalex := NULL;
			_scaley := NULL;
		END IF;

		RETURN public._ST_gdalwarp($1, $3, $4, NULL, _scalex, _scaley, _gridx, _gridy, _skewx, _skewy, _dimx, _dimy);
	END;
	$_$;


--
-- Name: FUNCTION st_resample(rast public.raster, ref public.raster, algorithm text, maxerr double precision, usescale boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resample(rast public.raster, ref public.raster, algorithm text, maxerr double precision, usescale boolean) IS 'args: rast, ref, algorithm=NearestNeighbour, maxerr=0.125, usescale=true - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.';


--
-- Name: st_resample(public.raster, double precision, double precision, double precision, double precision, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resample(rast public.raster, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_gdalwarp($1, $8,	$9, NULL, $2, $3, $4, $5, $6, $7) $_$;


--
-- Name: FUNCTION st_resample(rast public.raster, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resample(rast public.raster, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) IS 'args: rast, scalex=0, scaley=0, gridx=NULL, gridy=NULL, skewx=0, skewy=0, algorithm=NearestNeighbor, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.';


--
-- Name: st_resample(public.raster, integer, integer, double precision, double precision, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resample(rast public.raster, width integer, height integer, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE
    AS $_$ SELECT public._ST_gdalwarp($1, $8,	$9, NULL, NULL, NULL, $4, $5, $6, $7, $2, $3) $_$;


--
-- Name: FUNCTION st_resample(rast public.raster, width integer, height integer, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resample(rast public.raster, width integer, height integer, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) IS 'args: rast, width, height, gridx=NULL, gridy=NULL, skewx=0, skewy=0, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.';


--
-- Name: st_rescale(public.raster, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rescale(rast public.raster, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT  public._ST_GdalWarp($1, $3, $4, NULL, $2, $2) $_$;


--
-- Name: FUNCTION st_rescale(rast public.raster, scalexy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rescale(rast public.raster, scalexy double precision, algorithm text, maxerr double precision) IS 'args: rast, scalexy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its scale (or pixel size). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_rescale(public.raster, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rescale(rast public.raster, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT  public._ST_GdalWarp($1, $4, $5, NULL, $2, $3) $_$;


--
-- Name: FUNCTION st_rescale(rast public.raster, scalex double precision, scaley double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rescale(rast public.raster, scalex double precision, scaley double precision, algorithm text, maxerr double precision) IS 'args: rast, scalex, scaley, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its scale (or pixel size). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_resize(public.raster, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resize(rast public.raster, percentwidth double precision, percentheight double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		_width integer;
		_height integer;
	BEGIN
		-- range check
		IF $2 <= 0. OR $2 > 1. OR $3 <= 0. OR $3 > 1. THEN
			RAISE EXCEPTION 'Percentages must be a value greater than zero and less than or equal to one, e.g. 0.5 for 50%%';
		END IF;

		SELECT width, height INTO _width, _height FROM public.ST_Metadata($1);

		_width := round(_width::double precision * $2)::integer;
		_height:= round(_height::double precision * $3)::integer;

		IF _width < 1 THEN
			_width := 1;
		END IF;
		IF _height < 1 THEN
			_height := 1;
		END IF;

		RETURN public._ST_gdalwarp(
			$1,
			$4, $5,
			NULL,
			NULL, NULL,
			NULL, NULL,
			NULL, NULL,
			_width, _height
		);
	END;
	$_$;


--
-- Name: FUNCTION st_resize(rast public.raster, percentwidth double precision, percentheight double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resize(rast public.raster, percentwidth double precision, percentheight double precision, algorithm text, maxerr double precision) IS 'args: rast, percentwidth, percentheight, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height';


--
-- Name: st_resize(public.raster, integer, integer, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resize(rast public.raster, width integer, height integer, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $4, $5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, abs($2), abs($3)) $_$;


--
-- Name: FUNCTION st_resize(rast public.raster, width integer, height integer, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resize(rast public.raster, width integer, height integer, algorithm text, maxerr double precision) IS 'args: rast, width, height, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height';


--
-- Name: st_resize(public.raster, text, text, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_resize(rast public.raster, width text, height text, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		i integer;

		wh text[2];

		whi integer[2];
		whd double precision[2];

		_width integer;
		_height integer;
	BEGIN
		wh[1] := trim(both from $2);
		wh[2] := trim(both from $3);

		-- see if width and height are percentages
		FOR i IN 1..2 LOOP
			IF position('%' in wh[i]) > 0 THEN
				BEGIN
					wh[i] := (regexp_matches(wh[i], E'^(\\d*.?\\d*)%{1}$'))[1];
					IF length(wh[i]) < 1 THEN
						RAISE invalid_parameter_value;
					END IF;

					whd[i] := wh[i]::double precision * 0.01;
				EXCEPTION WHEN OTHERS THEN -- TODO: WHEN invalid_parameter_value !
					RAISE EXCEPTION 'Invalid percentage value provided for width/height';
					RETURN NULL;
				END;
			ELSE
				BEGIN
					whi[i] := abs(wh[i]::integer);
				EXCEPTION WHEN OTHERS THEN -- TODO: only handle appropriate SQLSTATE
					RAISE EXCEPTION 'Non-integer value provided for width/height';
					RETURN NULL;
				END;
			END IF;
		END LOOP;

		IF whd[1] IS NOT NULL OR whd[2] IS NOT NULL THEN
			SELECT foo.width, foo.height INTO _width, _height FROM public.ST_Metadata($1) AS foo;

			IF whd[1] IS NOT NULL THEN
				whi[1] := round(_width::double precision * whd[1])::integer;
			END IF;

			IF whd[2] IS NOT NULL THEN
				whi[2] := round(_height::double precision * whd[2])::integer;
			END IF;

		END IF;

		-- should NEVER be here
		IF whi[1] IS NULL OR whi[2] IS NULL THEN
			RAISE EXCEPTION 'Unable to determine appropriate width or height';
			RETURN NULL;
		END IF;

		FOR i IN 1..2 LOOP
			IF whi[i] < 1 THEN
				whi[i] = 1;
			END IF;
		END LOOP;

		RETURN public._ST_gdalwarp(
			$1,
			$4, $5,
			NULL,
			NULL, NULL,
			NULL, NULL,
			NULL, NULL,
			whi[1], whi[2]
		);
	END;
	$_$;


--
-- Name: FUNCTION st_resize(rast public.raster, width text, height text, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_resize(rast public.raster, width text, height text, algorithm text, maxerr double precision) IS 'args: rast, width, height, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height';


--
-- Name: st_reskew(public.raster, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_reskew(rast public.raster, skewxy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_GdalWarp($1, $3, $4, NULL, 0, 0, NULL, NULL, $2, $2) $_$;


--
-- Name: FUNCTION st_reskew(rast public.raster, skewxy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_reskew(rast public.raster, skewxy double precision, algorithm text, maxerr double precision) IS 'args: rast, skewxy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its skew (or rotation parameters). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_reskew(public.raster, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_reskew(rast public.raster, skewx double precision, skewy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_GdalWarp($1, $4, $5, NULL, 0, 0, NULL, NULL, $2, $3) $_$;


--
-- Name: FUNCTION st_reskew(rast public.raster, skewx double precision, skewy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_reskew(rast public.raster, skewx double precision, skewy double precision, algorithm text, maxerr double precision) IS 'args: rast, skewx, skewy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its skew (or rotation parameters). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_retile(regclass, name, public.geometry, double precision, double precision, integer, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_retile(tab regclass, col name, ext public.geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text DEFAULT 'NearestNeighbour'::text) RETURNS SETOF public.raster
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
DECLARE
  rec RECORD;
  ipx FLOAT8;
  ipy FLOAT8;
  tx int;
  ty int;
  te GEOMETRY; -- tile extent
  ncols int;
  nlins int;
  srid int;
  sql TEXT;
BEGIN

  RAISE DEBUG 'Target coverage will have sfx=%, sfy=%', sfx, sfy;

  -- 2. Loop over each target tile and build it from source tiles
  ipx := st_xmin(ext);
  ncols := ceil((st_xmax(ext)-ipx)/sfx/tw);
  IF sfy < 0 THEN
    ipy := st_ymax(ext);
    nlins := ceil((st_ymin(ext)-ipy)/sfy/th);
  ELSE
    ipy := st_ymin(ext);
    nlins := ceil((st_ymax(ext)-ipy)/sfy/th);
  END IF;

  srid := ST_Srid(ext);

  RAISE DEBUG 'Target coverage will have % x % tiles, each of approx size % x %', ncols, nlins, tw, th;
  RAISE DEBUG 'Target coverage will cover extent %', ext::box2d;

  FOR tx IN 0..ncols-1 LOOP
    FOR ty IN 0..nlins-1 LOOP
      te := ST_MakeEnvelope(ipx + tx     *  tw  * sfx,
                             ipy + ty     *  th  * sfy,
                             ipx + (tx+1) *  tw  * sfx,
                             ipy + (ty+1) *  th  * sfy,
                             srid);
      --RAISE DEBUG 'sfx/sfy: %, %', sfx, sfy;
      --RAISE DEBUG 'tile extent %', te;
      sql := 'SELECT count(*),  public.ST_Clip(  public.ST_Union(  public.ST_SnapToGrid(  public.ST_Rescale(  public.ST_Clip(' || quote_ident(col)
          || ',  public.ST_Expand($3, greatest($1,$2))),$1, $2, $6), $4, $5, $1, $2)), $3) g FROM ' || tab::text
          || ' WHERE  public.ST_Intersects(' || quote_ident(col) || ', $3)';
      --RAISE DEBUG 'SQL: %', sql;
      FOR rec IN EXECUTE sql USING sfx, sfy, te, ipx, ipy, algo LOOP
        --RAISE DEBUG '% source tiles intersect target tile %,% with extent %', rec.count, tx, ty, te::box2d;
        IF rec.g IS NULL THEN
          RAISE WARNING 'No source tiles cover target tile %,% with extent %',
            tx, ty, te::box2d;
        ELSE
          --RAISE DEBUG 'Tile for extent % has size % x %', te::box2d, st_width(rec.g), st_height(rec.g);
          RETURN NEXT rec.g;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  RETURN;
END;
$_$;


--
-- Name: FUNCTION st_retile(tab regclass, col name, ext public.geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_retile(tab regclass, col name, ext public.geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text) IS 'args: tab, col, ext, sfx, sfy, tw, th, algo=''NearestNeighbor'' - Return a set of configured tiles from an arbitrarily tiled raster coverage.';


--
-- Name: st_rotation(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_rotation(public.raster) RETURNS double precision
    LANGUAGE sql
    AS $_$ SELECT ( public.ST_Geotransform($1)).theta_i $_$;


--
-- Name: FUNCTION st_rotation(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_rotation(public.raster) IS 'args: rast - Returns the rotation of the raster in radian.';


--
-- Name: st_roughness(public.raster, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_roughness(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_roughness($1, $2, NULL::raster, $3, $4) $_$;


--
-- Name: st_roughness(public.raster, integer, public.raster, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_roughness(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_pixwidth double precision;
		_pixheight double precision;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_roughness4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1);
	END;
	$$;


--
-- Name: st_samealignment(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_samealignment(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_sameAlignment';


--
-- Name: FUNCTION st_samealignment(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_samealignment(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.';


--
-- Name: st_samealignment(double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_samealignment(st_makeemptyraster(1, 1, $1, $2, $3, $4, $5, $6), st_makeemptyraster(1, 1, $7, $8, $9, $10, $11, $12)) $_$;


--
-- Name: FUNCTION st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision) IS 'args: ulx1, uly1, scalex1, scaley1, skewx1, skewy1, ulx2, uly2, scalex2, scaley2, skewx2, skewy2 - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.';


--
-- Name: st_scalex(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_scalex(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getXScale';


--
-- Name: FUNCTION st_scalex(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_scalex(public.raster) IS 'args: rast - Returns the X component of the pixel width in units of coordinate reference system.';


--
-- Name: st_scaley(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_scaley(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getYScale';


--
-- Name: FUNCTION st_scaley(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_scaley(public.raster) IS 'args: rast - Returns the Y component of the pixel height in units of coordinate reference system.';


--
-- Name: st_setbandisnodata(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setbandisnodata(rast public.raster, band integer DEFAULT 1) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setBandIsNoData';


--
-- Name: FUNCTION st_setbandisnodata(rast public.raster, band integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setbandisnodata(rast public.raster, band integer) IS 'args: rast, band=1 - Sets the isnodata flag of the band to TRUE.';


--
-- Name: st_setbandnodatavalue(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setbandnodatavalue(rast public.raster, nodatavalue double precision) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_setbandnodatavalue($1, 1, $2, FALSE) $_$;


--
-- Name: FUNCTION st_setbandnodatavalue(rast public.raster, nodatavalue double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setbandnodatavalue(rast public.raster, nodatavalue double precision) IS 'args: rast, nodatavalue - Sets the value for the given band that represents no data. Band 1 is assumed if no band is specified. To mark a band as having no nodata value, set the nodata value = NULL.';


--
-- Name: st_setbandnodatavalue(public.raster, integer, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setbandnodatavalue(rast public.raster, band integer, nodatavalue double precision, forcechecking boolean DEFAULT false) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setBandNoDataValue';


--
-- Name: FUNCTION st_setbandnodatavalue(rast public.raster, band integer, nodatavalue double precision, forcechecking boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setbandnodatavalue(rast public.raster, band integer, nodatavalue double precision, forcechecking boolean) IS 'args: rast, band, nodatavalue, forcechecking=false - Sets the value for the given band that represents no data. Band 1 is assumed if no band is specified. To mark a band as having no nodata value, set the nodata value = NULL.';


--
-- Name: st_setgeoreference(public.raster, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setgeoreference(rast public.raster, georef text, format text DEFAULT 'GDAL'::text) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
    DECLARE
        params text[];
        rastout raster;
    BEGIN
        IF rast IS NULL THEN
            RAISE WARNING 'Cannot set georeferencing on a null raster in st_setgeoreference.';
            RETURN rastout;
        END IF;

        SELECT regexp_matches(georef,
            E'(-?\\d+(?:\\.\\d+)?)\\s(-?\\d+(?:\\.\\d+)?)\\s(-?\\d+(?:\\.\\d+)?)\\s' ||
            E'(-?\\d+(?:\\.\\d+)?)\\s(-?\\d+(?:\\.\\d+)?)\\s(-?\\d+(?:\\.\\d+)?)') INTO params;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'st_setgeoreference requires a string with 6 floating point values.';
        END IF;

        IF format = 'ESRI' THEN
            -- params array is now:
            -- {scalex, skewy, skewx, scaley, upperleftx, upperlefty}
            rastout := public.ST_setscale(rast, params[1]::float8, params[4]::float8);
            rastout := public.ST_setskew(rastout, params[3]::float8, params[2]::float8);
            rastout := public.ST_setupperleft(rastout,
                                   params[5]::float8 - (params[1]::float8 * 0.5),
                                   params[6]::float8 - (params[4]::float8 * 0.5));
        ELSE
            IF format != 'GDAL' THEN
                RAISE WARNING 'Format ''%'' is not recognized, defaulting to GDAL format.', format;
            END IF;
            -- params array is now:
            -- {scalex, skewy, skewx, scaley, upperleftx, upperlefty}

            rastout := public.ST_setscale(rast, params[1]::float8, params[4]::float8);
            rastout := public.ST_setskew( rastout, params[3]::float8, params[2]::float8);
            rastout := public.ST_setupperleft(rastout, params[5]::float8, params[6]::float8);
        END IF;
        RETURN rastout;
    END;
    $$;


--
-- Name: FUNCTION st_setgeoreference(rast public.raster, georef text, format text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setgeoreference(rast public.raster, georef text, format text) IS 'args: rast, georefcoords, format=GDAL - Set Georeference 6 georeference parameters in a single call. Numbers should be separated by white space. Accepts inputs in GDAL or ESRI format. Default is GDAL.';


--
-- Name: st_setgeoreference(public.raster, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setgeoreference(rast public.raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_setgeoreference($1, array_to_string(ARRAY[$4, $7, $6, $5, $2, $3], ' ')) $_$;


--
-- Name: FUNCTION st_setgeoreference(rast public.raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setgeoreference(rast public.raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision) IS 'args: rast, upperleftx, upperlefty, scalex, scaley, skewx, skewy - Set Georeference 6 georeference parameters in a single call. Numbers should be separated by white space. Accepts inputs in GDAL or ESRI format. Default is GDAL.';


--
-- Name: st_setgeotransform(public.raster, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setgeotransform(rast public.raster, imag double precision, jmag double precision, theta_i double precision, theta_ij double precision, xoffset double precision, yoffset double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setGeotransform';


--
-- Name: st_setrotation(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setrotation(rast public.raster, rotation double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setRotation';


--
-- Name: FUNCTION st_setrotation(rast public.raster, rotation double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setrotation(rast public.raster, rotation double precision) IS 'args: rast, rotation - Set the rotation of the raster in radian.';


--
-- Name: st_setscale(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setscale(rast public.raster, scale double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setScale';


--
-- Name: FUNCTION st_setscale(rast public.raster, scale double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setscale(rast public.raster, scale double precision) IS 'args: rast, xy - Sets the X and Y size of pixels in units of coordinate reference system. Number units/pixel width/height.';


--
-- Name: st_setscale(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setscale(rast public.raster, scalex double precision, scaley double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setScaleXY';


--
-- Name: FUNCTION st_setscale(rast public.raster, scalex double precision, scaley double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setscale(rast public.raster, scalex double precision, scaley double precision) IS 'args: rast, x, y - Sets the X and Y size of pixels in units of coordinate reference system. Number units/pixel width/height.';


--
-- Name: st_setskew(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setskew(rast public.raster, skew double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setSkew';


--
-- Name: FUNCTION st_setskew(rast public.raster, skew double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setskew(rast public.raster, skew double precision) IS 'args: rast, skewxy - Sets the georeference X and Y skew (or rotation parameter). If only one is passed in, sets X and Y to the same value.';


--
-- Name: st_setskew(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setskew(rast public.raster, skewx double precision, skewy double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setSkewXY';


--
-- Name: FUNCTION st_setskew(rast public.raster, skewx double precision, skewy double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setskew(rast public.raster, skewx double precision, skewy double precision) IS 'args: rast, skewx, skewy - Sets the georeference X and Y skew (or rotation parameter). If only one is passed in, sets X and Y to the same value.';


--
-- Name: st_setsrid(public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setsrid(rast public.raster, srid integer) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setSRID';


--
-- Name: FUNCTION st_setsrid(rast public.raster, srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setsrid(rast public.raster, srid integer) IS 'args: rast, srid - Sets the SRID of a raster to a particular integer srid defined in the spatial_ref_sys table.';


--
-- Name: st_setupperleft(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setupperleft(rast public.raster, upperleftx double precision, upperlefty double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setUpperLeftXY';


--
-- Name: FUNCTION st_setupperleft(rast public.raster, upperleftx double precision, upperlefty double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setupperleft(rast public.raster, upperleftx double precision, upperlefty double precision) IS 'args: rast, x, y - Sets the value of the upper left corner of the pixel to projected X and Y coordinates.';


--
-- Name: st_setvalue(public.raster, public.geometry, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalue(rast public.raster, geom public.geometry, newvalue double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_setvalues($1, 1, ARRAY[ROW($2, $3)]::geomval[], FALSE) $_$;


--
-- Name: FUNCTION st_setvalue(rast public.raster, geom public.geometry, newvalue double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalue(rast public.raster, geom public.geometry, newvalue double precision) IS 'args: rast, geom, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.';


--
-- Name: st_setvalue(public.raster, integer, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalue(rast public.raster, x integer, y integer, newvalue double precision) RETURNS public.raster
    LANGUAGE sql
    AS $_$ SELECT public.ST_setvalue($1, 1, $2, $3, $4) $_$;


--
-- Name: FUNCTION st_setvalue(rast public.raster, x integer, y integer, newvalue double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalue(rast public.raster, x integer, y integer, newvalue double precision) IS 'args: rast, columnx, rowy, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.';


--
-- Name: st_setvalue(public.raster, integer, public.geometry, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalue(rast public.raster, nband integer, geom public.geometry, newvalue double precision) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_setvalues($1, $2, ARRAY[ROW($3, $4)]::geomval[], FALSE) $_$;


--
-- Name: FUNCTION st_setvalue(rast public.raster, nband integer, geom public.geometry, newvalue double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalue(rast public.raster, nband integer, geom public.geometry, newvalue double precision) IS 'args: rast, bandnum, geom, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.';


--
-- Name: st_setvalue(public.raster, integer, integer, integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalue(rast public.raster, band integer, x integer, y integer, newvalue double precision) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setPixelValue';


--
-- Name: FUNCTION st_setvalue(rast public.raster, band integer, x integer, y integer, newvalue double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalue(rast public.raster, band integer, x integer, y integer, newvalue double precision) IS 'args: rast, bandnum, columnx, rowy, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.';


--
-- Name: st_setvalues(public.raster, integer, public.geomval[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalues(rast public.raster, nband integer, geomvalset public.geomval[], keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE c IMMUTABLE PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_setPixelValuesGeomval';


--
-- Name: FUNCTION st_setvalues(rast public.raster, nband integer, geomvalset public.geomval[], keepnodata boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalues(rast public.raster, nband integer, geomvalset public.geomval[], keepnodata boolean) IS 'args: rast, nband, geomvalset, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.';


--
-- Name: st_setvalues(public.raster, integer, integer, integer, double precision[], boolean[], boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[] DEFAULT NULL::boolean[], keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_setvalues($1, $2, $3, $4, $5, $6, FALSE, NULL, $7) $_$;


--
-- Name: FUNCTION st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], keepnodata boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], keepnodata boolean) IS 'args: rast, nband, columnx, rowy, newvalueset, noset=NULL, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.';


--
-- Name: st_setvalues(public.raster, integer, integer, integer, double precision[], double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_setvalues($1, $2, $3, $4, $5, NULL, TRUE, $6, $7) $_$;


--
-- Name: FUNCTION st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean) IS 'args: rast, nband, columnx, rowy, newvalueset, nosetvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.';


--
-- Name: st_setvalues(public.raster, integer, integer, integer, integer, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalues(rast public.raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	BEGIN
		IF width <= 0 OR height <= 0 THEN
			RAISE EXCEPTION 'Values for width and height must be greater than zero';
			RETURN NULL;
		END IF;
		RETURN public._ST_setvalues($1, 1, $2, $3, array_fill($6, ARRAY[$5, $4]::int[]), NULL, FALSE, NULL, $7);
	END;
	$_$;


--
-- Name: FUNCTION st_setvalues(rast public.raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalues(rast public.raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) IS 'args: rast, columnx, rowy, width, height, newvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.';


--
-- Name: st_setvalues(public.raster, integer, integer, integer, integer, integer, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $_$
	BEGIN
		IF width <= 0 OR height <= 0 THEN
			RAISE EXCEPTION 'Values for width and height must be greater than zero';
			RETURN NULL;
		END IF;
		RETURN public._ST_setvalues($1, $2, $3, $4, array_fill($7, ARRAY[$6, $5]::int[]), NULL, FALSE, NULL, $8);
	END;
	$_$;


--
-- Name: FUNCTION st_setvalues(rast public.raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_setvalues(rast public.raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) IS 'args: rast, nband, columnx, rowy, width, height, newvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.';


--
-- Name: st_skewx(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_skewx(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getXSkew';


--
-- Name: FUNCTION st_skewx(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_skewx(public.raster) IS 'args: rast - Returns the georeference X skew (or rotation parameter).';


--
-- Name: st_skewy(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_skewy(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getYSkew';


--
-- Name: FUNCTION st_skewy(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_skewy(public.raster) IS 'args: rast - Returns the georeference Y skew (or rotation parameter).';


--
-- Name: st_slope(public.raster, integer, text, text, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_slope(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_slope($1, $2, NULL::raster, $3, $4, $5, $6) $_$;


--
-- Name: st_slope(public.raster, integer, public.raster, text, text, double precision, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_slope(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_pixwidth double precision;
		_pixheight double precision;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		-- get properties
		_pixwidth := public.ST_PixelWidth(_rast);
		_pixheight := public.ST_PixelHeight(_rast);
		SELECT width, height INTO _width, _height FROM public.ST_Metadata(_rast);

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_slope4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1,
			_pixwidth::text, _pixheight::text,
			_width::text, _height::text,
			units::text, scale::text
		);
	END;
	$$;


--
-- Name: st_snaptogrid(public.raster, double precision, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $5, $6, NULL, $4, $4, $2, $3) $_$;


--
-- Name: FUNCTION st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text, maxerr double precision) IS 'args: rast, gridx, gridy, scalexy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_snaptogrid(public.raster, double precision, double precision, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $6, $7, NULL, $4, $5, $2, $3) $_$;


--
-- Name: FUNCTION st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text, maxerr double precision) IS 'args: rast, gridx, gridy, scalex, scaley, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_snaptogrid(public.raster, double precision, double precision, text, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_GdalWarp($1, $4, $5, NULL, $6, $7, $2, $3) $_$;


--
-- Name: FUNCTION st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, algorithm text, maxerr double precision, scalex double precision, scaley double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_snaptogrid(rast public.raster, gridx double precision, gridy double precision, algorithm text, maxerr double precision, scalex double precision, scaley double precision) IS 'args: rast, gridx, gridy, algorithm=NearestNeighbour, maxerr=0.125, scalex=DEFAULT 0, scaley=DEFAULT 0 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.';


--
-- Name: st_srid(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_srid(public.raster) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getSRID';


--
-- Name: FUNCTION st_srid(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_srid(public.raster) IS 'args: rast - Returns the spatial reference identifier of the raster as defined in spatial_ref_sys table.';


--
-- Name: st_stddev4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_stddev4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT stddev(unnest) FROM unnest($1) $_$;


--
-- Name: st_stddev4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_stddev4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT stddev(unnest) FROM unnest($1) $_$;


--
-- Name: st_sum4ma(double precision[], integer[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_sum4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_value double precision[][][];
		sum double precision;
		x int;
		y int;
		z int;
		ndims int;
	BEGIN
		sum := 0;

		ndims := array_ndims(value);
		-- add a third dimension if 2-dimension
		IF ndims = 2 THEN
			_value := public._ST_convertarray4ma(value);
		ELSEIF ndims != 3 THEN
			RAISE EXCEPTION 'First parameter of function must be a 3-dimension array';
		ELSE
			_value := value;
		END IF;

		-- raster
		FOR z IN array_lower(_value, 1)..array_upper(_value, 1) LOOP
			-- row
			FOR y IN array_lower(_value, 2)..array_upper(_value, 2) LOOP
				-- column
				FOR x IN array_lower(_value, 3)..array_upper(_value, 3) LOOP
					IF _value[z][y][x] IS NULL THEN
						IF array_length(userargs, 1) > 0 THEN
							_value[z][y][x] = userargs[array_lower(userargs, 1)]::double precision;
						ELSE
							CONTINUE;
						END IF;
					END IF;

					sum := sum + _value[z][y][x];
				END LOOP;
			END LOOP;
		END LOOP;

		RETURN sum;
	END;
	$$;


--
-- Name: st_sum4ma(double precision[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_sum4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
    DECLARE
        _matrix float[][];
        sum float;
    BEGIN
        _matrix := matrix;
        sum := 0;
        FOR x in array_lower(matrix, 1)..array_upper(matrix, 1) LOOP
            FOR y in array_lower(matrix, 2)..array_upper(matrix, 2) LOOP
                IF _matrix[x][y] IS NULL THEN
                    IF nodatamode = 'ignore' THEN
                        _matrix[x][y] := 0;
                    ELSE
                        _matrix[x][y] := nodatamode::float;
                    END IF;
                END IF;
                sum := sum + _matrix[x][y];
            END LOOP;
        END LOOP;
        RETURN sum;
    END;
    $$;


--
-- Name: st_summary(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_summary(rast public.raster) RETURNS text
    LANGUAGE plpgsql STABLE STRICT
    AS $$
	DECLARE
		extent box2d;
		metadata record;
		bandmetadata record;
		msg text;
		msgset text[];
	BEGIN
		extent := public.ST_Extent(rast::geometry);
		metadata := public.ST_Metadata(rast);

		msg := 'Raster of ' || metadata.width || 'x' || metadata.height || ' pixels has ' || metadata.numbands || ' ';

		IF metadata.numbands = 1 THEN
			msg := msg || 'band ';
		ELSE
			msg := msg || 'bands ';
		END IF;
		msg := msg || 'and extent of ' || extent;

		IF
			round(metadata.skewx::numeric, 10) <> round(0::numeric, 10) OR 
			round(metadata.skewy::numeric, 10) <> round(0::numeric, 10)
		THEN
			msg := 'Skewed ' || overlay(msg placing 'r' from 1 for 1);
		END IF;

		msgset := Array[]::text[] || msg;

		FOR bandmetadata IN SELECT * FROM public.ST_BandMetadata(rast, ARRAY[]::int[]) LOOP
			msg := 'band ' || bandmetadata.bandnum || ' of pixtype ' || bandmetadata.pixeltype || ' is ';
			IF bandmetadata.isoutdb IS FALSE THEN
				msg := msg || 'in-db ';
			ELSE
				msg := msg || 'out-db ';
			END IF;

			msg := msg || 'with ';
			IF bandmetadata.nodatavalue IS NOT NULL THEN
				msg := msg || 'NODATA value of ' || bandmetadata.nodatavalue;
			ELSE
				msg := msg || 'no NODATA value';
			END IF;

			msgset := msgset || ('    ' || msg);
		END LOOP;

		RETURN array_to_string(msgset, E'\n');
	END;
	$$;


--
-- Name: FUNCTION st_summary(rast public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_summary(rast public.raster) IS 'args: rast - Returns a text summary of the contents of the raster.';


--
-- Name: st_summarystats(public.raster, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_summarystats(rast public.raster, exclude_nodata_value boolean) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, 1, $2, 1) $_$;


--
-- Name: FUNCTION st_summarystats(rast public.raster, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_summarystats(rast public.raster, exclude_nodata_value boolean) IS 'args: rast, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.';


--
-- Name: st_summarystats(text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_summarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, 1, $3, 1) $_$;


--
-- Name: FUNCTION st_summarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_summarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean) IS 'args: rastertable, rastercolumn, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.';


--
-- Name: st_summarystats(public.raster, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_summarystats(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true) RETURNS public.summarystats
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public._ST_summarystats($1, $2, $3, 1) $_$;


--
-- Name: FUNCTION st_summarystats(rast public.raster, nband integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_summarystats(rast public.raster, nband integer, exclude_nodata_value boolean) IS 'args: rast, nband, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.';


--
-- Name: st_summarystats(text, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_summarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true) RETURNS public.summarystats
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_summarystats($1, $2, $3, $4, 1) $_$;


--
-- Name: FUNCTION st_summarystats(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_summarystats(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.';


--
-- Name: st_tile(public.raster, integer, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tile(rast public.raster, width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision) RETURNS SETOF public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_tile($1, $2, $3, NULL::integer[], $4, $5) $_$;


--
-- Name: FUNCTION st_tile(rast public.raster, width integer, height integer, padwithnodata boolean, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_tile(rast public.raster, width integer, height integer, padwithnodata boolean, nodataval double precision) IS 'args: rast, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.';


--
-- Name: st_tile(public.raster, integer[], integer, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tile(rast public.raster, nband integer[], width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision) RETURNS SETOF public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_tile($1, $3, $4, $2, $5, $6) $_$;


--
-- Name: FUNCTION st_tile(rast public.raster, nband integer[], width integer, height integer, padwithnodata boolean, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_tile(rast public.raster, nband integer[], width integer, height integer, padwithnodata boolean, nodataval double precision) IS 'args: rast, nband, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.';


--
-- Name: st_tile(public.raster, integer, integer, integer, boolean, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tile(rast public.raster, nband integer, width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision) RETURNS SETOF public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public._ST_tile($1, $3, $4, ARRAY[$2]::integer[], $5, $6) $_$;


--
-- Name: FUNCTION st_tile(rast public.raster, nband integer, width integer, height integer, padwithnodata boolean, nodataval double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_tile(rast public.raster, nband integer, width integer, height integer, padwithnodata boolean, nodataval double precision) IS 'args: rast, nband, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.';


--
-- Name: st_touches(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_touches(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_touches($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_touches(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_touches(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if raster rastA and rastB have at least one point in common but their interiors do not intersect.';


--
-- Name: st_touches(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_touches(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_touches($1, $2, $3, $4) END $_$;


--
-- Name: FUNCTION st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_touches(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA and rastB have at least one point in common but their interiors do not intersect.';


--
-- Name: st_tpi(public.raster, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tpi(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_tpi($1, $2, NULL::raster, $3, $4) $_$;


--
-- Name: st_tpi(public.raster, integer, public.raster, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tpi(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_pixwidth double precision;
		_pixheight double precision;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		-- get properties
		_pixwidth := public.ST_PixelWidth(_rast);
		_pixheight := public.ST_PixelHeight(_rast);
		SELECT width, height INTO _width, _height FROM public.ST_Metadata(_rast);

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_tpi4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1);
	END;
	$$;


--
-- Name: st_transform(public.raster, public.raster, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_transform(rast public.raster, alignto public.raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE plpgsql STABLE STRICT
    AS $_$
	DECLARE
		_srid integer;
		_scalex double precision;
		_scaley double precision;
		_gridx double precision;
		_gridy double precision;
		_skewx double precision;
		_skewy double precision;
	BEGIN
		SELECT srid, scalex, scaley, upperleftx, upperlefty, skewx, skewy INTO _srid, _scalex, _scaley, _gridx, _gridy, _skewx, _skewy FROM st_metadata($2);

		RETURN public._ST_gdalwarp($1, $3, $4, _srid, _scalex, _scaley, _gridx, _gridy, _skewx, _skewy, NULL, NULL);
	END;
	$_$;


--
-- Name: FUNCTION st_transform(rast public.raster, alignto public.raster, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_transform(rast public.raster, alignto public.raster, algorithm text, maxerr double precision) IS 'args: rast, alignto, algorithm=NearestNeighbor, maxerr=0.125 - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.';


--
-- Name: st_transform(public.raster, integer, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_transform(rast public.raster, srid integer, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $4, $5, $2, $3, $3) $_$;


--
-- Name: st_transform(public.raster, integer, double precision, double precision, text, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_transform(rast public.raster, srid integer, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $5, $6, $2, $3, $4) $_$;


--
-- Name: FUNCTION st_transform(rast public.raster, srid integer, scalex double precision, scaley double precision, algorithm text, maxerr double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_transform(rast public.raster, srid integer, scalex double precision, scaley double precision, algorithm text, maxerr double precision) IS 'args: rast, srid, scalex, scaley, algorithm=NearestNeighbor, maxerr=0.125 - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.';


--
-- Name: st_transform(public.raster, integer, text, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_transform(rast public.raster, srid integer, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0) RETURNS public.raster
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT public._ST_gdalwarp($1, $3, $4, $2, $5, $6) $_$;


--
-- Name: FUNCTION st_transform(rast public.raster, srid integer, algorithm text, maxerr double precision, scalex double precision, scaley double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_transform(rast public.raster, srid integer, algorithm text, maxerr double precision, scalex double precision, scaley double precision) IS 'args: rast, srid, algorithm=NearestNeighbor, maxerr=0.125, scalex, scaley - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.';


--
-- Name: st_tri(public.raster, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tri(rast public.raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT public.ST_tri($1, $2, NULL::raster, $3, $4) $_$;


--
-- Name: st_tri(public.raster, integer, public.raster, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_tri(rast public.raster, nband integer, customextent public.raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false) RETURNS public.raster
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    AS $$
	DECLARE
		_rast raster;
		_nband integer;
		_pixtype text;
		_pixwidth double precision;
		_pixheight double precision;
		_width integer;
		_height integer;
		_customextent raster;
		_extenttype text;
	BEGIN
		_customextent := customextent;
		IF _customextent IS NULL THEN
			_extenttype := 'FIRST';
		ELSE
			_extenttype := 'CUSTOM';
		END IF;

		IF interpolate_nodata IS TRUE THEN
			_rast := public.ST_MapAlgebra(
				ARRAY[ROW(rast, nband)]::rastbandarg[],
				'st_invdistweight4ma(double precision[][][], integer[][], text[])'::regprocedure,
				pixeltype,
				'FIRST', NULL,
				1, 1
			);
			_nband := 1;
			_pixtype := NULL;
		ELSE
			_rast := rast;
			_nband := nband;
			_pixtype := pixeltype;
		END IF;

		-- get properties
		_pixwidth := public.ST_PixelWidth(_rast);
		_pixheight := public.ST_PixelHeight(_rast);
		SELECT width, height INTO _width, _height FROM public.ST_Metadata(_rast);

		RETURN public.ST_MapAlgebra(
			ARRAY[ROW(_rast, _nband)]::rastbandarg[],
			' public._ST_tri4ma(double precision[][][], integer[][], text[])'::regprocedure,
			_pixtype,
			_extenttype, _customextent,
			1, 1);
	END;
	$$;


--
-- Name: st_upperleftx(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_upperleftx(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getXUpperLeft';


--
-- Name: FUNCTION st_upperleftx(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_upperleftx(public.raster) IS 'args: rast - Returns the upper left X coordinate of raster in projected spatial ref.';


--
-- Name: st_upperlefty(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_upperlefty(public.raster) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getYUpperLeft';


--
-- Name: FUNCTION st_upperlefty(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_upperlefty(public.raster) IS 'args: rast - Returns the upper left Y coordinate of raster in projected spatial ref.';


--
-- Name: st_value(public.raster, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_value(rast public.raster, pt public.geometry, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.ST_value($1, 1, $2, $3) $_$;


--
-- Name: FUNCTION st_value(rast public.raster, pt public.geometry, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_value(rast public.raster, pt public.geometry, exclude_nodata_value boolean) IS 'args: rast, pt, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.';


--
-- Name: st_value(public.raster, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_value(rast public.raster, x integer, y integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT st_value($1, 1, $2, $3, $4) $_$;


--
-- Name: FUNCTION st_value(rast public.raster, x integer, y integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_value(rast public.raster, x integer, y integer, exclude_nodata_value boolean) IS 'args: rast, x, y, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.';


--
-- Name: st_value(public.raster, integer, public.geometry, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_value(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $$
    DECLARE
        x float8;
        y float8;
        gtype text;
    BEGIN
        gtype := public.ST_geometrytype(pt);
        IF ( gtype != 'ST_Point' ) THEN
            RAISE EXCEPTION 'Attempting to get the value of a pixel with a non-point geometry';
        END IF;

				IF public.ST_SRID(pt) != public.ST_SRID(rast) THEN
            RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
				END IF;

        x := public.ST_x(pt);
        y := public.ST_y(pt);
        RETURN public.ST_value(rast,
                        band,
                        public.ST_worldtorastercoordx(rast, x, y),
                        public.ST_worldtorastercoordy(rast, x, y),
                        exclude_nodata_value);
    END;
    $$;


--
-- Name: FUNCTION st_value(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_value(rast public.raster, band integer, pt public.geometry, exclude_nodata_value boolean) IS 'args: rast, band, pt, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.';


--
-- Name: st_value(public.raster, integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_value(rast public.raster, band integer, x integer, y integer, exclude_nodata_value boolean DEFAULT true) RETURNS double precision
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getPixelValue';


--
-- Name: FUNCTION st_value(rast public.raster, band integer, x integer, y integer, exclude_nodata_value boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_value(rast public.raster, band integer, x integer, y integer, exclude_nodata_value boolean) IS 'args: rast, band, x, y, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.';


--
-- Name: st_valuecount(public.raster, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, 1, TRUE, $2, $3) $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rast, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, 1, TRUE, ARRAY[$2]::double precision[], $3)).count $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, searchvalue double precision, roundto double precision) IS 'args: rast, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, $2, 1, TRUE, $3, $4) $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rastertable, rastercolumn, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, 1, TRUE, ARRAY[$3]::double precision[], $4)).count $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision) IS 'args: rastertable, rastercolumn, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(public.raster, integer, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, $2, TRUE, $3, $4) $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rast, nband, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(public.raster, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, nband integer, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, $2, TRUE, ARRAY[$3]::double precision[], $4)).count $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, nband integer, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, nband integer, searchvalue double precision, roundto double precision) IS 'args: rast, nband, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, integer, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, TRUE, $4, $5) $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rastertable, rastercolumn, nband, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, TRUE, ARRAY[$4]::double precision[], $5)).count $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision) IS 'args: rastertable, rastercolumn, nband, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(public.raster, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, $4, $5) $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rast, nband=1, exclude_nodata_value=true, searchvalues=NULL, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(public.raster, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, ARRAY[$4]::double precision[], $5)).count $_$;


--
-- Name: FUNCTION st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) IS 'args: rast, nband, exclude_nodata_value, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, $4, $5, $6) $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, searchvalues=NULL, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuecount(text, text, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS integer
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, $4, ARRAY[$5]::double precision[], $6)).count $_$;


--
-- Name: FUNCTION st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) IS 'args: rastertable, rastercolumn, nband, exclude_nodata_value, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.';


--
-- Name: st_valuepercent(public.raster, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, 1, TRUE, $2, $3) $_$;


--
-- Name: st_valuepercent(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, 1, TRUE, ARRAY[$2]::double precision[], $3)).percent $_$;


--
-- Name: st_valuepercent(text, text, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, $2, 1, TRUE, $3, $4) $_$;


--
-- Name: st_valuepercent(text, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, 1, TRUE, ARRAY[$3]::double precision[], $4)).percent $_$;


--
-- Name: st_valuepercent(public.raster, integer, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, $2, TRUE, $3, $4) $_$;


--
-- Name: st_valuepercent(public.raster, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, nband integer, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, $2, TRUE, ARRAY[$3]::double precision[], $4)).percent $_$;


--
-- Name: st_valuepercent(text, text, integer, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, TRUE, $4, $5) $_$;


--
-- Name: st_valuepercent(text, text, integer, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, TRUE, ARRAY[$4]::double precision[], $5)).percent $_$;


--
-- Name: st_valuepercent(public.raster, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, $4, $5) $_$;


--
-- Name: st_valuepercent(public.raster, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rast public.raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, ARRAY[$4]::double precision[], $5)).percent $_$;


--
-- Name: st_valuepercent(text, text, integer, boolean, double precision[], double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision) RETURNS SETOF record
    LANGUAGE sql STABLE
    AS $_$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, $4, $5, $6) $_$;


--
-- Name: st_valuepercent(text, text, integer, boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0) RETURNS double precision
    LANGUAGE sql STABLE STRICT
    AS $_$ SELECT ( public._ST_valuecount($1, $2, $3, $4, ARRAY[$5]::double precision[], $6)).percent $_$;


--
-- Name: st_width(public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_width(public.raster) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT PARALLEL SAFE
    AS '$libdir/rtpostgis-2.3', 'RASTER_getWidth';


--
-- Name: FUNCTION st_width(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_width(public.raster) IS 'args: rast - Returns the width of the raster in pixels.';


--
-- Name: st_within(public.raster, public.raster); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_within(rast1 public.raster, rast2 public.raster) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT public.st_within($1, NULL::integer, $2, NULL::integer) $_$;


--
-- Name: FUNCTION st_within(rast1 public.raster, rast2 public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_within(rast1 public.raster, rast2 public.raster) IS 'args: rastA, rastB - Return true if no points of raster rastA lie in the exterior of raster rastB and at least one point of the interior of rastA lies in the interior of rastB.';


--
-- Name: st_within(public.raster, integer, public.raster, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE COST 1000 PARALLEL SAFE
    AS $_$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_within(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_contains($3, $4, $1, $2) END $_$;


--
-- Name: FUNCTION st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_within(rast1 public.raster, nband1 integer, rast2 public.raster, nband2 integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastA lie in the exterior of raster rastB and at least one point of the interior of rastA lies in the interior of rastB.';


--
-- Name: st_worldtorastercoord(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoord(rast public.raster, pt public.geometry, OUT columnx integer, OUT rowy integer) RETURNS record
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		rx integer;
		ry integer;
	BEGIN
		IF public.ST_geometrytype(pt) != 'ST_Point' THEN
			RAISE EXCEPTION 'Attempting to compute raster coordinate with a non-point geometry';
		END IF;
		IF public.ST_SRID(rast) != public.ST_SRID(pt) THEN
			RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
		END IF;

		SELECT rc.columnx AS x, rc.rowy AS y INTO columnx, rowy FROM public._ST_worldtorastercoord($1, public.ST_x(pt), public.ST_y(pt)) AS rc;
		RETURN;
	END;
	$_$;


--
-- Name: FUNCTION st_worldtorastercoord(rast public.raster, pt public.geometry, OUT columnx integer, OUT rowy integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoord(rast public.raster, pt public.geometry, OUT columnx integer, OUT rowy integer) IS 'args: rast, pt - Returns the upper left corner as column and row given geometric X and Y (longitude and latitude) or a point geometry expressed in the spatial reference coordinate system of the raster.';


--
-- Name: st_worldtorastercoord(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoord(rast public.raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) RETURNS record
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT columnx, rowy FROM public._ST_worldtorastercoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_worldtorastercoord(rast public.raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoord(rast public.raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) IS 'args: rast, longitude, latitude - Returns the upper left corner as column and row given geometric X and Y (longitude and latitude) or a point geometry expressed in the spatial reference coordinate system of the raster.';


--
-- Name: st_worldtorastercoordx(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT columnx FROM public._ST_worldtorastercoord($1, $2, NULL) $_$;


--
-- Name: FUNCTION st_worldtorastercoordx(rast public.raster, xw double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision) IS 'args: rast, xw - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: st_worldtorastercoordx(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordx(rast public.raster, pt public.geometry) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		xr integer;
	BEGIN
		IF ( public.ST_geometrytype(pt) != 'ST_Point' ) THEN
			RAISE EXCEPTION 'Attempting to compute raster coordinate with a non-point geometry';
		END IF;
		IF public.ST_SRID(rast) != public.ST_SRID(pt) THEN
			RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
		END IF;
		SELECT columnx INTO xr FROM public._ST_worldtorastercoord($1, public.ST_x(pt), public.ST_y(pt));
		RETURN xr;
	END;
	$_$;


--
-- Name: FUNCTION st_worldtorastercoordx(rast public.raster, pt public.geometry); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordx(rast public.raster, pt public.geometry) IS 'args: rast, pt - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: st_worldtorastercoordx(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision, yw double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT columnx FROM public._ST_worldtorastercoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_worldtorastercoordx(rast public.raster, xw double precision, yw double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordx(rast public.raster, xw double precision, yw double precision) IS 'args: rast, xw, yw - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: st_worldtorastercoordy(public.raster, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordy(rast public.raster, yw double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT rowy FROM public._ST_worldtorastercoord($1, NULL, $2) $_$;


--
-- Name: FUNCTION st_worldtorastercoordy(rast public.raster, yw double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordy(rast public.raster, yw double precision) IS 'args: rast, xw - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: st_worldtorastercoordy(public.raster, public.geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordy(rast public.raster, pt public.geometry) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$
	DECLARE
		yr integer;
	BEGIN
		IF ( st_geometrytype(pt) != 'ST_Point' ) THEN
			RAISE EXCEPTION 'Attempting to compute raster coordinate with a non-point geometry';
		END IF;
		IF ST_SRID(rast) != ST_SRID(pt) THEN
			RAISE EXCEPTION 'Raster and geometry do not have the same SRID';
		END IF;
		SELECT rowy INTO yr FROM public._ST_worldtorastercoord($1, st_x(pt), st_y(pt));
		RETURN yr;
	END;
	$_$;


--
-- Name: FUNCTION st_worldtorastercoordy(rast public.raster, pt public.geometry); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordy(rast public.raster, pt public.geometry) IS 'args: rast, pt - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: st_worldtorastercoordy(public.raster, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_worldtorastercoordy(rast public.raster, xw double precision, yw double precision) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT rowy FROM public._ST_worldtorastercoord($1, $2, $3) $_$;


--
-- Name: FUNCTION st_worldtorastercoordy(rast public.raster, xw double precision, yw double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.st_worldtorastercoordy(rast public.raster, xw double precision, yw double precision) IS 'args: rast, xw, yw - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.';


--
-- Name: updaterastersrid(name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.updaterastersrid(table_name name, column_name name, new_srid integer) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._UpdateRasterSRID('', $1, $2, $3) $_$;


--
-- Name: FUNCTION updaterastersrid(table_name name, column_name name, new_srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.updaterastersrid(table_name name, column_name name, new_srid integer) IS 'args: table_name, column_name, new_srid - Change the SRID of all rasters in the user-specified column and table.';


--
-- Name: updaterastersrid(name, name, name, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) RETURNS boolean
    LANGUAGE sql STRICT
    AS $_$ SELECT  public._UpdateRasterSRID($1, $2, $3, $4) $_$;


--
-- Name: FUNCTION updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) IS 'args: schema_name, table_name, column_name, new_srid - Change the SRID of all rasters in the user-specified column and table.';


--
-- Name: wavg_finalfunc(point); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.wavg_finalfunc(agg_state point) RETURNS double precision
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
begin
    IF COALESCE(agg_state[1], 0) = 0 THEN
        RETURN 0;
    ELSE
        return agg_state[0] / agg_state[1];
    END IF;
end;
$$;


--
-- Name: wavg_sfunc(point, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.wavg_sfunc(agg_state point, value double precision, weight double precision) RETURNS point
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
    value_sum double precision;
    area_sum double precision;
BEGIN
	IF value IS NULL OR weight IS NULL THEN
		RETURN point(agg_state[0], agg_state[1]);
	END IF;
    
	value_sum = agg_state[0] + value*weight;
    area_sum = agg_state[1] + weight;

    return point(value_sum, area_sum);
end;
$$;


--
-- Name: st_countagg(public.raster, boolean); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_countagg(public.raster, boolean) (
    SFUNC = public._st_countagg_transfn,
    STYPE = public.agg_count,
    FINALFUNC = public._st_countagg_finalfn
);


--
-- Name: AGGREGATE st_countagg(public.raster, boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_countagg(public.raster, boolean) IS 'args: rast, exclude_nodata_value - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.';


--
-- Name: st_countagg(public.raster, integer, boolean); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_countagg(public.raster, integer, boolean) (
    SFUNC = public._st_countagg_transfn,
    STYPE = public.agg_count,
    FINALFUNC = public._st_countagg_finalfn
);


--
-- Name: AGGREGATE st_countagg(public.raster, integer, boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_countagg(public.raster, integer, boolean) IS 'args: rast, nband, exclude_nodata_value - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.';


--
-- Name: st_countagg(public.raster, integer, boolean, double precision); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_countagg(public.raster, integer, boolean, double precision) (
    SFUNC = public._st_countagg_transfn,
    STYPE = public.agg_count,
    FINALFUNC = public._st_countagg_finalfn
);


--
-- Name: AGGREGATE st_countagg(public.raster, integer, boolean, double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_countagg(public.raster, integer, boolean, double precision) IS 'args: rast, nband, exclude_nodata_value, sample_percent - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.';


--
-- Name: st_samealignment(public.raster); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_samealignment(public.raster) (
    SFUNC = public._st_samealignment_transfn,
    STYPE = public.agg_samealignment,
    FINALFUNC = public._st_samealignment_finalfn
);


--
-- Name: AGGREGATE st_samealignment(public.raster); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_samealignment(public.raster) IS 'args: rastfield - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.';


--
-- Name: st_summarystatsagg(public.raster, boolean, double precision); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_summarystatsagg(public.raster, boolean, double precision) (
    SFUNC = public._st_summarystats_transfn,
    STYPE = internal,
    FINALFUNC = public._st_summarystats_finalfn
);


--
-- Name: AGGREGATE st_summarystatsagg(public.raster, boolean, double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_summarystatsagg(public.raster, boolean, double precision) IS 'args: rast, exclude_nodata_value, sample_percent - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.';


--
-- Name: st_summarystatsagg(public.raster, integer, boolean); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_summarystatsagg(public.raster, integer, boolean) (
    SFUNC = public._st_summarystats_transfn,
    STYPE = internal,
    FINALFUNC = public._st_summarystats_finalfn
);


--
-- Name: AGGREGATE st_summarystatsagg(public.raster, integer, boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_summarystatsagg(public.raster, integer, boolean) IS 'args: rast, nband, exclude_nodata_value - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.';


--
-- Name: st_summarystatsagg(public.raster, integer, boolean, double precision); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_summarystatsagg(public.raster, integer, boolean, double precision) (
    SFUNC = public._st_summarystats_transfn,
    STYPE = internal,
    FINALFUNC = public._st_summarystats_finalfn
);


--
-- Name: AGGREGATE st_summarystatsagg(public.raster, integer, boolean, double precision); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON AGGREGATE public.st_summarystatsagg(public.raster, integer, boolean, double precision) IS 'args: rast, nband, exclude_nodata_value, sample_percent - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.';


--
-- Name: st_union(public.raster); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_union(public.raster) (
    SFUNC = public._st_union_transfn,
    STYPE = internal,
    FINALFUNC = public._st_union_finalfn
);


--
-- Name: st_union(public.raster, integer); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_union(public.raster, integer) (
    SFUNC = public._st_union_transfn,
    STYPE = internal,
    FINALFUNC = public._st_union_finalfn
);


--
-- Name: st_union(public.raster, text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_union(public.raster, text) (
    SFUNC = public._st_union_transfn,
    STYPE = internal,
    FINALFUNC = public._st_union_finalfn
);


--
-- Name: st_union(public.raster, public.unionarg[]); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_union(public.raster, public.unionarg[]) (
    SFUNC = public._st_union_transfn,
    STYPE = internal,
    FINALFUNC = public._st_union_finalfn
);


--
-- Name: st_union(public.raster, integer, text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.st_union(public.raster, integer, text) (
    SFUNC = public._st_union_transfn,
    STYPE = internal,
    FINALFUNC = public._st_union_finalfn
);


--
-- Name: weighted_avg(double precision, double precision); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.weighted_avg(double precision, double precision) (
    SFUNC = public.wavg_sfunc,
    STYPE = point,
    INITCOND = '(0,0)',
    FINALFUNC = public.wavg_finalfunc
);


--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&& (
    PROCEDURE = public.raster_overlap,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.&&),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&& (
    PROCEDURE = public.geometry_raster_overlap,
    LEFTARG = public.geometry,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.&&),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: &&; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&& (
    PROCEDURE = public.raster_geometry_overlap,
    LEFTARG = public.raster,
    RIGHTARG = public.geometry,
    COMMUTATOR = OPERATOR(public.&&),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: &<; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&< (
    PROCEDURE = public.raster_overleft,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.&>),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: &<|; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&<| (
    PROCEDURE = public.raster_overbelow,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.|&>),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: &>; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.&> (
    PROCEDURE = public.raster_overright,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.&<),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: <<; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.<< (
    PROCEDURE = public.raster_left,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.>>),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: <<|; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.<<| (
    PROCEDURE = public.raster_below,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.|>>),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: =; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.= (
    PROCEDURE = public.raster_eq,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.=),
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


--
-- Name: >>; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.>> (
    PROCEDURE = public.raster_right,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.<<),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: @; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.@ (
    PROCEDURE = public.raster_contained,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.~),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: @; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.@ (
    PROCEDURE = public.raster_contained_by_geometry,
    LEFTARG = public.raster,
    RIGHTARG = public.geometry,
    COMMUTATOR = OPERATOR(public.~),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: @; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.@ (
    PROCEDURE = public.geometry_contained_by_raster,
    LEFTARG = public.geometry,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.~),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: |&>; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.|&> (
    PROCEDURE = public.raster_overabove,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.&<|),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: |>>; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.|>> (
    PROCEDURE = public.raster_above,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.<<|),
    RESTRICT = positionsel,
    JOIN = positionjoinsel
);


--
-- Name: ~; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.~ (
    PROCEDURE = public.raster_contain,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.@),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: ~; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.~ (
    PROCEDURE = public.raster_geometry_contain,
    LEFTARG = public.raster,
    RIGHTARG = public.geometry,
    COMMUTATOR = OPERATOR(public.@),
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: ~; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.~ (
    PROCEDURE = public.geometry_raster_contain,
    LEFTARG = public.geometry,
    RIGHTARG = public.raster,
    RESTRICT = contsel,
    JOIN = contjoinsel
);


--
-- Name: ~=; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR public.~= (
    PROCEDURE = public.raster_same,
    LEFTARG = public.raster,
    RIGHTARG = public.raster,
    COMMUTATOR = OPERATOR(public.~=),
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);


--
-- Name: hash_raster_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY public.hash_raster_ops USING hash;


--
-- Name: hash_raster_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS public.hash_raster_ops
    DEFAULT FOR TYPE public.raster USING hash FAMILY public.hash_raster_ops AS
    OPERATOR 1 public.=(public.raster,public.raster) ,
    FUNCTION 1 (public.raster, public.raster) public.raster_hash(public.raster);


--
-- Name: CAST (public.raster AS public.box3d); Type: CAST; Schema: -; Owner: -
--

CREATE CAST (public.raster AS public.box3d) WITH FUNCTION public.box3d(public.raster) AS ASSIGNMENT;


--
-- Name: CAST (public.raster AS bytea); Type: CAST; Schema: -; Owner: -
--

CREATE CAST (public.raster AS bytea) WITH FUNCTION public.bytea(public.raster) AS ASSIGNMENT;


--
-- Name: CAST (public.raster AS public.geometry); Type: CAST; Schema: -; Owner: -
--

CREATE CAST (public.raster AS public.geometry) WITH FUNCTION public.st_convexhull(public.raster) AS ASSIGNMENT;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: process_query_function_logs; Type: TABLE; Schema: log; Owner: -
--

CREATE TABLE log.process_query_function_logs (
    id integer NOT NULL,
    ts timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_query_function_id integer NOT NULL,
    log_type character varying(25),
    description text,
    file text,
    line integer,
    callstack text
);


--
-- Name: process_query_function_logs_id_seq; Type: SEQUENCE; Schema: log; Owner: -
--

CREATE SEQUENCE log.process_query_function_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_query_function_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: log; Owner: -
--

ALTER SEQUENCE log.process_query_function_logs_id_seq OWNED BY log.process_query_function_logs.id;


--
-- Name: trigger_logs; Type: TABLE; Schema: log; Owner: -
--

CREATE TABLE log.trigger_logs (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT '2018-07-11 19:52:17.33823'::timestamp without time zone NOT NULL,
    activity text,
    tg_name text,
    new_data text,
    old_data text
);


--
-- Name: trigger_logs_id_seq; Type: SEQUENCE; Schema: log; Owner: -
--

CREATE SEQUENCE log.trigger_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trigger_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: log; Owner: -
--

ALTER SEQUENCE log.trigger_logs_id_seq OWNED BY log.trigger_logs.id;


--
-- Name: business_objects_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_objects_translations (
    id integer NOT NULL,
    current_name character varying(100) NOT NULL,
    spanish_translation character varying(100) DEFAULT ''::character varying,
    english_translation character varying(100) DEFAULT ''::character varying,
    ts timestamp without time zone DEFAULT now()
);


--
-- Name: business_objects_translations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.business_objects_translations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: business_objects_translations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.business_objects_translations_id_seq OWNED BY public.business_objects_translations.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    organization_id integer NOT NULL,
    description text
);


--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: concretes_by_declareds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.concretes_by_declareds (
    id integer NOT NULL,
    declared_id integer NOT NULL,
    concrete_id integer NOT NULL
);


--
-- Name: concretes_by_declareds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.concretes_by_declareds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: concretes_by_declareds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.concretes_by_declareds_id_seq OWNED BY public.concretes_by_declareds.id;


--
-- Name: data_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    unity character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    duration integer
);


--
-- Name: data_types_by_pixels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_types_by_pixels (
    id integer NOT NULL,
    data_type_id integer NOT NULL,
    pixel_id integer NOT NULL,
    value double precision NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    date date
);


--
-- Name: data_types_by_pixels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_types_by_pixels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_types_by_pixels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_types_by_pixels_id_seq OWNED BY public.data_types_by_pixels.id;


--
-- Name: data_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_types_id_seq OWNED BY public.data_types.id;


--
-- Name: date_by_process_f2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.date_by_process_f2 (
    id integer NOT NULL,
    date date NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_f2_id integer DEFAULT '-1'::integer NOT NULL
);


--
-- Name: date_by_process_f2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.date_by_process_f2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: date_by_process_f2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.date_by_process_f2_id_seq OWNED BY public.date_by_process_f2.id;


--
-- Name: db_actions_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_actions_logs (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    event character varying(30) NOT NULL,
    user_id integer,
    description text,
    object_class character varying(50) NOT NULL,
    object_id character varying(30) NOT NULL,
    object character varying
);


--
-- Name: db_actions_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.db_actions_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: db_actions_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.db_actions_logs_id_seq OWNED BY public.db_actions_logs.id;


--
-- Name: declarations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.declarations (
    id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    date date,
    use_declared_id integer,
    field_id integer NOT NULL
);


--
-- Name: declarations_concrete; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.declarations_concrete (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    date_from timestamp without time zone,
    date_to timestamp without time zone,
    use_concrete_id integer,
    declaration_id integer NOT NULL
);


--
-- Name: declarations_concrete_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.declarations_concrete_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: declarations_concrete_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.declarations_concrete_id_seq OWNED BY public.declarations_concrete.id;


--
-- Name: declarations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.declarations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: declarations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.declarations_id_seq OWNED BY public.declarations.id;


--
-- Name: farms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.farms (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    version_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    code character varying(150) NOT NULL
);


--
-- Name: farms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.farms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: farms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.farms_id_seq OWNED BY public.farms.id;


--
-- Name: fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fields (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    date_from date,
    date_to date,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    farm_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    the_geom public.geometry,
    code character varying(50) NOT NULL,
    group_name character varying(150)
);


--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fields_id_seq OWNED BY public.fields.id;


--
-- Name: format_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.format_types (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    name character varying(50)
);


--
-- Name: format_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.format_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: format_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.format_types_id_seq OWNED BY public.format_types.id;


--
-- Name: functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.functions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    path text NOT NULL,
    description character varying(200),
    fx_saved_name character varying(200),
    column_name character varying
);


--
-- Name: functions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.functions_id_seq OWNED BY public.functions.id;


--
-- Name: groups_by_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups_by_options (
    id integer NOT NULL,
    user_group_id integer NOT NULL,
    menu_option_id integer NOT NULL
);


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_by_options_id_seq
    START WITH 51
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_by_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_by_options_id_seq OWNED BY public.groups_by_options.id;


--
-- Name: imagen_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imagen_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    pixel_size integer
);


--
-- Name: imagen_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imagen_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imagen_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imagen_types_id_seq OWNED BY public.imagen_types.id;


--
-- Name: import_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_data (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    path character varying(100) NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    result character varying(100),
    model_name character varying(35),
    original_name character varying(200),
    comments text,
    client_id integer NOT NULL,
    project_id integer NOT NULL,
    version_id integer NOT NULL
);


--
-- Name: import_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.import_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.import_data_id_seq OWNED BY public.import_data.id;


--
-- Name: layer_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layer_types (
    id integer NOT NULL,
    name character varying(250) NOT NULL,
    image_type_id integer NOT NULL,
    parameter_type_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: layer_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layer_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layer_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layer_types_id_seq OWNED BY public.layer_types.id;


--
-- Name: layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.layers (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    imagen_type_id integer NOT NULL,
    data_type_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: layers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.layers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: layers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.layers_id_seq OWNED BY public.layers.id;


--
-- Name: log_import_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_import_fields (
    id integer NOT NULL,
    description text,
    process_id integer,
    ts timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: log_import_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_import_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_import_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_import_fields_id_seq OWNED BY public.log_import_fields.id;


--
-- Name: log_import_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_import_images (
    id integer NOT NULL,
    description text,
    process_id integer,
    ts timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: log_import_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_import_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_import_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_import_images_id_seq OWNED BY public.log_import_images.id;


--
-- Name: log_process_functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_process_functions (
    id integer NOT NULL,
    description text,
    process_function_id integer,
    ts timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: log_process_functions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_process_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_process_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_process_functions_id_seq OWNED BY public.log_process_functions.id;


--
-- Name: maps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maps (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    quantity integer,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    organization_id integer NOT NULL,
    path character varying
);


--
-- Name: maps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maps_id_seq OWNED BY public.maps.id;


--
-- Name: menu_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menu_options (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    controller character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    description character varying(500),
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    parent_id integer,
    menu_icon character varying(50),
    "order" integer NOT NULL
);


--
-- Name: menu_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menu_options_id_seq
    START WITH 35
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menu_options_id_seq OWNED BY public.menu_options.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    name character varying(50) NOT NULL
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: parameter_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parameter_types (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    name character varying(50),
    unit character varying(50),
    description character varying(250),
    quantity integer,
    format_type_id integer DEFAULT 1 NOT NULL
);


--
-- Name: parameter_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parameter_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parameter_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parameter_types_id_seq OWNED BY public.parameter_types.id;


--
-- Name: parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parameters (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    use_id integer,
    month integer,
    parameter_type_id integer NOT NULL,
    value character varying(50),
    map_id integer NOT NULL,
    region_id integer NOT NULL,
    priority integer NOT NULL
);


--
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parameters_id_seq OWNED BY public.parameters.id;


--
-- Name: pixel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pixel (
    id integer NOT NULL,
    y integer NOT NULL,
    x integer NOT NULL,
    set_id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    the_geom public.geometry,
    centroid_x real,
    centroid_y real
);


--
-- Name: pixel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pixel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pixel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pixel_id_seq OWNED BY public.pixel.id;


--
-- Name: pixel_selection_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pixel_selection_rules (
    id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    name character varying(50) NOT NULL,
    tolerance integer NOT NULL
);


--
-- Name: pixel_selection_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pixel_selection_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pixel_selection_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pixel_selection_rules_id_seq OWNED BY public.pixel_selection_rules.id;


--
-- Name: pixel_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pixel_sets (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    imagen_type_id integer DEFAULT '-1'::integer NOT NULL,
    width integer,
    height integer
);


--
-- Name: pixel_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pixel_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pixel_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pixel_sets_id_seq OWNED BY public.pixel_sets.id;


--
-- Name: process_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_fields (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    client_id integer NOT NULL,
    project_id integer NOT NULL,
    version_id integer NOT NULL,
    path text,
    description character varying,
    user_id integer NOT NULL,
    procces_run boolean DEFAULT false,
    qt_errors integer,
    check_run boolean DEFAULT false NOT NULL,
    import_from integer
);


--
-- Name: process_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_fields_id_seq OWNED BY public.process_fields.id;


--
-- Name: process_functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_functions (
    id integer NOT NULL,
    status character varying(20) NOT NULL,
    process_result_id integer NOT NULL,
    function_id integer,
    user_id integer NOT NULL,
    name character varying(30) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying,
    procces_run boolean DEFAULT false,
    map_id integer NOT NULL
);


--
-- Name: process_functions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_functions_id_seq OWNED BY public.process_functions.id;


--
-- Name: process_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_images (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying,
    process_run boolean DEFAULT false,
    raster_file_id integer,
    user_id integer,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL
);


--
-- Name: process_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_images_id_seq OWNED BY public.process_images.id;


--
-- Name: process_pixels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_pixels (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying,
    path text,
    set_id integer,
    user_id integer NOT NULL,
    procces_run boolean DEFAULT false
);


--
-- Name: process_pixels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_pixels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_pixels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_pixels_id_seq OWNED BY public.process_pixels.id;


--
-- Name: process_query_functions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_query_functions (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    status character varying(20) NOT NULL,
    user_id integer NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying,
    procces_run boolean DEFAULT false,
    pixel_id integer,
    region_id text,
    client_id text,
    project_id text,
    version_id text,
    farm_id text,
    group_name text,
    field_id text,
    use_concrete_id text,
    date timestamp without time zone,
    date_from timestamp without time zone,
    date_to timestamp without time zone,
    group_field boolean DEFAULT false NOT NULL,
    group_month boolean DEFAULT false NOT NULL,
    aggregate_function character varying(50),
    function_id text,
    filter_description text
);


--
-- Name: process_query_functions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_query_functions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_query_functions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_query_functions_id_seq OWNED BY public.process_query_functions.id;


--
-- Name: process_regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_regions (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    path text,
    description character varying,
    procces_run boolean DEFAULT false,
    map_id integer NOT NULL,
    user_id integer
);


--
-- Name: process_regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_regions_id_seq OWNED BY public.process_regions.id;


--
-- Name: process_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_results (
    set_id integer NOT NULL,
    id integer NOT NULL,
    pixel_selection_rules_id integer,
    user_id integer NOT NULL,
    version_id integer NOT NULL,
    name character varying(100) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    start_process_at timestamp without time zone,
    end_process_at timestamp without time zone,
    description character varying(200),
    client_id integer NOT NULL,
    imagen_type_id integer NOT NULL,
    procces_run boolean DEFAULT false
);


--
-- Name: process_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.process_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: process_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.process_results_id_seq OWNED BY public.process_results.id;


--
-- Name: processes_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.processes_vw AS
 SELECT 'process_fields'::text AS process_class,
    process_fields.id,
    process_fields.ts,
    date_trunc('seconds'::text, process_fields.created_at) AS created_at,
    process_fields.start_process_at,
    process_fields.end_process_at,
    process_fields.description,
    process_fields.user_id,
    process_fields.procces_run
   FROM public.process_fields
UNION
 SELECT 'process_functions'::text AS process_class,
    process_functions.id,
    process_functions.ts,
    date_trunc('seconds'::text, process_functions.created_at) AS created_at,
    process_functions.start_process_at,
    process_functions.end_process_at,
    process_functions.description,
    process_functions.user_id,
    process_functions.procces_run
   FROM public.process_functions
UNION
 SELECT 'process_images'::text AS process_class,
    process_images.id,
    process_images.ts,
    date_trunc('seconds'::text, process_images.created_at) AS created_at,
    process_images.start_process_at,
    process_images.end_process_at,
    process_images.description,
    process_images.user_id,
    process_images.process_run AS procces_run
   FROM public.process_images
UNION
 SELECT 'process_pixels'::text AS process_class,
    process_pixels.id,
    process_pixels.ts,
    date_trunc('seconds'::text, process_pixels.created_at) AS created_at,
    process_pixels.start_process_at,
    process_pixels.end_process_at,
    process_pixels.description,
    process_pixels.user_id,
    process_pixels.procces_run
   FROM public.process_pixels
UNION
 SELECT 'process_regions'::text AS process_class,
    process_regions.id,
    process_regions.ts,
    date_trunc('seconds'::text, process_regions.created_at) AS created_at,
    process_regions.start_process_at,
    process_regions.end_process_at,
    process_regions.description,
    process_regions.user_id,
    process_regions.procces_run
   FROM public.process_regions
UNION
 SELECT 'process_results'::text AS process_class,
    process_results.id,
    process_results.ts,
    date_trunc('seconds'::text, process_results.created_at) AS created_at,
    process_results.start_process_at,
    process_results.end_process_at,
    process_results.description,
    process_results.user_id,
    process_results.procces_run
   FROM public.process_results;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    client_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    parent_id integer,
    description text
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: r2_log_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.r2_log_activity (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    ip inet,
    user_id integer,
    post_data character varying,
    get_data character varying,
    controller character varying,
    method character varying,
    uri character varying,
    http_response_code integer
);


--
-- Name: r2_log_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.r2_log_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: r2_log_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.r2_log_activity_id_seq OWNED BY public.r2_log_activity.id;


--
-- Name: r2_rest_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.r2_rest_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    session_id character varying(75) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    last_communication timestamp without time zone,
    gcm_id character varying
);


--
-- Name: r2_rest_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.r2_rest_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: r2_rest_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.r2_rest_sessions_id_seq OWNED BY public.r2_rest_sessions.id;


--
-- Name: r2_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.r2_sessions (
    id character varying(40) NOT NULL,
    ip_address character varying(45) NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    data text DEFAULT ''::text NOT NULL
);


--
-- Name: raster_columns; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.raster_columns AS
 SELECT current_database() AS r_table_catalog,
    n.nspname AS r_table_schema,
    c.relname AS r_table_name,
    a.attname AS r_raster_column,
    COALESCE(public._raster_constraint_info_srid(n.nspname, c.relname, a.attname), ( SELECT public.st_srid('010100000000000000000000000000000000000000'::public.geometry) AS st_srid)) AS srid,
    public._raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'x'::bpchar) AS scale_x,
    public._raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'y'::bpchar) AS scale_y,
    public._raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'width'::text) AS blocksize_x,
    public._raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'height'::text) AS blocksize_y,
    COALESCE(public._raster_constraint_info_alignment(n.nspname, c.relname, a.attname), false) AS same_alignment,
    COALESCE(public._raster_constraint_info_regular_blocking(n.nspname, c.relname, a.attname), false) AS regular_blocking,
    public._raster_constraint_info_num_bands(n.nspname, c.relname, a.attname) AS num_bands,
    public._raster_constraint_info_pixel_types(n.nspname, c.relname, a.attname) AS pixel_types,
    public._raster_constraint_info_nodata_values(n.nspname, c.relname, a.attname) AS nodata_values,
    public._raster_constraint_info_out_db(n.nspname, c.relname, a.attname) AS out_db,
    public._raster_constraint_info_extent(n.nspname, c.relname, a.attname) AS extent,
    COALESCE(public._raster_constraint_info_index(n.nspname, c.relname, a.attname), false) AS spatial_index
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'raster'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND ((c.relkind)::text = ANY ((ARRAY['r'::character(1), 'v'::character(1), 'm'::character(1), 'f'::character(1)])::text[])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- Name: raster_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raster_files (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    path character varying(250) NOT NULL,
    image_type_id integer NOT NULL,
    image_date date,
    pixel_set_id integer
);


--
-- Name: raster_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.raster_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raster_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.raster_files_id_seq OWNED BY public.raster_files.id;


--
-- Name: raster_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raster_groups (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    files_quantity integer,
    layers_quantity integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: raster_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.raster_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raster_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.raster_groups_id_seq OWNED BY public.raster_groups.id;


--
-- Name: raster_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raster_layers (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    layer_type_id integer NOT NULL,
    raster_file_id integer,
    image_date date,
    layer_path text NOT NULL
);


--
-- Name: raster_layers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.raster_layers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raster_layers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.raster_layers_id_seq OWNED BY public.raster_layers.id;


--
-- Name: raster_overviews; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.raster_overviews AS
 SELECT current_database() AS o_table_catalog,
    n.nspname AS o_table_schema,
    c.relname AS o_table_name,
    a.attname AS o_raster_column,
    current_database() AS r_table_catalog,
    (split_part(split_part(s.consrc, '''::name'::text, 1), ''''::text, 2))::name AS r_table_schema,
    (split_part(split_part(s.consrc, '''::name'::text, 2), ''''::text, 2))::name AS r_table_name,
    (split_part(split_part(s.consrc, '''::name'::text, 3), ''''::text, 2))::name AS r_raster_column,
    (btrim(split_part(s.consrc, ','::text, 2)))::integer AS overview_factor
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n,
    pg_constraint s
  WHERE ((t.typname = 'raster'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND ((c.relkind)::text = ANY ((ARRAY['r'::character(1), 'v'::character(1), 'm'::character(1), 'f'::character(1)])::text[])) AND (s.connamespace = n.oid) AND (s.conrelid = c.oid) AND (s.consrc ~~ '%_overview_constraint(%'::text) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    the_geom public.geometry,
    map_id integer,
    process_id integer NOT NULL
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.results (
    id integer NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_id integer NOT NULL,
    field_id integer NOT NULL,
    intersect_idx real NOT NULL,
    selected boolean DEFAULT true NOT NULL,
    selected_by_user boolean,
    pixel_id integer NOT NULL,
    set_id integer NOT NULL,
    centroid_x real,
    centroid_y real,
    the_geom public.geometry
);


--
-- Name: use_concretes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.use_concretes (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    password bytea DEFAULT '\x'::bytea,
    email character varying(320) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    last_login timestamp without time zone,
    last_ip inet,
    inactive_reason character varying(500),
    activation_code character varying(10),
    failed_login_count integer DEFAULT 0,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    password_sent_at timestamp without time zone,
    organization_id integer NOT NULL
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    project_id integer NOT NULL
);


--
-- Name: view_process_results; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_process_results AS
 SELECT pre.id,
    pr.name AS project_name,
    v.name AS version_name,
    u.name AS user_name,
    c.name AS client_name
   FROM ((((public.process_results pre
     JOIN public.users u ON ((u.id = pre.user_id)))
     JOIN public.versions v ON ((v.id = pre.version_id)))
     JOIN public.projects pr ON ((pr.id = v.project_id)))
     JOIN public.clients c ON ((c.id = pr.client_id)));


--
-- Name: result_focus1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.result_focus1 AS
 SELECT DISTINCT r.id AS result_id,
    r.selected AS sel_rule,
    r.selected_by_user AS sel_user,
    r.pixel_id,
    r.centroid_y AS latitud,
    r.centroid_x AS longitud,
    r.intersect_idx,
    f.id AS field_id,
    f.name AS field_name,
    f.date_from AS field_date_from,
    f.date_to AS field_date_to,
    fa.id AS farm_id,
    fa.name AS farm_name,
    view_process_results.id AS process_id,
    view_process_results.version_name,
    view_process_results.project_name,
    view_process_results.client_name,
    view_process_results.user_name,
    u.id AS use_concrete_id,
    u.name AS use_concrete_name,
    (dc.date_from)::date AS uses_date_from,
    (dc.date_to)::date AS uses_date_to,
    r.the_geom
   FROM ((((((public.results r
     LEFT JOIN public.view_process_results ON ((view_process_results.id = r.process_id)))
     LEFT JOIN public.fields f ON ((f.id = r.field_id)))
     LEFT JOIN public.farms fa ON ((fa.id = f.farm_id)))
     LEFT JOIN public.declarations de ON ((de.field_id = f.id)))
     LEFT JOIN public.declarations_concrete dc ON ((de.id = dc.declaration_id)))
     LEFT JOIN public.use_concretes u ON ((u.id = dc.use_concrete_id)));


--
-- Name: results_f1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.results_f1 (
    id integer NOT NULL,
    field_id integer NOT NULL,
    process_id integer NOT NULL,
    date date NOT NULL,
    use_concrete_id integer,
    uses_date_from date,
    uses_date_to date,
    result_id integer
);


--
-- Name: results_f1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.results_f1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_f1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.results_f1_id_seq OWNED BY public.results_f1.id;


--
-- Name: results_f2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.results_f2 (
    id integer NOT NULL,
    key character varying(250) NOT NULL,
    value character varying(250),
    process_result_id integer,
    process_focus_id integer,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    date timestamp without time zone
);


--
-- Name: results_f2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.results_f2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_f2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.results_f2_id_seq OWNED BY public.results_f2.id;


--
-- Name: results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.results_id_seq OWNED BY public.results.id;


--
-- Name: temporal_expansion_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.temporal_expansion_rules (
    id integer NOT NULL,
    region_id integer NOT NULL,
    use_declared_id integer NOT NULL,
    use_concrete_id integer NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    month_to integer,
    month_from integer,
    declaration_month integer
);


--
-- Name: temporal_expansion_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.temporal_expansion_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temporal_expansion_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.temporal_expansion_rules_id_seq OWNED BY public.temporal_expansion_rules.id;


--
-- Name: test_20160628; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.test_20160628 AS
 SELECT fi.id,
    fi.name,
    fi.date_from,
    fi.date_to,
    fi.ts,
    fi.created_at,
    fi.farm_id,
    fi.active,
    fi.the_geom,
    fi.code
   FROM (public.fields fi
     JOIN public.farms fa ON ((fi.farm_id = fa.id)))
  WHERE (fa.version_id = 76)
  ORDER BY fi.name;


--
-- Name: test_20170731; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.test_20170731 AS
 SELECT fi.id,
    fi.name,
    fi.date_from,
    fi.date_to,
    fi.ts,
    fi.created_at,
    fi.farm_id,
    fi.active,
    fi.the_geom,
    fi.code,
    fi.group_name
   FROM (public.fields fi
     JOIN public.farms fa ON ((fi.farm_id = fa.id)))
  WHERE (fa.version_id = 118);


--
-- Name: test_20170731_2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.test_20170731_2 AS
 SELECT p.id,
    p.y,
    p.x,
    p.set_id,
    p.ts,
    p.created_at,
    p.the_geom,
    p.centroid_x,
    p.centroid_y
   FROM public.pixel p
  WHERE (p.set_id = 62);


--
-- Name: test_20170804; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.test_20170804 AS
 SELECT fi.id,
    fi.name,
    fi.date_from,
    fi.date_to,
    fi.ts,
    fi.created_at,
    fi.farm_id,
    fi.active,
    fi.the_geom,
    fi.code
   FROM (public.fields fi
     JOIN public.farms fa ON ((fi.farm_id = fa.id)))
  WHERE (fa.version_id = 117)
  ORDER BY fi.name;


--
-- Name: test_20170804_1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.test_20170804_1 AS
 SELECT results.id,
    results.ts,
    results.created_at,
    results.process_id,
    results.field_id,
    results.intersect_idx,
    results.selected,
    results.selected_by_user,
    results.pixel_id,
    results.set_id,
    results.centroid_x,
    results.centroid_y,
    results.the_geom
   FROM public.results
  WHERE (results.process_id = 418);


--
-- Name: test_crosstab; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_crosstab (
    the_geom public.geometry,
    pixel_id integer,
    pivot integer,
    "2000-02-18" text,
    "2000-03-05" text,
    "2000-03-21" text,
    "2000-04-06" text,
    "2000-04-22" text,
    "2000-05-08" text,
    "2000-05-24" text,
    "2000-06-09" text,
    "2000-06-25" text,
    "2000-07-11" text,
    "2000-07-27" text,
    "2000-08-12" text,
    "2000-08-28" text,
    "2000-09-13" text,
    "2000-09-29" text,
    "2000-10-15" text,
    "2000-10-31" text,
    "2000-11-16" text,
    "2000-12-02" text,
    "2000-12-18" text,
    "2001-01-01" text,
    "2001-01-17" text,
    "2001-02-02" text,
    "2001-02-18" text,
    "2001-03-06" text,
    "2001-03-22" text,
    "2001-04-07" text,
    "2001-04-23" text,
    "2001-05-09" text,
    "2001-05-25" text,
    "2001-06-10" text,
    "2001-06-26" text,
    "2001-07-12" text,
    "2001-07-28" text,
    "2001-08-13" text,
    "2001-08-29" text,
    "2001-09-14" text,
    "2001-09-30" text,
    "2001-10-16" text,
    "2001-11-01" text,
    "2001-11-17" text,
    "2001-12-03" text,
    "2001-12-19" text,
    "2002-01-01" text,
    "2002-01-17" text,
    "2002-02-02" text,
    "2002-02-18" text,
    "2002-03-06" text,
    "2002-03-22" text,
    "2002-04-07" text,
    "2002-04-23" text,
    "2002-05-09" text,
    "2002-05-25" text,
    "2002-06-10" text,
    "2002-06-26" text,
    "2002-07-12" text,
    "2002-07-28" text,
    "2002-08-13" text,
    "2002-08-29" text,
    "2002-09-14" text,
    "2002-09-30" text,
    "2002-10-16" text,
    "2002-11-01" text,
    "2002-11-17" text,
    "2002-12-03" text,
    "2002-12-19" text,
    "2003-01-01" text,
    "2003-01-17" text,
    "2003-02-02" text,
    "2003-02-18" text,
    "2003-03-06" text,
    "2003-03-22" text,
    "2003-04-07" text,
    "2003-04-23" text,
    "2003-05-09" text,
    "2003-05-25" text,
    "2003-06-10" text,
    "2003-06-26" text,
    "2003-07-12" text,
    "2003-07-28" text,
    "2003-08-13" text,
    "2003-08-29" text,
    "2003-09-14" text,
    "2003-09-30" text,
    "2003-10-16" text,
    "2003-11-01" text,
    "2003-11-17" text,
    "2003-12-03" text,
    "2003-12-19" text,
    "2004-01-01" text,
    "2004-01-17" text,
    "2004-02-02" text,
    "2004-02-18" text,
    "2004-03-05" text,
    "2004-03-21" text,
    "2004-04-06" text,
    "2004-04-22" text,
    "2004-05-08" text,
    "2004-05-24" text,
    "2004-06-09" text,
    "2004-06-25" text,
    "2004-07-11" text,
    "2004-07-27" text,
    "2004-08-12" text,
    "2004-08-28" text,
    "2004-09-13" text,
    "2004-09-29" text,
    "2004-10-15" text,
    "2004-10-31" text,
    "2004-11-16" text,
    "2004-12-02" text,
    "2004-12-18" text,
    "2005-01-01" text,
    "2005-01-17" text,
    "2005-02-02" text,
    "2005-02-18" text,
    "2005-03-06" text,
    "2005-03-22" text,
    "2005-04-07" text,
    "2005-04-23" text,
    "2005-05-09" text,
    "2005-05-25" text,
    "2005-06-10" text,
    "2005-06-26" text,
    "2005-07-12" text,
    "2005-07-28" text,
    "2005-08-13" text,
    "2005-08-29" text,
    "2005-09-14" text,
    "2005-09-30" text,
    "2005-10-16" text,
    "2005-11-01" text,
    "2005-11-17" text,
    "2005-12-03" text,
    "2005-12-19" text,
    "2006-01-01" text,
    "2006-01-17" text,
    "2006-02-02" text,
    "2006-02-18" text,
    "2006-03-06" text,
    "2006-03-22" text,
    "2006-04-07" text,
    "2006-04-23" text,
    "2006-05-09" text,
    "2006-05-25" text,
    "2006-06-10" text,
    "2006-06-26" text,
    "2006-07-12" text,
    "2006-07-28" text,
    "2006-08-13" text,
    "2006-08-29" text,
    "2006-09-14" text,
    "2006-09-30" text,
    "2006-10-16" text,
    "2006-11-01" text,
    "2006-11-17" text,
    "2006-12-03" text,
    "2006-12-19" text,
    "2007-01-01" text,
    "2007-01-17" text,
    "2007-02-02" text,
    "2007-02-18" text,
    "2007-03-06" text,
    "2007-03-22" text,
    "2007-04-07" text,
    "2007-04-23" text,
    "2007-05-09" text,
    "2007-05-25" text,
    "2007-06-10" text,
    "2007-06-26" text,
    "2007-07-12" text,
    "2007-07-28" text,
    "2007-08-13" text,
    "2007-08-29" text,
    "2007-09-14" text,
    "2007-09-30" text,
    "2007-10-16" text,
    "2007-11-01" text,
    "2007-11-17" text,
    "2007-12-03" text,
    "2007-12-19" text,
    "2008-01-01" text,
    "2008-01-17" text,
    "2008-02-02" text,
    "2008-02-18" text,
    "2008-03-05" text,
    "2008-03-21" text,
    "2008-04-06" text,
    "2008-04-22" text,
    "2008-05-08" text,
    "2008-05-24" text,
    "2008-06-09" text,
    "2008-06-25" text,
    "2008-07-11" text,
    "2008-07-27" text,
    "2008-08-12" text,
    "2008-08-28" text,
    "2008-09-13" text,
    "2008-09-29" text,
    "2008-10-15" text,
    "2008-10-31" text,
    "2008-11-16" text,
    "2008-12-02" text,
    "2008-12-18" text,
    "2009-01-01" text,
    "2009-01-17" text,
    "2009-02-02" text,
    "2009-02-18" text,
    "2009-03-06" text,
    "2009-03-22" text,
    "2009-04-07" text,
    "2009-04-23" text,
    "2009-05-09" text,
    "2009-05-25" text,
    "2009-06-10" text,
    "2009-06-26" text,
    "2009-07-12" text,
    "2009-07-28" text,
    "2009-08-13" text,
    "2009-08-29" text,
    "2009-09-14" text,
    "2009-09-30" text,
    "2009-10-16" text,
    "2009-11-01" text,
    "2009-11-17" text,
    "2009-12-03" text,
    "2009-12-19" text,
    "2010-01-01" text,
    "2010-01-17" text,
    "2010-02-02" text,
    "2010-02-18" text,
    "2010-03-06" text,
    "2010-03-22" text,
    "2010-04-07" text,
    "2010-04-23" text,
    "2010-05-09" text,
    "2010-05-25" text,
    "2010-06-10" text,
    "2010-06-26" text,
    "2010-07-12" text,
    "2010-07-28" text,
    "2010-08-13" text,
    "2010-08-29" text,
    "2010-09-14" text,
    "2010-09-30" text,
    "2010-10-16" text,
    "2010-11-01" text,
    "2010-11-17" text,
    "2010-12-03" text,
    "2010-12-19" text,
    "2011-01-01" text,
    "2011-01-17" text,
    "2011-02-02" text,
    "2011-02-18" text,
    "2011-03-06" text,
    "2011-03-22" text,
    "2011-04-07" text,
    "2011-04-23" text,
    "2011-05-09" text,
    "2011-05-25" text,
    "2011-06-10" text,
    "2011-06-26" text,
    "2011-07-12" text,
    "2011-07-28" text,
    "2011-08-13" text,
    "2011-08-29" text,
    "2011-09-14" text,
    "2011-09-30" text,
    "2011-10-16" text,
    "2011-11-01" text,
    "2011-11-17" text,
    "2011-12-03" text,
    "2011-12-19" text,
    "2012-01-01" text,
    "2012-01-17" text,
    "2012-02-02" text,
    "2012-02-18" text,
    "2012-03-05" text,
    "2012-03-21" text,
    "2012-04-06" text,
    "2012-04-22" text,
    "2012-05-08" text,
    "2012-05-24" text,
    "2012-06-09" text,
    "2012-06-25" text,
    "2012-07-11" text,
    "2012-07-27" text,
    "2012-08-12" text,
    "2012-08-28" text,
    "2012-09-13" text,
    "2012-09-29" text,
    "2012-10-15" text,
    "2012-10-31" text,
    "2012-11-16" text,
    "2012-12-02" text,
    "2012-12-18" text,
    "2013-01-01" text,
    "2013-01-17" text,
    "2013-02-02" text,
    "2013-02-18" text,
    "2013-03-06" text,
    "2013-03-22" text,
    "2013-04-07" text,
    "2013-04-23" text,
    "2013-05-09" text,
    "2013-05-25" text,
    "2013-06-10" text,
    "2013-06-26" text,
    "2013-07-12" text,
    "2013-07-28" text,
    "2013-08-13" text,
    "2013-08-29" text,
    "2013-09-14" text,
    "2013-09-30" text,
    "2013-10-16" text,
    "2013-11-01" text,
    "2013-11-17" text,
    "2013-12-03" text,
    "2013-12-19" text,
    "2014-01-01" text,
    "2014-01-17" text,
    "2014-02-02" text,
    "2014-02-18" text,
    "2014-03-06" text,
    "2014-03-22" text,
    "2014-04-07" text,
    "2014-04-23" text,
    "2014-05-09" text,
    "2014-05-25" text,
    "2014-06-10" text,
    "2014-06-26" text,
    "2014-07-12" text,
    "2014-07-28" text,
    "2014-08-13" text,
    "2014-08-29" text,
    "2014-09-14" text,
    "2014-09-30" text,
    "2014-10-16" text,
    "2014-11-01" text,
    "2014-11-17" text,
    "2014-12-03" text,
    "2014-12-19" text,
    "2015-01-01" text,
    "2015-01-17" text,
    "2015-02-02" text,
    "2015-02-18" text,
    "2015-03-06" text,
    "2015-03-22" text,
    "2015-04-07" text,
    "2015-04-23" text,
    "2015-05-09" text,
    "2015-05-25" text,
    "2015-06-10" text,
    "2015-06-26" text,
    "2015-07-12" text,
    "2015-07-28" text,
    "2015-08-13" text,
    "2015-08-29" text,
    "2015-09-14" text,
    "2015-09-30" text,
    "2015-10-16" text,
    "2015-11-01" text,
    "2015-11-17" text,
    "2015-12-03" text,
    "2015-12-19" text,
    "2016-01-01" text,
    "2016-01-17" text,
    "2016-02-02" text,
    "2016-02-18" text,
    "2016-03-05" text,
    "2016-03-21" text,
    "2016-04-06" text,
    "2016-04-22" text,
    "2016-05-08" text,
    "2016-05-24" text,
    "2016-06-09" text,
    "2016-06-25" text,
    "2016-07-11" text,
    "2016-07-27" text,
    "2016-08-12" text,
    "2016-08-28" text,
    "2016-09-13" text,
    "2016-09-29" text,
    "2016-10-15" text,
    "2016-10-31" text,
    "2016-11-16" text,
    "2016-12-02" text,
    "2016-12-18" text,
    "2017-01-01" text,
    "2017-01-17" text,
    "2017-02-02" text,
    "2017-02-18" text,
    "2017-03-06" text,
    "2017-03-22" text,
    "2017-04-07" text,
    "2017-04-23" text,
    "2017-05-09" text,
    "2017-05-25" text,
    "2017-06-10" text,
    "2017-06-26" text,
    "2017-07-12" text,
    "2017-07-28" text,
    "2017-08-13" text,
    "2017-08-29" text,
    "2017-09-14" text,
    "2017-09-30" text,
    "2017-10-16" text,
    "2017-11-01" text,
    "2017-11-17" text,
    "2017-12-03" text,
    "2017-12-19" text,
    "2018-01-01" text,
    "2018-01-17" text,
    "2018-02-02" text,
    "2018-02-18" text,
    "2018-03-06" text,
    "2018-03-22" text,
    "2018-04-07" text,
    "2018-04-23" text,
    "2018-05-09" text,
    "2018-05-25" text,
    "2018-06-10" text,
    "2018-06-26" text,
    "2018-07-12" text,
    "2018-07-28" text,
    "2018-08-13" text,
    "2018-08-29" text,
    "2018-09-14" text,
    "2018-09-30" text,
    "2018-10-16" text,
    "2018-11-01" text,
    "2018-11-17" text,
    "2018-12-03" text,
    "2018-12-19" text,
    "2019-01-01" text,
    "2019-01-17" text,
    "2019-02-02" text,
    "2019-02-18" text,
    "2019-03-06" text,
    "2019-03-22" text,
    "2019-04-07" text,
    "2019-04-23" text,
    "2019-05-09" text,
    "2019-05-25" text,
    "2019-06-10" text
);


--
-- Name: tmp_pixel_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tmp_pixel_ids (
    id integer NOT NULL
);


--
-- Name: tmp_raster_layers_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tmp_raster_layers_ids (
    id integer
);


--
-- Name: use_concretes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.use_concretes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: use_concretes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.use_concretes_id_seq OWNED BY public.use_concretes.id;


--
-- Name: use_declareds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.use_declareds (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)
);


--
-- Name: use_declareds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.use_declareds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: use_declareds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.use_declareds_id_seq OWNED BY public.use_declareds.id;


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_groups (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)
);


--
-- Name: user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_groups_id_seq
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_groups_id_seq OWNED BY public.user_groups.id;


--
-- Name: users_by_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_by_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_group_id integer NOT NULL
);


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_by_groups_id_seq
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_by_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_by_groups_id_seq OWNED BY public.users_by_groups.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: debug_pixel; Type: TABLE; Schema: tmp; Owner: -
--

CREATE TABLE tmp.debug_pixel (
    id integer,
    y integer,
    x integer,
    set_id integer,
    ts timestamp(6) without time zone,
    created_at timestamp(6) without time zone,
    the_geom public.geometry,
    centroid_x real,
    centroid_y real
);


--
-- Name: tmp_1597914902269; Type: TABLE; Schema: tmp; Owner: -
--

CREATE TABLE tmp.tmp_1597914902269 (
    pixel_id integer,
    raster_layer_id integer,
    value double precision,
    perc_insersect double precision
);


--
-- Name: process_query_function_logs id; Type: DEFAULT; Schema: log; Owner: -
--

ALTER TABLE ONLY log.process_query_function_logs ALTER COLUMN id SET DEFAULT nextval('log.process_query_function_logs_id_seq'::regclass);


--
-- Name: trigger_logs id; Type: DEFAULT; Schema: log; Owner: -
--

ALTER TABLE ONLY log.trigger_logs ALTER COLUMN id SET DEFAULT nextval('log.trigger_logs_id_seq'::regclass);


--
-- Name: business_objects_translations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_objects_translations ALTER COLUMN id SET DEFAULT nextval('public.business_objects_translations_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: concretes_by_declareds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concretes_by_declareds ALTER COLUMN id SET DEFAULT nextval('public.concretes_by_declareds_id_seq'::regclass);


--
-- Name: data_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types ALTER COLUMN id SET DEFAULT nextval('public.data_types_id_seq'::regclass);


--
-- Name: data_types_by_pixels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types_by_pixels ALTER COLUMN id SET DEFAULT nextval('public.data_types_by_pixels_id_seq'::regclass);


--
-- Name: date_by_process_f2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_by_process_f2 ALTER COLUMN id SET DEFAULT nextval('public.date_by_process_f2_id_seq'::regclass);


--
-- Name: db_actions_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_actions_logs ALTER COLUMN id SET DEFAULT nextval('public.db_actions_logs_id_seq'::regclass);


--
-- Name: declarations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations ALTER COLUMN id SET DEFAULT nextval('public.declarations_id_seq'::regclass);


--
-- Name: declarations_concrete id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations_concrete ALTER COLUMN id SET DEFAULT nextval('public.declarations_concrete_id_seq'::regclass);


--
-- Name: farms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms ALTER COLUMN id SET DEFAULT nextval('public.farms_id_seq'::regclass);


--
-- Name: fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields ALTER COLUMN id SET DEFAULT nextval('public.fields_id_seq'::regclass);


--
-- Name: format_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.format_types ALTER COLUMN id SET DEFAULT nextval('public.format_types_id_seq'::regclass);


--
-- Name: functions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions ALTER COLUMN id SET DEFAULT nextval('public.functions_id_seq'::regclass);


--
-- Name: groups_by_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_by_options ALTER COLUMN id SET DEFAULT nextval('public.groups_by_options_id_seq'::regclass);


--
-- Name: imagen_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imagen_types ALTER COLUMN id SET DEFAULT nextval('public.imagen_types_id_seq'::regclass);


--
-- Name: import_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_data ALTER COLUMN id SET DEFAULT nextval('public.import_data_id_seq'::regclass);


--
-- Name: layer_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layer_types ALTER COLUMN id SET DEFAULT nextval('public.layer_types_id_seq'::regclass);


--
-- Name: layers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers ALTER COLUMN id SET DEFAULT nextval('public.layers_id_seq'::regclass);


--
-- Name: log_import_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_fields ALTER COLUMN id SET DEFAULT nextval('public.log_import_fields_id_seq'::regclass);


--
-- Name: log_import_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_images ALTER COLUMN id SET DEFAULT nextval('public.log_import_images_id_seq'::regclass);


--
-- Name: log_process_functions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_process_functions ALTER COLUMN id SET DEFAULT nextval('public.log_process_functions_id_seq'::regclass);


--
-- Name: maps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maps ALTER COLUMN id SET DEFAULT nextval('public.maps_id_seq'::regclass);


--
-- Name: menu_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_options ALTER COLUMN id SET DEFAULT nextval('public.menu_options_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: parameter_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameter_types ALTER COLUMN id SET DEFAULT nextval('public.parameter_types_id_seq'::regclass);


--
-- Name: parameters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters ALTER COLUMN id SET DEFAULT nextval('public.parameters_id_seq'::regclass);


--
-- Name: pixel id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel ALTER COLUMN id SET DEFAULT nextval('public.pixel_id_seq'::regclass);


--
-- Name: pixel_selection_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel_selection_rules ALTER COLUMN id SET DEFAULT nextval('public.pixel_selection_rules_id_seq'::regclass);


--
-- Name: pixel_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel_sets ALTER COLUMN id SET DEFAULT nextval('public.pixel_sets_id_seq'::regclass);


--
-- Name: process_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields ALTER COLUMN id SET DEFAULT nextval('public.process_fields_id_seq'::regclass);


--
-- Name: process_functions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions ALTER COLUMN id SET DEFAULT nextval('public.process_functions_id_seq'::regclass);


--
-- Name: process_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_images ALTER COLUMN id SET DEFAULT nextval('public.process_images_id_seq'::regclass);


--
-- Name: process_pixels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_pixels ALTER COLUMN id SET DEFAULT nextval('public.process_pixels_id_seq'::regclass);


--
-- Name: process_query_functions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_query_functions ALTER COLUMN id SET DEFAULT nextval('public.process_query_functions_id_seq'::regclass);


--
-- Name: process_regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_regions ALTER COLUMN id SET DEFAULT nextval('public.process_regions_id_seq'::regclass);


--
-- Name: process_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results ALTER COLUMN id SET DEFAULT nextval('public.process_results_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: r2_log_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_log_activity ALTER COLUMN id SET DEFAULT nextval('public.r2_log_activity_id_seq'::regclass);


--
-- Name: r2_rest_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_rest_sessions ALTER COLUMN id SET DEFAULT nextval('public.r2_rest_sessions_id_seq'::regclass);


--
-- Name: raster_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_files ALTER COLUMN id SET DEFAULT nextval('public.raster_files_id_seq'::regclass);


--
-- Name: raster_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_groups ALTER COLUMN id SET DEFAULT nextval('public.raster_groups_id_seq'::regclass);


--
-- Name: raster_layers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_layers ALTER COLUMN id SET DEFAULT nextval('public.raster_layers_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results ALTER COLUMN id SET DEFAULT nextval('public.results_id_seq'::regclass);


--
-- Name: results_f1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f1 ALTER COLUMN id SET DEFAULT nextval('public.results_f1_id_seq'::regclass);


--
-- Name: results_f2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f2 ALTER COLUMN id SET DEFAULT nextval('public.results_f2_id_seq'::regclass);


--
-- Name: temporal_expansion_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules ALTER COLUMN id SET DEFAULT nextval('public.temporal_expansion_rules_id_seq'::regclass);


--
-- Name: use_concretes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.use_concretes ALTER COLUMN id SET DEFAULT nextval('public.use_concretes_id_seq'::regclass);


--
-- Name: use_declareds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.use_declareds ALTER COLUMN id SET DEFAULT nextval('public.use_declareds_id_seq'::regclass);


--
-- Name: user_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups ALTER COLUMN id SET DEFAULT nextval('public.user_groups_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_by_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_by_groups ALTER COLUMN id SET DEFAULT nextval('public.users_by_groups_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: process_query_function_logs process_query_function_logs_pk; Type: CONSTRAINT; Schema: log; Owner: -
--

ALTER TABLE ONLY log.process_query_function_logs
    ADD CONSTRAINT process_query_function_logs_pk PRIMARY KEY (id);


--
-- Name: trigger_logs trigger_logs_pkey; Type: CONSTRAINT; Schema: log; Owner: -
--

ALTER TABLE ONLY log.trigger_logs
    ADD CONSTRAINT trigger_logs_pkey PRIMARY KEY (id);


--
-- Name: business_objects_translations business_objects_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_objects_translations
    ADD CONSTRAINT business_objects_translations_pkey PRIMARY KEY (id);


--
-- Name: clients clients_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pk PRIMARY KEY (id);


--
-- Name: concretes_by_declareds concretes_by_declareds_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_pk PRIMARY KEY (id);


--
-- Name: data_types_by_pixels data_by_pixels; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types_by_pixels
    ADD CONSTRAINT data_by_pixels PRIMARY KEY (id);


--
-- Name: layers data_type_by_imagen_type_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers
    ADD CONSTRAINT data_type_by_imagen_type_pk PRIMARY KEY (id);


--
-- Name: data_types data_types_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types
    ADD CONSTRAINT data_types_pk PRIMARY KEY (id);


--
-- Name: date_by_process_f2 date_by_process_f2_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_by_process_f2
    ADD CONSTRAINT date_by_process_f2_pk PRIMARY KEY (id);


--
-- Name: db_actions_logs db_actions_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_actions_logs
    ADD CONSTRAINT db_actions_logs_pkey PRIMARY KEY (id);


--
-- Name: declarations_concrete declarations_concrete_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations_concrete
    ADD CONSTRAINT declarations_concrete_pkey PRIMARY KEY (id);


--
-- Name: declarations declarations_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations
    ADD CONSTRAINT declarations_pk PRIMARY KEY (id);


--
-- Name: fields farm_field_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT farm_field_code UNIQUE (farm_id, code);


--
-- Name: farms farms_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_code UNIQUE (code, version_id);


--
-- Name: farms farms_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_pk PRIMARY KEY (id);


--
-- Name: fields fields_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_pk PRIMARY KEY (id);


--
-- Name: format_types format_types_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.format_types
    ADD CONSTRAINT format_types_pk PRIMARY KEY (id);


--
-- Name: functions functions_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions
    ADD CONSTRAINT functions_id_pk PRIMARY KEY (id);


--
-- Name: groups_by_options groups_by_options_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_by_options
    ADD CONSTRAINT groups_by_options_pk PRIMARY KEY (id);


--
-- Name: imagen_types imagen_types_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imagen_types
    ADD CONSTRAINT imagen_types_pk PRIMARY KEY (id);


--
-- Name: import_data import_data_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_data
    ADD CONSTRAINT import_data_pk PRIMARY KEY (id);


--
-- Name: layer_types layer_type_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layer_types
    ADD CONSTRAINT layer_type_pk PRIMARY KEY (id);


--
-- Name: r2_log_activity log_activity_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_log_activity
    ADD CONSTRAINT log_activity_pk PRIMARY KEY (id);


--
-- Name: log_import_fields log_import_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_fields
    ADD CONSTRAINT log_import_fields_pkey PRIMARY KEY (id);


--
-- Name: log_import_images log_import_images_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_images
    ADD CONSTRAINT log_import_images_pk PRIMARY KEY (id);


--
-- Name: log_process_functions log_process_functions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_process_functions
    ADD CONSTRAINT log_process_functions_pk PRIMARY KEY (id);


--
-- Name: maps map_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maps
    ADD CONSTRAINT map_pk PRIMARY KEY (id);


--
-- Name: menu_options menu_option_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_options
    ADD CONSTRAINT menu_option_pk PRIMARY KEY (id);


--
-- Name: organizations organizations_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pk PRIMARY KEY (id);


--
-- Name: parameter_types parameter_types_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameter_types
    ADD CONSTRAINT parameter_types_pk PRIMARY KEY (id);


--
-- Name: parameters parameters_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pk PRIMARY KEY (id);


--
-- Name: pixel pixel_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel
    ADD CONSTRAINT pixel_pk PRIMARY KEY (id);


--
-- Name: pixel_selection_rules pixel_selection_rules_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel_selection_rules
    ADD CONSTRAINT pixel_selection_rules_pk PRIMARY KEY (id);


--
-- Name: pixel_sets pixel_sets_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel_sets
    ADD CONSTRAINT pixel_sets_pk PRIMARY KEY (id);


--
-- Name: process_fields process_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields
    ADD CONSTRAINT process_fields_pkey PRIMARY KEY (id);


--
-- Name: process_functions process_functions_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions
    ADD CONSTRAINT process_functions_id_pk PRIMARY KEY (id);


--
-- Name: process_images process_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_images
    ADD CONSTRAINT process_images_pkey PRIMARY KEY (id);


--
-- Name: process_pixels process_pixels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_pixels
    ADD CONSTRAINT process_pixels_pkey PRIMARY KEY (id);


--
-- Name: process_query_functions process_query_functions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_query_functions
    ADD CONSTRAINT process_query_functions_pk PRIMARY KEY (id);


--
-- Name: process_regions process_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_regions
    ADD CONSTRAINT process_regions_pkey PRIMARY KEY (id);


--
-- Name: process_results process_results_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_id_pk PRIMARY KEY (id);


--
-- Name: projects projects_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pk PRIMARY KEY (id);


--
-- Name: r2_rest_sessions r2_rest_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_rest_sessions
    ADD CONSTRAINT r2_rest_sessions_pkey PRIMARY KEY (id);


--
-- Name: r2_sessions r2_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_sessions
    ADD CONSTRAINT r2_sessions_pkey PRIMARY KEY (id);


--
-- Name: raster_files raster_files_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_files
    ADD CONSTRAINT raster_files_pk PRIMARY KEY (id);


--
-- Name: raster_groups raster_groups_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_groups
    ADD CONSTRAINT raster_groups_pk PRIMARY KEY (id);


--
-- Name: raster_layers raster_layers_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_layers
    ADD CONSTRAINT raster_layers_pk PRIMARY KEY (id);


--
-- Name: regions regions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pk PRIMARY KEY (id);


--
-- Name: results_f2 result_focus2_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f2
    ADD CONSTRAINT result_focus2_pk PRIMARY KEY (id);


--
-- Name: results_f1 results_f1_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f1
    ADD CONSTRAINT results_f1_id_pk PRIMARY KEY (id);


--
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id);


--
-- Name: temporal_expansion_rules temporal_expansion_rules_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_pk PRIMARY KEY (id);


--
-- Name: temporal_expansion_rules temporal_expansion_rules_unique_idx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_unique_idx UNIQUE (region_id, use_declared_id, use_concrete_id, declaration_month);


--
-- Name: tmp_pixel_ids tmp_pixel_ids_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tmp_pixel_ids
    ADD CONSTRAINT tmp_pixel_ids_id_pk PRIMARY KEY (id);


--
-- Name: declarations unique_constraint_date_field_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations
    ADD CONSTRAINT unique_constraint_date_field_id UNIQUE (date, field_id);


--
-- Name: use_concretes use_concretes_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.use_concretes
    ADD CONSTRAINT use_concretes_pk PRIMARY KEY (id);


--
-- Name: use_declareds use_declareds_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.use_declareds
    ADD CONSTRAINT use_declareds_pk PRIMARY KEY (id);


--
-- Name: users_by_groups user_by_groups_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_by_groups
    ADD CONSTRAINT user_by_groups_pk PRIMARY KEY (id);


--
-- Name: user_groups user_groups_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_pk PRIMARY KEY (id);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: versions versions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pk PRIMARY KEY (id);


--
-- Name: declarations_concrete_declaration_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX declarations_concrete_declaration_id_idx ON public.declarations_concrete USING btree (declaration_id);


--
-- Name: declarations_concrete_use_concrete_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX declarations_concrete_use_concrete_id_idx ON public.declarations_concrete USING btree (use_concrete_id);


--
-- Name: farms_version_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX farms_version_id_idx ON public.farms USING btree (version_id);


--
-- Name: field_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX field_idx ON public.results USING btree (field_id);


--
-- Name: fields_farm_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fields_farm_id_idx ON public.fields USING btree (farm_id);


--
-- Name: fields_the_geom_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fields_the_geom_idx ON public.fields USING gist (the_geom);


--
-- Name: fki_clients_to_organizations_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_clients_to_organizations_fk ON public.clients USING btree (organization_id);


--
-- Name: fki_menu_options_to_menu_options_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_menu_options_to_menu_options_fk ON public.menu_options USING btree (parent_id);


--
-- Name: fki_process_functions_map_id_to_maps; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_process_functions_map_id_to_maps ON public.process_functions USING btree (map_id);


--
-- Name: fki_process_functions_to_functions_fkey; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_process_functions_to_functions_fkey ON public.process_functions USING btree (function_id);


--
-- Name: fki_process_regions_to_maps_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_process_regions_to_maps_fk ON public.process_regions USING btree (map_id);


--
-- Name: fki_projects_to_projects_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_projects_to_projects_fk ON public.projects USING btree (parent_id);


--
-- Name: fki_users_to_organizations_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_users_to_organizations_fk ON public.users USING btree (organization_id);


--
-- Name: fki_version_to_projecs_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fki_version_to_projecs_fk ON public.versions USING btree (project_id);


--
-- Name: pixel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pixel_idx ON public.results USING btree (pixel_id);


--
-- Name: pixel_set_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pixel_set_id_idx ON public.pixel USING btree (set_id);


--
-- Name: pixel_sets_imagen_type_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pixel_sets_imagen_type_id_idx ON public.pixel_sets USING btree (imagen_type_id);


--
-- Name: pixel_the_geom_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pixel_the_geom_idx ON public.pixel USING gist (the_geom);


--
-- Name: process_field_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX process_field_id_idx ON public.results USING btree (process_id, field_id);


--
-- Name: process_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX process_idx ON public.results USING btree (process_id);


--
-- Name: process_results_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX process_results_user_id_idx ON public.process_results USING btree (user_id);


--
-- Name: process_results_version_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX process_results_version_id_idx ON public.process_results USING btree (version_id);


--
-- Name: projects_client_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX projects_client_id_idx ON public.projects USING btree (client_id);


--
-- Name: r2_sessions_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX r2_sessions_timestamp ON public.r2_sessions USING btree ("timestamp");


--
-- Name: raster_layers_raster_file_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX raster_layers_raster_file_id_idx ON public.raster_layers USING btree (raster_file_id);


--
-- Name: regions_the_geom_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX regions_the_geom_idx ON public.regions USING gist (the_geom);


--
-- Name: result_f2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX result_f2_idx ON public.results_f2 USING btree (key, process_result_id, process_focus_id, date);


--
-- Name: result_f2_idx2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX result_f2_idx2 ON public.results_f2 USING btree (date, process_result_id);


--
-- Name: result_f2_process_focus_id_process_result_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX result_f2_process_focus_id_process_result_id_idx ON public.results_f2 USING btree (process_focus_id, process_result_id);


--
-- Name: result_f2_process_result_id_process_focus_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX result_f2_process_result_id_process_focus_id_idx ON public.results_f2 USING btree (process_result_id, process_focus_id);


--
-- Name: results_f2_process_result_id_process_focus_id_key_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX results_f2_process_result_id_process_focus_id_key_date_idx ON public.results_f2 USING btree (process_result_id, process_focus_id, key, date);


--
-- Name: results_process_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX results_process_id_idx ON public.results USING btree (process_id);


--
-- Name: results_the_geom_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX results_the_geom_idx ON public.results USING gist (the_geom);


--
-- Name: versions_client_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_client_id_idx ON public.versions USING btree (project_id);


--
-- Name: raster_layers focus_raster_layers_debug_tg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER focus_raster_layers_debug_tg BEFORE UPDATE ON public.raster_layers FOR EACH ROW EXECUTE PROCEDURE log.debug();


--
-- Name: process_query_function_logs process_query_function_logs_process_query_function_id_to_proces; Type: FK CONSTRAINT; Schema: log; Owner: -
--

ALTER TABLE ONLY log.process_query_function_logs
    ADD CONSTRAINT process_query_function_logs_process_query_function_id_to_proces FOREIGN KEY (process_query_function_id) REFERENCES public.process_query_functions(id) ON DELETE CASCADE;


--
-- Name: clients clients_to_organizations_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: concretes_by_declareds concretes_by_declareds_to_use_concretes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_to_use_concretes_id_fkey FOREIGN KEY (concrete_id) REFERENCES public.use_concretes(id) ON DELETE CASCADE;


--
-- Name: concretes_by_declareds concretes_by_declareds_to_use_declareds_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.concretes_by_declareds
    ADD CONSTRAINT concretes_by_declareds_to_use_declareds_id_fkey FOREIGN KEY (declared_id) REFERENCES public.use_declareds(id) ON DELETE CASCADE;


--
-- Name: data_types_by_pixels data_by_pixels_to_data_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types_by_pixels
    ADD CONSTRAINT data_by_pixels_to_data_type_id_fkey FOREIGN KEY (data_type_id) REFERENCES public.data_types(id) ON DELETE CASCADE;


--
-- Name: data_types_by_pixels data_by_pixels_to_pixeles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_types_by_pixels
    ADD CONSTRAINT data_by_pixels_to_pixeles_id_fkey FOREIGN KEY (pixel_id) REFERENCES public.pixel(id) ON DELETE CASCADE;


--
-- Name: layers data_type_by_imagen_type_to_data_types_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers
    ADD CONSTRAINT data_type_by_imagen_type_to_data_types_id_fkey FOREIGN KEY (data_type_id) REFERENCES public.data_types(id) ON DELETE CASCADE;


--
-- Name: layers data_type_by_imagen_type_to_imagen_types_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers
    ADD CONSTRAINT data_type_by_imagen_type_to_imagen_types_id_fkey FOREIGN KEY (imagen_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;


--
-- Name: date_by_process_f2 date_by_process_f2_to_process_functions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.date_by_process_f2
    ADD CONSTRAINT date_by_process_f2_to_process_functions FOREIGN KEY (process_f2_id) REFERENCES public.process_functions(id) ON DELETE CASCADE;


--
-- Name: declarations_concrete declarations_concrete_to_declarations_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations_concrete
    ADD CONSTRAINT declarations_concrete_to_declarations_fk FOREIGN KEY (declaration_id) REFERENCES public.declarations(id) ON DELETE CASCADE;


--
-- Name: declarations_concrete declarations_concrete_to_use_concretes_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations_concrete
    ADD CONSTRAINT declarations_concrete_to_use_concretes_fk FOREIGN KEY (use_concrete_id) REFERENCES public.use_concretes(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: declarations declarations_to_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations
    ADD CONSTRAINT declarations_to_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: declarations declarations_to_use_declared_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.declarations
    ADD CONSTRAINT declarations_to_use_declared_id_fkey FOREIGN KEY (use_declared_id) REFERENCES public.use_declareds(id) ON DELETE CASCADE;


--
-- Name: farms farms_to_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_to_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions(id) ON DELETE CASCADE;


--
-- Name: fields fields_to_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_to_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;


--
-- Name: db_actions_logs fk_db_actions_logs_to_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_actions_logs
    ADD CONSTRAINT fk_db_actions_logs_to_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: functions fk_functions_to_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.functions
    ADD CONSTRAINT fk_functions_to_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: results_f1 fk_results_f1_to_fields; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f1
    ADD CONSTRAINT fk_results_f1_to_fields FOREIGN KEY (field_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: results_f1 fk_results_f1_to_process_results; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f1
    ADD CONSTRAINT fk_results_f1_to_process_results FOREIGN KEY (process_id) REFERENCES public.process_results(id) ON DELETE CASCADE;


--
-- Name: results_f1 fk_results_f1_to_use_concretes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results_f1
    ADD CONSTRAINT fk_results_f1_to_use_concretes FOREIGN KEY (use_concrete_id) REFERENCES public.use_concretes(id) ON DELETE CASCADE;


--
-- Name: groups_by_options groups_by_options_to_menu_option_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_by_options
    ADD CONSTRAINT groups_by_options_to_menu_option_fkey FOREIGN KEY (menu_option_id) REFERENCES public.menu_options(id) ON DELETE CASCADE;


--
-- Name: groups_by_options groups_by_options_to_user_groups_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_by_options
    ADD CONSTRAINT groups_by_options_to_user_groups_id_fkey FOREIGN KEY (user_group_id) REFERENCES public.user_groups(id) ON DELETE CASCADE;


--
-- Name: layer_types layer_types_to_image_types_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layer_types
    ADD CONSTRAINT layer_types_to_image_types_id_fkey FOREIGN KEY (image_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;


--
-- Name: layer_types layer_types_to_parameter_types_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layer_types
    ADD CONSTRAINT layer_types_to_parameter_types_id_fkey FOREIGN KEY (parameter_type_id) REFERENCES public.parameter_types(id) ON DELETE CASCADE;


--
-- Name: log_process_functions log_to_process_process_function_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_process_functions
    ADD CONSTRAINT log_to_process_process_function_id FOREIGN KEY (process_function_id) REFERENCES public.process_functions(id) ON DELETE CASCADE;


--
-- Name: menu_options menu_options_to_menu_options_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menu_options
    ADD CONSTRAINT menu_options_to_menu_options_fk FOREIGN KEY (parent_id) REFERENCES public.menu_options(id) ON DELETE CASCADE;


--
-- Name: parameter_types parameter_types_to_format_types_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameter_types
    ADD CONSTRAINT parameter_types_to_format_types_fk FOREIGN KEY (format_type_id) REFERENCES public.format_types(id) ON DELETE CASCADE;


--
-- Name: parameters parameters_map_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_map_id_fk FOREIGN KEY (map_id) REFERENCES public.maps(id) ON DELETE CASCADE;


--
-- Name: parameters parameters_parameter_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_parameter_type_id_fk FOREIGN KEY (parameter_type_id) REFERENCES public.parameter_types(id) ON DELETE CASCADE;


--
-- Name: parameters parameters_region_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_region_id_fk FOREIGN KEY (region_id) REFERENCES public.regions(id) ON DELETE CASCADE;


--
-- Name: parameters parameters_use_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_use_id_fk FOREIGN KEY (use_id) REFERENCES public.use_concretes(id) ON DELETE CASCADE;


--
-- Name: pixel_sets pixel_sets_to_imagen_types_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel_sets
    ADD CONSTRAINT pixel_sets_to_imagen_types_id FOREIGN KEY (imagen_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;


--
-- Name: pixel pixel_to_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pixel
    ADD CONSTRAINT pixel_to_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_fields process_fields_to_clients_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields
    ADD CONSTRAINT process_fields_to_clients_fk FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: process_fields process_fields_to_projects_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields
    ADD CONSTRAINT process_fields_to_projects_fk FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: process_fields process_fields_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields
    ADD CONSTRAINT process_fields_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: process_fields process_fields_to_versions_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_fields
    ADD CONSTRAINT process_fields_to_versions_fk FOREIGN KEY (version_id) REFERENCES public.versions(id) ON DELETE CASCADE;


--
-- Name: process_functions process_functions_map_id_to_maps; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions
    ADD CONSTRAINT process_functions_map_id_to_maps FOREIGN KEY (map_id) REFERENCES public.maps(id) ON DELETE CASCADE;


--
-- Name: process_functions process_functions_to_functions_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions
    ADD CONSTRAINT process_functions_to_functions_fkey FOREIGN KEY (function_id) REFERENCES public.functions(id) ON DELETE SET NULL;


--
-- Name: process_functions process_functions_to_process_results_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions
    ADD CONSTRAINT process_functions_to_process_results_fkey FOREIGN KEY (process_result_id) REFERENCES public.process_results(id) ON DELETE CASCADE;


--
-- Name: process_functions process_functions_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_functions
    ADD CONSTRAINT process_functions_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: log_import_fields process_id_to_process_fields_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_fields
    ADD CONSTRAINT process_id_to_process_fields_id FOREIGN KEY (process_id) REFERENCES public.process_fields(id) ON DELETE CASCADE;


--
-- Name: log_import_images process_id_to_process_images_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_import_images
    ADD CONSTRAINT process_id_to_process_images_id FOREIGN KEY (process_id) REFERENCES public.process_images(id) ON DELETE CASCADE;


--
-- Name: process_images process_images_raster_file_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_images
    ADD CONSTRAINT process_images_raster_file_id_fk FOREIGN KEY (raster_file_id) REFERENCES public.raster_files(id) ON DELETE CASCADE;


--
-- Name: process_pixels process_pixels_to_pixel_sets_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_pixels
    ADD CONSTRAINT process_pixels_to_pixel_sets_fk FOREIGN KEY (set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_pixels process_pixels_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_pixels
    ADD CONSTRAINT process_pixels_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: process_images process_pixels_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_images
    ADD CONSTRAINT process_pixels_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: process_query_functions process_query_functions_pixel_id_to_pixels; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_query_functions
    ADD CONSTRAINT process_query_functions_pixel_id_to_pixels FOREIGN KEY (pixel_id) REFERENCES public.pixel(id) ON DELETE CASCADE;


--
-- Name: process_regions process_regions_to_maps_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_regions
    ADD CONSTRAINT process_regions_to_maps_fk FOREIGN KEY (map_id) REFERENCES public.maps(id) ON DELETE CASCADE;


--
-- Name: process_results process_results_to_clients_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_clients_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: process_results process_results_to_imagen_types_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_imagen_types_id_fkey FOREIGN KEY (imagen_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;


--
-- Name: process_results process_results_to_pixel_selection_rules_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_pixel_selection_rules_id_fkey FOREIGN KEY (pixel_selection_rules_id) REFERENCES public.pixel_selection_rules(id) ON DELETE SET NULL;


--
-- Name: process_results process_results_to_pixel_sets_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_pixel_sets_id FOREIGN KEY (set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;


--
-- Name: process_results process_results_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: process_results process_results_to_versions_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_results
    ADD CONSTRAINT process_results_to_versions_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions(id) ON DELETE CASCADE;


--
-- Name: projects projects_to_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_to_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: projects projects_to_projects_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_to_projects_fk FOREIGN KEY (parent_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: r2_rest_sessions r2_rest_session_to_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.r2_rest_sessions
    ADD CONSTRAINT r2_rest_session_to_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: raster_files raster_files_image_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_files
    ADD CONSTRAINT raster_files_image_type_id_fk FOREIGN KEY (image_type_id) REFERENCES public.imagen_types(id) ON DELETE CASCADE;


--
-- Name: raster_files raster_files_pixel_set_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_files
    ADD CONSTRAINT raster_files_pixel_set_id_fk FOREIGN KEY (pixel_set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;


--
-- Name: raster_layers raster_layers_layer_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_layers
    ADD CONSTRAINT raster_layers_layer_type_id_fkey FOREIGN KEY (layer_type_id) REFERENCES public.layer_types(id) ON DELETE CASCADE;


--
-- Name: raster_layers raster_layers_raster_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raster_layers
    ADD CONSTRAINT raster_layers_raster_file_id_fkey FOREIGN KEY (raster_file_id) REFERENCES public.raster_files(id) ON DELETE SET NULL;


--
-- Name: regions regions_to_maps_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_to_maps_fk FOREIGN KEY (map_id) REFERENCES public.maps(id) ON DELETE CASCADE;


--
-- Name: regions regions_to_maps_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_to_maps_id_fkey FOREIGN KEY (map_id) REFERENCES public.maps(id) ON DELETE CASCADE;


--
-- Name: results results_to_fields_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_to_fields_fk FOREIGN KEY (field_id) REFERENCES public.fields(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: results results_to_pixel_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_to_pixel_fk FOREIGN KEY (pixel_id) REFERENCES public.pixel(id) ON DELETE CASCADE;


--
-- Name: results results_to_sets_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_to_sets_fk FOREIGN KEY (set_id) REFERENCES public.pixel_sets(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules temporal_expansion_rules_to_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_region_id_fkey FOREIGN KEY (region_id) REFERENCES public.regions(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules temporal_expansion_rules_to_use_concrete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_use_concrete_id_fkey FOREIGN KEY (use_concrete_id) REFERENCES public.use_concretes(id) ON DELETE CASCADE;


--
-- Name: temporal_expansion_rules temporal_expansion_rules_to_use_declared_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporal_expansion_rules
    ADD CONSTRAINT temporal_expansion_rules_to_use_declared_id_fkey FOREIGN KEY (use_declared_id) REFERENCES public.use_declareds(id) ON DELETE CASCADE;


--
-- Name: users_by_groups users_by_groups_to_user_groups_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_by_groups
    ADD CONSTRAINT users_by_groups_to_user_groups_id_fkey FOREIGN KEY (user_group_id) REFERENCES public.user_groups(id) ON DELETE CASCADE;


--
-- Name: users_by_groups users_by_groups_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_by_groups
    ADD CONSTRAINT users_by_groups_to_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_to_organizations_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: versions version_to_projecs_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT version_to_projecs_fk FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: TABLE raster_columns; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.raster_columns TO PUBLIC;


--
-- Name: TABLE raster_overviews; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.raster_overviews TO PUBLIC;


--
-- PostgreSQL database dump complete
--

