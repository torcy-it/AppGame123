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

    
    // UI state
    @Published var gameMessage = ""
    @Published var showMessage = false
    @Published var gameOver = false
    @Published var winner = ""
    @Published var lastPlayedByPlayer: Bool = true
    
    // Display state - separato dalla logica per forzare aggiornamenti UI
    @Published var displayMessage = ""  // Cosa mostrare sullo schermo (YOUR TURN, CPU TURN, etc)
    @Published var displayColor: String = "green"  // "green", "pink", "yellow"

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
            self.handleCard(card)
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

                    print("STATE → COLLECTING")

                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_200_000_000)

                        print("COLLECT CENTER PILE")
                        self.collectCenter(byPlayer: collector)

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
        guard let msg = collectionRule() else { return }
        handlePlayerCollect(message: msg)
    }

    private func handlePlayerCollect(message: String) {
        gameMessage = message
        showMessage = true

        collectCenter(byPlayer: true)
        turnState = .normal(playerTurn: true)

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self?.showMessage = false
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
