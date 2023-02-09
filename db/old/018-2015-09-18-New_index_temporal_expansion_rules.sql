
BEGIN;

ALTER TABLE public.temporal_expansion_rules
  ADD CONSTRAINT temporal_expansion_rules_unique_idx
  UNIQUE (region_id, use_declared_id, use_concrete_id, declaration_month);

COMMIT;
