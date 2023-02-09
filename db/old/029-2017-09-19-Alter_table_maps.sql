
BEGiN;
ALTER TABLE public.maps
   ALTER COLUMN name TYPE character varying(100);
COMMIT;