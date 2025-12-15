//
//  PixelButton.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//
import SwiftUI

struct PixelButton: View {
    var icon: String? = nil
    var text: String? = nil
    var action: () -> Void
    var width: CGFloat
    var height: CGFloat? = nil
    var primaryColor: Color
    var secondaryColor: Color
    var highlightedColor: Color
    var textColor: Color
    

    var body: some View {
        
        let viewHeight : CGFloat = height ?? 45
        
        Button(action: action) {
            ZStack {
                // Corpo del bottone (con bordo)
                RoundedRectangle(cornerRadius: 6)
                //.fill(Color(red: 134/255, green: 0/255, blue: 126/255))
                    .fill(secondaryColor)
                    .frame(height: viewHeight)
                    .offset(y:8)
                    .overlay(
                        // Bordo nero pixel
                        RoundedRectangle(cornerRadius: 6)
                            .offset(y: 8)
                            .stroke(Color.black, lineWidth: 2)
                    )
                
                
                // Corpo del bottone
                RoundedRectangle(cornerRadius: 6)
                //.fill(Color(red: 218/255, green: 0/255, blue: 206/255)) // DA00CE
                    .fill(primaryColor)
                    .frame(height: viewHeight)
                    .overlay(
                        // Bordo nero pixel
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .overlay(
                        // Highlight superiore
                        VStack {
                            RoundedRectangle(cornerRadius: 3)
                            //.fill(Color(red: 250/255, green: 115/255, blue: 251/255)) // FA73FB
                                .fill(highlightedColor)
                                .frame(height: 3)
                                .padding(.horizontal, 6)
                                .padding(.top, 4)
                            
                            Spacer()
                        }
                    )
                
                
                
                if(text != nil) {
                    Text(text!)
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 8)
                        .frame(height: 58)
                        .frame(width: width)
                        .padding(.top, 4)
                }else{
            
                    Image(icon!)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.top, 8)
                }
            }

        }
        .buttonStyle(.plain)
    }
}
