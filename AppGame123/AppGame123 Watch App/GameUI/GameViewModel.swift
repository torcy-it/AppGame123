//
//  GameViewModel.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//
import SwiftUI
import Combine


// MARK: - Card Model
struct Card: Identifiable, Equatable {
    let id = UUID()
    let value: Int
}

enum TurnState: Equatable {
    case normal(playerTurn: Bool)
    case forced(playerTurn: Bool, flipsRemaining: Int)
    case collecting(collectorIsPlayer: Bool)  // Nuovo stato per la raccolta
    indirect case paused(previous: TurnState)
    case gameOver
}

@MainActor
final class GameViewModel: ObservableObject {

    // Decks
    @Published var playerDeck: [Card] = []
    @Published var cpuDeck: [Card] = []
    @Published var tablePile: [Card] = []
    @Published var visiblePile: [(card: Card, isPlayer: Bool)] = []
    @Published var lastForcingCard: Card? = nil
    
    // UI state
    @Published var gameMessage = ""
    @Published var showMessage = false
    @Published var gameOver = false
    @Published var winner = ""
    @Published var lastPlayedByPlayer: Bool = true
    
    // Display state - separato dalla logica per forzare aggiornamenti UI
    @Published var displayMessage = ""  // Cosa mostrare sullo schermo (YOUR TURN, CPU TURN, etc)
    @Published var displayColor: String = "green"  // "green", "pink", "yellow"
    @Published var notificationMessage: String? = nil
    

    // Game state
    @Published var turnState: TurnState = .normal(playerTurn: true)
    
    var isPlayerTurn: Bool {
        switch turnState {
        case .normal(let p), .forced(let p, _):
            return p
        default:
            return false
        }
    }

    private var autoPlayTask: Task<Void, Never>?

    init() {
        setupGame()
    }

    
    // MARK: - Setup
    func setupGame() {
        autoPlayTask?.cancel()
        gameOver = false
        winner = ""
        showMessage = false
        gameMessage = ""

        var deck: [Card] = []
        for value in 1...10 {
            for _ in 1...4 { deck.append(Card(value: value)) }
        }
        deck.shuffle()

        playerDeck = Array(deck[0..<20])
        cpuDeck = Array(deck[20..<40])
        tablePile = []
        visiblePile = []

        turnState = .normal(playerTurn: true)
        startAutoPlay()
    }

    // MARK: - Auto Play Loop
    func startAutoPlay(intervalSeconds: Double = 1.8) {  // Rallentato da 1.3 a 1.8
        autoPlayTask?.cancel()

        autoPlayTask = Task { [weak self] in
            guard let self else { return }

            let ns = UInt64(intervalSeconds * 1_000_000_000)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: ns)

                switch self.turnState {
                case .paused, .gameOver, .collecting:  // ← Blocca anche durante la raccolta
                    continue
                default:
                    self.playNextCard()
                }
            }
        }
    }

    func stopAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = nil
    }

    // MARK: - Core Game
    func playNextCard() {
        switch turnState {
        case .gameOver, .paused:
            return
        default:
            break
        }

        if checkElimination() { return }

        print("────────────────────────")
        print("STATE BEFORE PLAY → \(turnState)")
        print("isPlayerTurn BEFORE → \(isPlayerTurn ? "PLAYER" : "CPU")")
        
        let playedByPlayer: Bool
        switch turnState {
        case .normal(let p), .forced(let p, _):
            playedByPlayer = p
        default:
            return
        }

        lastPlayedByPlayer = playedByPlayer

        let card = drawCard()

        print("CARD DRAWN → \(card.value) by \(isPlayerTurn ? "PLAYER" : "CPU")")

        displayMessage = lastPlayedByPlayer
            ? "YOU THREW \(card.value)"
            : "CPU THREW \(card.value)"
        displayColor = lastPlayedByPlayer ? "green" : "yellow"

        tablePile.append(card)
        visiblePile.append((card: card, isPlayer: lastPlayedByPlayer))

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)

            guard case .collecting = self.turnState else {
                self.handleCard(card)
                return
            }
        }
    }


    private func drawCard() -> Card {
        if playerDeck.isEmpty {
            endGame(winner: "CPU")
            fatalError("Player deck empty")
        }
        if cpuDeck.isEmpty {
            endGame(winner: "Player")
            fatalError("CPU deck empty")
        }

        // Semplice: playerTurn indica sempre chi gioca
        switch turnState {
        case .normal(let playerTurn), .forced(let playerTurn, _):
            return playerTurn ? playerDeck.removeFirst() : cpuDeck.removeFirst()
        default:
            fatalError("drawCard called in invalid state: \(turnState)")
        }
    }

    private func handleCard(_ card: Card) {
        switch turnState {

        case .normal(let playerTurn):

            print("HANDLE NORMAL")
            print("playerTurn = \(playerTurn ? "PLAYER" : "CPU")")
            print("card = \(card.value)")

            if card.value <= 3 {

                print("SPECIAL CARD \(card.value)")
                print("→ Opponent must play \(card.value) cards")
                
                lastForcingCard = card

                turnState = .forced(
                    playerTurn: !playerTurn,
                    flipsRemaining: card.value
                )

    
                print("NEW STATE → \(turnState)")
                print("isPlayerTurn AFTER → \(isPlayerTurn ? "PLAYER" : "CPU")")

            } else {

                print("NORMAL CARD → switch turn")

                turnState = .normal(playerTurn: !playerTurn)


                print("NEW STATE → \(turnState)")
                print("isPlayerTurn AFTER → \(isPlayerTurn ? "PLAYER" : "CPU")")
            }


        case .forced(let playerTurn, let flipsRemaining):

            let collector = !playerTurn

            print("HANDLE FORCED")
            print("playerTurn (must play) = \(playerTurn ? "PLAYER" : "CPU")")
            print("flipsRemaining = \(flipsRemaining)")
            print("collector = \(collector ? "PLAYER" : "CPU")")
            print("card = \(card.value)")

            if card.value <= 3 {

                print("NEW SPECIAL DURING FORCED")
                print("→ Reset obligation to \(card.value)")
                print("→ Opponent must respond")
                
                lastForcingCard = card

                turnState = .forced(
                    playerTurn: !playerTurn,
                    flipsRemaining: card.value
                )


                print("NEW STATE → \(turnState)")
                print("isPlayerTurn AFTER → \(isPlayerTurn ? "PLAYER" : "CPU")")

            } else {

                let newRemaining = flipsRemaining - 1

                print("NORMAL RESPONSE CARD")
                print("Remaining BEFORE = \(flipsRemaining)")
                print("Remaining AFTER = \(newRemaining)")

                if newRemaining <= 0 {

                    print("OBLIGATION FAILED")
                    print("→ \(collector ? "PLAYER" : "CPU") WILL COLLECT")

                    turnState = .collecting(collectorIsPlayer: collector)
                    
                    // Usa solo lo starburst invece della notifica verde
                    notificationMessage = collector
                        ? "YOU BEAT CPU WITH A SPECIAL CARD!"
                        : "CPU BEAT YOU WITH A SPECIAL CARD!"
                    
                    lastForcingCard = nil

                    print("STATE → COLLECTING")

                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_200_000_000)

                        print("COLLECT CENTER PILE")
                        self.collectCenter(byPlayer: collector)
                        self.notificationMessage = nil  // Nascondi lo starburst

                        self.turnState = .normal(playerTurn: collector)
                  

                        print("STATE AFTER COLLECT → \(self.turnState)")
                        print("isPlayerTurn AFTER COLLECT → \(self.isPlayerTurn ? "PLAYER" : "CPU")")
                    }

                } else {

                    print("MUST CONTINUE PLAYING")
                    print("Still \(newRemaining) cards to play")

                    turnState = .forced(
                        playerTurn: playerTurn,
                        flipsRemaining: newRemaining
                    )

                    print("STATE CONTINUES → \(turnState)")
                }
            }


        default:
            break
        }
    }
    
 

    private func collectCenter(byPlayer isPlayer: Bool) {
        if isPlayer {
            playerDeck.append(contentsOf: tablePile)
        } else {
            cpuDeck.append(contentsOf: tablePile)
        }
        tablePile.removeAll()
        visiblePile.removeAll()
        
    }

    private func checkElimination() -> Bool {
        if playerDeck.isEmpty { endGame(winner: "CPU"); return true }
        if cpuDeck.isEmpty { endGame(winner: "Player"); return true }
        return false
    }

    // MARK: - Tap / Slap Rules
    private func collectionRule() -> String? {
        guard tablePile.count >= 2 else { return nil }

        let last = tablePile[tablePile.count - 1].value
        let prev = tablePile[tablePile.count - 2].value

        if last + prev == 10 { return "THE TEN!" }
        if last == prev { return "THE TWIN!" }

        if tablePile.count >= 3 {
            let third = tablePile[tablePile.count - 3].value
            if third == last { return "THE SANDWICH!" }
        }

        return nil
    }

    func playerTap() {
        // Permetti tap durante .normal e .forced, blocca solo durante stati critici
        switch turnState {
        case .gameOver, .paused, .collecting:
            return  // Non permettere tap durante questi stati
        default:
            break  // Continua per .normal e .forced
        }
        
        // Controlla se c'è una regola valida
        if let msg = collectionRule() {
            handlePlayerCollect(message: msg)
        } else {
            // PENALTY: tap senza regola valida
            handlePenalty()
        }
    }

    private func handlePlayerCollect(message: String) {
        // Ferma temporaneamente l'auto-play per dare feedback visivo
        autoPlayTask?.cancel()
        
        // Usa solo lo starburst
        notificationMessage = message

        turnState = .collecting(collectorIsPlayer: true)

        collectCenter(byPlayer: true)

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self?.notificationMessage = nil  // Nascondi lo starburst
            self?.turnState = .normal(playerTurn: true)
            self?.startAutoPlay()  // Riavvia l'auto-play
        }
    }

    private func handlePenalty() {
        // Controlla se il giocatore ha carte da dare
        guard !playerDeck.isEmpty else { return }
        
        // Ferma l'auto-play
        autoPlayTask?.cancel()
        
        // Mostra messaggio penalty
        notificationMessage = "PENALTY\nPENALTY!"
        
        // Passa in stato collecting per bloccare il gioco
        let previousState = turnState
        turnState = .collecting(collectorIsPlayer: false)
        
        Task { [weak self] in
            guard let self else { return }
            
            // Aspetta un momento per mostrare il messaggio
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Trasferisci una carta dal giocatore alla CPU
            if !self.playerDeck.isEmpty {
                let penaltyCard = self.playerDeck.removeFirst()
                self.cpuDeck.append(penaltyCard)
                
                print("PENALTY: Player gives card (\(penaltyCard.value)) to CPU")
            }
            
            // Nascondi il messaggio
            self.notificationMessage = nil
            
            // Ripristina lo stato precedente
            self.turnState = previousState
            
            // Riavvia l'auto-play
            self.startAutoPlay()
        }
    }

    // MARK: - Pause / Resume
    func pause() {
        guard case .paused = turnState else {
            turnState = .paused(previous: turnState)
            return
        }
    }

    func resume() {
        if case .paused(let previous) = turnState {
            turnState = previous
        }
    }

    // MARK: - End Game
    private func endGame(winner: String) {
        self.winner = winner
        self.gameOver = true
        self.turnState = .gameOver
        stopAutoPlay()
    }

    deinit {
        autoPlayTask?.cancel()
    }
}
