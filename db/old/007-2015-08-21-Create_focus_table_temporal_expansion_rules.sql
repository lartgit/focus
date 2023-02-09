BEGIN;
--
CREATE TABLE public.temporal_expansion_rules
(
  id serial NOT NULL,
  region_id integer NOT NULL,
  use_declared_id integer NOT NULL,
  use_concrete_id integer NOT NULL,
  declaration_month date,
  delta_month_from date,
  delta_month_to date,
  ts timestamp(6) without time zone NOT NULL DEFAULT now(),
  created_at timestamp(6) without time zone NOT NULL DEFAULT now(),
  CONSTRAINT temporal_expansion_rules_pk PRIMARY KEY (id),
--Region
    CONSTRAINT temporal_expansion_rules_to_region_id_fkey FOREIGN KEY (region_id)
      REFERENCES regions (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
--Use_declared
--Con este Constraint Tengo una duda en el DER tentativo dice Use_declaration_id
--Asumi que es la tabla Use_declared 
    CONSTRAINT temporal_expansion_rules_to_use_declared_id_fkey FOREIGN KEY (use_declared_id)
      REFERENCES use_declareds (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
--Use_concrete
    CONSTRAINT temporal_expansion_rules_to_use_concrete_id_fkey FOREIGN KEY (use_concrete_id)
      REFERENCES use_concretes (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;

