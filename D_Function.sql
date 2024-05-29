CREATE OR REPLACE TABLE "D_Function" AS
SELECT 
TRY_CAST("ID" AS NUMBER(38,0)) AS "ID_Function"
, TRY_CAST("ID_Person" AS NUMBER(38,0)) AS "ID_Person"
, "ID_Unit"
, TRY_TO_DATE("ValidFrom", 'DD.MM.YYYY') AS "ValidFrom"
, TRY_TO_DATE("ValidTo", 'DD.MM.YYYY') AS "ValidTo"
, TRY_CAST("ID_FunctionType" AS NUMBER(38,0)) AS "ID_FunctionType"
FROM "OU_Function"
;
