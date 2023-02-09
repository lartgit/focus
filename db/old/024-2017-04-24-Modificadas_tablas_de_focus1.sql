
BEGIN;

DROP VIEW view_process_results;

ALTER TABLE process_results DROP COLUMN date;

CREATE OR REPLACE VIEW view_process_results AS 
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

CREATE OR REPLACE VIEW result_focus1 AS
SELECT
        r.id as result_id,
        r.selected as sel_rule,
        r.selected_by_user as sel_user,
        r.pixel_id as pixel_id,
        r.centroid_y as latitud,
        r.centroid_x as longitud,
        r.intersect_idx as intersect_idx,
        f.id as field_id,
        f.name as field_name,
        f.date_from as field_date_from,
        f.date_to as field_date_to,
        fa.id as farm_id,
        fa.name as farm_name,
        view_process_results.id as process_id,
        view_process_results.version_name,
        view_process_results.project_name,
        view_process_results.client_name,
        view_process_results.user_name,
        u.id as use_concrete_id,
        u.name as use_concrete_name,
        dc.date_from::timestamp::date as uses_date_from,
        dc.date_to::timestamp::date as uses_date_to,
        r.the_geom
    FROM results r
    LEFT JOIN view_process_results ON view_process_results.id = r.process_id
    LEFT JOIN fields f  ON f.id = r.field_id 
    LEFT JOIN farms fa  ON fa.id = f.farm_id 
    LEFT JOIN declarations de ON de.field_id = f.id 
    LEFT JOIN declarations_concrete dc on de.id = dc.declaration_id
    LEFT JOIN use_concretes u ON u.id = dc.use_concrete_id;

COMMIT;
