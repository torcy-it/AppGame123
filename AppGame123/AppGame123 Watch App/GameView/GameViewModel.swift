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

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    @Published var playerDeck: [Card] = []
    @Published var cpuDeck: [Card] = []
    @Published var centerPile: [Card] = []
    @Published var isPlayerTurn = true
    @Published var gameMessage = ""
    @Published var showMessage = false
    @Published var gameOver = false
    @Published var winner = ""
    
    private var cardTimer: Timer?
    private var forceFlipsRemaining = 0
    
    init() {
        setupGame()
    }
    
    // Setup iniziale del gioco
    func setupGame() {
        // Crea 40 carte: numeri da 1 a 10, ripetuti 4 volte
        var deck: [Card] = []
        for value in 1...10 {
            for _ in 1...4 {
                deck.append(Card(value: value))
            }
        }
        
        // Mescola il mazzo
        deck.shuffle()
        
        // Dividi in due mazzi
        playerDeck = Array(deck[0..<20])
        cpuDeck = Array(deck[20..<40])
        centerPile = []
        
        // Inizia il gioco automaticamente
        startAutoPlay()
    }
    
    // Avvia il gioco automatico
    func startAutoPlay() {
        cardTimer?.invalidate()
        cardTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.playNextCard()
        }
    }
    
    // Gioca la prossima carta
    func playNextCard() {
        // Controlla se qualcuno ha finito le carte
        if playerDeck.isEmpty {
            endGame(winner: "CPU")
            return
        }
        if cpuDeck.isEmpty {
            endGame(winner: "Player")
            return
        }
        
        // Gioca la carta
        let card: Card
        if isPlayerTurn {
            card = playerDeck.removeFirst()
        } else {
            card = cpuDeck.removeFirst()
        }
        
        centerPile.append(card)
        
        // Controlla se è una carta speciale (1, 2, 3)
        if forceFlipsRemaining > 0 {
            forceFlipsRemaining -= 1
            
            // Se la carta giocata è speciale, interrompe l'obbligo
            if card.value <= 3 {
                forceFlipsRemaining = card.value
                // Passa al giocatore successivo di chi ha giocato la carta speciale
                isPlayerTurn.toggle()
            }
            
            // Se non ci sono più carte forzate da girare, passa il turno
            if forceFlipsRemaining == 0 {
                isPlayerTurn.toggle()
            }
        } else {
            // Carte speciali attivano l'obbligo
            if card.value <= 3 {
                forceFlipsRemaining = card.value
                isPlayerTurn.toggle()
            } else {
                isPlayerTurn.toggle()
            }
        }
    }
    
    // Controlla se il giocatore può raccogliere (THE TEN, THE TWIN, THE SANDWICH)
    func canPlayerCollect() -> String? {
        guard centerPile.count >= 2 else { return nil }
        
        let lastCard = centerPile[centerPile.count - 1]
        let secondLastCard = centerPile[centerPile.count - 2]
        
        // THE TEN
        if lastCard.value + secondLastCard.value == 10 {
            return "THE TEN!"
        }
        
        // THE TWIN
        if lastCard.value == secondLastCard.value {
            return "THE TWIN!"
        }
        
        // THE SANDWICH
        if centerPile.count >= 3 {
            let thirdLastCard = centerPile[centerPile.count - 3]
            if thirdLastCard.value == lastCard.value {
                return "THE SANDWICH!"
            }
        }
        
        return nil
    }
    
    // Il giocatore clicca sullo schermo
    func playerTap() {
        if let message = canPlayerCollect() {
            collectCards(message: message)
        }
    }
    
    // Raccoglie tutte le carte al centro
    func collectCards(message: String) {
        gameMessage = message
        showMessage = true
        
        // Ferma il timer temporaneamente
        cardTimer?.invalidate()
        
        // Aggiungi le carte al mazzo del giocatore
        playerDeck.append(contentsOf: centerPile)
        centerPile.removeAll()
        forceFlipsRemaining = 0
        
        // Nascondi il messaggio dopo 1.5 secondi e riprendi il gioco
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showMessage = false
            self?.startAutoPlay()
        }
    }
    
    // Fine del gioco
    func endGame(winner: String) {
        cardTimer?.invalidate()
        self.winner = winner
        gameOver = true
    }
    
    deinit {
        cardTimer?.invalidate()
    }
}
