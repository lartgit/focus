BEGIN;

CREATE TABLE organizations
(
  id serial NOT NULL,
  ts timestamp without time zone DEFAULT now(),
  created_at timestamp without time zone DEFAULT now(),
  name character varying(50) NOT NULL,
  CONSTRAINT organizations_pk PRIMARY KEY (id)
);

INSERT INTO organizations (id, name) VALUES (-1, 'R2');
INSERT INTO organizations (name) VALUES ('LART'), ('CREA');

ALTER TABLE users ADD COLUMN organization_id integer NOT NULL DEFAULT 1;
ALTER TABLE users ALTER COLUMN organization_id DROP DEFAULT;
ALTER TABLE users ADD CONSTRAINT users_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES organizations (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
CREATE INDEX fki_users_to_organizations_fk ON users(organization_id);

UPDATE users SET organization_id = -1 WHERE id = -1;

ALTER TABLE clients ADD COLUMN organization_id integer NOT NULL DEFAULT 1;
ALTER TABLE clients ALTER COLUMN organization_id DROP DEFAULT;
ALTER TABLE clients ADD CONSTRAINT clients_to_organizations_fk FOREIGN KEY (organization_id) REFERENCES organizations (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
CREATE INDEX fki_clients_to_organizations_fk ON clients(organization_id);

-- ALTER TABLE maps ADD COLUMN user_id integer NOT NULL DEFAULT -1;
-- ALTER TABLE maps ALTER COLUMN user_id DROP DEFAULT;
-- ALTER TABLE maps ADD CONSTRAINT maps_to_users_fk FOREIGN KEY (user_id) REFERENCES users (id) ON UPDATE NO ACTION ON DELETE NO ACTION;
-- CREATE INDEX fki_maps_to_users_fk ON maps(user_id);

ALTER TABLE menu_options ADD COLUMN "order" integer NOT NULL DEFAULT 0;
ALTER TABLE menu_options ALTER COLUMN "order" DROP DEFAULT;

INSERT INTO menu_options (id, name, controller, action, menu_icon, parent_id, "order") VALUES (79, 'Organizaciones', 'organizations', 'index', '<i class="fa fa-suitcase"></i>',17, 2000);

--ALTER TABLE maps ADD COLUMN organization_id integer NOT NULL DEFAULT 1;
--ALTER TABLE maps ALTER COLUMN organization_id DROP DEFAULT;

COMMIT;
