BEGIN;

ALTER TABLE pixel_sets ADD COLUMN active boolean;

COMMIT;