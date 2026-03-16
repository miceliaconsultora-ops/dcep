# Gemini.md (Project Constitution)

## Data Schema
(Borrador basado en pantallas de Stitch)
```json
{
  "athlete": {
    "id": "uuid",
    "profile_id": "uuid",
    "name": "string",
    "last_name": "string",
    "nickname": "string",
    "age": "number",
    "height": "number",
    "weight": "number",
    "position": "string",
    "dominant_hand": "string",
    "category": "string",
    "stats": {
      "matches_played": "number",
      "win_rate": "number"
    }
  },
  "evaluation": {
    "id": "uuid",
    "athlete_id": "uuid",
    "date": "timestamp",
    "technique_scores": {
      "derecha": "number",
      "reves": "number",
      "sp_derecha": "number",
      "sp_reves": "number",
      "volea_der": "number",
      "volea_rev": "number",
      "bandeja": "number",
      "smash": "number",
      "observations": "string"
    },
    "attack_score": "number",
    "defense_score": "number",
    "tactical_score": "number",
    "physical_score": "number",
    "notes": "string"
  },
  "shift": {
    "id": "uuid",
    "date": "timestamp",
    "court_number": "number",
    "players": ["uuid"]
  }
}
```

### Technical Score Mapping
- 1: Malo
- 2: Regular
- 3: Bueno
- 4: Muy bueno
- 5: Excelente

## Behavioral Rules
- Follow B.L.A.S.T protocol strictly.
- Data-First rule applies.
- Self-Annealing rule for error handling.
- Deterministic logic prioritized.

## App Scope & Purpose
DCEP is a high-performance management system for Padel training. Its core functionality is the technical tracking of athletes through structured evaluations and shift management.

## User Roles & Permissions

### Admin (Coach - Diego Cipriano)
- **Full Control**: Primary user of the platform.
- **Evaluation Management**: CRUD complete for all technical evaluations ("Golpe por Golpe"), tactical/physical scores, and observations.
- **Athlete Administration**: Oversees all athlete profiles and can manage all data.
- **Calendar Admin**: Manages turn availability, confirms or modifies shift requests.

### Athlete (Player)
- **Self-Registration**: Can register and create their own player profile.
- **Profile Management**: Can edit their own personal/general features (Photo, Name, Age, Level preference) that *do not* involve technical evaluations.
- **Calendar interaction**: Can view available shifts and request/enroll in a training spot.
- **Strict Privacy**: Can ONLY see their own performance data/evaluations and the general shift calendar. Cannot see other athletes' evaluations.

## Architectural Invariants
- 3-Layer Build (Layer 1: architecture, Layer 2: navigation, Layer 3: tools)
