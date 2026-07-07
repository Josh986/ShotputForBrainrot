# Shotput for Brainrot — Brainrot Catalog
#
# Defines the seven Brainrot tiers that are the heart of the game's economy.
#
#   Distance thrown  ->  which Brainrot tier spawns  ->  passive income when captured
#
# Unlike coins-per-meter, distance here is *not* money. It gates ACCESS to better
# Brainrots. The excitement is: "If I can just throw 200 m farther, I unlock
# Legendary Brainrots that pay 100/s forever." Balancing knobs live in
# GameConstants (thresholds + income rates); this file assembles them into data.
#
#   0-100 m    Common      $1/s
#   100-300 m  Uncommon    $3/s
#   300-600 m  Rare        $10/s
#   600-1000 m Epic        $30/s
#   1000-2000m Legendary   $100/s
#   2000 m+    Mythic       $500/s
#   Secret     Secret       $5000/s

using { /Verse.org/Simulation }
using { GameConstants }
using { GameTypes }

# Returns the ordered list of all Brainrot tiers, weakest first. Ordering matters:
# GetTierForDistance walks it high-to-low to award the best tier a throw qualifies for.
MakeBrainrotCatalog<public>()<computes>:[]brainrot_def=
    array:
        brainrot_def{ Tier := brainrot_tier.Common,    Name := "Common Brainrot",    MinDistanceMeters := BrainrotCommonMinMeters,    IncomePerSecond := BrainrotCommonIncome }
        brainrot_def{ Tier := brainrot_tier.Uncommon,  Name := "Uncommon Brainrot",  MinDistanceMeters := BrainrotUncommonMinMeters,  IncomePerSecond := BrainrotUncommonIncome }
        brainrot_def{ Tier := brainrot_tier.Rare,      Name := "Rare Brainrot",      MinDistanceMeters := BrainrotRareMinMeters,      IncomePerSecond := BrainrotRareIncome }
        brainrot_def{ Tier := brainrot_tier.Epic,      Name := "Epic Brainrot",      MinDistanceMeters := BrainrotEpicMinMeters,      IncomePerSecond := BrainrotEpicIncome }
        brainrot_def{ Tier := brainrot_tier.Legendary, Name := "Legendary Brainrot", MinDistanceMeters := BrainrotLegendaryMinMeters, IncomePerSecond := BrainrotLegendaryIncome }
        brainrot_def{ Tier := brainrot_tier.Mythic,    Name := "Mythic Brainrot",    MinDistanceMeters := BrainrotMythicMinMeters,    IncomePerSecond := BrainrotMythicIncome }
        brainrot_def{ Tier := brainrot_tier.Secret,    Name := "SECRET Brainrot",    MinDistanceMeters := BrainrotSecretMinMeters,    IncomePerSecond := BrainrotSecretIncome }

# Given how far a throw travelled (meters), return the best Brainrot that spawns.
# Walks the catalog from strongest to weakest and returns the first whose distance
# threshold is met. Falls back to the Common tier so a throw always spawns *something*.
GetTierForDistance<public>(Catalog:[]brainrot_def, DistanceMeters:float)<transacts>:brainrot_def=
    # Iterate indices in reverse (strongest tier first).
    Count := Catalog.Length
    var Index:int = Count - 1
    loop:
        if (Index < 0) { break }
        if (Def := Catalog[Index], DistanceMeters >= Def.MinDistanceMeters):
            return Def
        set Index -= 1
    # Fallback: first entry (Common) or a hard-coded default if catalog is empty.
    if (First := Catalog[0]) { return First }
    return brainrot_def{ Tier := brainrot_tier.Common, Name := "Common Brainrot", MinDistanceMeters := 0.0, IncomePerSecond := 1 }

# Look up a tier's definition by enum value (used when summing base income).
GetBrainrotByTier<public>(Catalog:[]brainrot_def, Tier:brainrot_tier)<computes>:brainrot_def=
    for (Def : Catalog, Def.Tier = Tier):
        return Def
    if (First := Catalog[0]) { return First }
    return brainrot_def{ Tier := brainrot_tier.Common, Name := "Common Brainrot", MinDistanceMeters := 0.0, IncomePerSecond := 1 }
