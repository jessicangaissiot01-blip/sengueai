<#
  Mesure le temps de réponse de plusieurs modèles Gemini.

  Lancement, depuis le dossier du projet :
    powershell -ExecutionPolicy Bypass -File tools\mesurer_modeles.ps1

  La clé est demandée au lancement : elle n'est écrite dans aucun fichier.
  Chaque modèle est testé deux fois, avec la même question simple.
#>

$key = Read-Host "Colle ta cle Gemini puis appuie sur Entree"

# Chaque essai : le nom du modèle et le fichier de question à envoyer.
# question_low.json demande au modèle de moins "réfléchir" (réponse plus rapide).
$essais = @(
  @{ modele = 'gemini-2.5-flash-lite';    fichier = 'question.json' },
  @{ modele = 'gemini-flash-lite-latest'; fichier = 'question.json' },
  @{ modele = 'gemini-3.5-flash-lite';    fichier = 'question.json' },
  @{ modele = 'gemini-3.5-flash';         fichier = 'question.json' },
  @{ modele = 'gemini-3.5-flash';         fichier = 'question_low.json' }
)

foreach ($essai in $essais) {
  $corps = Get-Content (Join-Path $PSScriptRoot $essai.fichier) -Raw
  $url = "https://generativelanguage.googleapis.com/v1beta/models/$($essai.modele):generateContent"

  for ($numero = 1; $numero -le 2; $numero++) {
    $debut = Get-Date
    try {
      Invoke-RestMethod -Method Post -Uri $url -Headers @{ 'x-goog-api-key' = $key } `
        -ContentType 'application/json' -Body $corps -TimeoutSec 30 | Out-Null
      $duree = ((Get-Date) - $debut).TotalSeconds
      $resultat = 'OK'
    } catch {
      $duree = ((Get-Date) - $debut).TotalSeconds
      $resultat = "ERREUR : $($_.Exception.Message)"
    }
    Write-Host ("{0,-26} {1,-18} essai {2} : {3,5:N1} s  {4}" -f `
      $essai.modele, $essai.fichier, $numero, $duree, $resultat)
  }
}
