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
