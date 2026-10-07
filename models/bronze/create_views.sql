USE CATALOG logiflow;

CREATE OR REPLACE VIEW bronze.OCRD AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/OCRD/OCRD*.csv', format => 'csv', header => true, sep => ';');

CREATE OR REPLACE VIEW bronze.OWHS AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/OWHS/OWHS*.csv', format => 'csv', header => true, sep => ';');

CREATE OR REPLACE VIEW bronze.OITM AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/OITM/OITM*.csv', format => 'csv', header => true, sep => ';');

CREATE OR REPLACE VIEW bronze.OPKL AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/OPKL/OPKL*.csv', format => 'csv', header => true, sep => ';');

CREATE OR REPLACE VIEW bronze.OPKL1 AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/OPKL1/OPKL1*.csv', format => 'csv', header => true, sep => ';');

CREATE OR REPLACE VIEW bronze.AUX_Desconsideracoes AS
SELECT * FROM read_files('/Volumes/logiflow/bronze/raw_data/AUX_Desconsideracoes/AUX_Desconsideracoes*.csv', format => 'csv', header => true, sep => ';');
