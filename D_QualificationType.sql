--vytvoření tabulky D_QualificationType, změna datového typu "ID", rozšíření názvu sloupce "ID" pro snazší identifikaci

CREATE OR REPLACE TABLE "D_QualificationType" AS
SELECT TO_NUMBER("ID") AS "ID_QualificationType"
    ,"DisplayName" AS "DisplayName_Qualification"
    ,"Key" AS "Key"
FROM "OU_QualificationType"
WHERE "IsActive"='1';
