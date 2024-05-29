--vytvoření tabulky D_Qualification, změna datového typu sloupců z varchar na int, u sloupce "ID" rozšíření názvu pro snazší identifikaci
CREATE OR REPLACE TABLE "D_Qualification" AS
SELECT TO_NUMBER("ID") AS "ID_Qualification"
    ,TO_NUMBER("ID_Person") AS "ID_Person"
    ,TO_NUMBER("ID_QualificationType") AS "ID_QualificationType"
FROM "OU_Qualification";
