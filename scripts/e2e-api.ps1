$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:8080"
$guest = "e2e-" + [guid]::NewGuid().ToString("n").Substring(0, 8)

function Get-Json($method, $url, $body = $null) {
    $params = @{ Uri = $url; Method = $method; ContentType = "application/json" }
    if ($null -ne $body) { $params.Body = ($body | ConvertTo-Json -Compress -Depth 6) }
    return Invoke-RestMethod @params
}

$health = Get-Json GET "$base/health"
if ($health.store -ne "postgresql") { throw "health.store=$($health.store), expected postgresql" }
Write-Host "health ok store=$($health.store)"

$offers = Get-Json GET "$base/v1/offers"
if ($offers.Count -lt 8) { throw "too few cards: $($offers.Count)" }
$photo = $offers[0].imageUrl
if ($photo -notmatch '/static/places/') { throw "photo is not local: $photo" }
$probe = Invoke-WebRequest -Uri "$base$photo" -UseBasicParsing
if ($probe.StatusCode -ne 200 -or $probe.RawContentLength -lt 1000) { throw "photo not served: $photo" }
Write-Host "catalog $($offers.Count) cards photo=$photo"

$firstId = [string]$offers[0].id
$swipe = Get-Json POST "$base/v1/swipes" @{
    guestId     = $guest
    offerId     = $firstId
    liked       = $true
    tags        = @("spa")
    budgetTier  = "mid"
    kind        = "hotel"
    countryCode = "RU"
}
if (-not $swipe.saved) { throw "swipe was not saved" }
if (-not $swipe.deck) { throw "empty deck after swipe" }
foreach ($card in $swipe.deck) {
    if ([string]$card.id -eq $firstId) { throw "liked card returned in deck" }
}
Write-Host "swipe ok next=$($swipe.deck[0].title) why=$($swipe.deck[0].whyRecommended)"

$saved = Get-Json GET "$base/v1/saved?guestId=$guest"
if ($saved.Count -lt 1 -or [string]$saved[0].id -ne $firstId) { throw "saved list mismatch" }
Write-Host "saved ok $($saved[0].title)"

$profile = Get-Json GET "$base/v1/profile?guestId=$guest"
if ($profile.likes -lt 1 -or $profile.swipes -lt 1) { throw "empty profile" }
Write-Host "profile likes=$($profile.likes) swipes=$($profile.swipes)"

$chat = Get-Json POST "$base/v1/agent/chat" @{
    guestId = $guest
    message = "Sochi under 20000"
    liked   = @()
}
if (-not $chat.text) { throw "empty agent reply" }
Write-Host "chat $($chat.text)"

Write-Host "E2E OK: swipe -> PostgreSQL -> new card -> saved"
