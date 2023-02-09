BEGIN;

ALTER TABLE public.declarations
   ADD COLUMN active boolean NOT NULL DEFAULT true;   

ALTER TABLE public.farms
   ADD COLUMN active boolean NOT NULL DEFAULT true;   

ALTER TABLE public.fields
   ADD COLUMN active boolean NOT NULL DEFAULT true;     

ALTER TABLE public.projects
   ADD COLUMN active boolean NOT NULL DEFAULT true;    

ALTER TABLE public.sub_projects
   ADD COLUMN active boolean NOT NULL DEFAULT true;

ALTER TABLE public.versions
   ADD COLUMN active boolean NOT NULL DEFAULT true;

COMMIT;
