library(DBI)
# requres RPostgres to be built + installed
# which in turn requres PSQL to be installed

# read in project-specific renviron
readRenviron(".Renviron")

# Check renviron variables exist
pg_sysenv <- Sys.getenv(c(
  "PGHOST",
  "PGPORT",
  "PGDATABASE",
  "PGUSER",
  "PGPASSWORD"
))

# check all exist
stopifnot(!("" %in% pg_sysenv))
# assign in environment
list2env(as.list(pg_sysenv), envir = globalenv())

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = PGDATABASE,
  host = PGHOST,
  port = PGPORT,
  user = PGUSER,
  password = PGPASSWORD
)


dbListTables(con)

# relevant tables?
# eyeballed from tables list as of 09.11.2026
tables <- c(
  "analytical_method",
  "chemical_identifiers",
  "chemical_name_lookup",
  "data_source",
  "data_type",
  "data_type_sub",
  "environ_compartment",
  "environmental_con",
  "exposure_env_summary",
  "exposure_types_sample_matrix",
  "extraction_method",
  "fraction",
  "gender",
  "lifestage",
  "measured_category",
  "measured_type",
  "parent_compounds",
  "ref_id_type",
  "reliab_eval_sys",
  "sample_matrix",
  "sampling_method",
  "sites",
  "species",
  "species_identifier",
  "stressor_source",
  "stressor_type",
  "taxonomy_ncbi_unique",
  "tissue_ontology",
  "units_conversion",
  "user_ref"
)

# table sizes
dbGetQuery(
  con,
  "SELECT 
    relname AS TableName, 
    n_live_tup AS RowCount
FROM 
    pg_stat_user_tables
ORDER BY 
    n_live_tup DESC;
"
)

# try a small one
gender <- dbGetQuery(con, "SELECT * FROM gender;")

environmental_con <- dbGetQuery(
  con,
  "SELECT * FROM environmental_con LIMIT 100;"
)

environ_compartment <- dbGetQuery(con, "SELECT * FROM environ_compartment;")

environ_compartment_count <- dbGetQuery(
  con,
  "SELECT DISTINCT environ_compartment, COUNT(*) as count  FROM environmental_con GROUP BY environ_compartment"
)

# # Disconnect from the database
# dbDisconnect(con)
