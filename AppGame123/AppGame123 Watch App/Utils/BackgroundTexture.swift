//
//  BackgroundTexture.swift
//  AppGame123
//
//  Created by Adolfo Torcicollo on 12/12/25.
//

import SwiftUI

struct BackgroundTexture: View {
    var backgroundColor: Color? = nil
    var stripesColor: Color? = nil
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            Canvas { context, _ in
                let lineHeight: CGFloat = 2
                let totalLines = Int(ceil(size.height / lineHeight))

                for lineIndex in 0..<totalLines {
                    let yPosition = CGFloat(lineIndex) * lineHeight
                    
                    let rect = CGRect(
                        x: 0,
                        y: yPosition,
                        width: size.width,
                        height: lineHeight
                    )

                    let color: Color =
                        lineIndex.isMultiple(of: 2)
                        ? (backgroundColor ?? Color(red: 0/255, green: 40/255, blue: 56/255))
                        : (stripesColor ?? Color(red: 0/255, green: 56/255, blue: 72/255))


                    context.fill(
                        Path(rect),
                        with: .color(color)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}
