BEGIN; --axelbayerl

CREATE TABLE "r2_sessions" (
    "id" varchar(40) NOT NULL,
    "ip_address" varchar(45) NOT NULL,
    "timestamp" bigint DEFAULT 0 NOT NULL,
    "data" text DEFAULT '' NOT NULL,
    PRIMARY KEY ("id")
);

CREATE INDEX "r2_sessions_timestamp" ON "r2_sessions" ("timestamp");

COMMIT;
