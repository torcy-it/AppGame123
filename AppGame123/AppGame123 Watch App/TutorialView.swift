//
//  TutorialView.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//

import SwiftUI

struct TutorialView: View {
    let onBack: () -> Void
    var body: some View {
            
        ZStack {
            
            BackgroundTexture()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        
            VStack {
                Spacer()

                PixelButton(
                    text: "BACK",
                    action: {
                        onBack()
                    },
                    width: 120,
                    primaryColor: .gray,
                    secondaryColor: .black,
                    highlightedColor: .white,
                    textColor: .white
                )
            }
            .padding(.bottom, 20)
        }
        
    }
}
