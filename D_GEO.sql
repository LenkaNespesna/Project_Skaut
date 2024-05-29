CREATE OR REPLACE TABLE "D_GEO" AS
SELECT DISTINCT "kodobce"
    ,"nazobce"
    , "nazcobce" AS "nazev_casti_obce"
    ,"psc"
    , TRY_CAST("Latitude" AS FLOAT) AS "ZemSirka"
    , TRY_CAST("Longitude" AS FLOAT) AS "ZemDelka"
    , "text2" as"Kraj"
FROM "ObecPsc"
LEFT JOIN "Souradnice" on "Kod_obce" = "kodobce"
LEFT JOIN "KodObceKraj" on "chodnota1" = "kodobce"
;
