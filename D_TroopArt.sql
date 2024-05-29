
CREATE OR REPLACE TABLE "D_UnitTroopArt" AS
SELECT 
TO_NUMBER("ID") AS "ID_UnitTroopArt"
, TO_NUMBER("ID_Unit") AS "ID_Unit"
, TRY_CAST("ID_TroopArt" AS NUMBER) AS "ID_TroopArt"
, TRY_TO_DATE("ValidFrom", 'DD.MM.YYYY') AS "ValidFrom"
, TRY_TO_DATE("ValidTo", 'DD.MM.YYYY') AS "ValidTo"
FROM "OU_UnitTroopArt"
WHERE "IsValid" = 1
;
