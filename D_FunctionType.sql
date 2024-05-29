CREATE OR REPLACE TABLE "D_FunctionType" AS
SELECT 
TRY_CAST("ID" AS NUMBER(38,0)) AS "ID_FunctionType"
, "DisplayName" AS "DisplayName_FunctionType"
FROM "OU_FunctionType"
;
