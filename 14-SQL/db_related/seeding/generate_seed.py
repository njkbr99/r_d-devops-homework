from __future__ import annotations
import random
from datetime import date

random.seed(14)

# --- Data pools ---
UA_FIRST = [
    "Андрій","Олександр","Дмитро","Максим","Артем","Іван","Михайло","Богдан","Кирило","Владислав",
    "Олена","Ірина","Наталія","Оксана","Марія","Софія","Дарина","Аліна","Катерина","Юлія"
]
UA_LAST = [
    "Шевченко","Коваленко","Бондаренко","Мельник","Коваль","Мороз","Ткаченко","Кравченко","Поліщук","Козак",
    "Романенко","Іваненко","Петренко","Лисенко","Савченко","Олійник","Сидоренко","Гриценко","Захарченко","Кучер"
]
UA_STREETS = [
    "вул. Шевченка","вул. Франка","вул. Лесі Українки","просп. Перемоги","вул. Соборна",
    "вул. Грушевського","вул. Січових Стрільців","вул. Набережна","вул. Центральна","вул. Академічна"
]
UA_CITIES = ["Київ","Львів","Дніпро","Харків","Одеса"]

INSTITUTIONS = [
    ("Ліцей «Дніпровський» №23", "School", "Дніпро"),
    ("Київська гімназія №101", "School", "Київ"),
    ("ДНЗ «Сонечко»", "Kindergarten", "Львів"),
]

DIRECTIONS_SCHOOL = ["Mathematics", "Biology and Chemistry", "Language Studies"]
DIRECTIONS_KINDER = ["Language Studies", "Mathematics"]

def ua_address(city: str, idx: int) -> str:
    street = UA_STREETS[idx % len(UA_STREETS)]
    house = 5 + (idx % 80)
    return f"{city}, {street}, {house}"

def pick_name(i: int) -> tuple[str,str]:
    first = UA_FIRST[i % len(UA_FIRST)]
    last = UA_LAST[(i * 3) % len(UA_LAST)]

    # add deterministic suffix to avoid collisions
    if i >= len(UA_FIRST) * len(UA_LAST):
        last = f"{last}-{i}"

    return first, last

def unique_birth_date(child_id: int, base_year: int) -> date:
    year = base_year + (child_id // 366)
    day_of_year = (child_id % 365) + 1
    return date.fromordinal(date(year, 1, 1).toordinal() + day_of_year - 1)

def calc_age(bd: date, ref: date = date(2026, 1, 25)) -> int:
    return ref.year - bd.year - ((ref.month, ref.day) < (bd.month, bd.day))

def main() -> None:
    lines: list[str] = []
    lines.append("USE SchoolDB;")
    lines.append("SET NAMES utf8mb4;")
    lines.append("")
    lines.append("SET FOREIGN_KEY_CHECKS=0;")
    lines.append("TRUNCATE TABLE Parent_Children;")
    lines.append("TRUNCATE TABLE Parents;")
    lines.append("TRUNCATE TABLE Children;")
    lines.append("TRUNCATE TABLE Classes;")
    lines.append("TRUNCATE TABLE Institutions;")
    lines.append("SET FOREIGN_KEY_CHECKS=1;")
    lines.append("")

    # --- Institutions ---
    lines.append("-- Institutions (2 schools + 1 kindergarten)")
    lines.append("INSERT INTO Institutions (institution_id, institution_name, institution_type, address) VALUES")
    inst_rows = []
    for inst_id, (name, typ, city) in enumerate(INSTITUTIONS, start=1):
        inst_rows.append(f"  ({inst_id}, '{name}', '{typ}', '{ua_address(city, inst_id)}')")
    lines.append(",\n".join(inst_rows) + ";")
    lines.append("")

    # --- Classes ---
    # 10 classes per school, 2 for kindergarten
    # We'll keep class names unique per institution (good for screenshots)
    class_id = 1
    class_map = []  # (class_id, institution_id, class_name, direction)
    lines.append("-- Classes (10 per school, 2 per kindergarten)")
    rows = []
    for inst_id, (name, typ, city) in enumerate(INSTITUTIONS, start=1):
        if typ == "School":
            for k in range(1, 11):
                class_name = f"{k}-А"
                direction = DIRECTIONS_SCHOOL[(k - 1) % len(DIRECTIONS_SCHOOL)]
                class_map.append((class_id, inst_id, class_name, direction))
                rows.append(f"  ({class_id}, '{class_name}', {inst_id}, '{direction}')")
                class_id += 1
        else:
            for k in range(1, 3):
                class_name = f"Група {k}"
                direction = DIRECTIONS_KINDER[(k - 1) % len(DIRECTIONS_KINDER)]
                class_map.append((class_id, inst_id, class_name, direction))
                rows.append(f"  ({class_id}, '{class_name}', {inst_id}, '{direction}')")
                class_id += 1
    lines.append("INSERT INTO Classes (class_id, class_name, institution_id, direction) VALUES")
    lines.append(",\n".join(rows) + ";")
    lines.append("")

    # --- Children ---
    # Schools: 5 per class; Kindergarten: 15 per class
    child_id = 1
    child_rows = []
    child_to_inst_class = []  # (child_id, inst_id, class_id)
    lines.append("-- Children (5 per school class, 15 per kindergarten class)")
    for (cid, inst_id, cname, direction) in class_map:
        inst_type = INSTITUTIONS[inst_id - 1][1]
        n_children = 5 if inst_type == "School" else 15
        for j in range(n_children):
            fn, ln = pick_name(child_id + j + cid)
            if inst_type == "School":
                bd = unique_birth_date(child_id, 2010)
                year_entry = 2020 + ((cid + j) % 5)  # 2020-2024
            else:
                bd = unique_birth_date(child_id, 2019)
                year_entry = 2023 + ((cid + j) % 3)  # 2023-2025
            age = calc_age(bd)
            child_rows.append(
                f"  ({child_id}, '{fn}', '{ln}', '{bd.isoformat()}', {year_entry}, {age}, {inst_id}, {cid})"
            )
            child_to_inst_class.append((child_id, inst_id, cid))
            child_id += 1

    lines.append("INSERT INTO Children (child_id, first_name, last_name, birth_date, year_of_entry, age, institution_id, class_id) VALUES")
    lines.append(",\n".join(child_rows) + ";")
    lines.append("")

    # --- Parents ---
    # We'll create fewer parents than children, so some parents have multiple kids (the requirement you want)
    # Rule: 1 parent per 2 children (rounded up)
    total_children = child_id - 1
    total_parents = (total_children + 1) // 2
    parent_rows = []
    for pid in range(1, total_parents + 1):
        fn, ln = pick_name(1000 + pid)
        # add small variation to avoid too many identicals in demo
        if pid % 7 == 0:
            ln = ln + "а"
        parent_rows.append(f"  ({pid}, '{fn}', '{ln}')")

    lines.append("-- Parents (some will have multiple children)")
    lines.append("INSERT INTO Parents (parent_id, first_name, last_name) VALUES")
    lines.append(",\n".join(parent_rows) + ";")
    lines.append("")

    # --- Parent_Children links + tuition_fee ---
    # Each parent links to 2 children (last may link to 1). Fee randomized in reasonable range.
    link_rows = []
    child_cursor = 1
    for pid in range(1, total_parents + 1):
        for _ in range(2):
            if child_cursor > total_children:
                break
            fee = random.choice([1500, 1800, 2000, 2200, 2500, 2800, 3000, 3500, 4000])
            link_rows.append(f"  ({pid}, {child_cursor}, {fee:.2f})")
            child_cursor += 1

    lines.append("-- Parent_Children links (one parent -> many children possible)")
    lines.append("INSERT INTO Parent_Children (parent_id, child_id, tuition_fee) VALUES")
    lines.append(",\n".join(link_rows) + ";")
    lines.append("")

    out_path = "seed.sql"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Generated {out_path}")
    print(f"Institutions: {len(INSTITUTIONS)}")
    print(f"Classes: {len(class_map)}")
    print(f"Children: {total_children}")
    print(f"Parents: {total_parents}")
    print(f"Links: {len(link_rows)}")

if __name__ == "__main__":
    main()
