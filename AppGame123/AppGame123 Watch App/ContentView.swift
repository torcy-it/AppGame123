//
//  ContentView.swift
//  AppGame123 Watch App
//
//  Created by Adolfo Torcicollo on 12/12/25.
//

import SwiftUI

struct ContentView: View {
    
    let onNavigate: (AppRoute) -> Void
    
    var body: some View {
        
        ZStack {
            BackgroundTexture()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack{
                           
                HStack {
                    Spacer()
                        .frame(width: 133)
                    PixelButton(
                        text: "AO",
                        action: {
                            onNavigate(.settings)
                        },
                        width: 58,
                        primaryColor: Color(red: 202/255, green: 202/255, blue: 202/255),
                        secondaryColor:Color(red: 100/255, green: 100/255, blue: 100/255),
                        highlightedColor:Color(red:255/255,green:255/255,blue:255/255),
                        textColor: Color.black
                    )
                    
                    
                }
                
                Spacer()
                    .frame(height: 15)
                PixelButton(
                    text: "START GAME",
                    action: {
                        onNavigate(.game)
                    },
                    width: 190,
                    primaryColor: Color(red: 218/255, green: 0/255, blue: 206/255),
                    secondaryColor: Color(red: 134/255, green: 0/255, blue: 126/255),
                    highlightedColor: Color(red: 250/255, green: 115/255, blue: 251/255),
                    textColor: Color.white

                )
                Spacer()
                    .frame(height: 15)
                
                PixelButton(
                    text: "TUTORIAL",
                    action: {
                        onNavigate(.tutorial)
                    },
                    width: 140,
                    primaryColor: Color(red: 209/255,green: 211/255,blue: 38/255),
                    secondaryColor: Color(red: 179/255,green: 181/255,blue: 31/255),
                    highlightedColor: Color(red: 230/255,green: 232/255,blue: 90/255),
                    textColor: Color.black

                )
                Spacer().frame(height: 25)
            
            }
        }
    }
}

#Preview {
    RootView()
}
