-- odstranění prázných řádků
DELETE FROM "OU_UnitTree" WHERE "ID_Unit"='';

CREATE OR REPLACE TABLE "D_UnitTree" AS
SELECT
TO_NUMBER("ID_Unit") AS "ID_Unit" 
, "ID_UnitParent"
, TRY_TO_DATE("ValidFrom", 'DD.MM.YYYY') AS "ValidFrom"
, TRY_TO_DATE("ValidTo", 'DD.MM.YYYY') AS "ValidTo"
, "ID_UnitFoundReason"
, "UnitFoundDescription"
FROM "OU_UnitTree"
WHERE 1=1 
AND TRY_TO_DATE("ValidTo", 'DD.MM.YYYY') IS NULL
;
