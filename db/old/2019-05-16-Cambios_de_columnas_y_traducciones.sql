BEGIN;

DELETE FROM business_objects_translations WHERE current_name LIKE 'focus2_%';
INSERT INTO business_objects_translations (current_name, spanish_translation, english_translation) VALUES
	('focus2_data_count','Pixeles','Pixeles'),
	('focus2_day','Dia','Dia'),
	('focus2_farm_name','Campo','Campo'),
	('focus2_field_area','Superficie','Superficie'),
	('focus2_field_name','Lote','Lote'),
	('focus2_intersect_idx','Interseccion','Interseccion'),
	('focus2_lat','Lat','Lat'),
	('focus2_lon','Long','Long'),
	('focus2_month','Mes','Mes'),
	('focus2_pixel_id','Pixel ID','Pixel ID'),
	('focus2_udeveg','Unidad Geomorfologica','Unidad Geomorfologica'),
	('focus2_use_concrete_name','Uso','Uso'),
	('focus2_uses_date_from','Uso desde','Uso desde'),
	('focus2_uses_date_to','Uso hasta','Uso hasta'),
	('focus2_year','Año','Año');

ALTER TABLE public.clients ADD COLUMN description text;

ALTER TABLE public.projects ADD COLUMN description text;

COMMIT;