using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }

# ============================================================================
#  loot_zone
#  Eine benannte Loot-Zone fuer die Map: Spieler betritt den Trigger,
#  bekommt eine zufaellige Waffe aus einem Seltenheits-Pool.
#
#  Pro Zone ein Geraet platzieren (z. B. "Tilted Towers", "Retail Row").
#  Die Gewichte bestimmen, wie haeufig eine Seltenheit gezogen wird:
#  hohe Zahl = haeufiger.
# ============================================================================

LootedText<localizes>(Zone : string) : message = "{Zone}: Waffe aufgenommen"
CooldownText<localizes>(Zone : string) : message = "{Zone} ist leergeraeumt - warte auf den Respawn"

loot_zone := class(creative_device):

    # ---- Geraete-Referenzen -----------------------------------------------

    # Volume-Trigger, der die Zone abdeckt.
    @editable
    Trigger : trigger_device = trigger_device{}

    # Je ein Item-Granter pro Seltenheit. Leere Arrays werden uebersprungen.
    @editable
    CommonGranters : []item_granter_device = array{}

    @editable
    UncommonGranters : []item_granter_device = array{}

    @editable
    RareGranters : []item_granter_device = array{}

    @editable
    EpicGranters : []item_granter_device = array{}

    @editable
    LegendaryGranters : []item_granter_device = array{}

    # Optional: HUD-Rueckmeldung und Sound beim Looten.
    @editable
    HUD : hud_message_device = hud_message_device{}

    @editable
    LootSound : audio_player_device = audio_player_device{}

    # ---- Einstellungen ----------------------------------------------------

    @editable
    ZoneName : string = "Unbenannte Zone"

    # Gewichte der Seltenheiten (Common, Uncommon, Rare, Epic, Legendary).
    @editable
    WeightCommon : int = 40

    @editable
    WeightUncommon : int = 30

    @editable
    WeightRare : int = 18

    @editable
    WeightEpic : int = 9

    @editable
    WeightLegendary : int = 3

    # Wie viele Waffen pro Besuch.
    @editable
    ItemsPerVisit : int = 1

    # Sperre pro Spieler, damit man nicht im Trigger farmen kann.
    @editable
    CooldownSeconds : float = 60.0

    # ---- Laufzeit-Zustand -------------------------------------------------

    var OnCooldown : [player]logic = map{}

    # ---- Einstieg ---------------------------------------------------------

    OnBegin<override>()<suspends> : void =
        Trigger.TriggeredEvent.Subscribe(OnZoneEntered)

    OnZoneEntered(MaybeAgent : ?agent) : void =
        if (Agent := MaybeAgent?, Player := player[Agent]):
            if (Blocked := OnCooldown[Player], Blocked?):
                HUD.SetText(CooldownText(ZoneName))
                HUD.Show(Player)
            else:
                GiveLoot(Player)

    # ---- Loot -------------------------------------------------------------

    GiveLoot(Player : player) : void =
        var Granted : int = 0
        for (Index := 0..ItemsPerVisit - 1):
            Pool := PickPool()
            if (Pool.Length > 0, Granter := Pool[GetRandomInt(0, Pool.Length - 1)]):
                Granter.GrantItem(Player)
                set Granted += 1

        if (Granted > 0):
            HUD.SetText(LootedText(ZoneName))
            HUD.Show(Player)
            LootSound.Play(Player)
            spawn { StartCooldown(Player) }

    # Zieht einen Seltenheits-Pool nach Gewicht. Leere Pools fallen auf die
    # naechstniedrigere Seltenheit zurueck, damit nie ins Leere gegriffen wird.
    PickPool() : []item_granter_device =
        Total := WeightCommon + WeightUncommon + WeightRare + WeightEpic + WeightLegendary
        if (Total <= 0):
            return CommonGranters

        Roll := GetRandomInt(1, Total)

        Tiers := array:
            (WeightCommon, CommonGranters)
            (WeightUncommon, UncommonGranters)
            (WeightRare, RareGranters)
            (WeightEpic, EpicGranters)
            (WeightLegendary, LegendaryGranters)

        var Cursor : int = 0
        var Chosen : []item_granter_device = array{}
        for (Tier : Tiers):
            set Cursor += Tier(0)
            if (Chosen.Length = 0, Roll <= Cursor, Tier(1).Length > 0):
                set Chosen = Tier(1)

        if (Chosen.Length > 0):
            Chosen
        else:
            # Fallback: erster nicht leerer Pool.
            var Fallback : []item_granter_device = array{}
            for (Tier : Tiers):
                if (Fallback.Length = 0, Tier(1).Length > 0):
                    set Fallback = Tier(1)
            Fallback

    StartCooldown(Player : player)<suspends> : void =
        set OnCooldown[Player] = true
        Sleep(CooldownSeconds)
        set OnCooldown[Player] = false
