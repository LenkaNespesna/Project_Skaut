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
--projde název v tabulce D_Membership, pokud patří do klučičích názvů, započte 1 do sloupce 'kluci', pokud patří do holčičích názvů, započte 1 do sloupce 'holky'
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
--- Vytvořím si dočasnou tabulku, kde od roku 1993 počítám délku vedení oddílu
CREATE OR REPLACE TEMPORARY TABLE UNIT_DURATION AS
--- CTE vypočítávající trvání funkce
WITH FunctionType1 AS (
    SELECT 
        p."ID_Person",
        p."ID_Unit",
        p."ValidFrom",
        p."ValidTo",
        DATEDIFF('days', p."ValidFrom", COALESCE(p."ValidTo", CURRENT_DATE)) AS Duration,
        EXTRACT(YEAR FROM p."ValidFrom") AS YearFrom,
        EXTRACT(YEAR FROM COALESCE(p."ValidTo", CURRENT_DATE)) AS YearTo
    FROM 
        "D_Function" p
    --- Typ 92 je vedoucí oddílu a typ 174 je zástupce vedoucího oddílu
    WHERE p."ID_FunctionType" IN (92, 174)
    AND p."ValidFrom" >= DATE '1993-01-01'
    --- V tabulce se objevily chyby, kdy údaj ValidTo byl dříve než ValidFrom, ty odstraníme
    --- ValidTo IS NULL znamená, že osoba je stále ve funkci
    AND (p."ValidTo" > p."ValidFrom" OR p."ValidTo" IS NULL)
),
--- CTE s napojením na tabulku registrace, kde počítáme jen s velkými oddíly a v letech, kdy opravdu velkými oddíly byly (tedy měli aspoň 40 členů)
YearlyDurations AS (
    SELECT 
        f."ID_Unit",
        f.Duration,
        f.YearFrom,
        f.YearTo,
        ur."ID_TI",
        ur."RegularMembers"
    FROM 
        FunctionType1 f
    JOIN 
        "F_UnitRegistration" ur ON f."ID_Unit" = ur."ID_Unit"
    WHERE 
        ur."RegularMembers" > 40
        AND ur."ID_TI" BETWEEN f.YearFrom AND f.YearTo
)

SELECT 
    yd."ID_Unit",
    ROUND(AVG(yd.Duration)/365, 2) AS "PrumerVedouci"
FROM 
    YearlyDurations yd
GROUP BY 
    yd."ID_Unit"
ORDER BY 
    yd."ID_Unit"
;

-- Update the D_Unit table with the average stay duration
CREATE OR REPLACE TABLE "D_Unit" AS
SELECT 
    u.*,
    ---V některých vyšších org. jednotkách bude funkce vedoucí oddílu NULL
    IFNULL(d."PrumerVedouci", 0) AS "PrumerVedouci"
FROM 
    "D_Unit" u
LEFT JOIN 
    UNIT_DURATION d ON d."ID_Unit" = u."ID_Unit"
;

