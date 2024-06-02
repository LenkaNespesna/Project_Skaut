import csv

# Otevřu si tabulku D_GEO jako json, tedy seznam slovníků
cities = []
with open("in/tables/D_GEO.csv", encoding="utf-8") as dGeo:
    reader = csv.DictReader(dGeo)
    for line in reader:
        cities.append(line)


# Otevřu si tabulku OU_Unit jako seznam slovníků
units = []
with open("in/tables/OU_Unit.csv", encoding="utf-8") as dUnit:
    readerUnit = csv.DictReader(dUnit)
    for row in readerUnit:
        units.append(row)

for unit in units:
    match_found = False
    for city in cities:
        # Pokud je vyplněné i město i psč, vyhledá shodu a doplní kód obce
        if city["nazobce"] in unit.get("City"):
            # Přidám ke každému slovníku klíč kodobce a její hodnotu
            unit["kodobce"] = city["kodobce"]
            match_found = True
            break
        # Pokud chybí vyplněné PSČ a máme jen město, napáruji pomocí názvu města
        elif city["nazobce"] in unit.get("City"):
            unit["kodobce"] = city["kodobce"]
            match_found = True
            break
        # Pokud chybí i město v tabulce OU_Unit, napáruji pomocí "Location"
        elif city["nazobce"] in unit.get("Location"):
            unit["kodobce"] = city["kodobce"]
            match_found = True
            break
        # Někde mám jen informaci o o PSČ, napáruji pomocí něho
        elif city["psc"] == unit.get("Postcode"):
            unit["kodobce"] = city["kodobce"]
            match_found = True
            break
        # Někdy se název obce z ČSÚ nachází ve sloupci "nazev_casti_obce"
        elif (city["nazev_casti_obce"] in unit.get("City") or city[
            "nazev_casti_obce"
        ] in unit.get("Location")):
            unit["kodobce"] = city["kodobce"]
            match_found = True
            break
    # Pokud nelze spárovat, dám None
    if match_found == False:
        unit["kodobce"] = "Není dostupné"


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
    "kodobce",
]

with open(
    "out/tables/OU_UnitCityCode.csv", mode="w", newline="", encoding="utf-8"
) as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)

    writer.writeheader()

    for unit in units:
        writer.writerow(unit)
