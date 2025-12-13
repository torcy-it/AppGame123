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
    
    var body: some View {
        ZStack {
            BackgroundTexture()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header con back button e info
                HStack {
                    GlassBackButton {
                        onBack()
                    }
                    
                    Spacer()
                    
                    // Info giocatori
                    HStack(spacing: 15) {
                        VStack(spacing: 4) {
                            Text("YOU")
                                .font(.custom("PressStart2P-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(viewModel.playerDeck.count)")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("CPU")
                                .font(.custom("PressStart2P-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(viewModel.cpuDeck.count)")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Centro del tavolo - Carte a ventaglio
                ZStack {
                    if !viewModel.centerPile.isEmpty {
                        let totalCount = viewModel.centerPile.count
                        let visibleCards = Array(viewModel.centerPile.suffix(3))

                        ForEach(visibleCards.indices, id: \.self) { i in
                            let card = visibleCards[i]

                            // indice reale della carta nel centerPile
                            let realIndex = totalCount - visibleCards.count + i

                            // slot ciclico: 0 = sinistra, 1 = centro, 2 = destra
                            let slot = realIndex % 3

                            CardView(card: card)
                                .scaleEffect(scaleForSlot(slot))
                                .rotationEffect(.degrees(rotationForSlot(slot)))
                                .offset(
                                    x: offsetXForSlot(slot),
                                    y: offsetYForSlot(slot)
                                )
                                .zIndex(Double(realIndex)) // 👈 la più nuova SEMPRE sopra
                        }
                    } else {
                        Text("TAP TO START")
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(height: 280)
                .onTapGesture {
                    viewModel.playerTap()
                }
                
                Spacer()
                
                // Indicatore turno
                Text(viewModel.isPlayerTurn ? "YOUR TURN" : "CPU TURN")
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .foregroundColor(viewModel.isPlayerTurn ? Color(red: 0/255, green: 255/255, blue: 100/255) : .red)
                    .padding(.bottom, 30)
            }
            
            // Messaggio di raccolta
            if viewModel.showMessage {
                VStack(spacing: 15) {
                    Text(viewModel.gameMessage)
                        .font(.custom("PressStart2P-Regular", size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0/255, green: 255/255, blue: 100/255))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 4)
                                )
                        )
                }
            }
            
            // Game Over
            if viewModel.gameOver {
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.custom("PressStart2P-Regular", size: 20))
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.winner.uppercased()) WINS!")
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(Color(red: 0/255, green: 255/255, blue: 100/255))
                    
                    Button {
                        onBack()
                    } label: {
                        Text("BACK TO MENU")
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 218/255, green: 0/255, blue: 206/255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 3)
                        )
                )
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
        PixelNumber(value: card.value, size: 18) // più piccolo = non sborda
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
