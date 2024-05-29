--vytvoření D_unit
CREATE OR REPLACE TABLE "D_Unit" AS
SELECT 
TRY_CAST("ID" AS NUMBER(38,0)) AS "ID_Unit"
, "IsActive"
, "ID_UnitType"
, "Location"
, "City"
, "Postcode"
, "kodobce"
FROM "OU_UnitCityCode"
;

--přidání sloupce koedukace
--projde název membershipu, pokud patří do klučičích názvů, započte 1 do sloupce 'kluci', pokud patří do holčičích názvů, započte 1 do sloupce 'holky'
--potom grupuji podle ID_Unit - když je součet v 'kluci'>0 a zároveň součet v 'holky'>0, pak se jedná o koedukovanou jednotku. Pokud je hodnota v jednom ze sloupců 0, jedná se o single edukaci, napíše holky/kluci
-- uložím jako temp tabulku

CREATE OR REPLACE TEMP TABLE TEMP_KOEDUKACE AS

SELECT 
    "ID_Unit",
    SUM(CASE WHEN "ID_MembershipCategory" IN ('vlce', 'skaut', 'rover') THEN 1 ELSE 0 END) AS "kluci",
    SUM(CASE WHEN "ID_MembershipCategory" IN ('svetluska', 'skautka', 'ranger') THEN 1 ELSE 0 END) AS "holky",
    CASE 
        WHEN SUM(CASE WHEN "ID_MembershipCategory" IN ('vlce', 'skaut', 'rover') THEN 1 ELSE 0 END) > 0 
             AND SUM(CASE WHEN "ID_MembershipCategory" IN ('svetluska', 'skautka', 'ranger') THEN 1 ELSE 0 END) > 0 
        THEN 'koedukace' 
        WHEN SUM(CASE WHEN "ID_MembershipCategory" IN ('vlce', 'skaut', 'rover') THEN 1 ELSE 0 END) = 0 
             AND SUM(CASE WHEN "ID_MembershipCategory" IN ('svetluska', 'skautka', 'ranger') THEN 1 ELSE 0  END) > 0 THEN 'holky'
        WHEN SUM(CASE WHEN "ID_MembershipCategory" IN ('vlce', 'skaut', 'rover') THEN 1 ELSE 0 END) > 0 
             AND SUM(CASE WHEN "ID_MembershipCategory" IN ('svetluska', 'skautka', 'ranger') THEN 1 ELSE 0 END) = 0 THEN 'kluci'
        ELSE 'n/a' 
    END AS "koedukace"
FROM "OU_Membership"
WHERE "ID_MembershipCategory" IN ('vlce', 'svetluska', 'skautka', 'skaut', 'rover', 'ranger')
GROUP BY "ID_Unit"
ORDER BY "ID_Unit";

-- TEMP_KOEDUKACE připojím k D_Unit a D_Unit uložím s přidaným sloupcem

CREATE OR REPLACE TABLE "D_Unit" AS
SELECT u.*
    ,temped."koedukace"
FROM "D_Unit" AS u
LEFT JOIN "TEMP_KOEDUKACE" as temped ON u."ID_Unit"=temped."ID_Unit"
;



--jak dlouho vede vedoucí oddíl

CREATE OR REPLACE TEMPORARY TABLE UNIT_DURATION AS
WITH FunctionType1 AS (
    SELECT 
        p."ID_Person",
        p."ID_Unit",
        p."ValidFrom",
        p."ValidTo",
        DATEDIFF('days', p."ValidFrom", COALESCE(p."ValidTo", CURRENT_DATE)) AS Duration
    FROM 
        "D_Function" p
    WHERE 1=1
    AND (p."ID_FunctionType" = 92 OR p."ID_FunctionType" = 174)
    AND p."ValidFrom" >= DATE('1993-01-01')
    AND (p."ValidTo" > p."ValidFrom" OR p."ValidTo" IS NULL)
),

YearlyDurations AS (
    SELECT 
        u."ID_Unit",
        f.Duration
    FROM 
        FunctionType1 f
    LEFT JOIN 
        "D_Unit" u ON f."ID_Unit" = u."ID_Unit"
)

SELECT 
    "ID_Unit",
    ROUND(AVG(Duration)/365, 2) AS AverageStayDuration
FROM 
    YearlyDurations
GROUP BY 
    "ID_Unit"
ORDER BY 
    "ID_Unit"
;

CREATE OR REPLACE TABLE "D_Unit" AS
SELECT 
    U.*
    , IFNULL(D.AverageStayDuration, 0) AS "PrumerVedouci"
FROM "D_Unit" u
LEFT JOIN UNIT_DURATION d on d."ID_Unit" = u."ID_Unit"
;
