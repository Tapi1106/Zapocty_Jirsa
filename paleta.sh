#!/usr/bin/env bash
# Vypíše 16 základních barev terminálu ve třech sloupcích.
# První sloupec: názvy. Druhý: barevné písmo. Třetí: barevné pozadí.

nazvy=(Black DarkBlue DarkGreen DarkCyan DarkRed DarkMagenta DarkYellow Gray
       DarkGray Blue Green Cyan Red Magenta Yellow White)
# Pořadí ANSI kódů upravuji podle pořadí barev na obrázku zadání.
popredi=(30 34 32 36 31 35 33 37 90 94 92 96 91 95 93 97)
pozadi=(40 44 42 46 41 45 43 47 100 104 102 106 101 105 103 107)

for i in "${!nazvy[@]}"; do
    # %-15s zarovná název doleva na šířku 15 znaků.
    # \033[...m nastaví barvu. \033[0m vrátí původní vzhled.
    printf '%-15s\033[%sm%-15s\033[0m\033[%sm%-15s\033[0m\n' \
        "${nazvy[i]}" "${popredi[i]}" "${nazvy[i]}" \
        "${pozadi[i]}" "${nazvy[i]}"
done
