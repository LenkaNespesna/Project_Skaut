CREATE OR REPLACE TABLE "F_Person" AS
SELECT 
TRY_CAST("ID" AS NUMBER(38,0)) AS "ID_Person"
, "IsActive"
, "ID_PersonType"
, "ID_Sex"
, DATEDIFF(year, try_to_date("Birthday", 'DD.MM.YYYY'), current_date()) AS "Age"
FROM "OU_Person"
WHERE "IsActive" = 1
;
