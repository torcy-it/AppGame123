//
//  GameView.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//
import SwiftUI

struct GameView: View {
    let onBack: () -> Void
    @StateObject private var viewModel = GameViewModel()
    
    
    private var isPlayerTurn: Bool {
        switch viewModel.turnState {
        case .normal(let playerTurn):
            return playerTurn
        case .forced(_, let flipperIsPlayer, _):
            return flipperIsPlayer
        default:
            return false
        }
    }
    
    private var isPaused: Bool {
        if case .paused = viewModel.turnState { return true }
        return false
    }
    
    var body: some View {
        ZStack {
            // Background
            BackgroundTexture()
                .ignoresSafeArea()
            
            Spacer()
            Spacer()
            
            VStack(spacing: 0) {
                
                VStack(spacing: 2) {
                    Text("CARDS")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }.padding(.top, 15)
                                    
                // Info giocatori
                HStack(spacing: 12) {
                    
                    VStack(spacing: 2) {
                        Text("YOU")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.playerDeck.count)")
                            .font(.custom("PressStart2P-Regular", size: 18))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 2) {
                        Text("CPU")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.cpuDeck.count)")
                            .font(.custom("PressStart2P-Regular", size: 18))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 5)
                
                Spacer()
                Spacer()
                
                // Indicatore turno - SOPRA LE CARTE
                Text(isPlayerTurn ? "YOUR TURN" : "CPU TURN")
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .foregroundColor(
                        isPlayerTurn
                        ?Color(red: 0/255, green: 255/255, blue: 100/255)
                        : Color(red: 218/255, green: 0/255, blue: 206/255)
                    )
                    .padding(.bottom, -20)
                
                // Centro del tavolo - Carte a ventaglio
                ZStack {
                    if !viewModel.centerPile.isEmpty {
                        let totalCount = viewModel.centerPile.count
                        let visibleCards = Array(viewModel.centerPile.suffix(3))

                        ForEach(visibleCards.indices, id: \.self) { i in
                            let card = visibleCards[i]
                            let realIndex = totalCount - visibleCards.count + i
                            let slot = realIndex % 3

                            CardView(card: card)
                                .scaleEffect(0.60)
                                .rotationEffect(.degrees(rotationForSlot(slot)))
                                .offset(
                                    x: offsetXForSlot(slot),
                                    y: offsetYForSlot(slot)
                                )
                                .zIndex(Double(realIndex))
                        }
                    } else {
                        
                        // TAP TO START solo se è il turno del giocatore
                        VStack(spacing: 15) {
                            if isPlayerTurn {
                                Text("TAP TO START")
                                    .font(.custom("PressStart2P-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .frame(maxHeight: .infinity)
                .onTapGesture {
                    if !isPaused {
                        viewModel.playerTap()
                    }
                }
                
                Spacer()
            
            }
            
            .onTapGesture(count: 2) {
                if !viewModel.gameOver {
                    viewModel.pause()
                }
            }
            
            // Messaggio di raccolta
            if viewModel.showMessage {
                VStack(spacing: 15) {
                    Text(viewModel.gameMessage)
                        .font(.custom("PressStart2P-Regular", size: 15))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(width: 180, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0/255, green: 255/255, blue: 100/255))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 4)
                                )
                        )
                }
                .offset(y: 35)
            }
            
            // FINESTRA PAUSA
            if isPaused && !viewModel.gameOver {

                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                
                ZStack {
                    VStack(spacing: 8) {
                        Spacer().frame(height: 2)
                        
                        Text("PAUSED")
                            .font(.custom("PressStart2P-Regular", size: 15))
                            .foregroundColor(.white)
                        
                        Spacer().frame(height: 4)
                        
                        
                        PixelButton(
                            text: "RESUME",
                            action: {
                                viewModel.resume()
                            },
                            width: 170,
                            height: 40,
                            primaryColor: Color(red: 0/255, green: 255/255, blue: 120/255),
                            secondaryColor: Color(red: 0/255, green: 140/255, blue: 70/255),
                            highlightedColor: Color(red: 180/255, green: 255/255, blue: 210/255),
                            textColor: Color.black
                        )
                        
                        PixelButton(
                            text: "MAIN MENU",
                            action: {
                                onBack()
                            },
                            width: 170,
                            height: 40,
                            primaryColor: Color(red: 218/255, green: 0/255, blue: 206/255),
                            secondaryColor: Color(red: 134/255, green: 0/255, blue: 126/255),
                            highlightedColor: Color(red: 250/255, green: 115/255, blue: 251/255),
                            textColor: Color.white
                        )

                
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    )
                    .padding(6)
                    
                }.offset(y: -10)
            }
            
            // Game Over
            if viewModel.gameOver {
                ZStack {
                    
                    VStack(spacing: 8) {
                        Spacer().frame(height: 2)
                        
                        Text("GAME OVER")
                            .font(.custom("PressStart2P-Regular", size: 15))
                            .foregroundColor(.white)
                        
                        Spacer().frame(height: 4)
                        
                        Text("\(viewModel.winner.uppercased() == "PLAYER" ? "YOU" : "THE HOUSE") WINS!")
                            .font(.custom("PressStart2P-Regular", size: 8))
                            .foregroundColor(Color(red: 0/255, green: 255/255, blue: 100/255))
                            .multilineTextAlignment(.center)
                        
                        PixelButton(
                            text: "MAIN MENU",
                            action: {
                                onBack()
                            },
                            width: 180,
                            height: 40,
                            primaryColor: Color(red: 218/255, green: 0/255, blue: 206/255),
                            secondaryColor: Color(red: 134/255, green: 0/255, blue: 126/255),
                            highlightedColor: Color(red: 250/255, green: 115/255, blue: 251/255),
                            textColor: Color.white
                        )
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    )
                    .padding(6)
                }
            }

        }
    }
    
    private func scaleForSlot(_ slot: Int) -> CGFloat {
        return 0.60   
        
    }

    private func rotationForSlot(_ slot: Int) -> Double {
        switch slot {
        case 0: return -25
        case 1: return 0
        case 2: return 25
        default: return 0
        }
    }

    private func offsetXForSlot(_ slot: Int) -> CGFloat {
        switch slot {
        case 0: return -60
        case 1: return 0
        case 2: return 60
        default: return 0
        }
    }

    private func offsetYForSlot(_ slot: Int) -> CGFloat {
        switch slot {
        case 1: return 0
        default: return 20
        }
    }

    
    // Rotazione per effetto ventaglio
    private func rotationForCard(_ index: Int) -> Double {
        switch index {
        case 0: return -25  // Carta sinistra inclinata a sinistra
        case 1: return 0    // Carta centrale dritta
        case 2: return 25   // Carta destra inclinata a destra
        default: return 0
        }
    }
    
    private func scaleForCard(_ index: Int) -> CGFloat {
        
            return 0.60
        
    }
    
    // Offset X per spaziare le carte
    private func offsetXForCard(_ index: Int) -> CGFloat {
        switch index {
        case 0: return -60  // Carta sinistra
        case 1: return 0    // Carta centrale
        case 2: return 60   // Carta destra
        default: return 0
        }
    }
    
    // Offset Y per dare profondità
    private func offsetYForCard(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 20   // Carta sinistra leggermente più in basso
        case 1: return 0    // Carta centrale
        case 2: return 20   // Carta destra leggermente più in basso
        default: return 0
        }
    }
}

// MARK: - Card View 
struct CardView: View {
    let card: Card

    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 200
    private let inset: CGFloat = 14   // distanza sicura dai bordi

    var body: some View {
        ZStack {
            // Ombra
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: cardWidth, height: cardHeight)
                .offset(x: 4, y: 6)

            // Carta
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 100/255, green: 255/255, blue: 100/255),
                            Color(red: 80/255, green: 240/255, blue: 80/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 4)
                )

            // Numero centrale
            PixelNumber(value: card.value, size: 64)
        }
        // Angoli — overlay separati e sicuri
        .overlay(alignment: .topLeading) {
            cornerNumber
                .padding(inset)
        }
        .overlay(alignment: .topTrailing) {
            cornerNumber
                .padding(inset)
        }
        .overlay(alignment: .bottomLeading) {
            cornerNumber
                .padding(inset)
        }
        .overlay(alignment: .bottomTrailing) {
            cornerNumber
                .padding(inset)
        }
    }

    private var cornerNumber: some View {
        PixelNumber(value: card.value, size: 18)
    }
}

// MARK: - Pixel Number (per numeri in stile pixel)
struct PixelNumber: View {
    let value: Int
    var size: CGFloat = 24
    
    var body: some View {
        Text("\(value)")
            .font(.custom("PressStart2P-Regular", size: size))
            .foregroundColor(.black)
    }
}

// MARK: - Glass Back Button
struct GlassBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    
}
