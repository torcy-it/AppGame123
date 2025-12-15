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
    case forced(flipsRemaining: Int, flipperIsPlayer: Bool, collectorIsPlayer: Bool)
    indirect case paused(previous: TurnState)
    case gameOver
}

@MainActor
final class GameViewModel: ObservableObject {

    // Decks
    @Published var playerDeck: [Card] = []
    @Published var cpuDeck: [Card] = []
    @Published var centerPile: [Card] = []

    // UI state
    @Published var gameMessage = ""
    @Published var showMessage = false
    @Published var gameOver = false
    @Published var winner = ""

    // Game state
    @Published var turnState: TurnState = .normal(playerTurn: true)

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
        centerPile = []

        turnState = .normal(playerTurn: true)
        startAutoPlay()
    }

    // MARK: - Auto Play Loop
    func startAutoPlay(intervalSeconds: Double = 1.3) {
        autoPlayTask?.cancel()

        autoPlayTask = Task { [weak self] in
            guard let self else { return }

            let ns = UInt64(intervalSeconds * 1_000_000_000)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: ns)

                // se in pausa o game over, non giocare carte
                switch self.turnState {
                case .paused, .gameOver:
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
        // blocca se gameOver/paused
        switch turnState {
        case .gameOver, .paused:
            return
        default:
            break
        }

        if checkElimination() { return }

        let card = drawCard()
        centerPile.append(card)
        handleCard(card)
    }

    private func drawCard() -> Card {
        // controllo eliminazione SEMPRE prima di pescare
        if playerDeck.isEmpty {
            endGame(winner: "CPU")
            fatalError("Player deck empty")
        }
        if cpuDeck.isEmpty {
            endGame(winner: "Player")
            fatalError("CPU deck empty")
        }

        switch turnState {
        case .normal(let playerTurn):
            return playerTurn ? playerDeck.removeFirst() : cpuDeck.removeFirst()

        case .forced(_, let flipperIsPlayer, _):
            return flipperIsPlayer ? playerDeck.removeFirst() : cpuDeck.removeFirst()

        default:
            fatalError("drawCard called in invalid state: \(turnState)")
        }
    }

    

    private func handleCard(_ card: Card) {
        switch turnState {

        case .normal(let playerTurn):
            if card.value <= 3 {
                turnState = .forced(
                    flipsRemaining: card.value,
                    flipperIsPlayer: !playerTurn,
                    collectorIsPlayer: playerTurn
                )
            } else {
                turnState = .normal(playerTurn: !playerTurn)
            }

        case .forced(let flipsRemaining, let flipper, let collector):
            if card.value <= 3 {
                // chi ha appena giocato la nuova speciale
                let newSpecialPlayer = flipper

                // crea un NUOVO obbligo (rimpiazza il precedente)
                turnState = .forced(
                    flipsRemaining: card.value,          // nuovo conteggio
                    flipperIsPlayer: !newSpecialPlayer,  // risponde l’avversario
                    collectorIsPlayer: newSpecialPlayer  // chi raccoglie se fallisce
                )
                return
            }

            let newRemaining = flipsRemaining - 1
            if newRemaining <= 0 {
                collectCenter(byPlayer: collector)
                turnState = .normal(playerTurn: !collector)
            } else {
                turnState = .forced(
                    flipsRemaining: newRemaining,
                    flipperIsPlayer: flipper,
                    collectorIsPlayer: collector
                )
            }

        default:
            break
        }
    }

    

    private func collectCenter(byPlayer isPlayer: Bool) {
        if isPlayer {
            playerDeck.append(contentsOf: centerPile)
        } else {
            cpuDeck.append(contentsOf: centerPile)
        }
        centerPile.removeAll()
    }

    private func checkElimination() -> Bool {
        if playerDeck.isEmpty { endGame(winner: "CPU"); return true }
        if cpuDeck.isEmpty { endGame(winner: "Player"); return true }
        return false
    }

    // MARK: - Tap / Slap Rules
    private func collectionRule() -> String? {
        guard centerPile.count >= 2 else { return nil }

        let last = centerPile[centerPile.count - 1].value
        let prev = centerPile[centerPile.count - 2].value

        if last + prev == 10 { return "THE TEN!" }
        if last == prev { return "THE TWIN!" }

        if centerPile.count >= 3 {
            let third = centerPile[centerPile.count - 3].value
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

        // raccoglie sempre il player
        collectCenter(byPlayer: true)

        // reset obbligo: dopo una raccolta “slap”, parte il player
        turnState = .normal(playerTurn: true)

        // nascondi messaggio dopo un attimo
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
