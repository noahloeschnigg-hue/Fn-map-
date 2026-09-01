using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# ============================================================================
#  arena_manager
#  Rundenbasierter Spielmodus fuer eine eigene UEFN-Map.
#
#  Ablauf:
#    Warten auf Startknopf -> Countdown -> Runde laeuft
#    -> Rundenende durch Zeitablauf ODER erreichte Eliminierungs-Grenze
#    -> Sieger-Ansage -> naechste Runde
#
#  Alle @editable-Felder werden im UEFN-Details-Panel des Geraets zugewiesen.
# ============================================================================

# Lokalisierbare Texte. In Verse muessen HUD-Texte <localizes>-Funktionen sein.
CountdownText<localizes>(Seconds : int) : message = "Runde startet in {Seconds}..."
RoundStartText<localizes> : message = "Los geht's!"
ScoreText<localizes>(Score : int, Needed : int) : message = "Eliminierungen: {Score} / {Needed}"
TimeUpText<localizes> : message = "Zeit abgelaufen!"
RoundOverText<localizes> : message = "Runde beendet!"
YouWinText<localizes> : message = "Du gewinnst die Runde!"
WaitingText<localizes> : message = "Startknopf druecken, um die Runde zu beginnen."

arena_manager := class(creative_device):

    # ---- Geraete-Referenzen (im Level platzieren und hier zuweisen) --------

    @editable
    StartButton : button_device = button_device{}

    @editable
    HUD : hud_message_device = hud_message_device{}

    @editable
    PlayerSpawners : []player_spawner_device = array{}

    # Waffen, die jeder Spieler zu Rundenbeginn bekommt.
    @editable
    StartingGranters : []item_granter_device = array{}

    # Optional: wird am Ende des Matches ausgeloest (Sieger als Agent).
    @editable
    EndGame : end_game_device = end_game_device{}

    # ---- Einstellungen ----------------------------------------------------

    @editable
    RoundDurationSeconds : float = 300.0

    @editable
    CountdownSeconds : int = 5

    @editable
    EliminationsToWin : int = 15

    # Anzahl Runden, bevor das Match endet. 0 = endlos.
    @editable
    RoundsPerMatch : int = 3

    # ---- Laufzeit-Zustand -------------------------------------------------

    var Eliminations : [player]int = map{}
    var RoundNumber : int = 0
    var RoundIsLive : logic = false

    # Wird ausgeloest, sobald jemand EliminationsToWin erreicht.
    WinnerEvent : event(player) = event(player){}

    # ---- Einstieg ---------------------------------------------------------

    OnBegin<override>()<suspends> : void =
        StartButton.InteractedWithEvent.Subscribe(OnStartPressed)

        # Jeden Spawner abhoeren, damit wir jeden neuen Charakter verkabeln.
        for (Spawner : PlayerSpawners):
            Spawner.SpawnedEvent.Subscribe(OnPlayerSpawned)

        # Spieler, die schon da sind, plus alle, die spaeter joinen.
        for (Player : GetPlayspace().GetPlayers()):
            ResetScore(Player)
        GetPlayspace().PlayerAddedEvent().Subscribe(ResetScore)

        HUD.SetText(WaitingText)
        HUD.Show()

    # ---- Rundensteuerung --------------------------------------------------

    OnStartPressed(Agent : agent) : void =
        if (RoundIsLive?):
            return
        spawn { RunMatch() }

    RunMatch()<suspends> : void =
        loop:
            set RoundNumber += 1
            RunRound()

            if (RoundsPerMatch > 0 and RoundNumber >= RoundsPerMatch):
                if (Best := BestPlayer()):
                    EndGame.Activate(Best)
                break

            Sleep(5.0)

    RunRound()<suspends> : void =
        # Countdown
        var Remaining : int = CountdownSeconds
        loop:
            if (Remaining <= 0):
                break
            HUD.SetText(CountdownText(Remaining))
            HUD.Show()
            Sleep(1.0)
            set Remaining -= 1

        # Frischer Start fuer alle
        for (Player : GetPlayspace().GetPlayers()):
            ResetScore(Player)
            GrantLoadout(Player)

        set RoundIsLive = true
        HUD.SetText(RoundStartText)
        HUD.Show()

        # Wer zuerst fertig ist, beendet die Runde: Zeit oder Eliminierungsziel.
        var MaybeWinner : ?player = false
        race:
            Sleep(RoundDurationSeconds)
            block:
                Winner := WinnerEvent.Await()
                set MaybeWinner = option{Winner}

        set RoundIsLive = false

        if (Winner := MaybeWinner?):
            HUD.SetText(RoundOverText)
            HUD.Show()
            HUD.SetText(YouWinText)
            HUD.Show(Winner)
        else:
            HUD.SetText(TimeUpText)
            HUD.Show()
        Sleep(3.0)

    # ---- Spieler-Events ---------------------------------------------------

    OnPlayerSpawned(Agent : agent) : void =
        if (Character := Agent.GetFortCharacter[]):
            Character.EliminatedEvent().Subscribe(OnEliminated)
        if (Player := player[Agent], RoundIsLive?):
            GrantLoadout(Player)

    OnEliminated(Result : elimination_result) : void =
        if (not RoundIsLive?):
            return

        # Nur zaehlen, wenn es einen Verursacher gibt (kein Sturz-/Sturmtod).
        if:
            Killer := Result.EliminatingCharacter?
            KillerAgent := Killer.GetAgent[]
            KillerPlayer := player[KillerAgent]
        then:
            AddElimination(KillerPlayer)

    AddElimination(Player : player) : void =
        Current := if (Value := Eliminations[Player]) then Value else 0
        NewScore := Current + 1
        set Eliminations[Player] = NewScore

        HUD.SetText(ScoreText(NewScore, EliminationsToWin))
        HUD.Show(Player)

        if (NewScore >= EliminationsToWin):
            WinnerEvent.Signal(Player)

    # ---- Hilfsfunktionen --------------------------------------------------

    ResetScore(Player : player) : void =
        set Eliminations[Player] = 0

    GrantLoadout(Player : player) : void =
        for (Granter : StartingGranters):
            Granter.GrantItem(Player)

    # Spieler mit den meisten Eliminierungen, sofern ueberhaupt jemand gepunktet hat.
    BestPlayer() : ?player =
        var Leader : ?player = false
        var LeaderScore : int = 0
        for (Player -> Score : Eliminations):
            if (Score > LeaderScore):
                set Leader = option{Player}
                set LeaderScore = Score
        Leader
