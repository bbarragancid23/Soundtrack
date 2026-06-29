//
//  DotGridView.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/29/26.
//

import SwiftUI

struct DotGridView: View {
    let dotColor: Color = .gray.opacity(0.2)
    let spacing: CGFloat = 30.0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let linePoints: [((CGFloat, CGFloat), (CGFloat, CGFloat))] = [
                ((-1.0, 4.0 * spacing), (1.5 * spacing, 6.5 * spacing)),
                ((-1.0, 5.5 * spacing), (1.5 * spacing, 8.0 * spacing)),
                ((-1.0, 7.0 * spacing), (1.5 * spacing, 9.5 * spacing)),
                ((width, 15 * spacing), ((CGFloat(Int(width / spacing)) - 1.5) * spacing, 17.5 * spacing)),
                ((width, 16.5 * spacing), ((CGFloat(Int(width / spacing)) - 1.5) * spacing, 19 * spacing)),
                ((width, 18 * spacing), ((CGFloat(Int(width / spacing)) - 1.5) * spacing, 20.5 * spacing)),
            ]
            
            ZStack {
                ForEach(0...Int(width / spacing), id: \.self) { x in
                    ForEach(0...Int(height / spacing), id: \.self) {y in
                        Circle()
                            .fill(dotColor)
                            .frame(width: 4, height: 4)
                            .position(x: CGFloat(x) * spacing, y: CGFloat(y) * spacing)
                    }
                }
                ForEach(linePoints.indices, id: \.self) { index in
                    //print(item)
                    let (x, y) = linePoints[index]
                    let startPoint = CGPoint(x: x.0, y: x.1)
                    let endPoint = CGPoint(x: y.0, y: y.1)
                    Path { path in
                        path.move(to: startPoint)
                        path.addLine(to: endPoint)
                    }
                    .stroke(Color.black, lineWidth: 3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }
}

#Preview {
    DotGridView().ignoresSafeArea(.all)
}


