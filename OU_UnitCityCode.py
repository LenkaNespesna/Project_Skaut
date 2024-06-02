import csv
import pandas as pd

# Otevřu si tabulku D_GEO jako json, tedy seznam slovníků
cities = []
with open("in/tables/D_GEO.csv", encoding="utf-8") as dGeo:
    reader = csv.DictReader(dGeo)
    for line in reader:
        cities.append(line)

# Otevřu si tabulku s populací obcí v roce 2024
PocetObyvatel = pd.read_csv("in/tables/PocetObyvatel2024.csv")

# Určím si primární klíč
kod_obce = "kod_obce"

cities_df = pd.DataFrame(cities)

# Přejmenuju sloupec "kodobce", aby odpovídal primálnímu klíči
cities_df = cities_df.rename(columns={"kodobce": kod_obce})

# Převedu oba kody obcí na stringy
cities_df[kod_obce] = cities_df[kod_obce].astype(str)
PocetObyvatel[kod_obce] = PocetObyvatel[kod_obce].astype(str)

# Spojím tabulky podle primárního klíče
merged_cities = pd.merge(
    cities_df, PocetObyvatel[[kod_obce, "celkem"]], on=kod_obce, how="left"
)

# Převedu do slovníku
merged_cities_dict = merged_cities.to_dict(orient="records")

# Otevřu si tabulku OU_Unit jako seznam slovníků
units = []
with open("in/tables/OU_Unit.csv", encoding="utf-8") as dUnit:
    readerUnit = csv.DictReader(dUnit)
    for row in readerUnit:
        units.append(row)

# Otevřu si tabulku s počtem členů za různé roky
UnitRegistration = pd.read_csv("in/tables/OU_UnitRegistration.csv")
#Převedu na string sloupec "ID_Unit"
UnitRegistration["ID_Unit"] = UnitRegistration["ID_Unit"].astype(str)
# Vyfiltruji si jen řádky z roku 2024
UnitRegistration24 = UnitRegistration[UnitRegistration["Year"] == 2024]

# Určím si primární klíč
ID_Unit = "ID_Unit"

units_df = pd.DataFrame(units)
#Přejmenuju sloupec "ID" na "ID_Unit" podle primátního klíče
units_df = units_df.rename(columns={"ID": ID_Unit})

#Převedu na string, abych mohla spojit obě tabulky
units_df[ID_Unit] = units_df[ID_Unit].astype(str)

# Spojím tabulky podle primárního klíče

merged_units = pd.merge(
    units_df, UnitRegistration24[[ID_Unit, "RegularMembers"]], on=ID_Unit, how="left"
)
merged_units_dict = merged_units.to_dict(orient="records")

for unit in merged_units_dict:
    match_found = False
    for city in merged_cities_dict:
        # Pokud je vyplněné i město i psč, vyhledá shodu a doplní kód obce
        if city["nazobce"] in unit.get("City") and city["psc"] == unit.get("Postcode") and unit["RegularMembers"] < city["celkem"]:
            # Přidám ke každému slovníku klíč kodobce a její hodnotu
            unit["kod_obce"] = city["kod_obce"]
            match_found = True
            break
        # Pokud chybí vyplněné PSČ a máme jen město, napáruji pomocí názvu města
        elif city["nazobce"] in unit.get("City") and unit["RegularMembers"] < city["celkem"]:
            unit["kod_obce"] = city["kod_obce"]
            match_found = True
            break
        # Pokud chybí i město v tabulce OU_Unit, napáruji pomocí "Location"
        elif city["nazobce"] in unit.get("Location") and unit["RegularMembers"] < city["celkem"]:
            unit["kod_obce"] = city["kod_obce"]
            match_found = True
            break
        # Někde mám jen informaci o o PSČ, napáruji pomocí něho
        elif city["psc"] == unit.get("Postcode") and unit["RegularMembers"] < city["celkem"]:
            unit["kod_obce"] = city["kod_obce"]
            match_found = True
            break
        # Někdy se název obce z ČSÚ nachází ve sloupci "nazev_casti_obce"
        elif (city["nazev_casti_obce"] in unit.get("City") or city[
            "nazev_casti_obce"
        ] in unit.get("Location")) and unit["RegularMembers"] < city["celkem"]:
            unit["kod_obce"] = city["kod_obce"]
            match_found = True
            break
    # Pokud nelze spárovat, dám None
    if match_found == False:
        unit["kod_obce"] = "Není dostupné"


# filename = "OU_UnitCityCode.csv"

fieldnames = [
    "ID",
    "IsActive",
    "ID_UnitType",
    "DisplayName",
    "RegistrationNumber",
    "Location",
    "Street",
    "City",
    "Postcode",
    "State",
    "kod_obce",
]

with open(
    "out/tables/OU_UnitCityCode.csv", mode="w", newline="", encoding="utf-8"
) as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)

    writer.writeheader()

    for unit in units:
        writer.writerow(unit)
