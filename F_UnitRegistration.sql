--choose and columns cast

CREATE OR REPLACE TABLE "F_UnitRegistration" AS
SELECT TRY_TO_NUMBER("ID") AS "ID_UnitRegistration"
, TRY_TO_NUMBER("ID_Unit") AS "ID_Unit"
, "Year" AS "ID_TI"
, TRY_TO_NUMBER("ID_UnitRegistrationParent") AS "ID_UnitRegistrationParent"
, TRY_CAST(REPLACE("RegularMembersTo6", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembersTo6"
, TRY_CAST(REPLACE("RegularMembersTo15", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembersTo15"
, TRY_CAST(REPLACE("RegularMembersTo18", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembersTo18"
, TRY_CAST(REPLACE("RegularMembersTo26", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembersTo26"
, TRY_CAST(REPLACE("RegularMembersFrom26", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembersFrom26"
, TRY_CAST(REPLACE("RegularMembers", 'NULL', 0) AS NUMBER(18,0)) AS "RegularMembers"
FROM "OU_UnitRegistration"
;


-- Doplnění počtu dětí vs. dospělí
-- Počet dospělých

ALTER TABLE "F_UnitRegistration" ADD COLUMN "pocet_dospeli" integer;

UPDATE "F_UnitRegistration"
SET "pocet_dospeli" = ("RegularMembersTo26"+"RegularMembersFrom26");

--Počet dětí

ALTER TABLE "F_UnitRegistration" ADD COLUMN "pocet_deti" integer;

UPDATE "F_UnitRegistration" 
SET "pocet_deti"= ("RegularMembersTo6"+"RegularMembersTo15"+"RegularMembersTo18");

-- Procentuálni zastoupení dospělých a dětí

--Procento dospělých, DIV0 ošetřuje dělení nulou (když je dělitel 0, vrátí 0)

ALTER TABLE "F_UnitRegistration" ADD COLUMN "procento_dospeli" float;

UPDATE "F_UnitRegistration"
SET "procento_dospeli"=DIV0("pocet_dospeli", ("pocet_dospeli"+"pocet_deti"))*100;

--Procento dětí, DIV0 ošetřuje dělení nulou (když je dělitel 0, vrátí 0)

ALTER TABLE "F_UnitRegistration" ADD COLUMN "procento_deti" float;

UPDATE "F_UnitRegistration"
SET "procento_deti"=DIV0("pocet_deti", ("pocet_dospeli"+"pocet_deti"))*100;




-- přidání počtu RegularMembers v nadřazené jednotce
ALTER table "F_UnitRegistration" add column "RegularMembers_UnitParent" INTEGER;

CREATE OR REPLACE TEMPORARY TABLE TEMP_TABLE AS
SELECT t1."ID_UnitRegistration", t1."ID_UnitRegistrationParent", T2."RegularMembers"
FROM "F_UnitRegistration" T1
JOIN "F_UnitRegistration" T2 ON t1."ID_UnitRegistrationParent" = t2."ID_UnitRegistration"
;

UPDATE "F_UnitRegistration" 
SET "F_UnitRegistration"."RegularMembers_UnitParent" = TEMP_TABLE."RegularMembers"
from temp_table
where "F_UnitRegistration"."ID_UnitRegistration" = TEMP_TABLE."ID_UnitRegistration"
;

DROP TABLE TEMP_TABLE;

UPDATE "F_UnitRegistration" 
SET "RegularMembers_UnitParent" = IFNULL("RegularMembers_UnitParent", 0)
;

--přidání počtu kvalifikací (vůdcovky, čekatelky)
--1) VŮDCOVKY

CREATE OR REPLACE TEMP TABLE TEMP_PERSONREGISTRATION_QUALIFICATION_6 AS
SELECT pr."ID" AS "ID_PresonRegistration"
    ,pr."ID_Person"
    ,pr."ID_UnitRegistration"
    ,q."ID_QualificationType"
    ,q."ValidFrom"
FROM "OU_PersonRegistration" AS pr
INNER JOIN "OU_Qualification" AS q ON pr."ID_Person"=q."ID_Person"
WHERE q."ID_QualificationType"='6'
;

-- spojím UnitRegistration LEFT joinem s temp tabulku, ValidFrom porovnám s rokem Unit registration-> pokud je menší, započítám zkoušku


-- SEČÍST POČET 1 PRO PŘÍSLUŠNÉ ID_UnitRegistration a vložit jako nový sloupec
-- názvy sloupců vypsány explicitně, alias.* nefungoval
CREATE OR REPLACE TABLE "F_UnitRegistration" AS
SELECT  
    ur."ID_UnitRegistration",
    ur."ID_Unit", 
    ur."ID_TI",  
    ur."ID_UnitRegistrationParent",
    ur."RegularMembersTo6",
    ur."RegularMembersTo15",
    ur."RegularMembersTo18",
    ur."RegularMembersTo26",
    ur."RegularMembersFrom26",
    ur."RegularMembers",
    ur."pocet_dospeli",
    ur."pocet_deti",
    ur."procento_dospeli",
    ur."procento_deti",
    ur."RegularMembers_UnitParent",
       
    COUNT(CASE 
            WHEN DATE_PART(YEAR, TO_DATE(temp."ValidFrom", 'DD.MM.YYYY')) <= DATE_PART(YEAR, TO_DATE(ur."ID_TI", 'YYYY'))  
            THEN 1 
            ELSE 0 
          END) AS "pocet_vudcovske_zkousky"
FROM 
    "F_UnitRegistration" AS ur
LEFT JOIN 
    "TEMP_PERSONREGISTRATION_QUALIFICATION_6" AS temp
    ON ur."ID_UnitRegistration" = temp."ID_UnitRegistration"
GROUP BY 
    ur."ID_UnitRegistration",
    ur."ID_Unit", 
    ur."ID_TI",  
    ur."ID_UnitRegistrationParent",
    ur."RegularMembersTo6",
    ur."RegularMembersTo15",
    ur."RegularMembersTo18",
    ur."RegularMembersTo26",
    ur."RegularMembersFrom26",
    ur."RegularMembers",
    ur."pocet_dospeli",
    ur."pocet_deti",
    ur."procento_dospeli",
    ur."procento_deti",
    ur."RegularMembers_UnitParent"
HAVING 
    COUNT(CASE 
              WHEN DATE_PART(YEAR, TO_DATE(temp."ValidFrom", 'DD.MM.YYYY')) <= DATE_PART(YEAR, TO_DATE(ur."ID_TI", 'YYYY'))  
              THEN 1 
              ELSE 0 
          END) > 0
;

--2)čekatelky
--spojím PersonRegistration inner joinem s Qualification, kde je druh kvalifikace = 4, vytvořím temp tabulku


CREATE OR REPLACE TEMP TABLE TEMP_PERSONREGISTRATION_QUALIFICATION_4 AS
SELECT pr."ID" AS "ID_PresonRegistration"
    ,pr."ID_Person"
    ,pr."ID_UnitRegistration"
    ,q."ID_QualificationType"
    ,q."ValidFrom"
FROM "OU_PersonRegistration" AS pr
INNER JOIN "OU_Qualification" AS q ON pr."ID_Person"=q."ID_Person"
WHERE q."ID_QualificationType"=4 
;

-- spojím UnitRegistration LEFT joinem s temp tabulku, ValidFrom porovnám s rokem Unit registration-> pokud je menší, započítám zkoušku

-- SEČÍST POČET 1 PRO PŘÍSLUŠNÉ ID_UnitRegistration a vložit jako nový sloupec, 

CREATE OR REPLACE TABLE "F_UnitRegistration" AS --ur.* mi nefungovalo, proto jsou sloupce vypsané
SELECT 
    ur."ID_UnitRegistration",
    ur."ID_Unit", 
    ur."ID_TI",  
    ur."ID_UnitRegistrationParent",
    ur."RegularMembersTo6",
    ur."RegularMembersTo15",
    ur."RegularMembersTo18",
    ur."RegularMembersTo26",
    ur."RegularMembersFrom26",
    ur."RegularMembers",
    ur."pocet_dospeli",
    ur."pocet_deti",
    ur."procento_dospeli",
    ur."procento_deti",
    ur."RegularMembers_UnitParent",
    ur."pocet_vudcovske_zkousky",
       
    COUNT(CASE 
            WHEN DATE_PART(YEAR, TO_DATE(temp."ValidFrom", 'DD.MM.YYYY')) <= DATE_PART(YEAR,TO_DATE(ur."ID_TI", 'YYYY'))  
            THEN 1 
            ELSE 0 
          END) AS "pocet_cekatelske_zkousky"
FROM 
    "F_UnitRegistration" AS ur
LEFT JOIN 
    "TEMP_PERSONREGISTRATION_QUALIFICATION_4" AS temp
    ON ur."ID_UnitRegistration" = temp."ID_UnitRegistration"
GROUP BY 
    ur."ID_UnitRegistration",
    ur."ID_Unit", 
    ur."ID_TI",  
    ur."ID_UnitRegistrationParent",
    ur."RegularMembersTo6",
    ur."RegularMembersTo15",
    ur."RegularMembersTo18",
    ur."RegularMembersTo26",
    ur."RegularMembersFrom26",
    ur."RegularMembers",
    ur."pocet_dospeli",
    ur."pocet_deti",
    ur."procento_dospeli",
    ur."procento_deti",
    ur."RegularMembers_UnitParent",
    ur."pocet_vudcovske_zkousky"
HAVING 
    COUNT(CASE 
              WHEN DATE_PART(YEAR, TO_DATE(temp."ValidFrom", 'DD.MM.YYYY')) <= DATE_PART(YEAR, TO_DATE(ur."ID_TI", 'YYYY'))  
              THEN 1 
              ELSE 0 
          END) > 0
;

