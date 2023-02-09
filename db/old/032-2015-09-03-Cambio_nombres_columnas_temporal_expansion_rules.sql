BEGIN;


ALTER TABLE public.temporal_expansion_rules 
    DROP COLUMN declaration_month;
ALTER TABLE public.temporal_expansion_rules 
    DROP COLUMN delta_month_from;
ALTER TABLE public.temporal_expansion_rules 
    DROP COLUMN delta_month_to;

ALTER TABLE public.temporal_expansion_rules 
    ADD COLUMN declaration_month INTEGER;
ALTER TABLE public.temporal_expansion_rules 
    ADD COLUMN delta_month_from INTEGER;
ALTER TABLE public.temporal_expansion_rules 
    ADD COLUMN delta_month_to INTEGER;

COMMIT;
