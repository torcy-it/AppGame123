//
//  TutorialView.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//

import SwiftUI

struct TutorialView: View {

    @StateObject var tutorialVM: TutorialViewModel
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            BackgroundTexture()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // === QUESTA È LA TUA HUD REALE ===
                tutorialHUD

                Spacer()
            }

            // Overlay spiegazione
            TutorialOverlay(
                step: tutorialVM.step,
                showButton: tutorialVM.showGotIt,
                onGotIt: {
                    tutorialVM.gotIt()
                }
            )
        }
        .onAppear {
            tutorialVM.start()
        }
    }
}


extension TutorialView {

    var tutorialHUD: some View {

        VStack(spacing: 0) {

            VStack(spacing: 2) {
                Text("CARDS")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 15)

            HStack(spacing: 12) {

                VStack(spacing: 2) {
                    Text("YOU")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    Text("12")
                        .font(.custom("PressStart2P-Regular", size: 18))
                        .foregroundColor(.white)
                }

                VStack(spacing: 2) {
                    Text("CPU")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    Text("28")
                        .font(.custom("PressStart2P-Regular", size: 18))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 5)

            Spacer()
            Spacer()

            Text("YOUR TURN")
                .font(.custom("PressStart2P-Regular", size: 12))
                .foregroundColor(Color(red: 218/255, green: 0/255, blue: 206/255))
                .padding(.bottom, -20)
        }
    }
}


struct TutorialOverlay: View {

    let step: TutorialViewModel.Step
    let showButton: Bool
    let onGotIt: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {

                Text(message)
                    .font(.custom("PressStart2P-Regular", size: 9))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if showButton {
                    PixelButton(
                        text: "GOT IT",
                        action: onGotIt,
                        width: 140,
                        height: 36,
                        primaryColor: Color(red: 0/255, green: 255/255, blue: 120/255),
                        secondaryColor: Color(red: 0/255, green: 140/255, blue: 70/255),
                        highlightedColor: Color(red: 180/255, green: 255/255, blue: 210/255),
                        textColor: .black
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
            )
            .padding(.bottom, 20)
        }
    }

    private var message: String {
        switch step {
        case .goal:
            return """
            WIN by taking
            all opponent cards.

            NO cards = LOSE.
            """

        case .hudIntro:
            return """
            This shows how many
            cards YOU and CPU have.

            Green means
            YOUR TURN.
            """

        case .basics123:
            return """
            1 → flip 1
            2 → flip 2
            3 → flip 3
            """
        }
    }
}
