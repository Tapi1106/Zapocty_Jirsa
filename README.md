# Zápočtové úkoly – OWASP Juice Shop a paleta barev

Vypracováno a ověřeno 23. 10. 2026. Postup je napsaný jednoduše, aby se podle něj dalo cvičení zopakovat.

## 1. Vánoční speciál 2014 a sleva 50 %

### Zadání

V OWASP Juice Shopu koupit Vánoční speciál z roku 2014 a použít kupón na 50% slevu pro říjen 2026. Vše jsem dělal v místní cvičné aplikaci na `http://localhost:3000`. Údaje o zákazníkovi, adresa i karta jsou smyšlené; nejde o skutečnou platbu.

### 1. Příprava účtu

Nejdřív jsem ověřil, že aplikace běží. Pro tento pokus jsem přes rozhraní `POST /api/Users/` založil samostatný testovací účet `ukol23@example.invalid` a potom se do něj přihlásil v prohlížeči. Při opakování si lze účet založit také přes **Account → Login → Not yet a customer?**. Heslo se do tohoto repozitáře neukládá.

### 2. Nalezení skrytého produktu

Obyčejný dotaz `Christmas` na vyhledávacím API vrátil prázdný seznam. Vyzkoušel jsem proto tento vstup:

```text
Christmas%'))--
```

V terminálu jsem odeslal:

```bash
curl -sG --data-urlencode "q=Christmas%'))--" \
  http://localhost:3000/rest/products/search
```

`curl` pošle požadavek na webové rozhraní aplikace. Přepínač `-G` dá parametr do adresy a `--data-urlencode` správně zakóduje zvláštní znaky.

Jde o SQL injection: vstup se dostane přímo do databázového dotazu. Apostrof a závorky uzavřou původní část dotazu a `--` zakomentuje jeho zbytek, včetně podmínky, která vyřazuje odstraněné zboží. Proto se objeví i starý Vánoční speciál.

V odpovědi jsem našel:

| Údaj | Hodnota |
| --- | --- |
| Název | Christmas Super-Surprise-Box (2014 Edition) |
| ID produktu | `10` |
| Cena | `29.99` |
| Stav | Má vyplněné `deletedAt`, tedy je skrytý jako odstraněný produkt. |

![Odpověď vyhledávacího API se skrytým produktem](screenshots/00-produkt-api.jpg)

V této verzi aplikace zadání stejného vstupu do běžného hledání v prohlížeči stále zobrazovalo „No results found“. Důležitá byla odpověď API. Produkt jsem proto přidal do košíku přímo přes API.

### 3. Přidání produktu do košíku

Pro přístup ke svému košíku jsem se přihlásil také přes `POST /rest/user/login`. Posílá se JSON s položkami `email` a `password`. Odpověď obsahuje `authentication.token` a `authentication.bid`.

Token je dočasný přihlašovací klíč a `bid` je číslo košíku. Při opakování použiji vlastní hodnoty, například v těchto proměnných:

```bash
# Z přihlašovací odpovědi si vezmu svůj token a svoje bid.
# Zástupné texty níže je nutné nahradit, nejsou to skutečné přihlašovací údaje.
TOKEN='SEM_PATRI_VLASTNI_TOKEN'
BID='SEM_PATRI_CISLO_VLASTNIHO_KOSIKU'

curl -s http://localhost:3000/api/BasketItems/ \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  --data "{\"ProductId\":10,\"BasketId\":$BID,\"quantity\":1}"
```

`ProductId` určuje produkt, `BasketId` můj košík a `quantity` počet kusů. Server vrátil HTTP `200`. V prohlížeči jsem otevřel **Your Basket** a ověřil, že je uvnitř jeden Vánoční speciál za `29.99`.

![Vánoční speciál v košíku](screenshots/01-kosik.jpg)

### 4. Zjištění kupónu

Formát kupónu jsem ověřil ve zdrojových souborech běžícího Juice Shopu, konkrétně v `build/lib/insecurity.js` a `build/routes/coupon.js`. Aplikace používá kódování **Z85**, tedy převod textu na jinou textovou podobu. Nejde o šifrování ani o podepsaný kupón.

Text před zakódováním je:

```text
OCT26-50
```

- `OCT` znamená říjen.
- `26` znamená rok 2026.
- `50` znamená slevu 50 %.

Zakódování jsem ověřil přímo knihovnou dostupnou v kontejneru:

```bash
docker exec juice-shop /nodejs/bin/node -e \
  'const z=require("z85"); console.log(z.encode(Buffer.from("OCT26-50")))'
```

Výsledek:

```text
pEw8phz3^u
```

Tento příkaz počítá s kontejnerem pojmenovaným `juice-shop`, jak je tomu u této instalace. Kupón je určený pro říjen 2026; aplikace kontroluje aktuální měsíc serveru.

### 5. Použití kupónu

Klikl jsem na **Checkout**, přidal smyšlenou adresu a vybral **Standard Delivery** za `0.00`. V části plateb jsem rozbalil **Add a coupon**, zadal `pEw8phz3^u` a klikl na **Redeem**.

Aplikace zobrazila hlášku **Your discount of 50% will be applied during checkout.** Částka na této obrazovce klesla na `14.99`.

![Aplikace potvrdila 50% slevu](screenshots/02-sleva.jpg)

### 6. Dokončení nákupu

Pro místní simulaci jsem přidal testovací kartu `4111111111111111` se jménem **Student Test**. Potom jsem ji vybral, pokračoval na **Proceed to review** a dokončil objednávku tlačítkem **Place your order and pay**.

Zobrazilo se **Thank you for your purchase!** a objednávka číslo:

```text
f29b-4a233c121138e735
```

![Potvrzená objednávka Vánočního speciálu](screenshots/04-potvrzeni.jpg)

**Poznámka k zaokrouhlení:** Platební obrazovka ukazuje `14.99`, ale konečné potvrzení `15.00`. Polovina z `29.99` je `14.995`. Tato verze aplikace částky v různých krocích zaokrouhluje rozdílně. V potvrzení je uvedené zboží za `29.99`, doprava `0.00`, sleva `14.99` a výsledná cena `15.00`. Do postupu jsem zapsal skutečně zobrazené hodnoty.

Objednávku jsem ověřil i přes rozhraní sledování objednávky: obsahuje produkt ID `10`, množství `1` a slevu `14.99`. Úloha **Christmas Special** je označená jako splněná. Byla tak označená už před tímto opakováním, proto důkaz nového nákupu tvoří především nové potvrzení objednávky. Úloha **Forged Coupon** požaduje vyšší slevu; její splnění není součástí tohoto zadání.

## 2. Skript pro paletu 16 barev terminálu

### Co má skript dělat

Podle obrázku ze zadání má vypsat 16 řádků a tři sloupce:

1. Obyčejný název barvy.
2. Název napsaný příslušnou barvou.
3. Název na příslušném barevném pozadí.

Hotový soubor je [paleta.sh](paleta.sh).

### Spuštění

Ve složce se souborem otevřu terminál a zadám:

```bash
bash paleta.sh
```

Případně mu nastavím právo ke spuštění a spustím ho přímo:

```bash
chmod +x paleta.sh
./paleta.sh
```

### Jak jsem skript sestavil

Nejdřív jsem si do pole `nazvy` napsal všech 16 názvů v pořadí podle obrázku. Do dalších dvou polí jsem zapsal ANSI kódy pro písmo a pozadí. Pořadí kódů není jen od nejmenšího po největší, protože například modrá je v zadání před červenou.

| Typ barvy | Písmo | Pozadí |
| --- | --- | --- |
| Základních 8 barev | `30–37` | `40–47` |
| Světlých 8 barev | `90–97` | `100–107` |

Potom jsem použil smyčku `for`, která projde všechny názvy. Pomocí `printf` se na každém řádku vypíšou tři sloupce. Zápis `%-15s` vyhradí 15 znaků a zarovná text doleva. Tím sloupce zůstanou pod sebou.

Například:

```bash
printf '\033[34mModry text\033[0m\n'
printf '\033[44mModre pozadi\033[0m\n'
```

`\033[` začne řídicí sekvenci pro terminál, číslo vybere barvu a `m` ji použije. `\033[0m` nastavení zase zruší, aby další text nezůstal obarvený. `\n` přejde na nový řádek.

### Celý skript

```bash
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
```

### Kontrola výsledku

Zkontroloval jsem syntaxi příkazem:

```bash
bash -n paleta.sh
```

Příkaz skončil bez chyby. Skript jsem také skutečně spustil a ověřil, že vypisuje přesně 16 řádků a na každém tři názvy barev.

Následující snímek je **náhled skutečného výstupu skriptu převedeného z ANSI sekvencí do HTML**, nikoli fotografie terminálového okna. Používá ukázkovou paletu. Konkrétní odstíny při spuštění v terminálu určuje jeho barevné téma, takže mohou vypadat trochu jinak než na obrázku ze zadání. Černé písmo na tmavém pozadí může být špatně viditelné.

![Náhled 16 řádků a tří sloupců barev](screenshots/05-paleta.jpg)

## Přiložené soubory

- [paleta.sh](paleta.sh) – spustitelný Bash skript s českými komentáři.
- [overeni.json](overeni.json) – stručný záznam ověření bez hesel a přihlašovacích tokenů.
- [screenshots](screenshots/) – skutečné snímky z místní aplikace a náhled palety.

Postup byl ověřen na místní instanci Juice Shopu. SQL injection zde slouží pouze jako řešení školního cvičení v úmyslně zranitelné aplikaci.
