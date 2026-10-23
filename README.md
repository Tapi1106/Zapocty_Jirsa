# Zápočtové úkoly – OWASP Juice Shop a paleta barev

Vypracováno a ověřeno 23. 10. 2026. Níže je postup pro zopakování první úlohy přímo ve vývojářské konzoli prohlížeče. Snímky dokládají nalezený produkt, košík, přijatou slevu a dokončenou objednávku.

## 1. Vánoční speciál 2014 a sleva 50 %

### Zadání

V místním OWASP Juice Shopu koupit Vánoční speciál z roku 2014 a použít kupón na 50% slevu pro říjen 2026. Aplikace běží na `http://localhost:3000`. Údaje o zákazníkovi, adresa i karta jsou smyšlené; jde o místní laboratorní cvičení.

### 1. Přihlášení a otevření konzole

Na stránce Juice Shopu stisknu **F12** nebo **Ctrl + Shift + J** a otevřu záložku **Console / Konzole**. Příkazy níže zadávám právě sem, ne do systémového terminálu.

Konzole umožňuje spouštět JavaScript přímo v otevřené stránce. Funkcí `fetch()` odešlu požadavek do stejné aplikace, ve které jsem přihlášený. `await` počká, než dorazí odpověď. Pokud blok spouštím znovu, proměnné deklarované pomocí `var` lze použít opakovaně.

### 2. Skript pro paletu 16 barev terminálu

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
