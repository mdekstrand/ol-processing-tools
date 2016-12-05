-- Create indexes and constraints
ALTER TABLE authors ADD PRIMARY KEY (author_id);
ALTER TABLE authors ADD CONSTRAINT author_key_uq UNIQUE (author_key);
ALTER TABLE works ADD PRIMARY KEY (work_id);
ALTER TABLE works ADD CONSTRAINT work_key_uq UNIQUE (work_key);
ALTER TABLE editions ADD PRIMARY KEY (edition_id);
ALTER TABLE editions ADD CONSTRAINT edition_key_uq UNIQUE (edition_key);

-- Set up work-author join table
DROP TABLE IF EXISTS work_authors CASCADE;
CREATE TABLE work_authors
AS SELECT work_id, author_id
   FROM authors
     JOIN (SELECT work_id, jsonb_array_elements((work_data->'authors')) #>> '{author,key}' AS author_key FROM works) w
     USING (author_key);

CREATE INDEX work_author_wk_idx ON work_authors (work_id);
CREATE INDEX work_author_au_idx ON work_authors (author_id);
ALTER TABLE work_authors ADD CONSTRAINT work_author_wk_fk FOREIGN KEY (work_id) REFERENCES works;
ALTER TABLE work_authors ADD CONSTRAINT work_author_au_fk FOREIGN KEY (author_id) REFERENCES authors;

-- Set up edition-author join table
DROP TABLE IF EXISTS edition_authors;
CREATE TABLE edition_authors
AS SELECT edition_id, author_id
   FROM authors
     JOIN (SELECT edition_id, jsonb_array_elements((edition_data->'authors')) ->> 'key' AS author_key
           FROM editions) e
     USING (author_key);

CREATE INDEX edition_author_ed_idx ON edition_authors (edition_id);
CREATE INDEX edition_author_au_idx ON edition_authors (author_id);
ALTER TABLE edition_authors ADD CONSTRAINT edition_author_wk_fk FOREIGN KEY (edition_id) REFERENCES editions;
ALTER TABLE edition_authors ADD CONSTRAINT edition_author_au_fk FOREIGN KEY (author_id) REFERENCES authors;

-- Set up edition-work join table
DROP TABLE IF EXISTS edition_works;
CREATE TABLE edition_works
AS SELECT edition_id, work_id
   FROM works
     JOIN (SELECT edition_id, jsonb_array_elements((edition_data->'works')) ->> 'key' AS work_key FROM editions) w
     USING (work_key);

CREATE INDEX edition_work_ed_idx ON edition_works (edition_id);
CREATE INDEX edition_work_au_idx ON edition_works (work_id);
ALTER TABLE edition_works ADD CONSTRAINT edition_work_ed_fk FOREIGN KEY (edition_id) REFERENCES editions;
ALTER TABLE edition_works ADD CONSTRAINT edition_work_wk_fk FOREIGN KEY (work_id) REFERENCES works;

-- Extract ISBNs
DROP TABLE IF EXISTS edition_isbn;
CREATE TABLE edition_isbn
AS SELECT edition_id, jsonb_array_elements_text(edition_data->'isbn_10') AS isbn
   FROM editions
   UNION
   SELECT edition_id, jsonb_array_elements_text(edition_data->'isbn_13') AS isbn
   FROM editions;

CREATE INDEX edition_isbn_ed_idx ON edition_isbn (edition_id);
CREATE INDEX edition_isbn_idx ON edition_isbn (isbn);
ALTER TABLE edition_isbn ADD CONSTRAINT edition_work_ed_fk FOREIGN KEY (edition_id) REFERENCES editions;

ANALYZE;