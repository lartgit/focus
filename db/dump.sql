/**********
 * Function: log.debug
 */
CREATE OR REPLACE FUNCTION log.debug()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.__st_countagg_transfn
 */
CREATE OR REPLACE FUNCTION public.__st_countagg_transfn(agg agg_count, rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1)
 RETURNS agg_count
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._add_overview_constraint
 */
CREATE OR REPLACE FUNCTION public._add_overview_constraint(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, factor integer)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint(cn name, sql text)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_alignment
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_blocksize
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_coverage_tile
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_extent
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT COST 9000
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_nodata_values
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_num_bands
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_out_db
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_pixel_types
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_scale
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_spatially_unique
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._add_raster_constraint_srid
 */
CREATE OR REPLACE FUNCTION public._add_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._drop_overview_constraint
 */
CREATE OR REPLACE FUNCTION public._drop_overview_constraint(ovschema name, ovtable name, ovcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_overview_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint(rastschema name, rasttable name, cn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._drop_raster_constraint_alignment
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_same_alignment_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_blocksize
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
	BEGIN
		IF lower($4) != 'width' AND lower($4) != 'height' THEN
			RAISE EXCEPTION 'axis must be either "width" or "height"';
			RETURN FALSE;
		END IF;

		RETURN  public._drop_raster_constraint($1, $2, 'enforce_' || $4 || '_' || $3);
	END;
	$function$



/**********
 * Function: public._drop_raster_constraint_coverage_tile
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_coverage_tile_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_extent
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_max_extent_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_nodata_values
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_nodata_values_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_num_bands
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_num_bands_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_out_db
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_out_db_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_pixel_types
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_pixel_types_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_regular_blocking
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_regular_blocking(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT public._drop_raster_constraint($1, $2, 'enforce_regular_blocking_' || $3) $function$



/**********
 * Function: public._drop_raster_constraint_scale
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
	BEGIN
		IF lower($4) != 'x' AND lower($4) != 'y' THEN
			RAISE EXCEPTION 'axis must be either "x" or "y"';
			RETURN FALSE;
		END IF;

		RETURN  public._drop_raster_constraint($1, $2, 'enforce_scale' || $4 || '_' || $3);
	END;
	$function$



/**********
 * Function: public._drop_raster_constraint_spatially_unique
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public._drop_raster_constraint_srid
 */
CREATE OR REPLACE FUNCTION public._drop_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._drop_raster_constraint($1, $2, 'enforce_srid_' || $3) $function$



/**********
 * Function: public._overview_constraint
 */
CREATE OR REPLACE FUNCTION public._overview_constraint(ov raster, factor integer, refschema name, reftable name, refcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$ SELECT COALESCE((SELECT TRUE FROM public.raster_columns WHERE r_table_catalog = current_database() AND r_table_schema = $3 AND r_table_name = $4 AND r_raster_column = $5), FALSE) $function$



/**********
 * Function: public._overview_constraint_info
 */
CREATE OR REPLACE FUNCTION public._overview_constraint_info(ovschema name, ovtable name, ovcolumn name, OUT refschema name, OUT reftable name, OUT refcolumn name, OUT factor integer)
 RETURNS record
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_alignment
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_alignment(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_blocksize
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_blocksize(rastschema name, rasttable name, rastcolumn name, axis text)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_coverage_tile
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_coverage_tile(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_extent
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_extent(rastschema name, rasttable name, rastcolumn name)
 RETURNS geometry
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_index
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_index(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_nodata_values
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_nodata_values(rastschema name, rasttable name, rastcolumn name)
 RETURNS double precision[]
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_num_bands
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_num_bands(rastschema name, rasttable name, rastcolumn name)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_out_db
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_out_db(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean[]
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_pixel_types
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_pixel_types(rastschema name, rasttable name, rastcolumn name)
 RETURNS text[]
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_regular_blocking
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_regular_blocking(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_scale
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_scale(rastschema name, rasttable name, rastcolumn name, axis character)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_spatially_unique
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_spatially_unique(rastschema name, rasttable name, rastcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_info_srid
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_info_srid(rastschema name, rasttable name, rastcolumn name)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._raster_constraint_nodata_values
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_nodata_values(rast raster)
 RETURNS numeric[]
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT array_agg(round(nodatavalue::numeric, 10))::numeric[] FROM public.ST_BandMetaData($1, ARRAY[]::int[]); $function$



/**********
 * Function: public._raster_constraint_out_db
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_out_db(rast raster)
 RETURNS boolean[]
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT array_agg(isoutdb)::boolean[] FROM public.ST_BandMetaData($1, ARRAY[]::int[]); $function$



/**********
 * Function: public._raster_constraint_pixel_types
 */
CREATE OR REPLACE FUNCTION public._raster_constraint_pixel_types(rast raster)
 RETURNS text[]
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT array_agg(pixeltype)::text[] FROM  public.ST_BandMetaData($1, ARRAY[]::int[]); $function$



/**********
 * Function: public._st_aspect4ma
 */
CREATE OR REPLACE FUNCTION public._st_aspect4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_asraster
 */
CREATE OR REPLACE FUNCTION public._st_asraster(geom geometry, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, width integer DEFAULT 0, height integer DEFAULT 0, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_asRaster$function$



/**********
 * Function: public._st_clip
 */
CREATE OR REPLACE FUNCTION public._st_clip(rast raster, nband integer[], geom geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_clip$function$



/**********
 * Function: public._st_colormap
 */
CREATE OR REPLACE FUNCTION public._st_colormap(rast raster, nband integer, colormap text, method text DEFAULT 'INTERPOLATE'::text)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_colorMap$function$



/**********
 * Function: public._st_contains
 */
CREATE OR REPLACE FUNCTION public._st_contains(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_contains$function$



/**********
 * Function: public._st_containsproperly
 */
CREATE OR REPLACE FUNCTION public._st_containsproperly(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_containsProperly$function$



/**********
 * Function: public._st_convertarray4ma
 */
CREATE OR REPLACE FUNCTION public._st_convertarray4ma(value double precision[])
 RETURNS double precision[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._st_count
 */
CREATE OR REPLACE FUNCTION public._st_count(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1)
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
 	$function$



/**********
 * Function: public._st_count
 */
CREATE OR REPLACE FUNCTION public._st_count(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public._st_countagg_finalfn
 */
CREATE OR REPLACE FUNCTION public._st_countagg_finalfn(agg agg_count)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
	BEGIN
		IF agg IS NULL THEN
			RAISE EXCEPTION 'Cannot count coverage';
		END IF;

		RETURN agg.count;
	END;
	$function$



/**********
 * Function: public._st_countagg_transfn
 */
CREATE OR REPLACE FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, exclude_nodata_value boolean)
 RETURNS agg_count
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_countagg_transfn
 */
CREATE OR REPLACE FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, nband integer, exclude_nodata_value boolean)
 RETURNS agg_count
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_countagg_transfn
 */
CREATE OR REPLACE FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision)
 RETURNS agg_count
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_coveredby
 */
CREATE OR REPLACE FUNCTION public._st_coveredby(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_coveredby$function$



/**********
 * Function: public._st_covers
 */
CREATE OR REPLACE FUNCTION public._st_covers(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_covers$function$



/**********
 * Function: public._st_dfullywithin
 */
CREATE OR REPLACE FUNCTION public._st_dfullywithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_dfullywithin$function$



/**********
 * Function: public._st_dwithin
 */
CREATE OR REPLACE FUNCTION public._st_dwithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_dwithin$function$



/**********
 * Function: public._st_gdalwarp
 */
CREATE OR REPLACE FUNCTION public._st_gdalwarp(rast raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, srid integer DEFAULT NULL::integer, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, width integer DEFAULT NULL::integer, height integer DEFAULT NULL::integer)
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_GDALWarp$function$



/**********
 * Function: public._st_hillshade4ma
 */
CREATE OR REPLACE FUNCTION public._st_hillshade4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_histogram
 */
CREATE OR REPLACE FUNCTION public._st_histogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_histogramCoverage$function$



/**********
 * Function: public._st_histogram
 */
CREATE OR REPLACE FUNCTION public._st_histogram(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, min double precision DEFAULT NULL::double precision, max double precision DEFAULT NULL::double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_histogram$function$



/**********
 * Function: public._st_intersects
 */
CREATE OR REPLACE FUNCTION public._st_intersects(geom geometry, rast raster, nband integer DEFAULT NULL::integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$
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
	$function$



/**********
 * Function: public._st_intersects
 */
CREATE OR REPLACE FUNCTION public._st_intersects(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_intersects$function$



/**********
 * Function: public._st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public._st_mapalgebra(rastbandargset rastbandarg[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, distancex integer DEFAULT 0, distancey integer DEFAULT 0, extenttype text DEFAULT 'INTERSECTION'::text, customextent raster DEFAULT NULL::raster, mask double precision[] DEFAULT NULL::double precision[], weighted boolean DEFAULT NULL::boolean, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_nMapAlgebra$function$



/**********
 * Function: public._st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public._st_mapalgebra(rastbandargset rastbandarg[], expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_nMapAlgebraExpr$function$



/**********
 * Function: public._st_neighborhood
 */
CREATE OR REPLACE FUNCTION public._st_neighborhood(rast raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_neighborhood$function$



/**********
 * Function: public._st_overlaps
 */
CREATE OR REPLACE FUNCTION public._st_overlaps(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_overlaps$function$



/**********
 * Function: public._st_pixelaspolygons
 */
CREATE OR REPLACE FUNCTION public._st_pixelaspolygons(rast raster, band integer DEFAULT 1, columnx integer DEFAULT NULL::integer, rowy integer DEFAULT NULL::integer, exclude_nodata_value boolean DEFAULT true, OUT geom geometry, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_getPixelPolygons$function$



/**********
 * Function: public._st_quantile
 */
CREATE OR REPLACE FUNCTION public._st_quantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_quantileCoverage$function$



/**********
 * Function: public._st_quantile
 */
CREATE OR REPLACE FUNCTION public._st_quantile(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_quantile$function$



/**********
 * Function: public._st_rastertoworldcoord
 */
CREATE OR REPLACE FUNCTION public._st_rastertoworldcoord(rast raster, columnx integer DEFAULT NULL::integer, rowy integer DEFAULT NULL::integer, OUT longitude double precision, OUT latitude double precision)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_rasterToWorldCoord$function$



/**********
 * Function: public._st_reclass
 */
CREATE OR REPLACE FUNCTION public._st_reclass(rast raster, VARIADIC reclassargset reclassarg[])
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_reclass$function$



/**********
 * Function: public._st_roughness4ma
 */
CREATE OR REPLACE FUNCTION public._st_roughness4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_samealignment_finalfn
 */
CREATE OR REPLACE FUNCTION public._st_samealignment_finalfn(agg agg_samealignment)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT $1.aligned $function$



/**********
 * Function: public._st_samealignment_transfn
 */
CREATE OR REPLACE FUNCTION public._st_samealignment_transfn(agg agg_samealignment, rast raster)
 RETURNS agg_samealignment
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_setvalues
 */
CREATE OR REPLACE FUNCTION public._st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[] DEFAULT NULL::boolean[], hasnosetvalue boolean DEFAULT false, nosetvalue double precision DEFAULT NULL::double precision, keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_setPixelValuesArray$function$



/**********
 * Function: public._st_slope4ma
 */
CREATE OR REPLACE FUNCTION public._st_slope4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_summarystats
 */
CREATE OR REPLACE FUNCTION public._st_summarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1)
 RETURNS summarystats
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$ 
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
	$function$



/**********
 * Function: public._st_summarystats
 */
CREATE OR REPLACE FUNCTION public._st_summarystats(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 1)
 RETURNS summarystats
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_summaryStats$function$



/**********
 * Function: public._st_summarystats_finalfn
 */
CREATE OR REPLACE FUNCTION public._st_summarystats_finalfn(internal)
 RETURNS summarystats
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_summaryStats_finalfn$function$



/**********
 * Function: public._st_summarystats_transfn
 */
CREATE OR REPLACE FUNCTION public._st_summarystats_transfn(internal, raster, boolean, double precision)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_summaryStats_transfn$function$



/**********
 * Function: public._st_summarystats_transfn
 */
CREATE OR REPLACE FUNCTION public._st_summarystats_transfn(internal, raster, integer, boolean, double precision)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_summaryStats_transfn$function$



/**********
 * Function: public._st_summarystats_transfn
 */
CREATE OR REPLACE FUNCTION public._st_summarystats_transfn(internal, raster, integer, boolean)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_summaryStats_transfn$function$



/**********
 * Function: public._st_tile
 */
CREATE OR REPLACE FUNCTION public._st_tile(rast raster, width integer, height integer, nband integer[] DEFAULT NULL::integer[], padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision)
 RETURNS SETOF raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_tile$function$



/**********
 * Function: public._st_touches
 */
CREATE OR REPLACE FUNCTION public._st_touches(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 1000
AS '$libdir/rtpostgis-2.3', $function$RASTER_touches$function$



/**********
 * Function: public._st_tpi4ma
 */
CREATE OR REPLACE FUNCTION public._st_tpi4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_tri4ma
 */
CREATE OR REPLACE FUNCTION public._st_tri4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public._st_union_finalfn
 */
CREATE OR REPLACE FUNCTION public._st_union_finalfn(internal)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_finalfn$function$



/**********
 * Function: public._st_union_transfn
 */
CREATE OR REPLACE FUNCTION public._st_union_transfn(internal, raster, integer)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_transfn$function$



/**********
 * Function: public._st_union_transfn
 */
CREATE OR REPLACE FUNCTION public._st_union_transfn(internal, raster, integer, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_transfn$function$



/**********
 * Function: public._st_union_transfn
 */
CREATE OR REPLACE FUNCTION public._st_union_transfn(internal, raster)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_transfn$function$



/**********
 * Function: public._st_union_transfn
 */
CREATE OR REPLACE FUNCTION public._st_union_transfn(internal, raster, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_transfn$function$



/**********
 * Function: public._st_union_transfn
 */
CREATE OR REPLACE FUNCTION public._st_union_transfn(internal, raster, unionarg[])
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_union_transfn$function$



/**********
 * Function: public._st_valuecount
 */
CREATE OR REPLACE FUNCTION public._st_valuecount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_valueCountCoverage$function$



/**********
 * Function: public._st_valuecount
 */
CREATE OR REPLACE FUNCTION public._st_valuecount(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_valueCount$function$



/**********
 * Function: public._st_within
 */
CREATE OR REPLACE FUNCTION public._st_within(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public._st_contains($3, $4, $1, $2) $function$



/**********
 * Function: public._st_worldtorastercoord
 */
CREATE OR REPLACE FUNCTION public._st_worldtorastercoord(rast raster, longitude double precision DEFAULT NULL::double precision, latitude double precision DEFAULT NULL::double precision, OUT columnx integer, OUT rowy integer)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_worldToRasterCoord$function$



/**********
 * Function: public._updaterastersrid
 */
CREATE OR REPLACE FUNCTION public._updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
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
	$function$



/**********
 * Function: public.addoverviewconstraints
 */
CREATE OR REPLACE FUNCTION public.addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION addoverviewconstraints(name,name,name,name,name,name,integer) IS 'args: ovschema, ovtable, ovcolumn, refschema, reftable, refcolumn, ovfactor - Tag a raster column as being an overview of another.'

/**********
 * Function: public.addoverviewconstraints
 */
CREATE OR REPLACE FUNCTION public.addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public.AddOverviewConstraints('', $1, $2, '', $3, $4, $5) $function$

COMMENT ON FUNCTION addoverviewconstraints(name,name,name,name,integer) IS 'args: ovtable, ovcolumn, reftable, refcolumn, ovfactor - Tag a raster column as being an overview of another.'

/**********
 * Function: public.addrasterconstraints
 */
CREATE OR REPLACE FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT false, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION addrasterconstraints(name,name,name,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) IS 'args: rastschema, rasttable, rastcolumn, srid=true, scale_x=true, scale_y=true, blocksize_x=true, blocksize_y=true, same_alignment=true, regular_blocking=false, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.'

/**********
 * Function: public.addrasterconstraints
 */
CREATE OR REPLACE FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[])
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION addrasterconstraints(name,name,name,text[]) IS 'args: rastschema, rasttable, rastcolumn, VARIADIC constraints - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.'

/**********
 * Function: public.addrasterconstraints
 */
CREATE OR REPLACE FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT false, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT public.AddRasterConstraints('', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) $function$

COMMENT ON FUNCTION addrasterconstraints(name,name,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) IS 'args: rasttable, rastcolumn, srid, scale_x, scale_y, blocksize_x, blocksize_y, same_alignment, regular_blocking, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.'

/**********
 * Function: public.addrasterconstraints
 */
CREATE OR REPLACE FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[])
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT public.AddRasterConstraints('', $1, $2, VARIADIC $3) $function$

COMMENT ON FUNCTION addrasterconstraints(name,name,text[]) IS 'args: rasttable, rastcolumn, VARIADIC constraints - Adds raster constraints to a loaded raster table for a specific column that constrains spatial ref, scaling, blocksize, alignment, bands, band type and a flag to denote if raster column is regularly blocked. The table must be loaded with data for the constraints to be inferred. Returns true of the constraint setting was accomplished and if issues a notice.'

/**********
 * Function: public.box3d
 */
CREATE OR REPLACE FUNCTION public.box3d(raster)
 RETURNS box3d
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select box3d( public.ST_convexhull($1))$function$



/**********
 * Function: public.bytea
 */
CREATE OR REPLACE FUNCTION public.bytea(raster)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_to_bytea$function$



/**********
 * Function: public.dropoverviewconstraints
 */
CREATE OR REPLACE FUNCTION public.dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION dropoverviewconstraints(name,name,name) IS 'args: ovschema, ovtable, ovcolumn - Untag a raster column from being an overview of another.'

/**********
 * Function: public.dropoverviewconstraints
 */
CREATE OR REPLACE FUNCTION public.dropoverviewconstraints(ovtable name, ovcolumn name)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public.DropOverviewConstraints('', $1, $2) $function$

COMMENT ON FUNCTION dropoverviewconstraints(name,name) IS 'args: ovtable, ovcolumn - Untag a raster column from being an overview of another.'

/**********
 * Function: public.droprasterconstraints
 */
CREATE OR REPLACE FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT true, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION droprasterconstraints(name,name,name,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) IS 'args: rastschema, rasttable, rastcolumn, srid=true, scale_x=true, scale_y=true, blocksize_x=true, blocksize_y=true, same_alignment=true, regular_blocking=false, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.'

/**********
 * Function: public.droprasterconstraints
 */
CREATE OR REPLACE FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[])
 RETURNS boolean
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION droprasterconstraints(name,name,name,text[]) IS 'args: rastschema, rasttable, rastcolumn, constraints - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.'

/**********
 * Function: public.droprasterconstraints
 */
CREATE OR REPLACE FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, srid boolean DEFAULT true, scale_x boolean DEFAULT true, scale_y boolean DEFAULT true, blocksize_x boolean DEFAULT true, blocksize_y boolean DEFAULT true, same_alignment boolean DEFAULT true, regular_blocking boolean DEFAULT true, num_bands boolean DEFAULT true, pixel_types boolean DEFAULT true, nodata_values boolean DEFAULT true, out_db boolean DEFAULT true, extent boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT DropRasterConstraints('', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) $function$

COMMENT ON FUNCTION droprasterconstraints(name,name,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) IS 'args: rasttable, rastcolumn, srid, scale_x, scale_y, blocksize_x, blocksize_y, same_alignment, regular_blocking, num_bands=true, pixel_types=true, nodata_values=true, out_db=true, extent=true - Drops PostGIS raster constraints that refer to a raster table column. Useful if you need to reload data or update your raster column data.'

/**********
 * Function: public.droprasterconstraints
 */
CREATE OR REPLACE FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[])
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public.DropRasterConstraints('', $1, $2, VARIADIC $3) $function$



/**********
 * Function: public.extract_days
 */
CREATE OR REPLACE FUNCTION public.extract_days(daterange)
 RETURNS integer
 LANGUAGE sql
AS $function$
    SELECT UPPER($1) - LOWER($1);
$function$



/**********
 * Function: public.extract_days
 */
CREATE OR REPLACE FUNCTION public.extract_days(tsrange)
 RETURNS integer
 LANGUAGE sql
AS $function$
    SELECT (date_trunc('day',UPPER($1))::DATE - date_trunc('day',LOWER($1))::DATE) + 1;
$function$



/**********
 * Function: public.focus_abs_diff
 */
CREATE OR REPLACE FUNCTION public.focus_abs_diff(image_date date, query_date date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_cast_to_double
 */
CREATE OR REPLACE FUNCTION public.focus_cast_to_double(v_input text)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_garbagetodouble
 */
CREATE OR REPLACE FUNCTION public.focus_garbagetodouble(arg_garbage character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_evi_quality
 */
CREATE OR REPLACE FUNCTION public.focus_get_evi_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_evi_quality_raw
 */
CREATE OR REPLACE FUNCTION public.focus_get_evi_quality_raw(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_ndvi_quality
 */
CREATE OR REPLACE FUNCTION public.focus_get_ndvi_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_ndvi_quality_raw
 */
CREATE OR REPLACE FUNCTION public.focus_get_ndvi_quality_raw(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_parameter
 */
CREATE OR REPLACE FUNCTION public.focus_get_parameter(arg_parameter_name text, pixel_date date, param_use_id integer, param_region_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_get_quality
 */
CREATE OR REPLACE FUNCTION public.focus_get_quality(arg_map_id integer, arg_use_id integer, arg_pixel_id integer, arg_date timestamp without time zone)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.focus_process_raster
 */
CREATE OR REPLACE FUNCTION public.focus_process_raster(arg_rast character varying, arg_tmp_table regclass, arg_raster_layer_id integer, arg_s_srid integer DEFAULT 9001, arg_scale_factor double precision DEFAULT 1.0, arg_offset_value double precision DEFAULT 0.0)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN

        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect)
               SELECT p.id AS pixel_id, %s, r.val * %s + %s, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area 
               FROM ST_PixelAsPolygons(''%s''::raster) r 
               JOIN pixel p on St_intersects(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)
                           AND              (ST_Transform(St_SetSRID(r.geom, %s), 4326) && p.the_geom);', arg_tmp_table, arg_raster_layer_id, arg_scale_factor, arg_offset_value, arg_s_srid, arg_rast, arg_s_srid, arg_s_srid);

    RETURN 'Processed pixels';
END;
$function$



/**********
 * Function: public.focus_process_raster_modis
 */
CREATE OR REPLACE FUNCTION public.focus_process_raster_modis(arg_rast character varying, arg_tmp_table regclass, arg_raster_layer_id integer, arg_s_srid integer DEFAULT 9001, arg_scale_factor double precision DEFAULT 1.0, arg_offset_value double precision DEFAULT 0.0)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
        EXECUTE format('INSERT INTO %s (pixel_id, raster_layer_id, value, perc_insersect) SELECT p.id AS pixel_id, %s, r.val * %s + %s, ST_Area(St_intersection(ST_Transform(St_SetSRID(r.geom, %s), 4326), p.the_geom)) / ST_Area(p.the_geom) as perc_area 
  FROM ST_PixelAsPolygons(''%s''::raster) r 
               JOIN pixel p on St_intersects(ST_Centroid(ST_Transform(St_SetSRID(r.geom, %s), 4326)), p.the_geom)
                           AND              (ST_Centroid(ST_Transform(St_SetSRID(r.geom, %s), 4326)) && p.the_geom);', arg_tmp_table, arg_raster_layer_id, arg_scale_factor, arg_offset_value, arg_s_srid, arg_rast, arg_s_srid, arg_s_srid);
  
    RETURN 'Processed pixels';
END;
$function$



/**********
 * Function: public.focus_upsert_result2
 */
CREATE OR REPLACE FUNCTION public.focus_upsert_result2(param_key character varying, param_process_result_id integer, param_process_focus_2_id integer, param_value character varying, param_date timestamp without time zone)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.geometry_contained_by_raster
 */
CREATE OR REPLACE FUNCTION public.geometry_contained_by_raster(geometry, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1 @ $2::geometry$function$



/**********
 * Function: public.geometry_raster_contain
 */
CREATE OR REPLACE FUNCTION public.geometry_raster_contain(geometry, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1 ~ $2::geometry$function$



/**********
 * Function: public.geometry_raster_overlap
 */
CREATE OR REPLACE FUNCTION public.geometry_raster_overlap(geometry, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1 OPERATOR(public.&&) $2::geometry$function$



/**********
 * Function: public.get_parameter
 */
CREATE OR REPLACE FUNCTION public.get_parameter(arg_parameter_name text, pixel_date date, param_use_id integer, param_region_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
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
$function$



/**********
 * Function: public.postgis_gdal_version
 */
CREATE OR REPLACE FUNCTION public.postgis_gdal_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_gdal_version$function$

COMMENT ON FUNCTION postgis_gdal_version() IS 'Reports the version of the GDAL library in use by PostGIS.'

/**********
 * Function: public.postgis_noop
 */
CREATE OR REPLACE FUNCTION public.postgis_noop(raster)
 RETURNS geometry
 LANGUAGE c
 STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_noop$function$



/**********
 * Function: public.postgis_raster_lib_build_date
 */
CREATE OR REPLACE FUNCTION public.postgis_raster_lib_build_date()
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_lib_build_date$function$

COMMENT ON FUNCTION postgis_raster_lib_build_date() IS 'Reports full raster library build date.'

/**********
 * Function: public.postgis_raster_lib_version
 */
CREATE OR REPLACE FUNCTION public.postgis_raster_lib_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_lib_version$function$

COMMENT ON FUNCTION postgis_raster_lib_version() IS 'Reports full raster version and build configuration infos.'

/**********
 * Function: public.postgis_raster_scripts_installed
 */
CREATE OR REPLACE FUNCTION public.postgis_raster_scripts_installed()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT '2.3.1'::text || ' r' || 15264::text AS version $function$



/**********
 * Function: public.r2_geomcollection_to_multipolygon_by_area
 */
CREATE OR REPLACE FUNCTION public.r2_geomcollection_to_multipolygon_by_area(geom geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public.r2_multipolygon_to_polygon_by_area
 */
CREATE OR REPLACE FUNCTION public.r2_multipolygon_to_polygon_by_area(geom geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 STRICT
AS $function$
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
	$function$



/**********
 * Function: public.raster_above
 */
CREATE OR REPLACE FUNCTION public.raster_above(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry |>> $2::geometry$function$



/**********
 * Function: public.raster_below
 */
CREATE OR REPLACE FUNCTION public.raster_below(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry <<| $2::geometry$function$



/**********
 * Function: public.raster_contain
 */
CREATE OR REPLACE FUNCTION public.raster_contain(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry ~ $2::geometry$function$



/**********
 * Function: public.raster_contained
 */
CREATE OR REPLACE FUNCTION public.raster_contained(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry @ $2::geometry$function$



/**********
 * Function: public.raster_contained_by_geometry
 */
CREATE OR REPLACE FUNCTION public.raster_contained_by_geometry(raster, geometry)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry @ $2$function$



/**********
 * Function: public.raster_eq
 */
CREATE OR REPLACE FUNCTION public.raster_eq(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.raster_hash($1) = public.raster_hash($2) $function$



/**********
 * Function: public.raster_geometry_contain
 */
CREATE OR REPLACE FUNCTION public.raster_geometry_contain(raster, geometry)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry ~ $2$function$



/**********
 * Function: public.raster_geometry_overlap
 */
CREATE OR REPLACE FUNCTION public.raster_geometry_overlap(raster, geometry)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry OPERATOR(public.&&) $2$function$



/**********
 * Function: public.raster_hash
 */
CREATE OR REPLACE FUNCTION public.raster_hash(raster)
 RETURNS integer
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$hashvarlena$function$



/**********
 * Function: public.raster_in
 */
CREATE OR REPLACE FUNCTION public.raster_in(cstring)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_in$function$



/**********
 * Function: public.raster_left
 */
CREATE OR REPLACE FUNCTION public.raster_left(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry << $2::geometry$function$



/**********
 * Function: public.raster_out
 */
CREATE OR REPLACE FUNCTION public.raster_out(raster)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_out$function$



/**********
 * Function: public.raster_overabove
 */
CREATE OR REPLACE FUNCTION public.raster_overabove(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry |&> $2::geometry$function$



/**********
 * Function: public.raster_overbelow
 */
CREATE OR REPLACE FUNCTION public.raster_overbelow(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry &<| $2::geometry$function$



/**********
 * Function: public.raster_overlap
 */
CREATE OR REPLACE FUNCTION public.raster_overlap(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry OPERATOR(public.&&) $2::geometry$function$



/**********
 * Function: public.raster_overleft
 */
CREATE OR REPLACE FUNCTION public.raster_overleft(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::public.geometry &< $2::public.geometry$function$



/**********
 * Function: public.raster_overright
 */
CREATE OR REPLACE FUNCTION public.raster_overright(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::public.geometry &> $2::public.geometry$function$



/**********
 * Function: public.raster_right
 */
CREATE OR REPLACE FUNCTION public.raster_right(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry >> $2::geometry$function$



/**********
 * Function: public.raster_same
 */
CREATE OR REPLACE FUNCTION public.raster_same(raster, raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select $1::geometry ~= $2::geometry$function$



/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(rast raster, addbandargset addbandarg[])
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_addBand$function$

COMMENT ON FUNCTION st_addband(raster,addbandarg[]) IS 'args: rast, addbandargset - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(rast raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_addBandOutDB$function$

COMMENT ON FUNCTION st_addband(raster,integer,text,integer[],double precision) IS 'args: rast, index, outdbfile, outdbindex, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(rast raster, index integer, pixeltype text, initialvalue double precision DEFAULT '0'::numeric, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT  public.ST_addband($1, ARRAY[ROW($2, $3, $4, $5)]::addbandarg[]) $function$

COMMENT ON FUNCTION st_addband(raster,integer,text,double precision,double precision) IS 'args: rast, index, pixeltype, initialvalue=0, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(rast raster, outdbfile text, outdbindex integer[], index integer DEFAULT NULL::integer, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_AddBand($1, $4, $2, $3, $5) $function$

COMMENT ON FUNCTION st_addband(raster,text,integer[],integer,double precision) IS 'args: rast, outdbfile, outdbindex, index=at_end, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(rast raster, pixeltype text, initialvalue double precision DEFAULT '0'::numeric, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT  public.ST_addband($1, ARRAY[ROW(NULL, $2, $3, $4)]::addbandarg[]) $function$

COMMENT ON FUNCTION st_addband(raster,text,double precision,double precision) IS 'args: rast, pixeltype, initialvalue=0, nodataval=NULL - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(torast raster, fromrast raster, fromband integer DEFAULT 1, torastindex integer DEFAULT NULL::integer)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_copyBand$function$

COMMENT ON FUNCTION st_addband(raster,raster,integer,integer) IS 'args: torast, fromrast, fromband=1, torastindex=at_end - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_addband
 */
CREATE OR REPLACE FUNCTION public.st_addband(torast raster, fromrasts raster[], fromband integer DEFAULT 1, torastindex integer DEFAULT NULL::integer)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_addBandRasterArray$function$

COMMENT ON FUNCTION st_addband(raster,raster[],integer,integer) IS 'args: torast, fromrasts, fromband=1, torastindex=at_end - Returns a raster with the new band(s) of given type added with given initial value in the given index location. If no index is specified, the band is added to the end.'

/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, 1, $3, $4) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, $3, $4, $5) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, nband integer, sample_percent double precision)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, $3, TRUE, $4) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rastertable text, rastercolumn text, sample_percent double precision)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, 1, TRUE, $3) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rast raster, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, 1, $2, $3) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, $2, $3, $4) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rast raster, nband integer, sample_percent double precision)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, $2, TRUE, $3) $function$



/**********
 * Function: public.st_approxcount
 */
CREATE OR REPLACE FUNCTION public.st_approxcount(rast raster, sample_percent double precision)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, 1, TRUE, $2) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_histogram($1, $2, $3, $4, $5, $6, $7, $8) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, $4, $5, $6, NULL, $7) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, $5, NULL, $6) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, $5, $6, $7) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, nband integer, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, TRUE, $4, 0, NULL, FALSE) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rastertable text, rastercolumn text, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, 1, TRUE, $3, 0, NULL, FALSE) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, $4, $5, $6, $7) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, $4, $5, NULL, $6) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, $4, NULL, $5) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, $4, $5, $6) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, $3, 0, NULL, FALSE) $function$



/**********
 * Function: public.st_approxhistogram
 */
CREATE OR REPLACE FUNCTION public.st_approxhistogram(rast raster, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, 1, TRUE, $2, 0, NULL, FALSE) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE
AS $function$ SELECT ( public._ST_quantile($1, $2, 1, $3, 0.1, ARRAY[$4]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_quantile($1, $2, $3, $4, $5, $6) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, $4, $5, ARRAY[$6]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, TRUE, $4, ARRAY[$5]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, nband integer, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_quantile($1, $2, $3, TRUE, $4, $5) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE
AS $function$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, 0.1, ARRAY[$3]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_quantile($1, $2, 1, TRUE, 0.1, $3) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, $3, ARRAY[$4]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rastertable text, rastercolumn text, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_quantile($1, $2, 1, TRUE, $3, $4) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ( public._ST_quantile($1, 1, $2, 0.1, ARRAY[$3]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_quantile($1, $2, $3, $4, $5) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, $4, ARRAY[$5]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, nband integer, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, TRUE, $3, ARRAY[$4]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, nband integer, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_quantile($1, $2, TRUE, $3, $4) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ( public._ST_quantile($1, 1, TRUE, 0.1, ARRAY[$2]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_quantile($1, 1, TRUE, 0.1, $2) $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, sample_percent double precision, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, 1, TRUE, $2, ARRAY[$3]::double precision[])).value $function$



/**********
 * Function: public.st_approxquantile
 */
CREATE OR REPLACE FUNCTION public.st_approxquantile(rast raster, sample_percent double precision, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_quantile($1, 1, TRUE, $2, $3) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, 1, $3, 0.1) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, $3, $4, $5) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, nband integer, sample_percent double precision)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, $3, TRUE, $4) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rastertable text, rastercolumn text, sample_percent double precision)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, 1, TRUE, $3) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rast raster, exclude_nodata_value boolean, sample_percent double precision DEFAULT 0.1)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, 1, $2, $3) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, sample_percent double precision DEFAULT 0.1)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, $3, $4) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rast raster, nband integer, sample_percent double precision)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, TRUE, $3) $function$



/**********
 * Function: public.st_approxsummarystats
 */
CREATE OR REPLACE FUNCTION public.st_approxsummarystats(rast raster, sample_percent double precision)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, 1, TRUE, $2) $function$



/**********
 * Function: public.st_asbinary
 */
CREATE OR REPLACE FUNCTION public.st_asbinary(raster, outasin boolean DEFAULT false)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_to_binary$function$

COMMENT ON FUNCTION st_asbinary(raster,boolean) IS 'args: rast, outasin=FALSE - Return the Well-Known Binary (WKB) representation of the raster without SRID meta data.'

/**********
 * Function: public.st_asgdalraster
 */
CREATE OR REPLACE FUNCTION public.st_asgdalraster(rast raster, format text, options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_asGDALRaster$function$

COMMENT ON FUNCTION st_asgdalraster(raster,text,text[],integer) IS 'args: rast, format, options=NULL, srid=sameassource - Return the raster tile in the designated GDAL Raster format. Raster formats are one of those supported by your compiled library. Use ST_GDALRasters() to get a list of formats supported by your library.'

/**********
 * Function: public.st_asjpeg
 */
CREATE OR REPLACE FUNCTION public.st_asjpeg(rast raster, nband integer, options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_asjpeg(st_band($1, $2), $3) $function$

COMMENT ON FUNCTION st_asjpeg(raster,integer,text[]) IS 'args: rast, nband, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.'

/**********
 * Function: public.st_asjpeg
 */
CREATE OR REPLACE FUNCTION public.st_asjpeg(rast raster, nband integer, quality integer)
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_asjpeg($1, ARRAY[$2], $3) $function$

COMMENT ON FUNCTION st_asjpeg(raster,integer,integer) IS 'args: rast, nband, quality - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.'

/**********
 * Function: public.st_asjpeg
 */
CREATE OR REPLACE FUNCTION public.st_asjpeg(rast raster, nbands integer[], options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_asjpeg(st_band($1, $2), $3) $function$

COMMENT ON FUNCTION st_asjpeg(raster,integer[],text[]) IS 'args: rast, nbands, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.'

/**********
 * Function: public.st_asjpeg
 */
CREATE OR REPLACE FUNCTION public.st_asjpeg(rast raster, nbands integer[], quality integer)
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_asjpeg(raster,integer[],integer) IS 'args: rast, nbands, quality - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.'

/**********
 * Function: public.st_asjpeg
 */
CREATE OR REPLACE FUNCTION public.st_asjpeg(rast raster, options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$

COMMENT ON FUNCTION st_asjpeg(raster,text[]) IS 'args: rast, options=NULL - Return the raster tile selected bands as a single Joint Photographic Exports Group (JPEG) image (byte array). If no band is specified and 1 or more than 3 bands, then only the first band is used. If only 3 bands then all 3 bands are used and mapped to RGB.'

/**********
 * Function: public.st_aspect
 */
CREATE OR REPLACE FUNCTION public.st_aspect(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_aspect
 */
CREATE OR REPLACE FUNCTION public.st_aspect(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_aspect($1, $2, NULL::raster, $3, $4, $5) $function$



/**********
 * Function: public.st_aspng
 */
CREATE OR REPLACE FUNCTION public.st_aspng(rast raster, nband integer, compression integer)
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_aspng($1, ARRAY[$2], $3) $function$

COMMENT ON FUNCTION st_aspng(raster,integer,integer) IS 'args: rast, nband, compression - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.'

/**********
 * Function: public.st_aspng
 */
CREATE OR REPLACE FUNCTION public.st_aspng(rast raster, nband integer, options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_aspng(st_band($1, $2), $3) $function$

COMMENT ON FUNCTION st_aspng(raster,integer,text[]) IS 'args: rast, nband, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.'

/**********
 * Function: public.st_aspng
 */
CREATE OR REPLACE FUNCTION public.st_aspng(rast raster, nbands integer[], compression integer)
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_aspng(raster,integer[],integer) IS 'args: rast, nbands, compression - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.'

/**********
 * Function: public.st_aspng
 */
CREATE OR REPLACE FUNCTION public.st_aspng(rast raster, nbands integer[], options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_aspng(st_band($1, $2), $3) $function$

COMMENT ON FUNCTION st_aspng(raster,integer[],text[]) IS 'args: rast, nbands, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.'

/**********
 * Function: public.st_aspng
 */
CREATE OR REPLACE FUNCTION public.st_aspng(rast raster, options text[] DEFAULT NULL::text[])
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$

COMMENT ON FUNCTION st_aspng(raster,text[]) IS 'args: rast, options=NULL - Return the raster tile selected bands as a single portable network graphics (PNG) image (byte array). If 1, 3, or 4 bands in raster and no bands are specified, then all bands are used. If more 2 or more than 4 bands and no bands specified, then only band 1 is used. Bands are mapped to RGB or RGBA space.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, ref raster, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 STABLE
AS $function$
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
	$function$

COMMENT ON FUNCTION st_asraster(geometry,raster,text[],double precision[],double precision[],boolean) IS 'args: geom, ref, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, ref raster, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT  public.ST_AsRaster($1, $2, ARRAY[$3]::text[], ARRAY[$4]::double precision[], ARRAY[$5]::double precision[], $6) $function$

COMMENT ON FUNCTION st_asraster(geometry,raster,text,double precision,double precision,boolean) IS 'args: geom, ref, pixeltype, value=1, nodataval=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, $6, $7, $8, NULL, NULL, $4, $5, $9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,double precision,double precision,double precision,double precision,text[],double precision[],double precision[],double precision,double precision,boolean) IS 'args: geom, scalex, scaley, gridx=NULL, gridy=NULL, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, ARRAY[$6]::text[], ARRAY[$7]::double precision[], ARRAY[$8]::double precision[], NULL, NULL, $4, $5, $9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,double precision,double precision,double precision,double precision,text,double precision,double precision,double precision,double precision,boolean) IS 'args: geom, scalex, scaley, gridx, gridy, pixeltype, value=1, nodataval=0, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, ARRAY[$4]::text[], ARRAY[$5]::double precision[], ARRAY[$6]::double precision[], $7, $8, NULL, NULL, $9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,double precision,double precision,text,double precision,double precision,double precision,double precision,double precision,double precision,boolean) IS 'args: geom, scalex, scaley, pixeltype, value=1, nodataval=0, upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, $2, $3, NULL, NULL, $4, $5, $6, $7, $8, NULL, NULL,	$9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,double precision,double precision,text[],double precision[],double precision[],double precision,double precision,double precision,double precision,boolean) IS 'args: geom, scalex, scaley, pixeltype, value=ARRAY[1], nodataval=ARRAY[0], upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, width integer, height integer, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, pixeltype text[] DEFAULT ARRAY['8BUI'::text], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, $6, $7, $8, NULL, NULL, $4, $5, $9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,integer,integer,double precision,double precision,text[],double precision[],double precision[],double precision,double precision,boolean) IS 'args: geom, width, height, gridx=NULL, gridy=NULL, pixeltype=ARRAY[''8BUI''], value=ARRAY[1], nodataval=ARRAY[0], skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, ARRAY[$6]::text[], ARRAY[$7]::double precision[], ARRAY[$8]::double precision[], NULL, NULL, $4, $5, $9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,integer,integer,double precision,double precision,text,double precision,double precision,double precision,double precision,boolean) IS 'args: geom, width, height, gridx, gridy, pixeltype, value=1, nodataval=0, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, width integer, height integer, pixeltype text, value double precision DEFAULT 1, nodataval double precision DEFAULT 0, upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, ARRAY[$4]::text[], ARRAY[$5]::double precision[], ARRAY[$6]::double precision[], $7, $8, NULL, NULL,$9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,integer,integer,text,double precision,double precision,double precision,double precision,double precision,double precision,boolean) IS 'args: geom, width, height, pixeltype, value=1, nodataval=0, upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_asraster
 */
CREATE OR REPLACE FUNCTION public.st_asraster(geom geometry, width integer, height integer, pixeltype text[], value double precision[] DEFAULT ARRAY[(1)::double precision], nodataval double precision[] DEFAULT ARRAY[(0)::double precision], upperleftx double precision DEFAULT NULL::double precision, upperlefty double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, touched boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_asraster($1, NULL, NULL, $2, $3, $4, $5, $6, $7, $8, NULL, NULL,	$9, $10, $11) $function$

COMMENT ON FUNCTION st_asraster(geometry,integer,integer,text[],double precision[],double precision[],double precision,double precision,double precision,double precision,boolean) IS 'args: geom, width, height, pixeltype, value=ARRAY[1], nodataval=ARRAY[0], upperleftx=NULL, upperlefty=NULL, skewx=0, skewy=0, touched=false - Converts a PostGIS geometry to a PostGIS raster.'

/**********
 * Function: public.st_astiff
 */
CREATE OR REPLACE FUNCTION public.st_astiff(rast raster, compression text, srid integer DEFAULT NULL::integer)
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$

COMMENT ON FUNCTION st_astiff(raster,text,integer) IS 'args: rast, compression='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.'

/**********
 * Function: public.st_astiff
 */
CREATE OR REPLACE FUNCTION public.st_astiff(rast raster, nbands integer[], compression text, srid integer DEFAULT NULL::integer)
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_astiff(st_band($1, $2), $3, $4) $function$

COMMENT ON FUNCTION st_astiff(raster,integer[],text,integer) IS 'args: rast, nbands, compression='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.'

/**********
 * Function: public.st_astiff
 */
CREATE OR REPLACE FUNCTION public.st_astiff(rast raster, nbands integer[], options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer)
 RETURNS bytea
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_astiff(st_band($1, $2), $3, $4) $function$

COMMENT ON FUNCTION st_astiff(raster,integer[],text[],integer) IS 'args: rast, nbands, options, srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.'

/**********
 * Function: public.st_astiff
 */
CREATE OR REPLACE FUNCTION public.st_astiff(rast raster, options text[] DEFAULT NULL::text[], srid integer DEFAULT NULL::integer)
 RETURNS bytea
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$

COMMENT ON FUNCTION st_astiff(raster,text[],integer) IS 'args: rast, options='', srid=sameassource - Return the raster selected bands as a single TIFF image (byte array). If no band is specified, then will try to use all bands.'

/**********
 * Function: public.st_band
 */
CREATE OR REPLACE FUNCTION public.st_band(rast raster, nband integer)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT  public.ST_band($1, ARRAY[$2]) $function$

COMMENT ON FUNCTION st_band(raster,integer) IS 'args: rast, nband - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.'

/**********
 * Function: public.st_band
 */
CREATE OR REPLACE FUNCTION public.st_band(rast raster, nbands integer[] DEFAULT ARRAY[1])
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_band$function$

COMMENT ON FUNCTION st_band(raster,integer[]) IS 'args: rast, nbands = ARRAY[1] - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.'

/**********
 * Function: public.st_band
 */
CREATE OR REPLACE FUNCTION public.st_band(rast raster, nbands text, delimiter character DEFAULT ','::bpchar)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT  public.ST_band($1, regexp_split_to_array(regexp_replace($2, '[[:space:]]', '', 'g'), E'\\' || array_to_string(regexp_split_to_array($3, ''), E'\\'))::int[]) $function$

COMMENT ON FUNCTION st_band(raster,text,character) IS 'args: rast, nbands, delimiter=, - Returns one or more bands of an existing raster as a new raster. Useful for building new rasters from existing rasters.'

/**********
 * Function: public.st_bandisnodata
 */
CREATE OR REPLACE FUNCTION public.st_bandisnodata(rast raster, band integer DEFAULT 1, forcechecking boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_bandIsNoData$function$

COMMENT ON FUNCTION st_bandisnodata(raster,integer,boolean) IS 'args: rast, band, forceChecking=true - Returns true if the band is filled with only nodata values.'

/**********
 * Function: public.st_bandisnodata
 */
CREATE OR REPLACE FUNCTION public.st_bandisnodata(rast raster, forcechecking boolean)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_bandisnodata($1, 1, $2) $function$

COMMENT ON FUNCTION st_bandisnodata(raster,boolean) IS 'args: rast, forceChecking=true - Returns true if the band is filled with only nodata values.'

/**********
 * Function: public.st_bandmetadata
 */
CREATE OR REPLACE FUNCTION public.st_bandmetadata(rast raster, band integer DEFAULT 1, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text)
 RETURNS record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT pixeltype, nodatavalue, isoutdb, path FROM public.ST_BandMetaData($1, ARRAY[$2]::int[]) LIMIT 1 $function$

COMMENT ON FUNCTION st_bandmetadata(raster,integer) IS 'args: rast, bandnum=1 - Returns basic meta data for a specific raster band. band num 1 is assumed if none-specified.'

/**********
 * Function: public.st_bandmetadata
 */
CREATE OR REPLACE FUNCTION public.st_bandmetadata(rast raster, band integer[], OUT bandnum integer, OUT pixeltype text, OUT nodatavalue double precision, OUT isoutdb boolean, OUT path text)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_bandmetadata$function$



/**********
 * Function: public.st_bandnodatavalue
 */
CREATE OR REPLACE FUNCTION public.st_bandnodatavalue(rast raster, band integer DEFAULT 1)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getBandNoDataValue$function$

COMMENT ON FUNCTION st_bandnodatavalue(raster,integer) IS 'args: rast, bandnum=1 - Returns the value in a given band that represents no data. If no band num 1 is assumed.'

/**********
 * Function: public.st_bandpath
 */
CREATE OR REPLACE FUNCTION public.st_bandpath(rast raster, band integer DEFAULT 1)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getBandPath$function$

COMMENT ON FUNCTION st_bandpath(raster,integer) IS 'args: rast, bandnum=1 - Returns system file path to a band stored in file system. If no bandnum specified, 1 is assumed.'

/**********
 * Function: public.st_bandpixeltype
 */
CREATE OR REPLACE FUNCTION public.st_bandpixeltype(rast raster, band integer DEFAULT 1)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getBandPixelTypeName$function$

COMMENT ON FUNCTION st_bandpixeltype(raster,integer) IS 'args: rast, bandnum=1 - Returns the type of pixel for given band. If no bandnum specified, 1 is assumed.'

/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, geom geometry, crop boolean)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ST_Clip($1, NULL, $2, null::double precision[], $3) $function$



/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, geom geometry, nodataval double precision, crop boolean DEFAULT true)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ST_Clip($1, NULL, $2, ARRAY[$3]::double precision[], $4) $function$



/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, geom geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ST_Clip($1, NULL, $2, $3, $4) $function$



/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, nband integer, geom geometry, crop boolean)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ST_Clip($1, ARRAY[$2]::integer[], $3, null::double precision[], $4) $function$



/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, nband integer, geom geometry, nodataval double precision, crop boolean DEFAULT true)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ST_Clip($1, ARRAY[$2]::integer[], $3, ARRAY[$4]::double precision[], $5) $function$



/**********
 * Function: public.st_clip
 */
CREATE OR REPLACE FUNCTION public.st_clip(rast raster, nband integer[], geom geometry, nodataval double precision[] DEFAULT NULL::double precision[], crop boolean DEFAULT true)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
	BEGIN
		-- short-cut if geometry's extent fully contains raster's extent
		IF (nodataval IS NULL OR array_length(nodataval, 1) < 1) AND geom ~ ST_Envelope(rast) THEN
			RETURN rast;
		END IF;

		RETURN public._ST_Clip($1, $2, $3, $4, $5);
	END;
	$function$



/**********
 * Function: public.st_colormap
 */
CREATE OR REPLACE FUNCTION public.st_colormap(rast raster, colormap text, method text DEFAULT 'INTERPOLATE'::text)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_ColorMap($1, 1, $2, $3) $function$



/**********
 * Function: public.st_colormap
 */
CREATE OR REPLACE FUNCTION public.st_colormap(rast raster, nband integer DEFAULT 1, colormap text DEFAULT 'grayscale'::text, method text DEFAULT 'INTERPOLATE'::text)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public.st_contains
 */
CREATE OR REPLACE FUNCTION public.st_contains(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_contains(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_contains($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_contains(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastB lie in the exterior of raster rastA and at least one point of the interior of rastB lies in the interior of rastA.'

/**********
 * Function: public.st_contains
 */
CREATE OR REPLACE FUNCTION public.st_contains(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_contains($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_contains(raster,raster) IS 'args: rastA, rastB - Return true if no points of raster rastB lie in the exterior of raster rastA and at least one point of the interior of rastB lies in the interior of rastA.'

/**********
 * Function: public.st_containsproperly
 */
CREATE OR REPLACE FUNCTION public.st_containsproperly(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_containsproperly(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_containsproperly($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_containsproperly(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if rastB intersects the interior of rastA but not the boundary or exterior of rastA.'

/**********
 * Function: public.st_containsproperly
 */
CREATE OR REPLACE FUNCTION public.st_containsproperly(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_containsproperly($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_containsproperly(raster,raster) IS 'args: rastA, rastB - Return true if rastB intersects the interior of rastA but not the boundary or exterior of rastA.'

/**********
 * Function: public.st_convexhull
 */
CREATE OR REPLACE FUNCTION public.st_convexhull(raster)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE STRICT COST 300
AS '$libdir/rtpostgis-2.3', $function$RASTER_convex_hull$function$



/**********
 * Function: public.st_count
 */
CREATE OR REPLACE FUNCTION public.st_count(rastertable text, rastercolumn text, exclude_nodata_value boolean)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, 1, $3, 1) $function$

COMMENT ON FUNCTION st_count(text,text,boolean) IS 'args: rastertable, rastercolumn, exclude_nodata_value - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.'

/**********
 * Function: public.st_count
 */
CREATE OR REPLACE FUNCTION public.st_count(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true)
 RETURNS bigint
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_count($1, $2, $3, $4, 1) $function$

COMMENT ON FUNCTION st_count(text,text,integer,boolean) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.'

/**********
 * Function: public.st_count
 */
CREATE OR REPLACE FUNCTION public.st_count(rast raster, exclude_nodata_value boolean)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, 1, $2, 1) $function$

COMMENT ON FUNCTION st_count(raster,boolean) IS 'args: rast, exclude_nodata_value - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.'

/**********
 * Function: public.st_count
 */
CREATE OR REPLACE FUNCTION public.st_count(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true)
 RETURNS bigint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_count($1, $2, $3, 1) $function$

COMMENT ON FUNCTION st_count(raster,integer,boolean) IS 'args: rast, nband=1, exclude_nodata_value=true - Returns the number of pixels in a given band of a raster or raster coverage. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the nodata value.'

/**********
 * Function: public.st_coveredby
 */
CREATE OR REPLACE FUNCTION public.st_coveredby(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_coveredby(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_coveredby($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_coveredby(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastA lie outside raster rastB.'

/**********
 * Function: public.st_coveredby
 */
CREATE OR REPLACE FUNCTION public.st_coveredby(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_coveredby($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_coveredby(raster,raster) IS 'args: rastA, rastB - Return true if no points of raster rastA lie outside raster rastB.'

/**********
 * Function: public.st_covers
 */
CREATE OR REPLACE FUNCTION public.st_covers(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_covers(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_covers($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_covers(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastB lie outside raster rastA.'

/**********
 * Function: public.st_covers
 */
CREATE OR REPLACE FUNCTION public.st_covers(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_covers($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_covers(raster,raster) IS 'args: rastA, rastB - Return true if no points of raster rastB lie outside raster rastA.'

/**********
 * Function: public.st_createoverview
 */
CREATE OR REPLACE FUNCTION public.st_createoverview(tab regclass, col name, factor integer, algo text DEFAULT 'NearestNeighbour'::text)
 RETURNS regclass
 LANGUAGE plpgsql
 STRICT
AS $function$
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
$function$

COMMENT ON FUNCTION st_createoverview(regclass,name,integer,text) IS 'args: tab, col, factor, algo=''NearestNeighbor'' - Create an reduced resolution version of a given raster coverage.'

/**********
 * Function: public.st_dfullywithin
 */
CREATE OR REPLACE FUNCTION public.st_dfullywithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($3), $5) AND $3::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($1), $5) AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._ST_dfullywithin(st_convexhull($1), st_convexhull($3), $5) ELSE public._ST_dfullywithin($1, $2, $3, $4, $5) END $function$

COMMENT ON FUNCTION st_dfullywithin(raster,integer,raster,integer,double precision) IS 'args: rastA, nbandA, rastB, nbandB, distance_of_srid - Return true if rasters rastA and rastB are fully within the specified distance of each other.'

/**********
 * Function: public.st_dfullywithin
 */
CREATE OR REPLACE FUNCTION public.st_dfullywithin(rast1 raster, rast2 raster, distance double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT st_dfullywithin($1, NULL::integer, $2, NULL::integer, $3) $function$

COMMENT ON FUNCTION st_dfullywithin(raster,raster,double precision) IS 'args: rastA, rastB, distance_of_srid - Return true if rasters rastA and rastB are fully within the specified distance of each other.'

/**********
 * Function: public.st_disjoint
 */
CREATE OR REPLACE FUNCTION public.st_disjoint(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT CASE WHEN $2 IS NULL OR $4 IS NULL THEN st_disjoint(st_convexhull($1), st_convexhull($3)) ELSE NOT public._ST_intersects($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_disjoint(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA does not spatially intersect rastB.'

/**********
 * Function: public.st_disjoint
 */
CREATE OR REPLACE FUNCTION public.st_disjoint(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT st_disjoint($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_disjoint(raster,raster) IS 'args: rastA, rastB - Return true if raster rastA does not spatially intersect rastB.'

/**********
 * Function: public.st_distinct4ma
 */
CREATE OR REPLACE FUNCTION public.st_distinct4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT COUNT(DISTINCT unnest)::float FROM unnest($1) $function$



/**********
 * Function: public.st_distinct4ma
 */
CREATE OR REPLACE FUNCTION public.st_distinct4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT COUNT(DISTINCT unnest)::double precision FROM unnest($1) $function$



/**********
 * Function: public.st_dumpaspolygons
 */
CREATE OR REPLACE FUNCTION public.st_dumpaspolygons(rast raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true)
 RETURNS SETOF geomval
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_dumpAsPolygons$function$



/**********
 * Function: public.st_dumpvalues
 */
CREATE OR REPLACE FUNCTION public.st_dumpvalues(rast raster, nband integer[] DEFAULT NULL::integer[], exclude_nodata_value boolean DEFAULT true, OUT nband integer, OUT valarray double precision[])
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_dumpValues$function$

COMMENT ON FUNCTION st_dumpvalues(raster,integer[],boolean) IS 'args: rast, nband=NULL, exclude_nodata_value=true - Get the values of the specified band as a 2-dimension array.'

/**********
 * Function: public.st_dumpvalues
 */
CREATE OR REPLACE FUNCTION public.st_dumpvalues(rast raster, nband integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT valarray FROM public.ST_dumpvalues($1, ARRAY[$2]::integer[], $3) $function$

COMMENT ON FUNCTION st_dumpvalues(raster,integer,boolean) IS 'args: rast, nband, exclude_nodata_value=true - Get the values of the specified band as a 2-dimension array.'

/**********
 * Function: public.st_dwithin
 */
CREATE OR REPLACE FUNCTION public.st_dwithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($3), $5) AND $3::geometry OPERATOR(public.&&) ST_Expand(ST_ConvexHull($1), $5) AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._ST_dwithin(st_convexhull($1), st_convexhull($3), $5) ELSE public._ST_dwithin($1, $2, $3, $4, $5) END $function$

COMMENT ON FUNCTION st_dwithin(raster,integer,raster,integer,double precision) IS 'args: rastA, nbandA, rastB, nbandB, distance_of_srid - Return true if rasters rastA and rastB are within the specified distance of each other.'

/**********
 * Function: public.st_dwithin
 */
CREATE OR REPLACE FUNCTION public.st_dwithin(rast1 raster, rast2 raster, distance double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_dwithin($1, NULL::integer, $2, NULL::integer, $3) $function$

COMMENT ON FUNCTION st_dwithin(raster,raster,double precision) IS 'args: rastA, rastB, distance_of_srid - Return true if rasters rastA and rastB are within the specified distance of each other.'

/**********
 * Function: public.st_envelope
 */
CREATE OR REPLACE FUNCTION public.st_envelope(raster)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_envelope$function$



/**********
 * Function: public.st_fromgdalraster
 */
CREATE OR REPLACE FUNCTION public.st_fromgdalraster(gdaldata bytea, srid integer DEFAULT NULL::integer)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_fromGDALRaster$function$

COMMENT ON FUNCTION st_fromgdalraster(bytea,integer) IS 'args: gdaldata, srid=NULL - Returns a raster from a supported GDAL raster file.'

/**********
 * Function: public.st_gdaldrivers
 */
CREATE OR REPLACE FUNCTION public.st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT create_options text)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getGDALDrivers$function$

COMMENT ON FUNCTION st_gdaldrivers() IS 'args: OUT idx, OUT short_name, OUT long_name, OUT create_options - Returns a list of raster formats supported by your lib gdal. These are the formats you can output your raster using ST_AsGDALRaster.'

/**********
 * Function: public.st_georeference
 */
CREATE OR REPLACE FUNCTION public.st_georeference(rast raster, format text DEFAULT 'GDAL'::text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
    $function$

COMMENT ON FUNCTION st_georeference(raster,text) IS 'args: rast, format=GDAL - Returns the georeference meta data in GDAL or ESRI format as commonly seen in a world file. Default is GDAL.'

/**********
 * Function: public.st_geotransform
 */
CREATE OR REPLACE FUNCTION public.st_geotransform(raster, OUT imag double precision, OUT jmag double precision, OUT theta_i double precision, OUT theta_ij double precision, OUT xoffset double precision, OUT yoffset double precision)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_getGeotransform$function$



/**********
 * Function: public.st_hasnoband
 */
CREATE OR REPLACE FUNCTION public.st_hasnoband(rast raster, nband integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_hasNoBand$function$

COMMENT ON FUNCTION st_hasnoband(raster,integer) IS 'args: rast, bandnum=1 - Returns true if there is no band with given band number. If no band number is specified, then band number 1 is assumed.'

/**********
 * Function: public.st_height
 */
CREATE OR REPLACE FUNCTION public.st_height(raster)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getHeight$function$

COMMENT ON FUNCTION st_height(raster) IS 'args: rast - Returns the height of the raster in pixels.'

/**********
 * Function: public.st_hillshade
 */
CREATE OR REPLACE FUNCTION public.st_hillshade(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, azimuth double precision DEFAULT 315.0, altitude double precision DEFAULT 45.0, max_bright double precision DEFAULT 255.0, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_hillshade
 */
CREATE OR REPLACE FUNCTION public.st_hillshade(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, azimuth double precision DEFAULT 315.0, altitude double precision DEFAULT 45.0, max_bright double precision DEFAULT 255.0, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_hillshade($1, $2, NULL::raster, $3, $4, $5, $6, $7, $8) $function$



/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, TRUE, 1, $4, NULL, $5) $function$

COMMENT ON FUNCTION st_histogram(text,text,integer,integer,boolean) IS 'args: rastertable, rastercolumn, nband, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_histogram($1, $2, $3, TRUE, 1, $4, $5, $6) $function$

COMMENT ON FUNCTION st_histogram(text,text,integer,integer,double precision[],boolean) IS 'args: rastertable, rastercolumn, nband=1, bins, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_histogram($1, $2, $3, $4, 1, $5, $6, $7) $function$

COMMENT ON FUNCTION st_histogram(text,text,integer,boolean,integer,double precision[],boolean) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, bins=autocomputed, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_histogram($1, $2, $3, $4, 1, $5, NULL, $6) $function$

COMMENT ON FUNCTION st_histogram(text,text,integer,boolean,integer,boolean) IS 'args: rastertable, rastercolumn, nband, exclude_nodata_value, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rast raster, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, 1, $3, NULL, $4) $function$

COMMENT ON FUNCTION st_histogram(raster,integer,integer,boolean) IS 'args: rast, nband, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rast raster, nband integer, bins integer, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, TRUE, 1, $3, $4, $5) $function$

COMMENT ON FUNCTION st_histogram(raster,integer,integer,double precision[],boolean) IS 'args: rast, nband, bins, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, bins integer DEFAULT 0, width double precision[] DEFAULT NULL::double precision[], "right" boolean DEFAULT false, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, 1, $4, $5, $6) $function$

COMMENT ON FUNCTION st_histogram(raster,integer,boolean,integer,double precision[],boolean) IS 'args: rast, nband=1, exclude_nodata_value=true, bins=autocomputed, width=NULL, right=false - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_histogram
 */
CREATE OR REPLACE FUNCTION public.st_histogram(rast raster, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT min, max, count, percent FROM public._ST_histogram($1, $2, $3, 1, $4, NULL, $5) $function$

COMMENT ON FUNCTION st_histogram(raster,integer,boolean,integer,boolean) IS 'args: rast, nband, exclude_nodata_value, bins, right - Returns a set of record summarizing a raster or raster coverage data distribution separate bin ranges. Number of bins are autocomputed if not specified.'

/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(geomin geometry, rast raster, band integer DEFAULT 1)
 RETURNS SETOF geomval
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, nodataval double precision[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, $2, $3, $4, 'BOTH', $5) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, nodataval double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, $2, $3, $4, 'BOTH', ARRAY[$5, $5]) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, returnband text DEFAULT 'BOTH'::text, nodataval double precision[] DEFAULT NULL::double precision[])
 RETURNS raster
 LANGUAGE plpgsql
 STABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, returnband text, nodataval double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, $2, $3, $4, $5, ARRAY[$6, $6]) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, rast2 raster, nodataval double precision[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, 1, $2, 1, 'BOTH', $3) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, rast2 raster, nodataval double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, 1, $2, 1, 'BOTH', ARRAY[$3, $3]) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, rast2 raster, returnband text DEFAULT 'BOTH'::text, nodataval double precision[] DEFAULT NULL::double precision[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, 1, $2, 1, $3, $4) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast1 raster, rast2 raster, returnband text, nodataval double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($1, 1, $2, 1, $3, ARRAY[$4, $4]) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast raster, band integer, geomin geometry)
 RETURNS SETOF geomval
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($3, $1, $2) $function$



/**********
 * Function: public.st_intersection
 */
CREATE OR REPLACE FUNCTION public.st_intersection(rast raster, geomin geometry)
 RETURNS SETOF geomval
 LANGUAGE sql
 STABLE
AS $function$ SELECT st_intersection($2, $1, 1) $function$



/**********
 * Function: public.st_intersects
 */
CREATE OR REPLACE FUNCTION public.st_intersects(geom geometry, rast raster, nband integer DEFAULT NULL::integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $2::geometry AND public._st_intersects($1, $2, $3); $function$

COMMENT ON FUNCTION st_intersects(geometry,raster,integer) IS 'args: geommin, rast, nband=NULL - Return true if raster rastA spatially intersects raster rastB.'

/**********
 * Function: public.st_intersects
 */
CREATE OR REPLACE FUNCTION public.st_intersects(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_intersects(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_intersects($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_intersects(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA spatially intersects raster rastB.'

/**********
 * Function: public.st_intersects
 */
CREATE OR REPLACE FUNCTION public.st_intersects(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_intersects($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_intersects(raster,raster) IS 'args: rastA, rastB - Return true if raster rastA spatially intersects raster rastB.'

/**********
 * Function: public.st_intersects
 */
CREATE OR REPLACE FUNCTION public.st_intersects(rast raster, geom geometry, nband integer DEFAULT NULL::integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1::geometry OPERATOR(public.&&) $2 AND public._st_intersects($2, $1, $3) $function$

COMMENT ON FUNCTION st_intersects(raster,geometry,integer) IS 'args: rast, geommin, nband=NULL - Return true if raster rastA spatially intersects raster rastB.'

/**********
 * Function: public.st_intersects
 */
CREATE OR REPLACE FUNCTION public.st_intersects(rast raster, nband integer, geom geometry)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1::geometry OPERATOR(public.&&) $3 AND public._st_intersects($3, $1, $2) $function$

COMMENT ON FUNCTION st_intersects(raster,integer,geometry) IS 'args: rast, nband, geommin - Return true if raster rastA spatially intersects raster rastB.'

/**********
 * Function: public.st_invdistweight4ma
 */
CREATE OR REPLACE FUNCTION public.st_invdistweight4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_iscoveragetile
 */
CREATE OR REPLACE FUNCTION public.st_iscoveragetile(rast raster, coverage raster, tilewidth integer, tileheight integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public.st_isempty
 */
CREATE OR REPLACE FUNCTION public.st_isempty(rast raster)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_isEmpty$function$

COMMENT ON FUNCTION st_isempty(raster) IS 'args: rast - Returns true if the raster is empty (width = 0 and height = 0). Otherwise, returns false.'

/**********
 * Function: public.st_makeemptyraster
 */
CREATE OR REPLACE FUNCTION public.st_makeemptyraster(rast raster)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
    $function$

COMMENT ON FUNCTION st_makeemptyraster(raster) IS 'args: rast - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).'

/**********
 * Function: public.st_makeemptyraster
 */
CREATE OR REPLACE FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT  public.ST_makeemptyraster($1, $2, $3, $4, $5, -($5), 0, 0, public.ST_SRID('POINT(0 0)'::geometry)) $function$

COMMENT ON FUNCTION st_makeemptyraster(integer,integer,double precision,double precision,double precision) IS 'args: width, height, upperleftx, upperlefty, pixelsize - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).'

/**********
 * Function: public.st_makeemptyraster
 */
CREATE OR REPLACE FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer DEFAULT 0)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_makeEmpty$function$

COMMENT ON FUNCTION st_makeemptyraster(integer,integer,double precision,double precision,double precision,double precision,double precision,double precision,integer) IS 'args: width, height, upperleftx, upperlefty, scalex, scaley, skewx, skewy, srid=unknown - Returns an empty raster (having no bands) of given dimensions (width & height), upperleft X and Y, pixel size and rotation (scalex, scaley, skewx & skewy) and reference system (srid). If a raster is passed in, returns a new raster with the same size, alignment and SRID. If srid is left out, the spatial ref is set to unknown (0).'

/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast1 raster, band1 integer, rast2 raster, band2 integer, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_mapalgebra(ARRAY[ROW($1, $2), ROW($3, $4)]::rastbandarg[], $5, $6, $7, $8, $9, $10) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast1 raster, nband1 integer, rast2 raster, nband2 integer, callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent raster DEFAULT NULL::raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_MapAlgebra(ARRAY[ROW($1, $2), ROW($3, $4)]::rastbandarg[], $5, $6, $9, $10, $7, $8,NULL::double precision [],NULL::boolean, VARIADIC $11) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast1 raster, rast2 raster, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public.ST_mapalgebra($1, 1, $2, 1, $3, $4, $5, $6, $7, $8) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rastbandargset rastbandarg[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent raster DEFAULT NULL::raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_MapAlgebra($1, $2, $3, $6, $7, $4, $5,NULL::double precision [],NULL::boolean, VARIADIC $8) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast raster, nband integer, callbackfunc regprocedure, mask double precision[], weighted boolean, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, customextent raster DEFAULT NULL::raster, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$
	select public._ST_mapalgebra(ARRAY[ROW($1,$2)]::rastbandarg[],$3,$6,NULL::integer,NULL::integer,$7,$8,$4,$5,VARIADIC $9)
	$function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast raster, nband integer[], callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'FIRST'::text, customextent raster DEFAULT NULL::raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE plpgsql
 STABLE
AS $function$
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
	$function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast raster, nband integer, callbackfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'FIRST'::text, customextent raster DEFAULT NULL::raster, distancex integer DEFAULT 0, distancey integer DEFAULT 0, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_MapAlgebra(ARRAY[ROW($1, $2)]::rastbandarg[], $3, $4, $7, $8, $5, $6,NULL::double precision [],NULL::boolean, VARIADIC $9) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast raster, nband integer, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_mapalgebra(ARRAY[ROW($1, $2)]::rastbandarg[], $4, $3, 'FIRST', $5::text) $function$



/**********
 * Function: public.st_mapalgebra
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebra(rast raster, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public.ST_mapalgebra($1, 1, $2, $3, $4) $function$



/**********
 * Function: public.st_mapalgebraexpr
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebraexpr(rast1 raster, band1 integer, rast2 raster, band2 integer, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_mapAlgebra2$function$



/**********
 * Function: public.st_mapalgebraexpr
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebraexpr(rast1 raster, rast2 raster, expression text, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, nodata1expr text DEFAULT NULL::text, nodata2expr text DEFAULT NULL::text, nodatanodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public.ST_mapalgebraexpr($1, 1, $2, 1, $3, $4, $5, $6, $7, $8) $function$



/**********
 * Function: public.st_mapalgebraexpr
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebraexpr(rast raster, band integer, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_mapAlgebraExpr$function$



/**********
 * Function: public.st_mapalgebraexpr
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebraexpr(rast raster, pixeltype text, expression text, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebraexpr($1, 1, $2, $3, $4) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast1 raster, band1 integer, rast2 raster, band2 integer, tworastuserfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE c
 STABLE
AS '$libdir/rtpostgis-2.3', $function$RASTER_mapAlgebra2$function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast1 raster, rast2 raster, tworastuserfunc regprocedure, pixeltype text DEFAULT NULL::text, extenttype text DEFAULT 'INTERSECTION'::text, VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public.ST_mapalgebrafct($1, 1, $2, 1, $3, $4, $5, VARIADIC $6) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, band integer, onerastuserfunc regprocedure)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, $2, NULL, $3, NULL) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, band integer, onerastuserfunc regprocedure, VARIADIC args text[])
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, $2, NULL, $3, VARIADIC $4) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, band integer, pixeltype text, onerastuserfunc regprocedure)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, $2, $3, $4, NULL) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, band integer, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[])
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_mapAlgebraFct$function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, onerastuserfunc regprocedure)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, 1, NULL, $2, NULL) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, onerastuserfunc regprocedure, VARIADIC args text[])
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, 1, NULL, $2, VARIADIC $3) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, pixeltype text, onerastuserfunc regprocedure)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, 1, $2, $3, NULL) $function$



/**********
 * Function: public.st_mapalgebrafct
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafct(rast raster, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[])
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_mapalgebrafct($1, 1, $2, $3, VARIADIC $4) $function$



/**********
 * Function: public.st_mapalgebrafctngb
 */
CREATE OR REPLACE FUNCTION public.st_mapalgebrafctngb(rast raster, band integer, pixeltype text, ngbwidth integer, ngbheight integer, onerastngbuserfunc regprocedure, nodatamode text, VARIADIC args text[])
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_mapAlgebraFctNgb$function$



/**********
 * Function: public.st_max4ma
 */
CREATE OR REPLACE FUNCTION public.st_max4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
    $function$



/**********
 * Function: public.st_max4ma
 */
CREATE OR REPLACE FUNCTION public.st_max4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_mean4ma
 */
CREATE OR REPLACE FUNCTION public.st_mean4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
    $function$



/**********
 * Function: public.st_mean4ma
 */
CREATE OR REPLACE FUNCTION public.st_mean4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_memsize
 */
CREATE OR REPLACE FUNCTION public.st_memsize(raster)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_memsize$function$

COMMENT ON FUNCTION st_memsize(raster) IS 'args: rast - Returns the amount of space (in bytes) the raster takes.'

/**********
 * Function: public.st_metadata
 */
CREATE OR REPLACE FUNCTION public.st_metadata(rast raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_metadata$function$

COMMENT ON FUNCTION st_metadata(raster) IS 'args: rast - Returns basic meta data about a raster object such as pixel size, rotation (skew), upper, lower left, etc.'

/**********
 * Function: public.st_min4ma
 */
CREATE OR REPLACE FUNCTION public.st_min4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
    $function$



/**********
 * Function: public.st_min4ma
 */
CREATE OR REPLACE FUNCTION public.st_min4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_minconvexhull
 */
CREATE OR REPLACE FUNCTION public.st_minconvexhull(rast raster, nband integer DEFAULT NULL::integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_convex_hull$function$



/**********
 * Function: public.st_mindist4ma
 */
CREATE OR REPLACE FUNCTION public.st_mindist4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_minpossiblevalue
 */
CREATE OR REPLACE FUNCTION public.st_minpossiblevalue(pixeltype text)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_minPossibleValue$function$



/**********
 * Function: public.st_nearestvalue
 */
CREATE OR REPLACE FUNCTION public.st_nearestvalue(rast raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_nearestvalue($1, $2, st_setsrid(st_makepoint(st_rastertoworldcoordx($1, $3, $4), st_rastertoworldcoordy($1, $3, $4)), st_srid($1)), $5) $function$

COMMENT ON FUNCTION st_nearestvalue(raster,integer,integer,integer,boolean) IS 'args: rast, bandnum, columnx, rowy, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_nearestvalue
 */
CREATE OR REPLACE FUNCTION public.st_nearestvalue(rast raster, band integer, pt geometry, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_nearestValue$function$

COMMENT ON FUNCTION st_nearestvalue(raster,integer,geometry,boolean) IS 'args: rast, bandnum, pt, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_nearestvalue
 */
CREATE OR REPLACE FUNCTION public.st_nearestvalue(rast raster, columnx integer, rowy integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_nearestvalue($1, 1, st_setsrid(st_makepoint(st_rastertoworldcoordx($1, $2, $3), st_rastertoworldcoordy($1, $2, $3)), st_srid($1)), $4) $function$

COMMENT ON FUNCTION st_nearestvalue(raster,integer,integer,boolean) IS 'args: rast, columnx, rowy, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_nearestvalue
 */
CREATE OR REPLACE FUNCTION public.st_nearestvalue(rast raster, pt geometry, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_nearestvalue($1, 1, $2, $3) $function$

COMMENT ON FUNCTION st_nearestvalue(raster,geometry,boolean) IS 'args: rast, pt, exclude_nodata_value=true - Returns the nearest non-NODATA value of a given bands pixel specified by a columnx and rowy or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_neighborhood
 */
CREATE OR REPLACE FUNCTION public.st_neighborhood(rast raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_neighborhood($1, $2, $3, $4, $5, $6, $7) $function$

COMMENT ON FUNCTION st_neighborhood(raster,integer,integer,integer,integer,integer,boolean) IS 'args: rast, bandnum, columnX, rowY, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_neighborhood
 */
CREATE OR REPLACE FUNCTION public.st_neighborhood(rast raster, band integer, pt geometry, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_neighborhood(raster,integer,geometry,integer,integer,boolean) IS 'args: rast, bandnum, pt, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_neighborhood
 */
CREATE OR REPLACE FUNCTION public.st_neighborhood(rast raster, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_neighborhood($1, 1, $2, $3, $4, $5, $6) $function$

COMMENT ON FUNCTION st_neighborhood(raster,integer,integer,integer,integer,boolean) IS 'args: rast, columnX, rowY, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_neighborhood
 */
CREATE OR REPLACE FUNCTION public.st_neighborhood(rast raster, pt geometry, distancex integer, distancey integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision[]
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_neighborhood($1, 1, $2, $3, $4, $5) $function$

COMMENT ON FUNCTION st_neighborhood(raster,geometry,integer,integer,boolean) IS 'args: rast, pt, distanceX, distanceY, exclude_nodata_value=true - Returns a 2-D double precision array of the non-NODATA values around a given bands pixel specified by either a columnX and rowY or a geometric point expressed in the same spatial reference coordinate system as the raster.'

/**********
 * Function: public.st_notsamealignmentreason
 */
CREATE OR REPLACE FUNCTION public.st_notsamealignmentreason(rast1 raster, rast2 raster)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_notSameAlignmentReason$function$

COMMENT ON FUNCTION st_notsamealignmentreason(raster,raster) IS 'args: rastA, rastB - Returns text stating if rasters are aligned and if not aligned, a reason why.'

/**********
 * Function: public.st_numbands
 */
CREATE OR REPLACE FUNCTION public.st_numbands(raster)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getNumBands$function$

COMMENT ON FUNCTION st_numbands(raster) IS 'args: rast - Returns the number of bands in the raster object.'

/**********
 * Function: public.st_overlaps
 */
CREATE OR REPLACE FUNCTION public.st_overlaps(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_overlaps(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._ST_overlaps($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_overlaps(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA and rastB intersect but one does not completely contain the other.'

/**********
 * Function: public.st_overlaps
 */
CREATE OR REPLACE FUNCTION public.st_overlaps(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_overlaps($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_overlaps(raster,raster) IS 'args: rastA, rastB - Return true if raster rastA and rastB intersect but one does not completely contain the other.'

/**********
 * Function: public.st_pixelascentroid
 */
CREATE OR REPLACE FUNCTION public.st_pixelascentroid(rast raster, x integer, y integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Centroid(geom) FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $function$

COMMENT ON FUNCTION st_pixelascentroid(raster,integer,integer) IS 'args: rast, x, y - Returns the centroid (point geometry) of the area represented by a pixel.'

/**********
 * Function: public.st_pixelascentroids
 */
CREATE OR REPLACE FUNCTION public.st_pixelascentroids(rast raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom geometry, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Centroid(geom), val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $function$

COMMENT ON FUNCTION st_pixelascentroids(raster,integer,boolean) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns the centroid (point geometry) for each pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel. The point geometry is the centroid of the area represented by a pixel.'

/**********
 * Function: public.st_pixelaspoint
 */
CREATE OR REPLACE FUNCTION public.st_pixelaspoint(rast raster, x integer, y integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ST_PointN(ST_ExteriorRing(geom), 1) FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $function$

COMMENT ON FUNCTION st_pixelaspoint(raster,integer,integer) IS 'args: rast, columnx, rowy - Returns a point geometry of the pixels upper-left corner.'

/**********
 * Function: public.st_pixelaspoints
 */
CREATE OR REPLACE FUNCTION public.st_pixelaspoints(rast raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom geometry, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_PointN(  public.ST_ExteriorRing(geom), 1), val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $function$

COMMENT ON FUNCTION st_pixelaspoints(raster,integer,boolean) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns a point geometry for each pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel. The coordinates of the point geometry are of the pixels upper-left corner.'

/**********
 * Function: public.st_pixelaspolygon
 */
CREATE OR REPLACE FUNCTION public.st_pixelaspolygon(rast raster, x integer, y integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT geom FROM public._ST_pixelaspolygons($1, NULL, $2, $3) $function$

COMMENT ON FUNCTION st_pixelaspolygon(raster,integer,integer) IS 'args: rast, columnx, rowy - Returns the polygon geometry that bounds the pixel for a particular row and column.'

/**********
 * Function: public.st_pixelaspolygons
 */
CREATE OR REPLACE FUNCTION public.st_pixelaspolygons(rast raster, band integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, OUT geom geometry, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT geom, val, x, y FROM public._ST_pixelaspolygons($1, $2, NULL, NULL, $3) $function$

COMMENT ON FUNCTION st_pixelaspolygons(raster,integer,boolean) IS 'args: rast, band=1, exclude_nodata_value=TRUE - Returns the polygon geometry that bounds every pixel of a raster band along with the value, the X and the Y raster coordinates of each pixel.'

/**********
 * Function: public.st_pixelheight
 */
CREATE OR REPLACE FUNCTION public.st_pixelheight(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getPixelHeight$function$

COMMENT ON FUNCTION st_pixelheight(raster) IS 'args: rast - Returns the pixel height in geometric units of the spatial reference system.'

/**********
 * Function: public.st_pixelofvalue
 */
CREATE OR REPLACE FUNCTION public.st_pixelofvalue(rast raster, nband integer, search double precision[], exclude_nodata_value boolean DEFAULT true, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_pixelOfValue$function$

COMMENT ON FUNCTION st_pixelofvalue(raster,integer,double precision[],boolean) IS 'args: rast, nband, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.'

/**********
 * Function: public.st_pixelofvalue
 */
CREATE OR REPLACE FUNCTION public.st_pixelofvalue(rast raster, nband integer, search double precision, exclude_nodata_value boolean DEFAULT true, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT x, y FROM public.ST_pixelofvalue($1, $2, ARRAY[$3], $4) $function$

COMMENT ON FUNCTION st_pixelofvalue(raster,integer,double precision,boolean) IS 'args: rast, nband, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.'

/**********
 * Function: public.st_pixelofvalue
 */
CREATE OR REPLACE FUNCTION public.st_pixelofvalue(rast raster, search double precision[], exclude_nodata_value boolean DEFAULT true, OUT val double precision, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT val, x, y FROM public.ST_pixelofvalue($1, 1, $2, $3) $function$

COMMENT ON FUNCTION st_pixelofvalue(raster,double precision[],boolean) IS 'args: rast, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.'

/**********
 * Function: public.st_pixelofvalue
 */
CREATE OR REPLACE FUNCTION public.st_pixelofvalue(rast raster, search double precision, exclude_nodata_value boolean DEFAULT true, OUT x integer, OUT y integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT x, y FROM public.ST_pixelofvalue($1, 1, ARRAY[$2], $3) $function$

COMMENT ON FUNCTION st_pixelofvalue(raster,double precision,boolean) IS 'args: rast, search, exclude_nodata_value=true - Get the columnx, rowy coordinates of the pixel whose value equals the search value.'

/**********
 * Function: public.st_pixelwidth
 */
CREATE OR REPLACE FUNCTION public.st_pixelwidth(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getPixelWidth$function$

COMMENT ON FUNCTION st_pixelwidth(raster) IS 'args: rast - Returns the pixel width in geometric units of the spatial reference system.'

/**********
 * Function: public.st_polygon
 */
CREATE OR REPLACE FUNCTION public.st_polygon(rast raster, band integer DEFAULT 1)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getPolygon$function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE
AS $function$ SELECT ( public._ST_quantile($1, $2, 1, $3, 1, ARRAY[$4]::double precision[])).value $function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_quantile($1, $2, $3, $4, 1, $5) $function$

COMMENT ON FUNCTION st_quantile(text,text,integer,boolean,double precision[]) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, quantiles=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, $4, 1, ARRAY[$5]::double precision[])).value $function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, TRUE, 1, ARRAY[$4]::double precision[])).value $function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_quantile($1, $2, $3, TRUE, 1, $4) $function$

COMMENT ON FUNCTION st_quantile(text,text,integer,double precision[]) IS 'args: rastertable, rastercolumn, nband, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, 1, TRUE, 1, ARRAY[$3]::double precision[])).value $function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rastertable text, rastercolumn text, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_quantile($1, $2, 1, TRUE, 1, $3) $function$



/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, exclude_nodata_value boolean, quantile double precision DEFAULT NULL::double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT ( public._ST_quantile($1, 1, $2, 1, ARRAY[$3]::double precision[])).value $function$

COMMENT ON FUNCTION st_quantile(raster,boolean,double precision) IS 'args: rast, exclude_nodata_value, quantile=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, quantiles double precision[] DEFAULT NULL::double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_quantile($1, $2, $3, 1, $4) $function$

COMMENT ON FUNCTION st_quantile(raster,integer,boolean,double precision[]) IS 'args: rast, nband=1, exclude_nodata_value=true, quantiles=NULL - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, nband integer, exclude_nodata_value boolean, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, $3, 1, ARRAY[$4]::double precision[])).value $function$

COMMENT ON FUNCTION st_quantile(raster,integer,boolean,double precision) IS 'args: rast, nband, exclude_nodata_value, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, nband integer, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, $2, TRUE, 1, ARRAY[$3]::double precision[])).value $function$

COMMENT ON FUNCTION st_quantile(raster,integer,double precision) IS 'args: rast, nband, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_quantile($1, $2, TRUE, 1, $3) $function$

COMMENT ON FUNCTION st_quantile(raster,integer,double precision[]) IS 'args: rast, nband, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, quantile double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_quantile($1, 1, TRUE, 1, ARRAY[$2]::double precision[])).value $function$

COMMENT ON FUNCTION st_quantile(raster,double precision) IS 'args: rast, quantile - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_quantile
 */
CREATE OR REPLACE FUNCTION public.st_quantile(rast raster, quantiles double precision[], OUT quantile double precision, OUT value double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_quantile($1, 1, TRUE, 1, $2) $function$

COMMENT ON FUNCTION st_quantile(raster,double precision[]) IS 'args: rast, quantiles - Compute quantiles for a raster or raster table coverage in the context of the sample or population. Thus, a value could be examined to be at the rasters 25%, 50%, 75% percentile.'

/**********
 * Function: public.st_range4ma
 */
CREATE OR REPLACE FUNCTION public.st_range4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
    $function$



/**********
 * Function: public.st_range4ma
 */
CREATE OR REPLACE FUNCTION public.st_range4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_rastertoworldcoord
 */
CREATE OR REPLACE FUNCTION public.st_rastertoworldcoord(rast raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision)
 RETURNS record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT longitude, latitude FROM public._ST_rastertoworldcoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_rastertoworldcoord(raster,integer,integer) IS 'args: rast, xcolumn, yrow - Returns the rasters upper left corner as geometric X and Y (longitude and latitude) given a column and row. Column and row starts at 1.'

/**********
 * Function: public.st_rastertoworldcoordx
 */
CREATE OR REPLACE FUNCTION public.st_rastertoworldcoordx(rast raster, xr integer)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT longitude FROM public._ST_rastertoworldcoord($1, $2, NULL) $function$

COMMENT ON FUNCTION st_rastertoworldcoordx(raster,integer) IS 'args: rast, xcolumn - Returns the geometric X coordinate upper left of a raster, column and row. Numbering of columns and rows starts at 1.'

/**********
 * Function: public.st_rastertoworldcoordx
 */
CREATE OR REPLACE FUNCTION public.st_rastertoworldcoordx(rast raster, xr integer, yr integer)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT longitude FROM public._ST_rastertoworldcoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_rastertoworldcoordx(raster,integer,integer) IS 'args: rast, xcolumn, yrow - Returns the geometric X coordinate upper left of a raster, column and row. Numbering of columns and rows starts at 1.'

/**********
 * Function: public.st_rastertoworldcoordy
 */
CREATE OR REPLACE FUNCTION public.st_rastertoworldcoordy(rast raster, xr integer, yr integer)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT latitude FROM public._ST_rastertoworldcoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_rastertoworldcoordy(raster,integer,integer) IS 'args: rast, xcolumn, yrow - Returns the geometric Y coordinate upper left corner of a raster, column and row. Numbering of columns and rows starts at 1.'

/**********
 * Function: public.st_rastertoworldcoordy
 */
CREATE OR REPLACE FUNCTION public.st_rastertoworldcoordy(rast raster, yr integer)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT latitude FROM public._ST_rastertoworldcoord($1, NULL, $2) $function$

COMMENT ON FUNCTION st_rastertoworldcoordy(raster,integer) IS 'args: rast, yrow - Returns the geometric Y coordinate upper left corner of a raster, column and row. Numbering of columns and rows starts at 1.'

/**********
 * Function: public.st_reclass
 */
CREATE OR REPLACE FUNCTION public.st_reclass(rast raster, nband integer, reclassexpr text, pixeltype text, nodataval double precision DEFAULT NULL::double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT st_reclass($1, ROW($2, $3, $4, $5)) $function$



/**********
 * Function: public.st_reclass
 */
CREATE OR REPLACE FUNCTION public.st_reclass(rast raster, reclassexpr text, pixeltype text)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_reclass($1, ROW(1, $2, $3, NULL)) $function$



/**********
 * Function: public.st_reclass
 */
CREATE OR REPLACE FUNCTION public.st_reclass(rast raster, VARIADIC reclassargset reclassarg[])
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$



/**********
 * Function: public.st_resample
 */
CREATE OR REPLACE FUNCTION public.st_resample(rast raster, ref raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, usescale boolean DEFAULT true)
 RETURNS raster
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_resample(raster,raster,text,double precision,boolean) IS 'args: rast, ref, algorithm=NearestNeighbour, maxerr=0.125, usescale=true - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.'

/**********
 * Function: public.st_resample
 */
CREATE OR REPLACE FUNCTION public.st_resample(rast raster, ref raster, usescale boolean, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT st_resample($1, $2, $4, $5, $3) $function$

COMMENT ON FUNCTION st_resample(raster,raster,boolean,text,double precision) IS 'args: rast, ref, usescale, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.'

/**********
 * Function: public.st_resample
 */
CREATE OR REPLACE FUNCTION public.st_resample(rast raster, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_gdalwarp($1, $8,	$9, NULL, $2, $3, $4, $5, $6, $7) $function$

COMMENT ON FUNCTION st_resample(raster,double precision,double precision,double precision,double precision,double precision,double precision,text,double precision) IS 'args: rast, scalex=0, scaley=0, gridx=NULL, gridy=NULL, skewx=0, skewy=0, algorithm=NearestNeighbor, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.'

/**********
 * Function: public.st_resample
 */
CREATE OR REPLACE FUNCTION public.st_resample(rast raster, width integer, height integer, gridx double precision DEFAULT NULL::double precision, gridy double precision DEFAULT NULL::double precision, skewx double precision DEFAULT 0, skewy double precision DEFAULT 0, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE
AS $function$ SELECT public._ST_gdalwarp($1, $8,	$9, NULL, NULL, NULL, $4, $5, $6, $7, $2, $3) $function$

COMMENT ON FUNCTION st_resample(raster,integer,integer,double precision,double precision,double precision,double precision,text,double precision) IS 'args: rast, width, height, gridx=NULL, gridy=NULL, skewx=0, skewy=0, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster using a specified resampling algorithm, new dimensions, an arbitrary grid corner and a set of raster georeferencing attributes defined or borrowed from another raster.'

/**********
 * Function: public.st_rescale
 */
CREATE OR REPLACE FUNCTION public.st_rescale(rast raster, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT  public._ST_GdalWarp($1, $4, $5, NULL, $2, $3) $function$

COMMENT ON FUNCTION st_rescale(raster,double precision,double precision,text,double precision) IS 'args: rast, scalex, scaley, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its scale (or pixel size). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_rescale
 */
CREATE OR REPLACE FUNCTION public.st_rescale(rast raster, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT  public._ST_GdalWarp($1, $3, $4, NULL, $2, $2) $function$

COMMENT ON FUNCTION st_rescale(raster,double precision,text,double precision) IS 'args: rast, scalexy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its scale (or pixel size). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_resize
 */
CREATE OR REPLACE FUNCTION public.st_resize(rast raster, percentwidth double precision, percentheight double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_resize(raster,double precision,double precision,text,double precision) IS 'args: rast, percentwidth, percentheight, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height'

/**********
 * Function: public.st_resize
 */
CREATE OR REPLACE FUNCTION public.st_resize(rast raster, width integer, height integer, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $4, $5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, abs($2), abs($3)) $function$

COMMENT ON FUNCTION st_resize(raster,integer,integer,text,double precision) IS 'args: rast, width, height, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height'

/**********
 * Function: public.st_resize
 */
CREATE OR REPLACE FUNCTION public.st_resize(rast raster, width text, height text, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_resize(raster,text,text,text,double precision) IS 'args: rast, width, height, algorithm=NearestNeighbor, maxerr=0.125 - Resize a raster to a new width/height'

/**********
 * Function: public.st_reskew
 */
CREATE OR REPLACE FUNCTION public.st_reskew(rast raster, skewx double precision, skewy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_GdalWarp($1, $4, $5, NULL, 0, 0, NULL, NULL, $2, $3) $function$

COMMENT ON FUNCTION st_reskew(raster,double precision,double precision,text,double precision) IS 'args: rast, skewx, skewy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its skew (or rotation parameters). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_reskew
 */
CREATE OR REPLACE FUNCTION public.st_reskew(rast raster, skewxy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_GdalWarp($1, $3, $4, NULL, 0, 0, NULL, NULL, $2, $2) $function$

COMMENT ON FUNCTION st_reskew(raster,double precision,text,double precision) IS 'args: rast, skewxy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by adjusting only its skew (or rotation parameters). New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_retile
 */
CREATE OR REPLACE FUNCTION public.st_retile(tab regclass, col name, ext geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text DEFAULT 'NearestNeighbour'::text)
 RETURNS SETOF raster
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
$function$

COMMENT ON FUNCTION st_retile(regclass,name,geometry,double precision,double precision,integer,integer,text) IS 'args: tab, col, ext, sfx, sfy, tw, th, algo=''NearestNeighbor'' - Return a set of configured tiles from an arbitrarily tiled raster coverage.'

/**********
 * Function: public.st_rotation
 */
CREATE OR REPLACE FUNCTION public.st_rotation(raster)
 RETURNS double precision
 LANGUAGE sql
AS $function$ SELECT ( public.ST_Geotransform($1)).theta_i $function$

COMMENT ON FUNCTION st_rotation(raster) IS 'args: rast - Returns the rotation of the raster in radian.'

/**********
 * Function: public.st_roughness
 */
CREATE OR REPLACE FUNCTION public.st_roughness(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_roughness
 */
CREATE OR REPLACE FUNCTION public.st_roughness(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_roughness($1, $2, NULL::raster, $3, $4) $function$



/**********
 * Function: public.st_samealignment
 */
CREATE OR REPLACE FUNCTION public.st_samealignment(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_sameAlignment$function$

COMMENT ON FUNCTION st_samealignment(raster,raster) IS 'args: rastA, rastB - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.'

/**********
 * Function: public.st_samealignment
 */
CREATE OR REPLACE FUNCTION public.st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_samealignment(st_makeemptyraster(1, 1, $1, $2, $3, $4, $5, $6), st_makeemptyraster(1, 1, $7, $8, $9, $10, $11, $12)) $function$

COMMENT ON FUNCTION st_samealignment(double precision,double precision,double precision,double precision,double precision,double precision,double precision,double precision,double precision,double precision,double precision,double precision) IS 'args: ulx1, uly1, scalex1, scaley1, skewx1, skewy1, ulx2, uly2, scalex2, scaley2, skewx2, skewy2 - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.'

/**********
 * Function: public.st_scalex
 */
CREATE OR REPLACE FUNCTION public.st_scalex(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getXScale$function$

COMMENT ON FUNCTION st_scalex(raster) IS 'args: rast - Returns the X component of the pixel width in units of coordinate reference system.'

/**********
 * Function: public.st_scaley
 */
CREATE OR REPLACE FUNCTION public.st_scaley(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getYScale$function$

COMMENT ON FUNCTION st_scaley(raster) IS 'args: rast - Returns the Y component of the pixel height in units of coordinate reference system.'

/**********
 * Function: public.st_setbandisnodata
 */
CREATE OR REPLACE FUNCTION public.st_setbandisnodata(rast raster, band integer DEFAULT 1)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setBandIsNoData$function$

COMMENT ON FUNCTION st_setbandisnodata(raster,integer) IS 'args: rast, band=1 - Sets the isnodata flag of the band to TRUE.'

/**********
 * Function: public.st_setbandnodatavalue
 */
CREATE OR REPLACE FUNCTION public.st_setbandnodatavalue(rast raster, band integer, nodatavalue double precision, forcechecking boolean DEFAULT false)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_setBandNoDataValue$function$

COMMENT ON FUNCTION st_setbandnodatavalue(raster,integer,double precision,boolean) IS 'args: rast, band, nodatavalue, forcechecking=false - Sets the value for the given band that represents no data. Band 1 is assumed if no band is specified. To mark a band as having no nodata value, set the nodata value = NULL.'

/**********
 * Function: public.st_setbandnodatavalue
 */
CREATE OR REPLACE FUNCTION public.st_setbandnodatavalue(rast raster, nodatavalue double precision)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_setbandnodatavalue($1, 1, $2, FALSE) $function$

COMMENT ON FUNCTION st_setbandnodatavalue(raster,double precision) IS 'args: rast, nodatavalue - Sets the value for the given band that represents no data. Band 1 is assumed if no band is specified. To mark a band as having no nodata value, set the nodata value = NULL.'

/**********
 * Function: public.st_setgeoreference
 */
CREATE OR REPLACE FUNCTION public.st_setgeoreference(rast raster, georef text, format text DEFAULT 'GDAL'::text)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
    $function$

COMMENT ON FUNCTION st_setgeoreference(raster,text,text) IS 'args: rast, georefcoords, format=GDAL - Set Georeference 6 georeference parameters in a single call. Numbers should be separated by white space. Accepts inputs in GDAL or ESRI format. Default is GDAL.'

/**********
 * Function: public.st_setgeoreference
 */
CREATE OR REPLACE FUNCTION public.st_setgeoreference(rast raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_setgeoreference($1, array_to_string(ARRAY[$4, $7, $6, $5, $2, $3], ' ')) $function$

COMMENT ON FUNCTION st_setgeoreference(raster,double precision,double precision,double precision,double precision,double precision,double precision) IS 'args: rast, upperleftx, upperlefty, scalex, scaley, skewx, skewy - Set Georeference 6 georeference parameters in a single call. Numbers should be separated by white space. Accepts inputs in GDAL or ESRI format. Default is GDAL.'

/**********
 * Function: public.st_setgeotransform
 */
CREATE OR REPLACE FUNCTION public.st_setgeotransform(rast raster, imag double precision, jmag double precision, theta_i double precision, theta_ij double precision, xoffset double precision, yoffset double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_setGeotransform$function$



/**********
 * Function: public.st_setrotation
 */
CREATE OR REPLACE FUNCTION public.st_setrotation(rast raster, rotation double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setRotation$function$

COMMENT ON FUNCTION st_setrotation(raster,double precision) IS 'args: rast, rotation - Set the rotation of the raster in radian.'

/**********
 * Function: public.st_setscale
 */
CREATE OR REPLACE FUNCTION public.st_setscale(rast raster, scale double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setScale$function$

COMMENT ON FUNCTION st_setscale(raster,double precision) IS 'args: rast, xy - Sets the X and Y size of pixels in units of coordinate reference system. Number units/pixel width/height.'

/**********
 * Function: public.st_setscale
 */
CREATE OR REPLACE FUNCTION public.st_setscale(rast raster, scalex double precision, scaley double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setScaleXY$function$

COMMENT ON FUNCTION st_setscale(raster,double precision,double precision) IS 'args: rast, x, y - Sets the X and Y size of pixels in units of coordinate reference system. Number units/pixel width/height.'

/**********
 * Function: public.st_setskew
 */
CREATE OR REPLACE FUNCTION public.st_setskew(rast raster, skew double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setSkew$function$

COMMENT ON FUNCTION st_setskew(raster,double precision) IS 'args: rast, skewxy - Sets the georeference X and Y skew (or rotation parameter). If only one is passed in, sets X and Y to the same value.'

/**********
 * Function: public.st_setskew
 */
CREATE OR REPLACE FUNCTION public.st_setskew(rast raster, skewx double precision, skewy double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setSkewXY$function$

COMMENT ON FUNCTION st_setskew(raster,double precision,double precision) IS 'args: rast, skewx, skewy - Sets the georeference X and Y skew (or rotation parameter). If only one is passed in, sets X and Y to the same value.'

/**********
 * Function: public.st_setsrid
 */
CREATE OR REPLACE FUNCTION public.st_setsrid(rast raster, srid integer)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setSRID$function$

COMMENT ON FUNCTION st_setsrid(raster,integer) IS 'args: rast, srid - Sets the SRID of a raster to a particular integer srid defined in the spatial_ref_sys table.'

/**********
 * Function: public.st_setupperleft
 */
CREATE OR REPLACE FUNCTION public.st_setupperleft(rast raster, upperleftx double precision, upperlefty double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_setUpperLeftXY$function$

COMMENT ON FUNCTION st_setupperleft(raster,double precision,double precision) IS 'args: rast, x, y - Sets the value of the upper left corner of the pixel to projected X and Y coordinates.'

/**********
 * Function: public.st_setvalue
 */
CREATE OR REPLACE FUNCTION public.st_setvalue(rast raster, band integer, x integer, y integer, newvalue double precision)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_setPixelValue$function$

COMMENT ON FUNCTION st_setvalue(raster,integer,integer,integer,double precision) IS 'args: rast, bandnum, columnx, rowy, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.'

/**********
 * Function: public.st_setvalue
 */
CREATE OR REPLACE FUNCTION public.st_setvalue(rast raster, geom geometry, newvalue double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_setvalues($1, 1, ARRAY[ROW($2, $3)]::geomval[], FALSE) $function$

COMMENT ON FUNCTION st_setvalue(raster,geometry,double precision) IS 'args: rast, geom, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.'

/**********
 * Function: public.st_setvalue
 */
CREATE OR REPLACE FUNCTION public.st_setvalue(rast raster, nband integer, geom geometry, newvalue double precision)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_setvalues($1, $2, ARRAY[ROW($3, $4)]::geomval[], FALSE) $function$

COMMENT ON FUNCTION st_setvalue(raster,integer,geometry,double precision) IS 'args: rast, bandnum, geom, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.'

/**********
 * Function: public.st_setvalue
 */
CREATE OR REPLACE FUNCTION public.st_setvalue(rast raster, x integer, y integer, newvalue double precision)
 RETURNS raster
 LANGUAGE sql
AS $function$ SELECT public.ST_setvalue($1, 1, $2, $3, $4) $function$

COMMENT ON FUNCTION st_setvalue(raster,integer,integer,double precision) IS 'args: rast, columnx, rowy, newvalue - Returns modified raster resulting from setting the value of a given band in a given columnx, rowy pixel or the pixels that intersect a particular geometry. Band numbers start at 1 and assumed to be 1 if not specified.'

/**********
 * Function: public.st_setvalues
 */
CREATE OR REPLACE FUNCTION public.st_setvalues(rast raster, nband integer, geomvalset geomval[], keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/rtpostgis-2.3', $function$RASTER_setPixelValuesGeomval$function$

COMMENT ON FUNCTION st_setvalues(raster,integer,geomval[],boolean) IS 'args: rast, nband, geomvalset, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.'

/**********
 * Function: public.st_setvalues
 */
CREATE OR REPLACE FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[] DEFAULT NULL::boolean[], keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_setvalues($1, $2, $3, $4, $5, $6, FALSE, NULL, $7) $function$

COMMENT ON FUNCTION st_setvalues(raster,integer,integer,integer,double precision[],boolean[],boolean) IS 'args: rast, nband, columnx, rowy, newvalueset, noset=NULL, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.'

/**********
 * Function: public.st_setvalues
 */
CREATE OR REPLACE FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_setvalues($1, $2, $3, $4, $5, NULL, TRUE, $6, $7) $function$

COMMENT ON FUNCTION st_setvalues(raster,integer,integer,integer,double precision[],double precision,boolean) IS 'args: rast, nband, columnx, rowy, newvalueset, nosetvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.'

/**********
 * Function: public.st_setvalues
 */
CREATE OR REPLACE FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
	BEGIN
		IF width <= 0 OR height <= 0 THEN
			RAISE EXCEPTION 'Values for width and height must be greater than zero';
			RETURN NULL;
		END IF;
		RETURN public._ST_setvalues($1, $2, $3, $4, array_fill($7, ARRAY[$6, $5]::int[]), NULL, FALSE, NULL, $8);
	END;
	$function$

COMMENT ON FUNCTION st_setvalues(raster,integer,integer,integer,integer,integer,double precision,boolean) IS 'args: rast, nband, columnx, rowy, width, height, newvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.'

/**********
 * Function: public.st_setvalues
 */
CREATE OR REPLACE FUNCTION public.st_setvalues(rast raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
	BEGIN
		IF width <= 0 OR height <= 0 THEN
			RAISE EXCEPTION 'Values for width and height must be greater than zero';
			RETURN NULL;
		END IF;
		RETURN public._ST_setvalues($1, 1, $2, $3, array_fill($6, ARRAY[$5, $4]::int[]), NULL, FALSE, NULL, $7);
	END;
	$function$

COMMENT ON FUNCTION st_setvalues(raster,integer,integer,integer,integer,double precision,boolean) IS 'args: rast, columnx, rowy, width, height, newvalue, keepnodata=FALSE - Returns modified raster resulting from setting the values of a given band.'

/**********
 * Function: public.st_skewx
 */
CREATE OR REPLACE FUNCTION public.st_skewx(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getXSkew$function$

COMMENT ON FUNCTION st_skewx(raster) IS 'args: rast - Returns the georeference X skew (or rotation parameter).'

/**********
 * Function: public.st_skewy
 */
CREATE OR REPLACE FUNCTION public.st_skewy(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getYSkew$function$

COMMENT ON FUNCTION st_skewy(raster) IS 'args: rast - Returns the georeference Y skew (or rotation parameter).'

/**********
 * Function: public.st_slope
 */
CREATE OR REPLACE FUNCTION public.st_slope(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_slope
 */
CREATE OR REPLACE FUNCTION public.st_slope(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, units text DEFAULT 'DEGREES'::text, scale double precision DEFAULT 1.0, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_slope($1, $2, NULL::raster, $3, $4, $5, $6) $function$



/**********
 * Function: public.st_snaptogrid
 */
CREATE OR REPLACE FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_GdalWarp($1, $4, $5, NULL, $6, $7, $2, $3) $function$

COMMENT ON FUNCTION st_snaptogrid(raster,double precision,double precision,text,double precision,double precision,double precision) IS 'args: rast, gridx, gridy, algorithm=NearestNeighbour, maxerr=0.125, scalex=DEFAULT 0, scaley=DEFAULT 0 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_snaptogrid
 */
CREATE OR REPLACE FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $6, $7, NULL, $4, $5, $2, $3) $function$

COMMENT ON FUNCTION st_snaptogrid(raster,double precision,double precision,double precision,double precision,text,double precision) IS 'args: rast, gridx, gridy, scalex, scaley, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_snaptogrid
 */
CREATE OR REPLACE FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $5, $6, NULL, $4, $4, $2, $3) $function$

COMMENT ON FUNCTION st_snaptogrid(raster,double precision,double precision,double precision,text,double precision) IS 'args: rast, gridx, gridy, scalexy, algorithm=NearestNeighbour, maxerr=0.125 - Resample a raster by snapping it to a grid. New pixel values are computed using the NearestNeighbor (english or american spelling), Bilinear, Cubic, CubicSpline or Lanczos resampling algorithm. Default is NearestNeighbor.'

/**********
 * Function: public.st_srid
 */
CREATE OR REPLACE FUNCTION public.st_srid(raster)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getSRID$function$

COMMENT ON FUNCTION st_srid(raster) IS 'args: rast - Returns the spatial reference identifier of the raster as defined in spatial_ref_sys table.'

/**********
 * Function: public.st_stddev4ma
 */
CREATE OR REPLACE FUNCTION public.st_stddev4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT stddev(unnest) FROM unnest($1) $function$



/**********
 * Function: public.st_stddev4ma
 */
CREATE OR REPLACE FUNCTION public.st_stddev4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT stddev(unnest) FROM unnest($1) $function$



/**********
 * Function: public.st_sum4ma
 */
CREATE OR REPLACE FUNCTION public.st_sum4ma(matrix double precision[], nodatamode text, VARIADIC args text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
    $function$



/**********
 * Function: public.st_sum4ma
 */
CREATE OR REPLACE FUNCTION public.st_sum4ma(value double precision[], pos integer[], VARIADIC userargs text[] DEFAULT NULL::text[])
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_summary
 */
CREATE OR REPLACE FUNCTION public.st_summary(rast raster)
 RETURNS text
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_summary(raster) IS 'args: rast - Returns a text summary of the contents of the raster.'

/**********
 * Function: public.st_summarystats
 */
CREATE OR REPLACE FUNCTION public.st_summarystats(rastertable text, rastercolumn text, exclude_nodata_value boolean)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, 1, $3, 1) $function$

COMMENT ON FUNCTION st_summarystats(text,text,boolean) IS 'args: rastertable, rastercolumn, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.'

/**********
 * Function: public.st_summarystats
 */
CREATE OR REPLACE FUNCTION public.st_summarystats(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true)
 RETURNS summarystats
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, $3, $4, 1) $function$

COMMENT ON FUNCTION st_summarystats(text,text,integer,boolean) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.'

/**********
 * Function: public.st_summarystats
 */
CREATE OR REPLACE FUNCTION public.st_summarystats(rast raster, exclude_nodata_value boolean)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, 1, $2, 1) $function$

COMMENT ON FUNCTION st_summarystats(raster,boolean) IS 'args: rast, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.'

/**********
 * Function: public.st_summarystats
 */
CREATE OR REPLACE FUNCTION public.st_summarystats(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true)
 RETURNS summarystats
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public._ST_summarystats($1, $2, $3, 1) $function$

COMMENT ON FUNCTION st_summarystats(raster,integer,boolean) IS 'args: rast, nband, exclude_nodata_value - Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a raster or raster coverage. Band 1 is assumed is no band is specified.'

/**********
 * Function: public.st_tile
 */
CREATE OR REPLACE FUNCTION public.st_tile(rast raster, nband integer[], width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision)
 RETURNS SETOF raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_tile($1, $3, $4, $2, $5, $6) $function$

COMMENT ON FUNCTION st_tile(raster,integer[],integer,integer,boolean,double precision) IS 'args: rast, nband, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.'

/**********
 * Function: public.st_tile
 */
CREATE OR REPLACE FUNCTION public.st_tile(rast raster, nband integer, width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision)
 RETURNS SETOF raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_tile($1, $3, $4, ARRAY[$2]::integer[], $5, $6) $function$

COMMENT ON FUNCTION st_tile(raster,integer,integer,integer,boolean,double precision) IS 'args: rast, nband, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.'

/**********
 * Function: public.st_tile
 */
CREATE OR REPLACE FUNCTION public.st_tile(rast raster, width integer, height integer, padwithnodata boolean DEFAULT false, nodataval double precision DEFAULT NULL::double precision)
 RETURNS SETOF raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_tile($1, $2, $3, NULL::integer[], $4, $5) $function$

COMMENT ON FUNCTION st_tile(raster,integer,integer,boolean,double precision) IS 'args: rast, width, height, padwithnodata=FALSE, nodataval=NULL - Returns a set of rasters resulting from the split of the input raster based upon the desired dimensions of the output rasters.'

/**********
 * Function: public.st_touches
 */
CREATE OR REPLACE FUNCTION public.st_touches(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_touches(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_touches($1, $2, $3, $4) END $function$

COMMENT ON FUNCTION st_touches(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if raster rastA and rastB have at least one point in common but their interiors do not intersect.'

/**********
 * Function: public.st_touches
 */
CREATE OR REPLACE FUNCTION public.st_touches(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_touches($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_touches(raster,raster) IS 'args: rastA, rastB - Return true if raster rastA and rastB have at least one point in common but their interiors do not intersect.'

/**********
 * Function: public.st_tpi
 */
CREATE OR REPLACE FUNCTION public.st_tpi(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_tpi
 */
CREATE OR REPLACE FUNCTION public.st_tpi(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_tpi($1, $2, NULL::raster, $3, $4) $function$



/**********
 * Function: public.st_transform
 */
CREATE OR REPLACE FUNCTION public.st_transform(rast raster, alignto raster, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_transform(raster,raster,text,double precision) IS 'args: rast, alignto, algorithm=NearestNeighbor, maxerr=0.125 - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.'

/**********
 * Function: public.st_transform
 */
CREATE OR REPLACE FUNCTION public.st_transform(rast raster, srid integer, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125, scalex double precision DEFAULT 0, scaley double precision DEFAULT 0)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $3, $4, $2, $5, $6) $function$

COMMENT ON FUNCTION st_transform(raster,integer,text,double precision,double precision,double precision) IS 'args: rast, srid, algorithm=NearestNeighbor, maxerr=0.125, scalex, scaley - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.'

/**********
 * Function: public.st_transform
 */
CREATE OR REPLACE FUNCTION public.st_transform(rast raster, srid integer, scalex double precision, scaley double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $5, $6, $2, $3, $4) $function$

COMMENT ON FUNCTION st_transform(raster,integer,double precision,double precision,text,double precision) IS 'args: rast, srid, scalex, scaley, algorithm=NearestNeighbor, maxerr=0.125 - Reprojects a raster in a known spatial reference system to another known spatial reference system using specified resampling algorithm. Options are NearestNeighbor, Bilinear, Cubic, CubicSpline, Lanczos defaulting to NearestNeighbor.'

/**********
 * Function: public.st_transform
 */
CREATE OR REPLACE FUNCTION public.st_transform(rast raster, srid integer, scalexy double precision, algorithm text DEFAULT 'NearestNeighbour'::text, maxerr double precision DEFAULT 0.125)
 RETURNS raster
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT public._ST_gdalwarp($1, $4, $5, $2, $3, $3) $function$



/**********
 * Function: public.st_tri
 */
CREATE OR REPLACE FUNCTION public.st_tri(rast raster, nband integer, customextent raster, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE
AS $function$
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
	$function$



/**********
 * Function: public.st_tri
 */
CREATE OR REPLACE FUNCTION public.st_tri(rast raster, nband integer DEFAULT 1, pixeltype text DEFAULT '32BF'::text, interpolate_nodata boolean DEFAULT false)
 RETURNS raster
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_tri($1, $2, NULL::raster, $3, $4) $function$



/**********
 * Function: public.st_upperleftx
 */
CREATE OR REPLACE FUNCTION public.st_upperleftx(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getXUpperLeft$function$

COMMENT ON FUNCTION st_upperleftx(raster) IS 'args: rast - Returns the upper left X coordinate of raster in projected spatial ref.'

/**********
 * Function: public.st_upperlefty
 */
CREATE OR REPLACE FUNCTION public.st_upperlefty(raster)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getYUpperLeft$function$

COMMENT ON FUNCTION st_upperlefty(raster) IS 'args: rast - Returns the upper left Y coordinate of raster in projected spatial ref.'

/**********
 * Function: public.st_value
 */
CREATE OR REPLACE FUNCTION public.st_value(rast raster, band integer, pt geometry, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
    $function$

COMMENT ON FUNCTION st_value(raster,integer,geometry,boolean) IS 'args: rast, band, pt, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.'

/**********
 * Function: public.st_value
 */
CREATE OR REPLACE FUNCTION public.st_value(rast raster, band integer, x integer, y integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getPixelValue$function$

COMMENT ON FUNCTION st_value(raster,integer,integer,integer,boolean) IS 'args: rast, band, x, y, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.'

/**********
 * Function: public.st_value
 */
CREATE OR REPLACE FUNCTION public.st_value(rast raster, pt geometry, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_value($1, 1, $2, $3) $function$

COMMENT ON FUNCTION st_value(raster,geometry,boolean) IS 'args: rast, pt, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.'

/**********
 * Function: public.st_value
 */
CREATE OR REPLACE FUNCTION public.st_value(rast raster, x integer, y integer, exclude_nodata_value boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT st_value($1, 1, $2, $3, $4) $function$

COMMENT ON FUNCTION st_value(raster,integer,integer,boolean) IS 'args: rast, x, y, exclude_nodata_value=true - Returns the value of a given band in a given columnx, rowy pixel or at a particular geometric point. Band numbers start at 1 and assumed to be 1 if not specified. If exclude_nodata_value is set to false, then all pixels include nodata pixels are considered to intersect and return value. If exclude_nodata_value is not passed in then reads it from metadata of raster.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, $4, $5, $6) $function$

COMMENT ON FUNCTION st_valuecount(text,text,integer,boolean,double precision[],double precision) IS 'args: rastertable, rastercolumn, nband=1, exclude_nodata_value=true, searchvalues=NULL, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, $4, ARRAY[$5]::double precision[], $6)).count $function$

COMMENT ON FUNCTION st_valuecount(text,text,integer,boolean,double precision,double precision) IS 'args: rastertable, rastercolumn, nband, exclude_nodata_value, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, TRUE, ARRAY[$4]::double precision[], $5)).count $function$

COMMENT ON FUNCTION st_valuecount(text,text,integer,double precision,double precision) IS 'args: rastertable, rastercolumn, nband, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, TRUE, $4, $5) $function$

COMMENT ON FUNCTION st_valuecount(text,text,integer,double precision[],double precision) IS 'args: rastertable, rastercolumn, nband, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, 1, TRUE, ARRAY[$3]::double precision[], $4)).count $function$

COMMENT ON FUNCTION st_valuecount(text,text,double precision,double precision) IS 'args: rastertable, rastercolumn, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, $2, 1, TRUE, $3, $4) $function$

COMMENT ON FUNCTION st_valuecount(text,text,double precision[],double precision) IS 'args: rastertable, rastercolumn, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, $2, $3, $4, $5) $function$

COMMENT ON FUNCTION st_valuecount(raster,integer,boolean,double precision[],double precision) IS 'args: rast, nband=1, exclude_nodata_value=true, searchvalues=NULL, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, ARRAY[$4]::double precision[], $5)).count $function$

COMMENT ON FUNCTION st_valuecount(raster,integer,boolean,double precision,double precision) IS 'args: rast, nband, exclude_nodata_value, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, nband integer, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, TRUE, ARRAY[$3]::double precision[], $4)).count $function$

COMMENT ON FUNCTION st_valuecount(raster,integer,double precision,double precision) IS 'args: rast, nband, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, $2, TRUE, $3, $4) $function$

COMMENT ON FUNCTION st_valuecount(raster,integer,double precision[],double precision) IS 'args: rast, nband, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, 1, TRUE, ARRAY[$2]::double precision[], $3)).count $function$

COMMENT ON FUNCTION st_valuecount(raster,double precision,double precision) IS 'args: rast, searchvalue, roundto=0 - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuecount
 */
CREATE OR REPLACE FUNCTION public.st_valuecount(rast raster, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT count integer)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, count FROM public._ST_valuecount($1, 1, TRUE, $2, $3) $function$

COMMENT ON FUNCTION st_valuecount(raster,double precision[],double precision) IS 'args: rast, searchvalues, roundto=0, OUT value, OUT count - Returns a set of records containing a pixel band value and count of the number of pixels in a given band of a raster (or a raster coverage) that have a given set of values. If no band is specified defaults to band 1. By default nodata value pixels are not counted. and all other values in the pixel are output and pixel band values are rounded to the nearest integer.'

/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, $4, $5, $6) $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, $4, ARRAY[$5]::double precision[], $6)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, TRUE, ARRAY[$4]::double precision[], $5)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, TRUE, $4, $5) $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 STABLE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, 1, TRUE, ARRAY[$3]::double precision[], $4)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 STABLE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, $2, 1, TRUE, $3, $4) $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, nband integer DEFAULT 1, exclude_nodata_value boolean DEFAULT true, searchvalues double precision[] DEFAULT NULL::double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, $2, $3, $4, $5) $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, $3, ARRAY[$4]::double precision[], $5)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, nband integer, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, $2, TRUE, ARRAY[$3]::double precision[], $4)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, nband integer, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, $2, TRUE, $3, $4) $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, searchvalue double precision, roundto double precision DEFAULT 0)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT ( public._ST_valuecount($1, 1, TRUE, ARRAY[$2]::double precision[], $3)).percent $function$



/**********
 * Function: public.st_valuepercent
 */
CREATE OR REPLACE FUNCTION public.st_valuepercent(rast raster, searchvalues double precision[], roundto double precision DEFAULT 0, OUT value double precision, OUT percent double precision)
 RETURNS SETOF record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT value, percent FROM public._ST_valuecount($1, 1, TRUE, $2, $3) $function$



/**********
 * Function: public.st_width
 */
CREATE OR REPLACE FUNCTION public.st_width(raster)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/rtpostgis-2.3', $function$RASTER_getWidth$function$

COMMENT ON FUNCTION st_width(raster) IS 'args: rast - Returns the width of the raster in pixels.'

/**********
 * Function: public.st_within
 */
CREATE OR REPLACE FUNCTION public.st_within(rast1 raster, nband1 integer, rast2 raster, nband2 integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT $1 OPERATOR(public.&&) $3 AND CASE WHEN $2 IS NULL OR $4 IS NULL THEN public._st_within(public.st_convexhull($1), public.st_convexhull($3)) ELSE public._st_contains($3, $4, $1, $2) END $function$

COMMENT ON FUNCTION st_within(raster,integer,raster,integer) IS 'args: rastA, nbandA, rastB, nbandB - Return true if no points of raster rastA lie in the exterior of raster rastB and at least one point of the interior of rastA lies in the interior of rastB.'

/**********
 * Function: public.st_within
 */
CREATE OR REPLACE FUNCTION public.st_within(rast1 raster, rast2 raster)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1000
AS $function$ SELECT public.st_within($1, NULL::integer, $2, NULL::integer) $function$

COMMENT ON FUNCTION st_within(raster,raster) IS 'args: rastA, rastB - Return true if no points of raster rastA lie in the exterior of raster rastB and at least one point of the interior of rastA lies in the interior of rastB.'

/**********
 * Function: public.st_worldtorastercoord
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoord(rast raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer)
 RETURNS record
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT columnx, rowy FROM public._ST_worldtorastercoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_worldtorastercoord(raster,double precision,double precision) IS 'args: rast, longitude, latitude - Returns the upper left corner as column and row given geometric X and Y (longitude and latitude) or a point geometry expressed in the spatial reference coordinate system of the raster.'

/**********
 * Function: public.st_worldtorastercoord
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoord(rast raster, pt geometry, OUT columnx integer, OUT rowy integer)
 RETURNS record
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_worldtorastercoord(raster,geometry) IS 'args: rast, pt - Returns the upper left corner as column and row given geometric X and Y (longitude and latitude) or a point geometry expressed in the spatial reference coordinate system of the raster.'

/**********
 * Function: public.st_worldtorastercoordx
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordx(rast raster, pt geometry)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_worldtorastercoordx(raster,geometry) IS 'args: rast, pt - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.st_worldtorastercoordx
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordx(rast raster, xw double precision)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT columnx FROM public._ST_worldtorastercoord($1, $2, NULL) $function$

COMMENT ON FUNCTION st_worldtorastercoordx(raster,double precision) IS 'args: rast, xw - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.st_worldtorastercoordx
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordx(rast raster, xw double precision, yw double precision)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT columnx FROM public._ST_worldtorastercoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_worldtorastercoordx(raster,double precision,double precision) IS 'args: rast, xw, yw - Returns the column in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.st_worldtorastercoordy
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordy(rast raster, pt geometry)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
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
	$function$

COMMENT ON FUNCTION st_worldtorastercoordy(raster,geometry) IS 'args: rast, pt - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.st_worldtorastercoordy
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordy(rast raster, xw double precision, yw double precision)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT rowy FROM public._ST_worldtorastercoord($1, $2, $3) $function$

COMMENT ON FUNCTION st_worldtorastercoordy(raster,double precision,double precision) IS 'args: rast, xw, yw - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.st_worldtorastercoordy
 */
CREATE OR REPLACE FUNCTION public.st_worldtorastercoordy(rast raster, yw double precision)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT rowy FROM public._ST_worldtorastercoord($1, NULL, $2) $function$

COMMENT ON FUNCTION st_worldtorastercoordy(raster,double precision) IS 'args: rast, xw - Returns the row in the raster of the point geometry (pt) or a X and Y world coordinate (xw, yw) represented in world spatial reference system of raster.'

/**********
 * Function: public.updaterastersrid
 */
CREATE OR REPLACE FUNCTION public.updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._UpdateRasterSRID($1, $2, $3, $4) $function$

COMMENT ON FUNCTION updaterastersrid(name,name,name,integer) IS 'args: schema_name, table_name, column_name, new_srid - Change the SRID of all rasters in the user-specified column and table.'

/**********
 * Function: public.updaterastersrid
 */
CREATE OR REPLACE FUNCTION public.updaterastersrid(table_name name, column_name name, new_srid integer)
 RETURNS boolean
 LANGUAGE sql
 STRICT
AS $function$ SELECT  public._UpdateRasterSRID('', $1, $2, $3) $function$

COMMENT ON FUNCTION updaterastersrid(name,name,integer) IS 'args: table_name, column_name, new_srid - Change the SRID of all rasters in the user-specified column and table.'

/**********
 * Function: public.wavg_finalfunc
 */
CREATE OR REPLACE FUNCTION public.wavg_finalfunc(agg_state point)
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
begin
    IF COALESCE(agg_state[1], 0) = 0 THEN
        RETURN 0;
    ELSE
        return agg_state[0] / agg_state[1];
    END IF;
end;
$function$



/**********
 * Function: public.wavg_sfunc
 */
CREATE OR REPLACE FUNCTION public.wavg_sfunc(agg_state point, value double precision, weight double precision)
 RETURNS point
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$



/**********
 * Aggregate: public.st_countagg
 */
CREATE AGGREGATE st_countagg(raster,integer,boolean) (SFUNC = public._st_countagg_transfn, STYPE = agg_count, FINALFUNC = 1538285)
COMMENT ON AGGREGATE st_countagg(raster,integer,boolean) IS 'args: rast, nband, exclude_nodata_value - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.'

/**********
 * Aggregate: public.st_countagg
 */
CREATE AGGREGATE st_countagg(raster,boolean) (SFUNC = public._st_countagg_transfn, STYPE = agg_count, FINALFUNC = 1538285)
COMMENT ON AGGREGATE st_countagg(raster,boolean) IS 'args: rast, exclude_nodata_value - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.'

/**********
 * Aggregate: public.st_countagg
 */
CREATE AGGREGATE st_countagg(raster,integer,boolean,double precision) (SFUNC = public._st_countagg_transfn, STYPE = agg_count, FINALFUNC = 1538285)
COMMENT ON AGGREGATE st_countagg(raster,integer,boolean,double precision) IS 'args: rast, nband, exclude_nodata_value, sample_percent - Aggregate. Returns the number of pixels in a given band of a set of rasters. If no band is specified defaults to band 1. If exclude_nodata_value is set to true, will only count pixels that are not equal to the NODATA value.'

/**********
 * Aggregate: public.st_samealignment
 */
CREATE AGGREGATE st_samealignment(raster) (SFUNC = _st_samealignment_transfn, STYPE = agg_samealignment, FINALFUNC = 1538627)
COMMENT ON AGGREGATE st_samealignment(raster) IS 'args: rastfield - Returns true if rasters have same skew, scale, spatial ref, and offset (pixels can be put on same grid without cutting into pixels) and false if they dont with notice detailing issue.'

/**********
 * Aggregate: public.st_summarystatsagg
 */
CREATE AGGREGATE st_summarystatsagg(raster,integer,boolean,double precision) (SFUNC = public._st_summarystats_transfn, STYPE = internal, FINALFUNC = 1538261)
COMMENT ON AGGREGATE st_summarystatsagg(raster,integer,boolean,double precision) IS 'args: rast, nband, exclude_nodata_value, sample_percent - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.'

/**********
 * Aggregate: public.st_summarystatsagg
 */
CREATE AGGREGATE st_summarystatsagg(raster,boolean,double precision) (SFUNC = public._st_summarystats_transfn, STYPE = internal, FINALFUNC = 1538261)
COMMENT ON AGGREGATE st_summarystatsagg(raster,boolean,double precision) IS 'args: rast, exclude_nodata_value, sample_percent - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.'

/**********
 * Aggregate: public.st_summarystatsagg
 */
CREATE AGGREGATE st_summarystatsagg(raster,integer,boolean) (SFUNC = public._st_summarystats_transfn, STYPE = internal, FINALFUNC = 1538261)
COMMENT ON AGGREGATE st_summarystatsagg(raster,integer,boolean) IS 'args: rast, nband, exclude_nodata_value - Aggregate. Returns summarystats consisting of count, sum, mean, stddev, min, max for a given raster band of a set of raster. Band 1 is assumed is no band is specified.'

/**********
 * Aggregate: public.st_union
 */
CREATE AGGREGATE st_union(raster,unionarg[]) (SFUNC = public._st_union_transfn, STYPE = internal, FINALFUNC = 1538681)
None

/**********
 * Aggregate: public.st_union
 */
CREATE AGGREGATE st_union(raster,integer,text) (SFUNC = public._st_union_transfn, STYPE = internal, FINALFUNC = 1538681)
None

/**********
 * Aggregate: public.st_union
 */
CREATE AGGREGATE st_union(raster,integer) (SFUNC = public._st_union_transfn, STYPE = internal, FINALFUNC = 1538681)
None

/**********
 * Aggregate: public.st_union
 */
CREATE AGGREGATE st_union(raster) (SFUNC = public._st_union_transfn, STYPE = internal, FINALFUNC = 1538681)
None

/**********
 * Aggregate: public.st_union
 */
CREATE AGGREGATE st_union(raster,text) (SFUNC = public._st_union_transfn, STYPE = internal, FINALFUNC = 1538681)
None

/**********
 * Aggregate: public.weighted_avg
 */
CREATE AGGREGATE weighted_avg(double precision,double precision) (SFUNC = wavg_sfunc, STYPE = point, INITCOND = (0,0), FINALFUNC = 1538822)
None

/**********
 * sequence: log.process_query_function_logs_id_seq
 */
CREATE SEQUENCE log.process_query_function_logs_id_seq;

/**********
 * sequence: log.trigger_logs_id_seq
 */
CREATE SEQUENCE log.trigger_logs_id_seq;

/**********
 * sequence: public.business_objects_translations_id_seq
 */
CREATE SEQUENCE public.business_objects_translations_id_seq;

/**********
 * sequence: public.clients_id_seq
 */
CREATE SEQUENCE public.clients_id_seq;

/**********
 * sequence: public.concretes_by_declareds_id_seq
 */
CREATE SEQUENCE public.concretes_by_declareds_id_seq;

/**********
 * sequence: public.data_types_by_pixels_id_seq
 */
CREATE SEQUENCE public.data_types_by_pixels_id_seq;

/**********
 * sequence: public.data_types_id_seq
 */
CREATE SEQUENCE public.data_types_id_seq;

/**********
 * sequence: public.date_by_process_f2_id_seq
 */
CREATE SEQUENCE public.date_by_process_f2_id_seq;

/**********
 * sequence: public.db_actions_logs_id_seq
 */
CREATE SEQUENCE public.db_actions_logs_id_seq;

/**********
 * sequence: public.declarations_concrete_id_seq
 */
CREATE SEQUENCE public.declarations_concrete_id_seq;

/**********
 * sequence: public.declarations_id_seq
 */
CREATE SEQUENCE public.declarations_id_seq;

/**********
 * sequence: public.farms_id_seq
 */
CREATE SEQUENCE public.farms_id_seq;

/**********
 * sequence: public.fields_id_seq
 */
CREATE SEQUENCE public.fields_id_seq;

/**********
 * sequence: public.format_types_id_seq
 */
CREATE SEQUENCE public.format_types_id_seq;

/**********
 * sequence: public.functions_id_seq
 */
CREATE SEQUENCE public.functions_id_seq;

/**********
 * sequence: public.groups_by_options_id_seq
 */
CREATE SEQUENCE public.groups_by_options_id_seq;

/**********
 * sequence: public.imagen_types_id_seq
 */
CREATE SEQUENCE public.imagen_types_id_seq;

/**********
 * sequence: public.import_data_id_seq
 */
CREATE SEQUENCE public.import_data_id_seq;

/**********
 * sequence: public.layer_types_id_seq
 */
CREATE SEQUENCE public.layer_types_id_seq;

/**********
 * sequence: public.layers_id_seq
 */
CREATE SEQUENCE public.layers_id_seq;

/**********
 * sequence: public.log_import_fields_id_seq
 */
CREATE SEQUENCE public.log_import_fields_id_seq;

/**********
 * sequence: public.log_import_images_id_seq
 */
CREATE SEQUENCE public.log_import_images_id_seq;

/**********
 * sequence: public.log_process_functions_id_seq
 */
CREATE SEQUENCE public.log_process_functions_id_seq;

/**********
 * sequence: public.maps_id_seq
 */
CREATE SEQUENCE public.maps_id_seq;

/**********
 * sequence: public.menu_options_id_seq
 */
CREATE SEQUENCE public.menu_options_id_seq;

/**********
 * sequence: public.organizations_id_seq
 */
CREATE SEQUENCE public.organizations_id_seq;

/**********
 * sequence: public.parameter_types_id_seq
 */
CREATE SEQUENCE public.parameter_types_id_seq;

/**********
 * sequence: public.parameters_id_seq
 */
CREATE SEQUENCE public.parameters_id_seq;

/**********
 * sequence: public.pixel_id_seq
 */
CREATE SEQUENCE public.pixel_id_seq;

/**********
 * sequence: public.pixel_selection_rules_id_seq
 */
CREATE SEQUENCE public.pixel_selection_rules_id_seq;

/**********
 * sequence: public.pixel_sets_id_seq
 */
CREATE SEQUENCE public.pixel_sets_id_seq;

/**********
 * sequence: public.process_fields_id_seq
 */
CREATE SEQUENCE public.process_fields_id_seq;

/**********
 * sequence: public.process_functions_id_seq
 */
CREATE SEQUENCE public.process_functions_id_seq;

/**********
 * sequence: public.process_images_id_seq
 */
CREATE SEQUENCE public.process_images_id_seq;

/**********
 * sequence: public.process_pixels_id_seq
 */
CREATE SEQUENCE public.process_pixels_id_seq;

/**********
 * sequence: public.process_query_functions_id_seq
 */
CREATE SEQUENCE public.process_query_functions_id_seq;

/**********
 * sequence: public.process_regions_id_seq
 */
CREATE SEQUENCE public.process_regions_id_seq;

/**********
 * sequence: public.process_results_id_seq
 */
CREATE SEQUENCE public.process_results_id_seq;

/**********
 * sequence: public.projects_id_seq
 */
CREATE SEQUENCE public.projects_id_seq;

/**********
 * sequence: public.r2_log_activity_id_seq
 */
CREATE SEQUENCE public.r2_log_activity_id_seq;

/**********
 * sequence: public.r2_rest_sessions_id_seq
 */
CREATE SEQUENCE public.r2_rest_sessions_id_seq;

/**********
 * sequence: public.raster_files_id_seq
 */
CREATE SEQUENCE public.raster_files_id_seq;

/**********
 * sequence: public.raster_groups_id_seq
 */
CREATE SEQUENCE public.raster_groups_id_seq;

/**********
 * sequence: public.raster_layers_id_seq
 */
CREATE SEQUENCE public.raster_layers_id_seq;

/**********
 * sequence: public.regions_id_seq
 */
CREATE SEQUENCE public.regions_id_seq;

/**********
 * sequence: public.results_f1_id_seq
 */
CREATE SEQUENCE public.results_f1_id_seq;

/**********
 * sequence: public.results_f2_id_seq
 */
CREATE SEQUENCE public.results_f2_id_seq;

/**********
 * sequence: public.results_id_seq
 */
CREATE SEQUENCE public.results_id_seq;

/**********
 * sequence: public.temporal_expansion_rules_id_seq
 */
CREATE SEQUENCE public.temporal_expansion_rules_id_seq;

/**********
 * sequence: public.use_concretes_id_seq
 */
CREATE SEQUENCE public.use_concretes_id_seq;

/**********
 * sequence: public.use_declareds_id_seq
 */
CREATE SEQUENCE public.use_declareds_id_seq;

/**********
 * sequence: public.user_groups_id_seq
 */
CREATE SEQUENCE public.user_groups_id_seq;

/**********
 * sequence: public.users_by_groups_id_seq
 */
CREATE SEQUENCE public.users_by_groups_id_seq;

/**********
 * sequence: public.users_id_seq
 */
CREATE SEQUENCE public.users_id_seq;

/**********
 * sequence: public.versions_id_seq
 */
CREATE SEQUENCE public.versions_id_seq;

/**********
 * table: log.process_query_function_logs
 */
CREATE TABLE log.process_query_function_logs (
    id integer DEFAULT nextval('log.process_query_function_logs_id_seq'::regclass) NOT NULL,
    ts timestamp(0) without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_query_function_id integer  NOT NULL,
    log_type character varying(25)  NULL,
    description text  NULL,
    file text  NULL,
    line integer  NULL,
    callstack text  NULL
);

ALTER TABLE log.process_query_function_logs ADD CONSTRAINT process_query_function_logs_pk
    PRIMARY KEY (id);
ALTER TABLE log.process_query_function_logs ADD CONSTRAINT process_query_function_logs_process_query_function_id_to_proces
    FOREIGN KEY (process_query_function_id) REFERENCES process_query_functions(id) ON DELETE CASCADE;

/**********
 * table: log.trigger_logs
 */
CREATE TABLE log.trigger_logs (
    id integer DEFAULT nextval('log.trigger_logs_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT '2018-07-11 19:52:17.33823'::timestamp without time zone NOT NULL,
    activity text  NULL,
    tg_name text  NULL,
    new_data text  NULL,
    old_data text  NULL
);

ALTER TABLE log.trigger_logs ADD CONSTRAINT trigger_logs_pkey
    PRIMARY KEY (id);

/**********
 * table: public.business_objects_translations
 */
CREATE TABLE public.business_objects_translations (
    id integer DEFAULT nextval('business_objects_translations_id_seq'::regclass) NOT NULL,
    current_name character varying(100)  NOT NULL,
    spanish_translation character varying(100) DEFAULT ''::character varying NULL,
    english_translation character varying(100) DEFAULT ''::character varying NULL,
    ts timestamp without time zone DEFAULT now() NULL
);

ALTER TABLE public.business_objects_translations ADD CONSTRAINT business_objects_translations_pkey
    PRIMARY KEY (id);

/**********
 * table: public.clients
 */
CREATE TABLE public.clients (
    id integer DEFAULT nextval('clients_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    organization_id integer  NOT NULL,
    description text  NULL
);

ALTER TABLE public.clients ADD CONSTRAINT clients_pk
    PRIMARY KEY (id);
ALTER TABLE public.clients ADD CONSTRAINT clients_to_organizations_fk
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

/**********
 * table: public.concretes_by_declareds
 */
CREATE TABLE public.concretes_by_declareds (
    id integer DEFAULT nextval('concretes_by_declareds_id_seq'::regclass) NOT NULL,
    declared_id integer  NOT NULL,
    concrete_id integer  NOT NULL
);

ALTER TABLE public.concretes_by_declareds ADD CONSTRAINT concretes_by_declareds_pk
    PRIMARY KEY (id);
ALTER TABLE public.concretes_by_declareds ADD CONSTRAINT concretes_by_declareds_to_use_concretes_id_fkey
    FOREIGN KEY (concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE;
ALTER TABLE public.concretes_by_declareds ADD CONSTRAINT concretes_by_declareds_to_use_declareds_id_fkey
    FOREIGN KEY (declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;

/**********
 * table: public.data_types
 */
CREATE TABLE public.data_types (
    id integer DEFAULT nextval('data_types_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    unity character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    duration integer  NULL
);

ALTER TABLE public.data_types ADD CONSTRAINT data_types_pk
    PRIMARY KEY (id);

/**********
 * table: public.data_types_by_pixels
 */
CREATE TABLE public.data_types_by_pixels (
    id integer DEFAULT nextval('data_types_by_pixels_id_seq'::regclass) NOT NULL,
    data_type_id integer  NOT NULL,
    pixel_id integer  NOT NULL,
    value double precision  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    date date  NULL
);

ALTER TABLE public.data_types_by_pixels ADD CONSTRAINT data_by_pixels
    PRIMARY KEY (id);
ALTER TABLE public.data_types_by_pixels ADD CONSTRAINT data_by_pixels_to_data_type_id_fkey
    FOREIGN KEY (data_type_id) REFERENCES data_types(id) ON DELETE CASCADE;
ALTER TABLE public.data_types_by_pixels ADD CONSTRAINT data_by_pixels_to_pixeles_id_fkey
    FOREIGN KEY (pixel_id) REFERENCES pixel(id) ON DELETE CASCADE;

/**********
 * table: public.date_by_process_f2
 */
CREATE TABLE public.date_by_process_f2 (
    id integer DEFAULT nextval('date_by_process_f2_id_seq'::regclass) NOT NULL,
    date date  NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_f2_id integer DEFAULT '-1'::integer NOT NULL
);

ALTER TABLE public.date_by_process_f2 ADD CONSTRAINT date_by_process_f2_pk
    PRIMARY KEY (id);
ALTER TABLE public.date_by_process_f2 ADD CONSTRAINT date_by_process_f2_to_process_functions
    FOREIGN KEY (process_f2_id) REFERENCES process_functions(id) ON DELETE CASCADE;

/**********
 * table: public.db_actions_logs
 */
CREATE TABLE public.db_actions_logs (
    id integer DEFAULT nextval('db_actions_logs_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    event character varying(30)  NOT NULL,
    user_id integer  NULL,
    description text  NULL,
    object_class character varying(50)  NOT NULL,
    object_id character varying(30)  NOT NULL,
    object character varying  NULL
);

ALTER TABLE public.db_actions_logs ADD CONSTRAINT db_actions_logs_pkey
    PRIMARY KEY (id);
ALTER TABLE public.db_actions_logs ADD CONSTRAINT fk_db_actions_logs_to_users
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

/**********
 * table: public.declarations
 */
CREATE TABLE public.declarations (
    id integer DEFAULT nextval('declarations_id_seq'::regclass) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    date date  NULL,
    use_declared_id integer  NULL,
    field_id integer  NOT NULL
);

ALTER TABLE public.declarations ADD CONSTRAINT declarations_pk
    PRIMARY KEY (id);
ALTER TABLE public.declarations ADD CONSTRAINT declarations_to_field_id_fkey
    FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE;
ALTER TABLE public.declarations ADD CONSTRAINT declarations_to_use_declared_id_fkey
    FOREIGN KEY (use_declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;
ALTER TABLE public.declarations ADD CONSTRAINT unique_constraint_date_field_id
    UNIQUE (date, field_id);

/**********
 * table: public.declarations_concrete
 */
CREATE TABLE public.declarations_concrete (
    id integer DEFAULT nextval('declarations_concrete_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    date_from timestamp without time zone  NULL,
    date_to timestamp without time zone  NULL,
    use_concrete_id integer  NULL,
    declaration_id integer  NOT NULL
);

ALTER TABLE public.declarations_concrete ADD CONSTRAINT declarations_concrete_pkey
    PRIMARY KEY (id);
ALTER TABLE public.declarations_concrete ADD CONSTRAINT declarations_concrete_to_declarations_fk
    FOREIGN KEY (declaration_id) REFERENCES declarations(id) ON DELETE CASCADE;
ALTER TABLE public.declarations_concrete ADD CONSTRAINT declarations_concrete_to_use_concretes_fk
    FOREIGN KEY (use_concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE DEFERRABLE;

/**********
 * table: public.farms
 */
CREATE TABLE public.farms (
    id integer DEFAULT nextval('farms_id_seq'::regclass) NOT NULL,
    name character varying(150)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    version_id integer  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    code character varying(150)  NOT NULL
);

ALTER TABLE public.farms ADD CONSTRAINT farms_code
    UNIQUE (code, version_id);
ALTER TABLE public.farms ADD CONSTRAINT farms_pk
    PRIMARY KEY (id);
ALTER TABLE public.farms ADD CONSTRAINT farms_to_version_id_fkey
    FOREIGN KEY (version_id) REFERENCES versions(id) ON DELETE CASCADE;

/**********
 * table: public.fields
 */
CREATE TABLE public.fields (
    id integer DEFAULT nextval('fields_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    date_from date  NULL,
    date_to date  NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    farm_id integer  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    the_geom geometry  NULL,
    code character varying(50)  NOT NULL,
    group_name character varying(150)  NULL
);

ALTER TABLE public.fields ADD CONSTRAINT farm_field_code
    UNIQUE (farm_id, code);
ALTER TABLE public.fields ADD CONSTRAINT fields_pk
    PRIMARY KEY (id);
ALTER TABLE public.fields ADD CONSTRAINT fields_to_farm_id_fkey
    FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE;

/**********
 * table: public.format_types
 */
CREATE TABLE public.format_types (
    id integer DEFAULT nextval('format_types_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    name character varying(50)  NULL
);

ALTER TABLE public.format_types ADD CONSTRAINT format_types_pk
    PRIMARY KEY (id);

/**********
 * table: public.functions
 */
CREATE TABLE public.functions (
    id integer DEFAULT nextval('functions_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer  NOT NULL,
    path text  NOT NULL,
    description character varying(200)  NULL,
    fx_saved_name character varying(200)  NULL,
    column_name character varying  NULL
);

ALTER TABLE public.functions ADD CONSTRAINT fk_functions_to_users
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.functions ADD CONSTRAINT functions_id_pk
    PRIMARY KEY (id);

/**********
 * table: public.groups_by_options
 */
CREATE TABLE public.groups_by_options (
    id integer DEFAULT nextval('groups_by_options_id_seq'::regclass) NOT NULL,
    user_group_id integer  NOT NULL,
    menu_option_id integer  NOT NULL
);

ALTER TABLE public.groups_by_options ADD CONSTRAINT groups_by_options_pk
    PRIMARY KEY (id);
ALTER TABLE public.groups_by_options ADD CONSTRAINT groups_by_options_to_menu_option_fkey
    FOREIGN KEY (menu_option_id) REFERENCES menu_options(id) ON DELETE CASCADE;
ALTER TABLE public.groups_by_options ADD CONSTRAINT groups_by_options_to_user_groups_id_fkey
    FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON DELETE CASCADE;

/**********
 * table: public.imagen_types
 */
CREATE TABLE public.imagen_types (
    id integer DEFAULT nextval('imagen_types_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    pixel_size integer  NULL
);

ALTER TABLE public.imagen_types ADD CONSTRAINT imagen_types_pk
    PRIMARY KEY (id);

/**********
 * table: public.import_data
 */
CREATE TABLE public.import_data (
    id integer DEFAULT nextval('import_data_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    path character varying(100)  NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    result character varying(100)  NULL,
    model_name character varying(35)  NULL,
    original_name character varying(200)  NULL,
    comments text  NULL,
    client_id integer  NOT NULL,
    project_id integer  NOT NULL,
    version_id integer  NOT NULL
);

ALTER TABLE public.import_data ADD CONSTRAINT import_data_pk
    PRIMARY KEY (id);

/**********
 * table: public.layer_types
 */
CREATE TABLE public.layer_types (
    id integer DEFAULT nextval('layer_types_id_seq'::regclass) NOT NULL,
    name character varying(250)  NOT NULL,
    image_type_id integer  NOT NULL,
    parameter_type_id integer  NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.layer_types ADD CONSTRAINT layer_type_pk
    PRIMARY KEY (id);
ALTER TABLE public.layer_types ADD CONSTRAINT layer_types_to_image_types_id_fkey
    FOREIGN KEY (image_type_id) REFERENCES imagen_types(id) ON DELETE CASCADE;
ALTER TABLE public.layer_types ADD CONSTRAINT layer_types_to_parameter_types_id_fkey
    FOREIGN KEY (parameter_type_id) REFERENCES parameter_types(id) ON DELETE CASCADE;

/**********
 * table: public.layers
 */
CREATE TABLE public.layers (
    id integer DEFAULT nextval('layers_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    imagen_type_id integer  NOT NULL,
    data_type_id integer  NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.layers ADD CONSTRAINT data_type_by_imagen_type_pk
    PRIMARY KEY (id);
ALTER TABLE public.layers ADD CONSTRAINT data_type_by_imagen_type_to_data_types_id_fkey
    FOREIGN KEY (data_type_id) REFERENCES data_types(id) ON DELETE CASCADE;
ALTER TABLE public.layers ADD CONSTRAINT data_type_by_imagen_type_to_imagen_types_id_fkey
    FOREIGN KEY (imagen_type_id) REFERENCES imagen_types(id) ON DELETE CASCADE;

/**********
 * table: public.log_import_fields
 */
CREATE TABLE public.log_import_fields (
    id integer DEFAULT nextval('log_import_fields_id_seq'::regclass) NOT NULL,
    description text  NULL,
    process_id integer  NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.log_import_fields ADD CONSTRAINT log_import_fields_pkey
    PRIMARY KEY (id);
ALTER TABLE public.log_import_fields ADD CONSTRAINT process_id_to_process_fields_id
    FOREIGN KEY (process_id) REFERENCES process_fields(id) ON DELETE CASCADE;

/**********
 * table: public.log_import_images
 */
CREATE TABLE public.log_import_images (
    id integer DEFAULT nextval('log_import_images_id_seq'::regclass) NOT NULL,
    description text  NULL,
    process_id integer  NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.log_import_images ADD CONSTRAINT log_import_images_pk
    PRIMARY KEY (id);
ALTER TABLE public.log_import_images ADD CONSTRAINT process_id_to_process_images_id
    FOREIGN KEY (process_id) REFERENCES process_images(id) ON DELETE CASCADE;

/**********
 * table: public.log_process_functions
 */
CREATE TABLE public.log_process_functions (
    id integer DEFAULT nextval('log_process_functions_id_seq'::regclass) NOT NULL,
    description text  NULL,
    process_function_id integer  NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.log_process_functions ADD CONSTRAINT log_process_functions_pk
    PRIMARY KEY (id);
ALTER TABLE public.log_process_functions ADD CONSTRAINT log_to_process_process_function_id
    FOREIGN KEY (process_function_id) REFERENCES process_functions(id) ON DELETE CASCADE;

/**********
 * table: public.maps
 */
CREATE TABLE public.maps (
    id integer DEFAULT nextval('maps_id_seq'::regclass) NOT NULL,
    name character varying(100)  NOT NULL,
    quantity integer  NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    organization_id integer  NOT NULL,
    path character varying  NULL
);

ALTER TABLE public.maps ADD CONSTRAINT map_pk
    PRIMARY KEY (id);

/**********
 * table: public.menu_options
 */
CREATE TABLE public.menu_options (
    id integer DEFAULT nextval('menu_options_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    controller character varying(50)  NOT NULL,
    action character varying(50)  NOT NULL,
    description character varying(500)  NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    parent_id integer  NULL,
    menu_icon character varying(50)  NULL,
    order integer  NOT NULL
);

ALTER TABLE public.menu_options ADD CONSTRAINT menu_option_pk
    PRIMARY KEY (id);
ALTER TABLE public.menu_options ADD CONSTRAINT menu_options_to_menu_options_fk
    FOREIGN KEY (parent_id) REFERENCES menu_options(id) ON DELETE CASCADE;

/**********
 * table: public.organizations
 */
CREATE TABLE public.organizations (
    id integer DEFAULT nextval('organizations_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NULL,
    created_at timestamp without time zone DEFAULT now() NULL,
    name character varying(50)  NOT NULL
);

ALTER TABLE public.organizations ADD CONSTRAINT organizations_pk
    PRIMARY KEY (id);

/**********
 * table: public.parameter_types
 */
CREATE TABLE public.parameter_types (
    id integer DEFAULT nextval('parameter_types_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    name character varying(50)  NULL,
    unit character varying(50)  NULL,
    description character varying(250)  NULL,
    quantity integer  NULL,
    format_type_id integer DEFAULT 1 NOT NULL
);

ALTER TABLE public.parameter_types ADD CONSTRAINT parameter_types_pk
    PRIMARY KEY (id);
ALTER TABLE public.parameter_types ADD CONSTRAINT parameter_types_to_format_types_fk
    FOREIGN KEY (format_type_id) REFERENCES format_types(id) ON DELETE CASCADE;

/**********
 * table: public.parameters
 */
CREATE TABLE public.parameters (
    id integer DEFAULT nextval('parameters_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    use_id integer  NULL,
    month integer  NULL,
    parameter_type_id integer  NOT NULL,
    value character varying(50)  NULL,
    map_id integer  NOT NULL,
    region_id integer  NOT NULL,
    priority integer  NOT NULL
);

ALTER TABLE public.parameters ADD CONSTRAINT parameters_map_id_fk
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE;
ALTER TABLE public.parameters ADD CONSTRAINT parameters_parameter_type_id_fk
    FOREIGN KEY (parameter_type_id) REFERENCES parameter_types(id) ON DELETE CASCADE;
ALTER TABLE public.parameters ADD CONSTRAINT parameters_pk
    PRIMARY KEY (id);
ALTER TABLE public.parameters ADD CONSTRAINT parameters_region_id_fk
    FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE CASCADE;
ALTER TABLE public.parameters ADD CONSTRAINT parameters_use_id_fk
    FOREIGN KEY (use_id) REFERENCES use_concretes(id) ON DELETE CASCADE;

/**********
 * table: public.pixel
 */
CREATE TABLE public.pixel (
    id integer DEFAULT nextval('pixel_id_seq'::regclass) NOT NULL,
    y integer  NOT NULL,
    x integer  NOT NULL,
    set_id integer  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    the_geom geometry  NULL,
    centroid_x real  NULL,
    centroid_y real  NULL
);

ALTER TABLE public.pixel ADD CONSTRAINT pixel_pk
    PRIMARY KEY (id);
ALTER TABLE public.pixel ADD CONSTRAINT pixel_to_set_id_fkey
    FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;

/**********
 * table: public.pixel_selection_rules
 */
CREATE TABLE public.pixel_selection_rules (
    id integer DEFAULT nextval('pixel_selection_rules_id_seq'::regclass) NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    name character varying(50)  NOT NULL,
    tolerance integer  NOT NULL
);

ALTER TABLE public.pixel_selection_rules ADD CONSTRAINT pixel_selection_rules_pk
    PRIMARY KEY (id);

/**********
 * table: public.pixel_sets
 */
CREATE TABLE public.pixel_sets (
    id integer DEFAULT nextval('pixel_sets_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    imagen_type_id integer DEFAULT '-1'::integer NOT NULL,
    width integer  NULL,
    height integer  NULL
);

ALTER TABLE public.pixel_sets ADD CONSTRAINT pixel_sets_pk
    PRIMARY KEY (id);
ALTER TABLE public.pixel_sets ADD CONSTRAINT pixel_sets_to_imagen_types_id
    FOREIGN KEY (imagen_type_id) REFERENCES imagen_types(id) ON DELETE CASCADE;

/**********
 * table: public.process_fields
 */
CREATE TABLE public.process_fields (
    id integer DEFAULT nextval('process_fields_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    client_id integer  NOT NULL,
    project_id integer  NOT NULL,
    version_id integer  NOT NULL,
    path text  NULL,
    description character varying  NULL,
    user_id integer  NOT NULL,
    procces_run boolean DEFAULT false NULL,
    qt_errors integer  NULL,
    check_run boolean DEFAULT false NOT NULL,
    import_from integer  NULL
);

ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_pkey
    PRIMARY KEY (id);
ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_to_clients_fk
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_to_projects_fk
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_to_users_fk
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.process_fields ADD CONSTRAINT process_fields_to_versions_fk
    FOREIGN KEY (version_id) REFERENCES versions(id) ON DELETE CASCADE;

/**********
 * table: public.process_functions
 */
CREATE TABLE public.process_functions (
    id integer DEFAULT nextval('process_functions_id_seq'::regclass) NOT NULL,
    status character varying(20)  NOT NULL,
    process_result_id integer  NOT NULL,
    function_id integer  NULL,
    user_id integer  NOT NULL,
    name character varying(30)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    description character varying  NULL,
    procces_run boolean DEFAULT false NULL,
    map_id integer  NOT NULL
);

ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_id_pk
    PRIMARY KEY (id);
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_map_id_to_maps
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_functions_fkey
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE SET NULL;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_process_results_fkey
    FOREIGN KEY (process_result_id) REFERENCES process_results(id) ON DELETE CASCADE;
ALTER TABLE public.process_functions ADD CONSTRAINT process_functions_to_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

/**********
 * table: public.process_images
 */
CREATE TABLE public.process_images (
    id integer DEFAULT nextval('process_images_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    description character varying  NULL,
    process_run boolean DEFAULT false NULL,
    raster_file_id integer  NULL,
    user_id integer  NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL
);

ALTER TABLE public.process_images ADD CONSTRAINT process_images_pkey
    PRIMARY KEY (id);
ALTER TABLE public.process_images ADD CONSTRAINT process_images_raster_file_id_fk
    FOREIGN KEY (raster_file_id) REFERENCES raster_files(id) ON DELETE CASCADE;
ALTER TABLE public.process_images ADD CONSTRAINT process_pixels_to_users_fk
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

/**********
 * table: public.process_pixels
 */
CREATE TABLE public.process_pixels (
    id integer DEFAULT nextval('process_pixels_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    description character varying  NULL,
    path text  NULL,
    set_id integer  NULL,
    user_id integer  NOT NULL,
    procces_run boolean DEFAULT false NULL
);

ALTER TABLE public.process_pixels ADD CONSTRAINT process_pixels_pkey
    PRIMARY KEY (id);
ALTER TABLE public.process_pixels ADD CONSTRAINT process_pixels_to_pixel_sets_fk
    FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;
ALTER TABLE public.process_pixels ADD CONSTRAINT process_pixels_to_users_fk
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

/**********
 * table: public.process_query_functions
 */
CREATE TABLE public.process_query_functions (
    id integer DEFAULT nextval('process_query_functions_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    status character varying(20)  NOT NULL,
    user_id integer  NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    description character varying  NULL,
    procces_run boolean DEFAULT false NULL,
    pixel_id integer  NULL,
    region_id text  NULL,
    client_id text  NULL,
    project_id text  NULL,
    version_id text  NULL,
    farm_id text  NULL,
    group_name text  NULL,
    field_id text  NULL,
    use_concrete_id text  NULL,
    date timestamp without time zone  NULL,
    date_from timestamp without time zone  NULL,
    date_to timestamp without time zone  NULL,
    group_field boolean DEFAULT false NOT NULL,
    group_month boolean DEFAULT false NOT NULL,
    aggregate_function character varying(50)  NULL,
    function_id text  NULL,
    filter_description text  NULL
);

ALTER TABLE public.process_query_functions ADD CONSTRAINT process_query_functions_pixel_id_to_pixels
    FOREIGN KEY (pixel_id) REFERENCES pixel(id) ON DELETE CASCADE;
ALTER TABLE public.process_query_functions ADD CONSTRAINT process_query_functions_pk
    PRIMARY KEY (id);

/**********
 * table: public.process_regions
 */
CREATE TABLE public.process_regions (
    id integer DEFAULT nextval('process_regions_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    path text  NULL,
    description character varying  NULL,
    procces_run boolean DEFAULT false NULL,
    map_id integer  NOT NULL,
    user_id integer  NULL
);

ALTER TABLE public.process_regions ADD CONSTRAINT process_regions_pkey
    PRIMARY KEY (id);
ALTER TABLE public.process_regions ADD CONSTRAINT process_regions_to_maps_fk
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE;

/**********
 * table: public.process_results
 */
CREATE TABLE public.process_results (
    set_id integer  NOT NULL,
    id integer DEFAULT nextval('process_results_id_seq'::regclass) NOT NULL,
    pixel_selection_rules_id integer  NULL,
    user_id integer  NOT NULL,
    version_id integer  NOT NULL,
    name character varying(100)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    start_process_at timestamp without time zone  NULL,
    end_process_at timestamp without time zone  NULL,
    description character varying(200)  NULL,
    client_id integer  NOT NULL,
    imagen_type_id integer  NOT NULL,
    procces_run boolean DEFAULT false NULL
);

ALTER TABLE public.process_results ADD CONSTRAINT process_results_id_pk
    PRIMARY KEY (id);
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_clients_id_fkey
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_imagen_types_id_fkey
    FOREIGN KEY (imagen_type_id) REFERENCES imagen_types(id) ON DELETE CASCADE;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_pixel_selection_rules_id_fkey
    FOREIGN KEY (pixel_selection_rules_id) REFERENCES pixel_selection_rules(id) ON DELETE SET NULL;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_pixel_sets_id
    FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.process_results ADD CONSTRAINT process_results_to_versions_id_fkey
    FOREIGN KEY (version_id) REFERENCES versions(id) ON DELETE CASCADE;

/**********
 * table: public.projects
 */
CREATE TABLE public.projects (
    id integer DEFAULT nextval('projects_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    client_id integer  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    parent_id integer  NULL,
    description text  NULL
);

ALTER TABLE public.projects ADD CONSTRAINT projects_pk
    PRIMARY KEY (id);
ALTER TABLE public.projects ADD CONSTRAINT projects_to_client_id_fkey
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
ALTER TABLE public.projects ADD CONSTRAINT projects_to_projects_fk
    FOREIGN KEY (parent_id) REFERENCES projects(id) ON DELETE CASCADE;

/**********
 * table: public.r2_log_activity
 */
CREATE TABLE public.r2_log_activity (
    id integer DEFAULT nextval('r2_log_activity_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NULL,
    created_at timestamp without time zone DEFAULT now() NULL,
    ip inet  NULL,
    user_id integer  NULL,
    post_data character varying  NULL,
    get_data character varying  NULL,
    controller character varying  NULL,
    method character varying  NULL,
    uri character varying  NULL,
    http_response_code integer  NULL
);

ALTER TABLE public.r2_log_activity ADD CONSTRAINT log_activity_pk
    PRIMARY KEY (id);

/**********
 * table: public.r2_rest_sessions
 */
CREATE TABLE public.r2_rest_sessions (
    id integer DEFAULT nextval('r2_rest_sessions_id_seq'::regclass) NOT NULL,
    user_id integer  NOT NULL,
    session_id character varying(75)  NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    timestamp bigint DEFAULT 0 NOT NULL,
    last_communication timestamp without time zone  NULL,
    gcm_id character varying  NULL
);

ALTER TABLE public.r2_rest_sessions ADD CONSTRAINT r2_rest_session_to_users_fk
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.r2_rest_sessions ADD CONSTRAINT r2_rest_sessions_pkey
    PRIMARY KEY (id);

/**********
 * table: public.r2_sessions
 */
CREATE TABLE public.r2_sessions (
    id character varying(40)  NOT NULL,
    ip_address character varying(45)  NOT NULL,
    timestamp bigint DEFAULT 0 NOT NULL,
    data text DEFAULT ''::text NOT NULL
);

ALTER TABLE public.r2_sessions ADD CONSTRAINT r2_sessions_pkey
    PRIMARY KEY (id);

/**********
 * table: public.raster_files
 */
CREATE TABLE public.raster_files (
    id integer DEFAULT nextval('raster_files_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NULL,
    created_at timestamp without time zone DEFAULT now() NULL,
    path character varying(250)  NOT NULL,
    image_type_id integer  NOT NULL,
    image_date date  NULL,
    pixel_set_id integer  NULL
);

ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_image_type_id_fk
    FOREIGN KEY (image_type_id) REFERENCES imagen_types(id) ON DELETE CASCADE;
ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_pixel_set_id_fk
    FOREIGN KEY (pixel_set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;
ALTER TABLE public.raster_files ADD CONSTRAINT raster_files_pk
    PRIMARY KEY (id);

/**********
 * table: public.raster_groups
 */
CREATE TABLE public.raster_groups (
    id integer DEFAULT nextval('raster_groups_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    files_quantity integer  NULL,
    layers_quantity integer  NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.raster_groups ADD CONSTRAINT raster_groups_pk
    PRIMARY KEY (id);

/**********
 * table: public.raster_layers
 */
CREATE TABLE public.raster_layers (
    id integer DEFAULT nextval('raster_layers_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    layer_type_id integer  NOT NULL,
    raster_file_id integer  NULL,
    image_date date  NULL,
    layer_path text  NOT NULL
);

ALTER TABLE public.raster_layers ADD CONSTRAINT raster_layers_layer_type_id_fkey
    FOREIGN KEY (layer_type_id) REFERENCES layer_types(id) ON DELETE CASCADE;
ALTER TABLE public.raster_layers ADD CONSTRAINT raster_layers_pk
    PRIMARY KEY (id);
ALTER TABLE public.raster_layers ADD CONSTRAINT raster_layers_raster_file_id_fkey
    FOREIGN KEY (raster_file_id) REFERENCES raster_files(id) ON DELETE SET NULL;

/**********
 * table: public.regions
 */
CREATE TABLE public.regions (
    id integer DEFAULT nextval('regions_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    the_geom geometry  NULL,
    map_id integer  NULL,
    process_id integer  NOT NULL
);

ALTER TABLE public.regions ADD CONSTRAINT regions_pk
    PRIMARY KEY (id);
ALTER TABLE public.regions ADD CONSTRAINT regions_to_maps_fk
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE;
ALTER TABLE public.regions ADD CONSTRAINT regions_to_maps_id_fkey
    FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE;

/**********
 * table: public.results
 */
CREATE TABLE public.results (
    id integer DEFAULT nextval('results_id_seq'::regclass) NOT NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    process_id integer  NOT NULL,
    field_id integer  NOT NULL,
    intersect_idx real  NOT NULL,
    selected boolean DEFAULT true NOT NULL,
    selected_by_user boolean  NULL,
    pixel_id integer  NOT NULL,
    set_id integer  NOT NULL,
    centroid_x real  NULL,
    centroid_y real  NULL,
    the_geom geometry  NULL
);

ALTER TABLE public.results ADD CONSTRAINT results_pkey
    PRIMARY KEY (id);
ALTER TABLE public.results ADD CONSTRAINT results_to_fields_fk
    FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE DEFERRABLE;
ALTER TABLE public.results ADD CONSTRAINT results_to_pixel_fk
    FOREIGN KEY (pixel_id) REFERENCES pixel(id) ON DELETE CASCADE;
ALTER TABLE public.results ADD CONSTRAINT results_to_sets_fk
    FOREIGN KEY (set_id) REFERENCES pixel_sets(id) ON DELETE CASCADE;

/**********
 * table: public.results_f1
 */
CREATE TABLE public.results_f1 (
    id integer DEFAULT nextval('results_f1_id_seq'::regclass) NOT NULL,
    field_id integer  NOT NULL,
    process_id integer  NOT NULL,
    date date  NOT NULL,
    use_concrete_id integer  NULL,
    uses_date_from date  NULL,
    uses_date_to date  NULL,
    result_id integer  NULL
);

ALTER TABLE public.results_f1 ADD CONSTRAINT fk_results_f1_to_fields
    FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE;
ALTER TABLE public.results_f1 ADD CONSTRAINT fk_results_f1_to_process_results
    FOREIGN KEY (process_id) REFERENCES process_results(id) ON DELETE CASCADE;
ALTER TABLE public.results_f1 ADD CONSTRAINT fk_results_f1_to_use_concretes
    FOREIGN KEY (use_concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE;
ALTER TABLE public.results_f1 ADD CONSTRAINT results_f1_id_pk
    PRIMARY KEY (id);

/**********
 * table: public.results_f2
 */
CREATE TABLE public.results_f2 (
    id integer DEFAULT nextval('results_f2_id_seq'::regclass) NOT NULL,
    key character varying(250)  NOT NULL,
    value character varying(250)  NULL,
    process_result_id integer  NULL,
    process_focus_id integer  NULL,
    ts timestamp without time zone DEFAULT now() NOT NULL,
    date timestamp without time zone  NULL
);

ALTER TABLE public.results_f2 ADD CONSTRAINT result_focus2_pk
    PRIMARY KEY (id);

/**********
 * table: public.spatial_ref_sys
 */
CREATE TABLE public.spatial_ref_sys (
    srid integer  NOT NULL,
    auth_name character varying(256)  NULL,
    auth_srid integer  NULL,
    srtext character varying(2048)  NULL,
    proj4text character varying(2048)  NULL
);

ALTER TABLE public.spatial_ref_sys ADD CONSTRAINT spatial_ref_sys_pkey
    PRIMARY KEY (srid);
ALTER TABLE public.spatial_ref_sys ADD CONSTRAINT spatial_ref_sys_srid_check
    CHECK (srid > 0 AND srid <= 998999);

/**********
 * table: public.temporal_expansion_rules
 */
CREATE TABLE public.temporal_expansion_rules (
    id integer DEFAULT nextval('temporal_expansion_rules_id_seq'::regclass) NOT NULL,
    region_id integer  NOT NULL,
    use_declared_id integer  NOT NULL,
    use_concrete_id integer  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    month_to integer  NULL,
    month_from integer  NULL,
    declaration_month integer  NULL
);

ALTER TABLE public.temporal_expansion_rules ADD CONSTRAINT temporal_expansion_rules_pk
    PRIMARY KEY (id);
ALTER TABLE public.temporal_expansion_rules ADD CONSTRAINT temporal_expansion_rules_to_region_id_fkey
    FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE CASCADE;
ALTER TABLE public.temporal_expansion_rules ADD CONSTRAINT temporal_expansion_rules_to_use_concrete_id_fkey
    FOREIGN KEY (use_concrete_id) REFERENCES use_concretes(id) ON DELETE CASCADE;
ALTER TABLE public.temporal_expansion_rules ADD CONSTRAINT temporal_expansion_rules_to_use_declared_id_fkey
    FOREIGN KEY (use_declared_id) REFERENCES use_declareds(id) ON DELETE CASCADE;
ALTER TABLE public.temporal_expansion_rules ADD CONSTRAINT temporal_expansion_rules_unique_idx
    UNIQUE (region_id, use_declared_id, use_concrete_id, declaration_month);

/**********
 * table: public.test_crosstab
 */
CREATE TABLE public.test_crosstab (
    the_geom geometry  NULL,
    pixel_id integer  NULL,
    pivot integer  NULL,
    2000-02-18 text  NULL,
    2000-03-05 text  NULL,
    2000-03-21 text  NULL,
    2000-04-06 text  NULL,
    2000-04-22 text  NULL,
    2000-05-08 text  NULL,
    2000-05-24 text  NULL,
    2000-06-09 text  NULL,
    2000-06-25 text  NULL,
    2000-07-11 text  NULL,
    2000-07-27 text  NULL,
    2000-08-12 text  NULL,
    2000-08-28 text  NULL,
    2000-09-13 text  NULL,
    2000-09-29 text  NULL,
    2000-10-15 text  NULL,
    2000-10-31 text  NULL,
    2000-11-16 text  NULL,
    2000-12-02 text  NULL,
    2000-12-18 text  NULL,
    2001-01-01 text  NULL,
    2001-01-17 text  NULL,
    2001-02-02 text  NULL,
    2001-02-18 text  NULL,
    2001-03-06 text  NULL,
    2001-03-22 text  NULL,
    2001-04-07 text  NULL,
    2001-04-23 text  NULL,
    2001-05-09 text  NULL,
    2001-05-25 text  NULL,
    2001-06-10 text  NULL,
    2001-06-26 text  NULL,
    2001-07-12 text  NULL,
    2001-07-28 text  NULL,
    2001-08-13 text  NULL,
    2001-08-29 text  NULL,
    2001-09-14 text  NULL,
    2001-09-30 text  NULL,
    2001-10-16 text  NULL,
    2001-11-01 text  NULL,
    2001-11-17 text  NULL,
    2001-12-03 text  NULL,
    2001-12-19 text  NULL,
    2002-01-01 text  NULL,
    2002-01-17 text  NULL,
    2002-02-02 text  NULL,
    2002-02-18 text  NULL,
    2002-03-06 text  NULL,
    2002-03-22 text  NULL,
    2002-04-07 text  NULL,
    2002-04-23 text  NULL,
    2002-05-09 text  NULL,
    2002-05-25 text  NULL,
    2002-06-10 text  NULL,
    2002-06-26 text  NULL,
    2002-07-12 text  NULL,
    2002-07-28 text  NULL,
    2002-08-13 text  NULL,
    2002-08-29 text  NULL,
    2002-09-14 text  NULL,
    2002-09-30 text  NULL,
    2002-10-16 text  NULL,
    2002-11-01 text  NULL,
    2002-11-17 text  NULL,
    2002-12-03 text  NULL,
    2002-12-19 text  NULL,
    2003-01-01 text  NULL,
    2003-01-17 text  NULL,
    2003-02-02 text  NULL,
    2003-02-18 text  NULL,
    2003-03-06 text  NULL,
    2003-03-22 text  NULL,
    2003-04-07 text  NULL,
    2003-04-23 text  NULL,
    2003-05-09 text  NULL,
    2003-05-25 text  NULL,
    2003-06-10 text  NULL,
    2003-06-26 text  NULL,
    2003-07-12 text  NULL,
    2003-07-28 text  NULL,
    2003-08-13 text  NULL,
    2003-08-29 text  NULL,
    2003-09-14 text  NULL,
    2003-09-30 text  NULL,
    2003-10-16 text  NULL,
    2003-11-01 text  NULL,
    2003-11-17 text  NULL,
    2003-12-03 text  NULL,
    2003-12-19 text  NULL,
    2004-01-01 text  NULL,
    2004-01-17 text  NULL,
    2004-02-02 text  NULL,
    2004-02-18 text  NULL,
    2004-03-05 text  NULL,
    2004-03-21 text  NULL,
    2004-04-06 text  NULL,
    2004-04-22 text  NULL,
    2004-05-08 text  NULL,
    2004-05-24 text  NULL,
    2004-06-09 text  NULL,
    2004-06-25 text  NULL,
    2004-07-11 text  NULL,
    2004-07-27 text  NULL,
    2004-08-12 text  NULL,
    2004-08-28 text  NULL,
    2004-09-13 text  NULL,
    2004-09-29 text  NULL,
    2004-10-15 text  NULL,
    2004-10-31 text  NULL,
    2004-11-16 text  NULL,
    2004-12-02 text  NULL,
    2004-12-18 text  NULL,
    2005-01-01 text  NULL,
    2005-01-17 text  NULL,
    2005-02-02 text  NULL,
    2005-02-18 text  NULL,
    2005-03-06 text  NULL,
    2005-03-22 text  NULL,
    2005-04-07 text  NULL,
    2005-04-23 text  NULL,
    2005-05-09 text  NULL,
    2005-05-25 text  NULL,
    2005-06-10 text  NULL,
    2005-06-26 text  NULL,
    2005-07-12 text  NULL,
    2005-07-28 text  NULL,
    2005-08-13 text  NULL,
    2005-08-29 text  NULL,
    2005-09-14 text  NULL,
    2005-09-30 text  NULL,
    2005-10-16 text  NULL,
    2005-11-01 text  NULL,
    2005-11-17 text  NULL,
    2005-12-03 text  NULL,
    2005-12-19 text  NULL,
    2006-01-01 text  NULL,
    2006-01-17 text  NULL,
    2006-02-02 text  NULL,
    2006-02-18 text  NULL,
    2006-03-06 text  NULL,
    2006-03-22 text  NULL,
    2006-04-07 text  NULL,
    2006-04-23 text  NULL,
    2006-05-09 text  NULL,
    2006-05-25 text  NULL,
    2006-06-10 text  NULL,
    2006-06-26 text  NULL,
    2006-07-12 text  NULL,
    2006-07-28 text  NULL,
    2006-08-13 text  NULL,
    2006-08-29 text  NULL,
    2006-09-14 text  NULL,
    2006-09-30 text  NULL,
    2006-10-16 text  NULL,
    2006-11-01 text  NULL,
    2006-11-17 text  NULL,
    2006-12-03 text  NULL,
    2006-12-19 text  NULL,
    2007-01-01 text  NULL,
    2007-01-17 text  NULL,
    2007-02-02 text  NULL,
    2007-02-18 text  NULL,
    2007-03-06 text  NULL,
    2007-03-22 text  NULL,
    2007-04-07 text  NULL,
    2007-04-23 text  NULL,
    2007-05-09 text  NULL,
    2007-05-25 text  NULL,
    2007-06-10 text  NULL,
    2007-06-26 text  NULL,
    2007-07-12 text  NULL,
    2007-07-28 text  NULL,
    2007-08-13 text  NULL,
    2007-08-29 text  NULL,
    2007-09-14 text  NULL,
    2007-09-30 text  NULL,
    2007-10-16 text  NULL,
    2007-11-01 text  NULL,
    2007-11-17 text  NULL,
    2007-12-03 text  NULL,
    2007-12-19 text  NULL,
    2008-01-01 text  NULL,
    2008-01-17 text  NULL,
    2008-02-02 text  NULL,
    2008-02-18 text  NULL,
    2008-03-05 text  NULL,
    2008-03-21 text  NULL,
    2008-04-06 text  NULL,
    2008-04-22 text  NULL,
    2008-05-08 text  NULL,
    2008-05-24 text  NULL,
    2008-06-09 text  NULL,
    2008-06-25 text  NULL,
    2008-07-11 text  NULL,
    2008-07-27 text  NULL,
    2008-08-12 text  NULL,
    2008-08-28 text  NULL,
    2008-09-13 text  NULL,
    2008-09-29 text  NULL,
    2008-10-15 text  NULL,
    2008-10-31 text  NULL,
    2008-11-16 text  NULL,
    2008-12-02 text  NULL,
    2008-12-18 text  NULL,
    2009-01-01 text  NULL,
    2009-01-17 text  NULL,
    2009-02-02 text  NULL,
    2009-02-18 text  NULL,
    2009-03-06 text  NULL,
    2009-03-22 text  NULL,
    2009-04-07 text  NULL,
    2009-04-23 text  NULL,
    2009-05-09 text  NULL,
    2009-05-25 text  NULL,
    2009-06-10 text  NULL,
    2009-06-26 text  NULL,
    2009-07-12 text  NULL,
    2009-07-28 text  NULL,
    2009-08-13 text  NULL,
    2009-08-29 text  NULL,
    2009-09-14 text  NULL,
    2009-09-30 text  NULL,
    2009-10-16 text  NULL,
    2009-11-01 text  NULL,
    2009-11-17 text  NULL,
    2009-12-03 text  NULL,
    2009-12-19 text  NULL,
    2010-01-01 text  NULL,
    2010-01-17 text  NULL,
    2010-02-02 text  NULL,
    2010-02-18 text  NULL,
    2010-03-06 text  NULL,
    2010-03-22 text  NULL,
    2010-04-07 text  NULL,
    2010-04-23 text  NULL,
    2010-05-09 text  NULL,
    2010-05-25 text  NULL,
    2010-06-10 text  NULL,
    2010-06-26 text  NULL,
    2010-07-12 text  NULL,
    2010-07-28 text  NULL,
    2010-08-13 text  NULL,
    2010-08-29 text  NULL,
    2010-09-14 text  NULL,
    2010-09-30 text  NULL,
    2010-10-16 text  NULL,
    2010-11-01 text  NULL,
    2010-11-17 text  NULL,
    2010-12-03 text  NULL,
    2010-12-19 text  NULL,
    2011-01-01 text  NULL,
    2011-01-17 text  NULL,
    2011-02-02 text  NULL,
    2011-02-18 text  NULL,
    2011-03-06 text  NULL,
    2011-03-22 text  NULL,
    2011-04-07 text  NULL,
    2011-04-23 text  NULL,
    2011-05-09 text  NULL,
    2011-05-25 text  NULL,
    2011-06-10 text  NULL,
    2011-06-26 text  NULL,
    2011-07-12 text  NULL,
    2011-07-28 text  NULL,
    2011-08-13 text  NULL,
    2011-08-29 text  NULL,
    2011-09-14 text  NULL,
    2011-09-30 text  NULL,
    2011-10-16 text  NULL,
    2011-11-01 text  NULL,
    2011-11-17 text  NULL,
    2011-12-03 text  NULL,
    2011-12-19 text  NULL,
    2012-01-01 text  NULL,
    2012-01-17 text  NULL,
    2012-02-02 text  NULL,
    2012-02-18 text  NULL,
    2012-03-05 text  NULL,
    2012-03-21 text  NULL,
    2012-04-06 text  NULL,
    2012-04-22 text  NULL,
    2012-05-08 text  NULL,
    2012-05-24 text  NULL,
    2012-06-09 text  NULL,
    2012-06-25 text  NULL,
    2012-07-11 text  NULL,
    2012-07-27 text  NULL,
    2012-08-12 text  NULL,
    2012-08-28 text  NULL,
    2012-09-13 text  NULL,
    2012-09-29 text  NULL,
    2012-10-15 text  NULL,
    2012-10-31 text  NULL,
    2012-11-16 text  NULL,
    2012-12-02 text  NULL,
    2012-12-18 text  NULL,
    2013-01-01 text  NULL,
    2013-01-17 text  NULL,
    2013-02-02 text  NULL,
    2013-02-18 text  NULL,
    2013-03-06 text  NULL,
    2013-03-22 text  NULL,
    2013-04-07 text  NULL,
    2013-04-23 text  NULL,
    2013-05-09 text  NULL,
    2013-05-25 text  NULL,
    2013-06-10 text  NULL,
    2013-06-26 text  NULL,
    2013-07-12 text  NULL,
    2013-07-28 text  NULL,
    2013-08-13 text  NULL,
    2013-08-29 text  NULL,
    2013-09-14 text  NULL,
    2013-09-30 text  NULL,
    2013-10-16 text  NULL,
    2013-11-01 text  NULL,
    2013-11-17 text  NULL,
    2013-12-03 text  NULL,
    2013-12-19 text  NULL,
    2014-01-01 text  NULL,
    2014-01-17 text  NULL,
    2014-02-02 text  NULL,
    2014-02-18 text  NULL,
    2014-03-06 text  NULL,
    2014-03-22 text  NULL,
    2014-04-07 text  NULL,
    2014-04-23 text  NULL,
    2014-05-09 text  NULL,
    2014-05-25 text  NULL,
    2014-06-10 text  NULL,
    2014-06-26 text  NULL,
    2014-07-12 text  NULL,
    2014-07-28 text  NULL,
    2014-08-13 text  NULL,
    2014-08-29 text  NULL,
    2014-09-14 text  NULL,
    2014-09-30 text  NULL,
    2014-10-16 text  NULL,
    2014-11-01 text  NULL,
    2014-11-17 text  NULL,
    2014-12-03 text  NULL,
    2014-12-19 text  NULL,
    2015-01-01 text  NULL,
    2015-01-17 text  NULL,
    2015-02-02 text  NULL,
    2015-02-18 text  NULL,
    2015-03-06 text  NULL,
    2015-03-22 text  NULL,
    2015-04-07 text  NULL,
    2015-04-23 text  NULL,
    2015-05-09 text  NULL,
    2015-05-25 text  NULL,
    2015-06-10 text  NULL,
    2015-06-26 text  NULL,
    2015-07-12 text  NULL,
    2015-07-28 text  NULL,
    2015-08-13 text  NULL,
    2015-08-29 text  NULL,
    2015-09-14 text  NULL,
    2015-09-30 text  NULL,
    2015-10-16 text  NULL,
    2015-11-01 text  NULL,
    2015-11-17 text  NULL,
    2015-12-03 text  NULL,
    2015-12-19 text  NULL,
    2016-01-01 text  NULL,
    2016-01-17 text  NULL,
    2016-02-02 text  NULL,
    2016-02-18 text  NULL,
    2016-03-05 text  NULL,
    2016-03-21 text  NULL,
    2016-04-06 text  NULL,
    2016-04-22 text  NULL,
    2016-05-08 text  NULL,
    2016-05-24 text  NULL,
    2016-06-09 text  NULL,
    2016-06-25 text  NULL,
    2016-07-11 text  NULL,
    2016-07-27 text  NULL,
    2016-08-12 text  NULL,
    2016-08-28 text  NULL,
    2016-09-13 text  NULL,
    2016-09-29 text  NULL,
    2016-10-15 text  NULL,
    2016-10-31 text  NULL,
    2016-11-16 text  NULL,
    2016-12-02 text  NULL,
    2016-12-18 text  NULL,
    2017-01-01 text  NULL,
    2017-01-17 text  NULL,
    2017-02-02 text  NULL,
    2017-02-18 text  NULL,
    2017-03-06 text  NULL,
    2017-03-22 text  NULL,
    2017-04-07 text  NULL,
    2017-04-23 text  NULL,
    2017-05-09 text  NULL,
    2017-05-25 text  NULL,
    2017-06-10 text  NULL,
    2017-06-26 text  NULL,
    2017-07-12 text  NULL,
    2017-07-28 text  NULL,
    2017-08-13 text  NULL,
    2017-08-29 text  NULL,
    2017-09-14 text  NULL,
    2017-09-30 text  NULL,
    2017-10-16 text  NULL,
    2017-11-01 text  NULL,
    2017-11-17 text  NULL,
    2017-12-03 text  NULL,
    2017-12-19 text  NULL,
    2018-01-01 text  NULL,
    2018-01-17 text  NULL,
    2018-02-02 text  NULL,
    2018-02-18 text  NULL,
    2018-03-06 text  NULL,
    2018-03-22 text  NULL,
    2018-04-07 text  NULL,
    2018-04-23 text  NULL,
    2018-05-09 text  NULL,
    2018-05-25 text  NULL,
    2018-06-10 text  NULL,
    2018-06-26 text  NULL,
    2018-07-12 text  NULL,
    2018-07-28 text  NULL,
    2018-08-13 text  NULL,
    2018-08-29 text  NULL,
    2018-09-14 text  NULL,
    2018-09-30 text  NULL,
    2018-10-16 text  NULL,
    2018-11-01 text  NULL,
    2018-11-17 text  NULL,
    2018-12-03 text  NULL,
    2018-12-19 text  NULL,
    2019-01-01 text  NULL,
    2019-01-17 text  NULL,
    2019-02-02 text  NULL,
    2019-02-18 text  NULL,
    2019-03-06 text  NULL,
    2019-03-22 text  NULL,
    2019-04-07 text  NULL,
    2019-04-23 text  NULL,
    2019-05-09 text  NULL,
    2019-05-25 text  NULL,
    2019-06-10 text  NULL
);


/**********
 * table: public.tmp_pixel_ids
 */
CREATE TABLE public.tmp_pixel_ids (
    id integer  NOT NULL
);

ALTER TABLE public.tmp_pixel_ids ADD CONSTRAINT tmp_pixel_ids_id_pk
    PRIMARY KEY (id);

/**********
 * table: public.tmp_raster_layers_ids
 */
CREATE TABLE public.tmp_raster_layers_ids (
    id integer  NULL
);


/**********
 * table: public.use_concretes
 */
CREATE TABLE public.use_concretes (
    id integer DEFAULT nextval('use_concretes_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.use_concretes ADD CONSTRAINT use_concretes_pk
    PRIMARY KEY (id);

/**********
 * table: public.use_declareds
 */
CREATE TABLE public.use_declareds (
    id integer DEFAULT nextval('use_declareds_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)  NULL
);

ALTER TABLE public.use_declareds ADD CONSTRAINT use_declareds_pk
    PRIMARY KEY (id);

/**********
 * table: public.user_groups
 */
CREATE TABLE public.user_groups (
    id integer DEFAULT nextval('user_groups_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying(200)  NULL
);

ALTER TABLE public.user_groups ADD CONSTRAINT user_groups_pk
    PRIMARY KEY (id);

/**********
 * table: public.users
 */
CREATE TABLE public.users (
    id integer DEFAULT nextval('users_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    password bytea DEFAULT '\x'::bytea NULL,
    email character varying(320)  NOT NULL,
    active boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    last_login timestamp without time zone  NULL,
    last_ip inet  NULL,
    inactive_reason character varying(500)  NULL,
    activation_code character varying(10)  NULL,
    failed_login_count integer DEFAULT 0 NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    password_sent_at timestamp without time zone  NULL,
    organization_id integer  NOT NULL
);

ALTER TABLE public.users ADD CONSTRAINT users_pk
    PRIMARY KEY (id);
ALTER TABLE public.users ADD CONSTRAINT users_to_organizations_fk
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

/**********
 * table: public.users_by_groups
 */
CREATE TABLE public.users_by_groups (
    id integer DEFAULT nextval('users_by_groups_id_seq'::regclass) NOT NULL,
    user_id integer  NOT NULL,
    user_group_id integer  NOT NULL
);

ALTER TABLE public.users_by_groups ADD CONSTRAINT user_by_groups_pk
    PRIMARY KEY (id);
ALTER TABLE public.users_by_groups ADD CONSTRAINT users_by_groups_to_user_groups_id_fkey
    FOREIGN KEY (user_group_id) REFERENCES user_groups(id) ON DELETE CASCADE;
ALTER TABLE public.users_by_groups ADD CONSTRAINT users_by_groups_to_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

/**********
 * table: public.versions
 */
CREATE TABLE public.versions (
    id integer DEFAULT nextval('versions_id_seq'::regclass) NOT NULL,
    name character varying(50)  NOT NULL,
    ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL,
    project_id integer  NOT NULL
);

ALTER TABLE public.versions ADD CONSTRAINT version_to_projecs_fk
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.versions ADD CONSTRAINT versions_pk
    PRIMARY KEY (id);

/**********
 * table: tmp.debug_pixel
 */
CREATE TABLE tmp.debug_pixel (
    id integer  NULL,
    y integer  NULL,
    x integer  NULL,
    set_id integer  NULL,
    ts timestamp(6) without time zone  NULL,
    created_at timestamp(6) without time zone  NULL,
    the_geom geometry  NULL,
    centroid_x real  NULL,
    centroid_y real  NULL
);


/**********
 * table: tmp.tmp_1597914902269
 */
CREATE TABLE tmp.tmp_1597914902269 (
    pixel_id integer  NULL,
    raster_layer_id integer  NULL,
    value double precision  NULL,
    perc_insersect double precision  NULL
);


/**********
 * view: public.geography_columns
 */
CREATE VIEW public.geography_columns AS
 SELECT current_database() AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geography_column,
    postgis_typmod_dims(a.atttypmod) AS coord_dimension,
    postgis_typmod_srid(a.atttypmod) AS srid,
    postgis_typmod_type(a.atttypmod) AS type
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE t.typname = 'geography'::name AND a.attisdropped = false AND a.atttypid = t.oid AND a.attrelid = c.oid AND c.relnamespace = n.oid AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND NOT pg_is_other_temp_schema(c.relnamespace) AND has_table_privilege(c.oid, 'SELECT'::text);

/**********
 * view: public.geometry_columns
 */
CREATE VIEW public.geometry_columns AS
 SELECT current_database()::character varying(256) AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geometry_column,
    COALESCE(postgis_typmod_dims(a.atttypmod), sn.ndims, 2) AS coord_dimension,
    COALESCE(NULLIF(postgis_typmod_srid(a.atttypmod), 0), sr.srid, 0) AS srid,
    replace(replace(COALESCE(NULLIF(upper(postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), st.type, 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text)::character varying(30) AS type
   FROM pg_class c
     JOIN pg_attribute a ON a.attrelid = c.oid AND NOT a.attisdropped
     JOIN pg_namespace n ON c.relnamespace = n.oid
     JOIN pg_type t ON a.atttypid = t.oid
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(split_part(s.consrc, ''''::text, 2), ')'::text, ''::text) AS type
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE s.consrc ~~* '%geometrytype(% = %'::text) st ON st.connamespace = n.oid AND st.conrelid = c.oid AND (a.attnum = ANY (st.conkey))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text)::integer AS ndims
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE s.consrc ~~* '%ndims(% = %'::text) sn ON sn.connamespace = n.oid AND sn.conrelid = c.oid AND (a.attnum = ANY (sn.conkey))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text), '('::text, ''::text)::integer AS srid
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE s.consrc ~~* '%srid(% = %'::text) sr ON sr.connamespace = n.oid AND sr.conrelid = c.oid AND (a.attnum = ANY (sr.conkey))
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND NOT c.relname = 'raster_columns'::name AND t.typname = 'geometry'::name AND NOT pg_is_other_temp_schema(c.relnamespace) AND has_table_privilege(c.oid, 'SELECT'::text);

/**********
 * view: public.processes_vw
 */
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
   FROM process_fields
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
   FROM process_functions
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
   FROM process_images
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
   FROM process_pixels
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
   FROM process_regions
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
   FROM process_results;

/**********
 * view: public.raster_columns
 */
CREATE VIEW public.raster_columns AS
 SELECT current_database() AS r_table_catalog,
    n.nspname AS r_table_schema,
    c.relname AS r_table_name,
    a.attname AS r_raster_column,
    COALESCE(_raster_constraint_info_srid(n.nspname, c.relname, a.attname), ( SELECT st_srid('010100000000000000000000000000000000000000'::geometry) AS st_srid)) AS srid,
    _raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'x'::bpchar) AS scale_x,
    _raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'y'::bpchar) AS scale_y,
    _raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'width'::text) AS blocksize_x,
    _raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'height'::text) AS blocksize_y,
    COALESCE(_raster_constraint_info_alignment(n.nspname, c.relname, a.attname), false) AS same_alignment,
    COALESCE(_raster_constraint_info_regular_blocking(n.nspname, c.relname, a.attname), false) AS regular_blocking,
    _raster_constraint_info_num_bands(n.nspname, c.relname, a.attname) AS num_bands,
    _raster_constraint_info_pixel_types(n.nspname, c.relname, a.attname) AS pixel_types,
    _raster_constraint_info_nodata_values(n.nspname, c.relname, a.attname) AS nodata_values,
    _raster_constraint_info_out_db(n.nspname, c.relname, a.attname) AS out_db,
    _raster_constraint_info_extent(n.nspname, c.relname, a.attname) AS extent,
    COALESCE(_raster_constraint_info_index(n.nspname, c.relname, a.attname), false) AS spatial_index
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE t.typname = 'raster'::name AND a.attisdropped = false AND a.atttypid = t.oid AND a.attrelid = c.oid AND c.relnamespace = n.oid AND (c.relkind::text = ANY (ARRAY['r'::character(1), 'v'::character(1), 'm'::character(1), 'f'::character(1)]::text[])) AND NOT pg_is_other_temp_schema(c.relnamespace) AND has_table_privilege(c.oid, 'SELECT'::text);

/**********
 * view: public.raster_overviews
 */
CREATE VIEW public.raster_overviews AS
 SELECT current_database() AS o_table_catalog,
    n.nspname AS o_table_schema,
    c.relname AS o_table_name,
    a.attname AS o_raster_column,
    current_database() AS r_table_catalog,
    split_part(split_part(s.consrc, '''::name'::text, 1), ''''::text, 2)::name AS r_table_schema,
    split_part(split_part(s.consrc, '''::name'::text, 2), ''''::text, 2)::name AS r_table_name,
    split_part(split_part(s.consrc, '''::name'::text, 3), ''''::text, 2)::name AS r_raster_column,
    btrim(split_part(s.consrc, ','::text, 2))::integer AS overview_factor
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n,
    pg_constraint s
  WHERE t.typname = 'raster'::name AND a.attisdropped = false AND a.atttypid = t.oid AND a.attrelid = c.oid AND c.relnamespace = n.oid AND (c.relkind::text = ANY (ARRAY['r'::character(1), 'v'::character(1), 'm'::character(1), 'f'::character(1)]::text[])) AND s.connamespace = n.oid AND s.conrelid = c.oid AND s.consrc ~~ '%_overview_constraint(%'::text AND NOT pg_is_other_temp_schema(c.relnamespace) AND has_table_privilege(c.oid, 'SELECT'::text);

/**********
 * view: public.result_focus1
 */
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
    dc.date_from::date AS uses_date_from,
    dc.date_to::date AS uses_date_to,
    r.the_geom
   FROM results r
     LEFT JOIN view_process_results ON view_process_results.id = r.process_id
     LEFT JOIN fields f ON f.id = r.field_id
     LEFT JOIN farms fa ON fa.id = f.farm_id
     LEFT JOIN declarations de ON de.field_id = f.id
     LEFT JOIN declarations_concrete dc ON de.id = dc.declaration_id
     LEFT JOIN use_concretes u ON u.id = dc.use_concrete_id;

/**********
 * view: public.test_20160628
 */
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
   FROM fields fi
     JOIN farms fa ON fi.farm_id = fa.id
  WHERE fa.version_id = 76
  ORDER BY fi.name;

/**********
 * view: public.test_20170731
 */
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
   FROM fields fi
     JOIN farms fa ON fi.farm_id = fa.id
  WHERE fa.version_id = 118;

/**********
 * view: public.test_20170731_2
 */
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
   FROM pixel p
  WHERE p.set_id = 62;

/**********
 * view: public.test_20170804
 */
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
   FROM fields fi
     JOIN farms fa ON fi.farm_id = fa.id
  WHERE fa.version_id = 117
  ORDER BY fi.name;

/**********
 * view: public.test_20170804_1
 */
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
   FROM results
  WHERE results.process_id = 418;

/**********
 * view: public.view_process_results
 */
CREATE VIEW public.view_process_results AS
 SELECT pre.id,
    pr.name AS project_name,
    v.name AS version_name,
    u.name AS user_name,
    c.name AS client_name
   FROM process_results pre
     JOIN users u ON u.id = pre.user_id
     JOIN versions v ON v.id = pre.version_id
     JOIN projects pr ON pr.id = v.project_id
     JOIN clients c ON c.id = pr.client_id;

/**********
 * Index: log.process_query_function_logs.process_query_function_logs_pk
 */
CREATE UNIQUE INDEX process_query_function_logs_pk ON log.process_query_function_logs USING btree (id)

/**********
 * Index: log.trigger_logs.trigger_logs_pkey
 */
CREATE UNIQUE INDEX trigger_logs_pkey ON log.trigger_logs USING btree (id)

/**********
 * Index: public.business_objects_translations.business_objects_translations_pkey
 */
CREATE UNIQUE INDEX business_objects_translations_pkey ON public.business_objects_translations USING btree (id)

/**********
 * Index: public.clients.clients_pk
 */
CREATE UNIQUE INDEX clients_pk ON public.clients USING btree (id)

/**********
 * Index: public.clients.fki_clients_to_organizations_fk
 */
CREATE INDEX fki_clients_to_organizations_fk ON public.clients USING btree (organization_id)

/**********
 * Index: public.concretes_by_declareds.concretes_by_declareds_pk
 */
CREATE UNIQUE INDEX concretes_by_declareds_pk ON public.concretes_by_declareds USING btree (id)

/**********
 * Index: public.data_types.data_types_pk
 */
CREATE UNIQUE INDEX data_types_pk ON public.data_types USING btree (id)

/**********
 * Index: public.data_types_by_pixels.data_by_pixels
 */
CREATE UNIQUE INDEX data_by_pixels ON public.data_types_by_pixels USING btree (id)

/**********
 * Index: public.date_by_process_f2.date_by_process_f2_pk
 */
CREATE UNIQUE INDEX date_by_process_f2_pk ON public.date_by_process_f2 USING btree (id)

/**********
 * Index: public.db_actions_logs.db_actions_logs_pkey
 */
CREATE UNIQUE INDEX db_actions_logs_pkey ON public.db_actions_logs USING btree (id)

/**********
 * Index: public.declarations.declarations_pk
 */
CREATE UNIQUE INDEX declarations_pk ON public.declarations USING btree (id)

/**********
 * Index: public.declarations.unique_constraint_date_field_id
 */
CREATE UNIQUE INDEX unique_constraint_date_field_id ON public.declarations USING btree (date, field_id)

/**********
 * Index: public.declarations_concrete.declarations_concrete_declaration_id_idx
 */
CREATE INDEX declarations_concrete_declaration_id_idx ON public.declarations_concrete USING btree (declaration_id)

/**********
 * Index: public.declarations_concrete.declarations_concrete_pkey
 */
CREATE UNIQUE INDEX declarations_concrete_pkey ON public.declarations_concrete USING btree (id)

/**********
 * Index: public.declarations_concrete.declarations_concrete_use_concrete_id_idx
 */
CREATE INDEX declarations_concrete_use_concrete_id_idx ON public.declarations_concrete USING btree (use_concrete_id)

/**********
 * Index: public.farms.farms_code
 */
CREATE UNIQUE INDEX farms_code ON public.farms USING btree (code, version_id)

/**********
 * Index: public.farms.farms_pk
 */
CREATE UNIQUE INDEX farms_pk ON public.farms USING btree (id)

/**********
 * Index: public.farms.farms_version_id_idx
 */
CREATE INDEX farms_version_id_idx ON public.farms USING btree (version_id)

/**********
 * Index: public.fields.farm_field_code
 */
CREATE UNIQUE INDEX farm_field_code ON public.fields USING btree (farm_id, code)

/**********
 * Index: public.fields.fields_farm_id_idx
 */
CREATE INDEX fields_farm_id_idx ON public.fields USING btree (farm_id)

/**********
 * Index: public.fields.fields_pk
 */
CREATE UNIQUE INDEX fields_pk ON public.fields USING btree (id)

/**********
 * Index: public.fields.fields_the_geom_idx
 */
CREATE INDEX fields_the_geom_idx ON public.fields USING gist (the_geom)

/**********
 * Index: public.format_types.format_types_pk
 */
CREATE UNIQUE INDEX format_types_pk ON public.format_types USING btree (id)

/**********
 * Index: public.functions.functions_id_pk
 */
CREATE UNIQUE INDEX functions_id_pk ON public.functions USING btree (id)

/**********
 * Index: public.groups_by_options.groups_by_options_pk
 */
CREATE UNIQUE INDEX groups_by_options_pk ON public.groups_by_options USING btree (id)

/**********
 * Index: public.imagen_types.imagen_types_pk
 */
CREATE UNIQUE INDEX imagen_types_pk ON public.imagen_types USING btree (id)

/**********
 * Index: public.import_data.import_data_pk
 */
CREATE UNIQUE INDEX import_data_pk ON public.import_data USING btree (id)

/**********
 * Index: public.layer_types.layer_type_pk
 */
CREATE UNIQUE INDEX layer_type_pk ON public.layer_types USING btree (id)

/**********
 * Index: public.layers.data_type_by_imagen_type_pk
 */
CREATE UNIQUE INDEX data_type_by_imagen_type_pk ON public.layers USING btree (id)

/**********
 * Index: public.log_import_fields.log_import_fields_pkey
 */
CREATE UNIQUE INDEX log_import_fields_pkey ON public.log_import_fields USING btree (id)

/**********
 * Index: public.log_import_images.log_import_images_pk
 */
CREATE UNIQUE INDEX log_import_images_pk ON public.log_import_images USING btree (id)

/**********
 * Index: public.log_process_functions.log_process_functions_pk
 */
CREATE UNIQUE INDEX log_process_functions_pk ON public.log_process_functions USING btree (id)

/**********
 * Index: public.maps.map_pk
 */
CREATE UNIQUE INDEX map_pk ON public.maps USING btree (id)

/**********
 * Index: public.menu_options.fki_menu_options_to_menu_options_fk
 */
CREATE INDEX fki_menu_options_to_menu_options_fk ON public.menu_options USING btree (parent_id)

/**********
 * Index: public.menu_options.menu_option_pk
 */
CREATE UNIQUE INDEX menu_option_pk ON public.menu_options USING btree (id)

/**********
 * Index: public.organizations.organizations_pk
 */
CREATE UNIQUE INDEX organizations_pk ON public.organizations USING btree (id)

/**********
 * Index: public.parameter_types.parameter_types_pk
 */
CREATE UNIQUE INDEX parameter_types_pk ON public.parameter_types USING btree (id)

/**********
 * Index: public.parameters.parameters_pk
 */
CREATE UNIQUE INDEX parameters_pk ON public.parameters USING btree (id)

/**********
 * Index: public.pixel.pixel_pk
 */
CREATE UNIQUE INDEX pixel_pk ON public.pixel USING btree (id)

/**********
 * Index: public.pixel.pixel_set_id_idx
 */
CREATE INDEX pixel_set_id_idx ON public.pixel USING btree (set_id)

/**********
 * Index: public.pixel.pixel_the_geom_idx
 */
CREATE INDEX pixel_the_geom_idx ON public.pixel USING gist (the_geom)

/**********
 * Index: public.pixel_selection_rules.pixel_selection_rules_pk
 */
CREATE UNIQUE INDEX pixel_selection_rules_pk ON public.pixel_selection_rules USING btree (id)

/**********
 * Index: public.pixel_sets.pixel_sets_imagen_type_id_idx
 */
CREATE INDEX pixel_sets_imagen_type_id_idx ON public.pixel_sets USING btree (imagen_type_id)

/**********
 * Index: public.pixel_sets.pixel_sets_pk
 */
CREATE UNIQUE INDEX pixel_sets_pk ON public.pixel_sets USING btree (id)

/**********
 * Index: public.process_fields.process_fields_pkey
 */
CREATE UNIQUE INDEX process_fields_pkey ON public.process_fields USING btree (id)

/**********
 * Index: public.process_functions.fki_process_functions_map_id_to_maps
 */
CREATE INDEX fki_process_functions_map_id_to_maps ON public.process_functions USING btree (map_id)

/**********
 * Index: public.process_functions.fki_process_functions_to_functions_fkey
 */
CREATE INDEX fki_process_functions_to_functions_fkey ON public.process_functions USING btree (function_id)

/**********
 * Index: public.process_functions.process_functions_id_pk
 */
CREATE UNIQUE INDEX process_functions_id_pk ON public.process_functions USING btree (id)

/**********
 * Index: public.process_images.process_images_pkey
 */
CREATE UNIQUE INDEX process_images_pkey ON public.process_images USING btree (id)

/**********
 * Index: public.process_pixels.process_pixels_pkey
 */
CREATE UNIQUE INDEX process_pixels_pkey ON public.process_pixels USING btree (id)

/**********
 * Index: public.process_query_functions.process_query_functions_pk
 */
CREATE UNIQUE INDEX process_query_functions_pk ON public.process_query_functions USING btree (id)

/**********
 * Index: public.process_regions.fki_process_regions_to_maps_fk
 */
CREATE INDEX fki_process_regions_to_maps_fk ON public.process_regions USING btree (map_id)

/**********
 * Index: public.process_regions.process_regions_pkey
 */
CREATE UNIQUE INDEX process_regions_pkey ON public.process_regions USING btree (id)

/**********
 * Index: public.process_results.process_results_id_pk
 */
CREATE UNIQUE INDEX process_results_id_pk ON public.process_results USING btree (id)

/**********
 * Index: public.process_results.process_results_user_id_idx
 */
CREATE INDEX process_results_user_id_idx ON public.process_results USING btree (user_id)

/**********
 * Index: public.process_results.process_results_version_id_idx
 */
CREATE INDEX process_results_version_id_idx ON public.process_results USING btree (version_id)

/**********
 * Index: public.projects.fki_projects_to_projects_fk
 */
CREATE INDEX fki_projects_to_projects_fk ON public.projects USING btree (parent_id)

/**********
 * Index: public.projects.projects_client_id_idx
 */
CREATE INDEX projects_client_id_idx ON public.projects USING btree (client_id)

/**********
 * Index: public.projects.projects_pk
 */
CREATE UNIQUE INDEX projects_pk ON public.projects USING btree (id)

/**********
 * Index: public.r2_log_activity.log_activity_pk
 */
CREATE UNIQUE INDEX log_activity_pk ON public.r2_log_activity USING btree (id)

/**********
 * Index: public.r2_rest_sessions.r2_rest_sessions_pkey
 */
CREATE UNIQUE INDEX r2_rest_sessions_pkey ON public.r2_rest_sessions USING btree (id)

/**********
 * Index: public.r2_sessions.r2_sessions_pkey
 */
CREATE UNIQUE INDEX r2_sessions_pkey ON public.r2_sessions USING btree (id)

/**********
 * Index: public.r2_sessions.r2_sessions_timestamp
 */
CREATE INDEX r2_sessions_timestamp ON public.r2_sessions USING btree ("timestamp")

/**********
 * Index: public.raster_files.raster_files_pk
 */
CREATE UNIQUE INDEX raster_files_pk ON public.raster_files USING btree (id)

/**********
 * Index: public.raster_groups.raster_groups_pk
 */
CREATE UNIQUE INDEX raster_groups_pk ON public.raster_groups USING btree (id)

/**********
 * Index: public.raster_layers.raster_layers_pk
 */
CREATE UNIQUE INDEX raster_layers_pk ON public.raster_layers USING btree (id)

/**********
 * Index: public.raster_layers.raster_layers_raster_file_id_idx
 */
CREATE INDEX raster_layers_raster_file_id_idx ON public.raster_layers USING btree (raster_file_id)

/**********
 * Index: public.regions.regions_pk
 */
CREATE UNIQUE INDEX regions_pk ON public.regions USING btree (id)

/**********
 * Index: public.regions.regions_the_geom_idx
 */
CREATE INDEX regions_the_geom_idx ON public.regions USING gist (the_geom)

/**********
 * Index: public.results.field_idx
 */
CREATE INDEX field_idx ON public.results USING btree (field_id)

/**********
 * Index: public.results.pixel_idx
 */
CREATE INDEX pixel_idx ON public.results USING btree (pixel_id)

/**********
 * Index: public.results.process_field_id_idx
 */
CREATE INDEX process_field_id_idx ON public.results USING btree (process_id, field_id)

/**********
 * Index: public.results.process_idx
 */
CREATE INDEX process_idx ON public.results USING btree (process_id)

/**********
 * Index: public.results.results_pkey
 */
CREATE UNIQUE INDEX results_pkey ON public.results USING btree (id)

/**********
 * Index: public.results.results_process_id_idx
 */
CREATE INDEX results_process_id_idx ON public.results USING btree (process_id)

/**********
 * Index: public.results.results_the_geom_idx
 */
CREATE INDEX results_the_geom_idx ON public.results USING gist (the_geom)

/**********
 * Index: public.results_f1.results_f1_id_pk
 */
CREATE UNIQUE INDEX results_f1_id_pk ON public.results_f1 USING btree (id)

/**********
 * Index: public.results_f2.result_f2_idx
 */
CREATE INDEX result_f2_idx ON public.results_f2 USING btree (key, process_result_id, process_focus_id, date)

/**********
 * Index: public.results_f2.result_f2_idx2
 */
CREATE INDEX result_f2_idx2 ON public.results_f2 USING btree (date, process_result_id)

/**********
 * Index: public.results_f2.result_f2_process_focus_id_process_result_id_idx
 */
CREATE INDEX result_f2_process_focus_id_process_result_id_idx ON public.results_f2 USING btree (process_focus_id, process_result_id)

/**********
 * Index: public.results_f2.result_f2_process_result_id_process_focus_id_idx
 */
CREATE INDEX result_f2_process_result_id_process_focus_id_idx ON public.results_f2 USING btree (process_result_id, process_focus_id)

/**********
 * Index: public.results_f2.result_focus2_pk
 */
CREATE UNIQUE INDEX result_focus2_pk ON public.results_f2 USING btree (id)

/**********
 * Index: public.results_f2.results_f2_process_result_id_process_focus_id_key_date_idx
 */
CREATE UNIQUE INDEX results_f2_process_result_id_process_focus_id_key_date_idx ON public.results_f2 USING btree (process_result_id, process_focus_id, key, date)

/**********
 * Index: public.spatial_ref_sys.spatial_ref_sys_pkey
 */
CREATE UNIQUE INDEX spatial_ref_sys_pkey ON public.spatial_ref_sys USING btree (srid)

/**********
 * Index: public.temporal_expansion_rules.temporal_expansion_rules_pk
 */
CREATE UNIQUE INDEX temporal_expansion_rules_pk ON public.temporal_expansion_rules USING btree (id)

/**********
 * Index: public.temporal_expansion_rules.temporal_expansion_rules_unique_idx
 */
CREATE UNIQUE INDEX temporal_expansion_rules_unique_idx ON public.temporal_expansion_rules USING btree (region_id, use_declared_id, use_concrete_id, declaration_month)

/**********
 * Index: public.tmp_pixel_ids.tmp_pixel_ids_id_pk
 */
CREATE UNIQUE INDEX tmp_pixel_ids_id_pk ON public.tmp_pixel_ids USING btree (id)

/**********
 * Index: public.use_concretes.use_concretes_pk
 */
CREATE UNIQUE INDEX use_concretes_pk ON public.use_concretes USING btree (id)

/**********
 * Index: public.use_declareds.use_declareds_pk
 */
CREATE UNIQUE INDEX use_declareds_pk ON public.use_declareds USING btree (id)

/**********
 * Index: public.user_groups.user_groups_pk
 */
CREATE UNIQUE INDEX user_groups_pk ON public.user_groups USING btree (id)

/**********
 * Index: public.users.fki_users_to_organizations_fk
 */
CREATE INDEX fki_users_to_organizations_fk ON public.users USING btree (organization_id)

/**********
 * Index: public.users.users_pk
 */
CREATE UNIQUE INDEX users_pk ON public.users USING btree (id)

/**********
 * Index: public.users_by_groups.user_by_groups_pk
 */
CREATE UNIQUE INDEX user_by_groups_pk ON public.users_by_groups USING btree (id)

/**********
 * Index: public.versions.fki_version_to_projecs_fk
 */
CREATE INDEX fki_version_to_projecs_fk ON public.versions USING btree (project_id)

/**********
 * Index: public.versions.versions_client_id_idx
 */
CREATE INDEX versions_client_id_idx ON public.versions USING btree (project_id)

/**********
 * Index: public.versions.versions_pk
 */
CREATE UNIQUE INDEX versions_pk ON public.versions USING btree (id)

