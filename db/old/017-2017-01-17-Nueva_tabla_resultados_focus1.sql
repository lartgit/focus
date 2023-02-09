BEGIN;

DROP TABLE IF EXISTS results_f1;

CREATE TABLE results_f1
(
    id serial NOT NULL,
    result_id integer NOT NULL,
    field_id integer NOT NULL,
    process_id integer NOT NULL,
    date date NOT NULL,
    use_concrete_id integer,
    uses_date_from date,
    uses_date_to date,
    CONSTRAINT results_f1_id_pk PRIMARY KEY (id),
    CONSTRAINT fk_results_f1_to_results FOREIGN KEY (result_id) REFERENCES results (id) ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_results_f1_to_fields FOREIGN KEY (field_id) REFERENCES fields (id) ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_results_f1_to_process_results FOREIGN KEY (process_id) REFERENCES process_results (id) ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT fk_results_f1_to_use_concretes FOREIGN KEY (use_concrete_id) REFERENCES use_concretes (id) ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMIT;