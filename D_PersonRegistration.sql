--vyvoření tabulky D_PersonRegistration, změna datového typu z varchar na int, u "ID" rozšíření názvu pro snazší identifikaci

CREATE OR REPLACE TABLE "D_PersonRegistration" AS 
SELECT TO_NUMBER(PR."ID" )AS "ID_PersonRegistration"
    ,TO_NUMBER(PR."ID_Person") AS "ID_Person"
    ,TO_NUMBER(PR."ID_UnitRegistration") AS "ID_UnitRegistration"
    , CASE 
WHEN "ID_UnitType" = 'oddil' THEN UR."ID"::NUMBER
WHEN "ID_UnitType" = 'druzina' THEN UR."ID_UnitRegistrationParent"::NUMBER
ELSE NULL
END AS "ID_UnitOddil" 
FROM "OU_PersonRegistration" PR
LEFT JOIN "F_UnitRegistration" UR ON PR."ID_UnitRegistration" = UR."ID"
LEFT JOIN "D_Unit" U on UR."ID_Unit" = U."ID_Unit"
;
