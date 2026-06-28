# Reclaim

Reclaim est une app SwiftUI de digital wellbeing. Elle cree une friction positive avant le scroll automatique: blocages, challenges courts, pauses intentionnelles et progression visible.

## V0

- UI locale.
- Sessions simulees.
- Challenge mathematique.
- Stats locales.

## V1

- Autorisation Screen Time avec FamilyControls.
- Selection reelle d'apps via FamilyActivityPicker.
- Blocage immediat via ManagedSettings.
- Deblocage temporaire apres challenge.

## V2

- Redesign UI complet: fond clair, grosses cards arrondies, couleurs plus vivantes.
- Mascotte originale Reclaim en SwiftUI, sans asset externe.
- Ecran Blocages central.
- Blocage immediat ameliore avec choix de duree.
- Configuration locale de blocages planifies.
- Mode strict local.
- Challenge ameliore avec difficulte.
- Stats redesign.

## V3

- Stabilisation progressive sans refonte UI ni nouvelle architecture.
- Suppression des fallbacks runtime qui faisaient passer un blocage local pour un blocage reel.
- Blocage immediat uniquement via Screen Time: FamilyControls + ManagedSettings.
- Selection Screen Time partagee avec l'extension via App Groups.
- Ajout d'une cible `DeviceActivityMonitorExtension` pour reagir aux evenements DeviceActivity.
- Limite anti-scroll via `DeviceActivityCenter`: iOS declenche un evenement apres un seuil d'utilisation des apps choisies.
- Stats renommees autour du temps recupere / blocages declenches, sans promettre un temps exact non mesure.
- Blocages planifies conserves comme preparation UI; l'enforcement planifie complet reste une etape separee.

## V4

- Refonte UI/UX premium sans changer l'architecture Screen Time existante.
- Navigation reduite a 3 menus: `Accueil`, `Blocages`, `Progres`.
- Direction visuelle Reclaim appliquee: fond `#FAF9F6`, cards blanches, texte `#1F2937`, accents caramel, mint doux et periwinkle.
- Mascotte ecureuil horloger utilisee comme identite visuelle principale depuis les images locales dans `Reclaim/Assets/`.
- Accueil restructure autour de `Aujourd'hui`, blocage actuel, temps d'ecran du jour et prochains blocages.
- Blocages transforme en hub central: blocage scroll, blocage immediat et blocages planifies.
- Progres refondu avec gros chiffres, switch `Temps d'ecran` / `Temps economise`, vue semaine, vue mois et projection douce.
- Ajout de pickers horizontaux scrollables pour les durees anti-scroll et blocage immediat.
- Persistance legere UserDefaults pour stats, durees, blocages planifies, mode strict et reglages de limite.
- Reglages secondaires retires de la tab bar et accessibles via un bouton/sheet.

## V4.1

- Accueil rendu dynamique: le temps d'ecran du jour est estime depuis la baseline utilisateur et le temps recupere par Reclaim.
- Graphique Accueil clarifie: courbe verte pour l'usage estime jusqu'a l'heure actuelle, pointilles pour la baseline avant Reclaim.
- Onboarding de premiere ouverture: age + moyenne quotidienne des deux semaines precedentes, utilisee pour la projection de temps de vie.
- Blocages planifies modifiables et supprimables, avec un maximum volontaire pour garder l'app simple.
- `Mes prochains blocages` affiche les prochains blocages restants de la journee.
- Progres regroupe semaine et mois dans une meme card avec segments, et la matrice montre uniquement les annees de vie recuperees.
- Durees anti-scroll, pause et blocage immediat reglees a la minute avec une regle visuelle.
- Icone d'app raccordee depuis l'asset local fourni.

## V4.2

- Navigation en 4 onglets: `Accueil`, `Blocages`, `Progres`, `Parametres`.
- Le bouton reglages a ete retire de l'accueil au profit de l'onglet `Parametres`.
- Onboarding simplifie: demande d'autorisation Screen Time des le depart, sans saisie manuelle du temps d'ecran.
- Page `Blocages` minimaliste en trois entrees: blocage scroll, blocages planifies, blocage immediat.
- `Blocage auto` renomme en `Blocage scroll`.
- Reglages globaux de groupe principal, challenges et blocage scroll deplaces dans `Parametres`.
- Sliders de duree remplaces par une regle visuelle plus moderne avec graduations.

## V4.3

- Regle de duree ajustee: curseur fixe au centre, graduations espacees, nombres multiples de 5 comme reperes.
- Couleur d'action harmonisee sur le caramel/orange Reclaim.
- Onboarding allonge: intention, age + moyenne quotidienne, demande Screen Time obligatoire a cliquer, projection animee.
- Si Screen Time n'est pas autorise, les vues basees sur le temps d'ecran affichent `Indisponible sans autorisation`.
- Le reglage detaille du blocage scroll est retire de `Parametres`; il reste uniquement dans l'onglet `Blocages`.

Palette V4:

- Background: `#FAF9F6`
- Card: `#FFFFFF`
- Text: `#1F2937`
- Primary: `#E88A4D`
- Secondary: `#5FC9B0`
- Accent: `#7C8CF8`
- Muted text: `#6B7280`
- Border: `#E5E7EB`

## Setup Xcode

1. Ouvrir `Reclaim.xcodeproj` dans Xcode.
2. Selectionner la target `Reclaim`, puis `Signing & Capabilities`.
3. Choisir l'equipe Apple Developer payante, pas `Personal Team`.
4. Remplacer le bundle identifier placeholder `com.example.Reclaim` par votre identifiant, par exemple `com.votre-domaine.Reclaim`.
5. Activer `Family Controls` sur la target app.
6. Activer `App Groups` sur la target app avec votre App Group, par exemple `group.com.votre-domaine.Reclaim`.
7. Selectionner la target `DeviceActivityMonitorExtension`.
8. Utiliser la meme Signing Team.
9. Remplacer le bundle identifier placeholder `com.example.Reclaim.DeviceActivityMonitorExtension` par l'identifiant de votre extension.
10. Activer les memes capabilities: `Family Controls` et `App Groups`.
11. Dans Apple Developer Portal, verifier que l'App ID principal et l'App ID de l'extension ont bien les capabilities correspondantes.
12. Supprimer l'app deja installee sur l'iPhone apres tout changement d'entitlement, puis relancer depuis Xcode.
13. Tester de preference sur iPhone reel: Screen Time, FamilyControls et DeviceActivity sont limites ou peu fiables sur simulateur.
14. Remplacer aussi `group.com.example.Reclaim` dans les entitlements et les constantes Swift par votre App Group reel.
15. Ne pas ajouter de secrets, entitlements generes localement ou provisioning profiles dans le repo.

Les valeurs de signing sont volontairement anonymisees dans le repo public: `DEVELOPMENT_TEAM` est vide, les bundle identifiers utilisent `com.example.*` et l'App Group utilise `group.com.example.Reclaim`. Chaque developpeur doit les configurer localement dans Xcode et dans Apple Developer Portal avant de lancer l'app sur iPhone.

Si le bouton d'autorisation affiche `Couldn't communicate with a helper application`, l'app installee n'est generalement pas signee avec l'entitlement Family Controls valide. Refaire la capability dans Xcode, verifier le provisioning profile, supprimer l'app de l'iPhone, puis relancer depuis Xcode.

## Current limitations

- Les APIs Screen Time necessitent les entitlements Apple et un provisioning profile compatible.
- DeviceActivity ne fournit pas un tracking foreground au milliseconde pres; Reclaim utilise les seuils que iOS expose.
- La duree de blocage de la limite de session est partagee avec l'extension, qui retire le shield automatiquement apres la duree configuree.
- Les blocages planifies restent une configuration preparee dans l'app: l'enforcement planifie recurrent complet sera raccorde proprement ensuite.
- iOS ne donne pas simplement a l'app l'historique global Screen Time des deux semaines precedentes; Reclaim demande donc une baseline manuelle au premier lancement.
- Certaines fonctionnalites doivent etre validees sur iPhone reel avec un compte Apple Developer et un provisioning profile frais.
- Reclaim ne copie aucun asset, screenshot ou mascotte d'app existante.

## Roadmap

V5:
- Enforcement planifie recurrent avec DeviceActivity.
- Deverrouillage automatique apres duree de blocage de session.
- Limites quotidiennes et hebdomadaires.
- ShieldConfiguration personnalisee.
- Challenges avances.
- Vrais rapports hebdomadaires bases sur davantage de donnees persistantes.
