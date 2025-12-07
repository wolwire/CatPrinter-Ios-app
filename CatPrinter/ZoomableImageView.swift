//
//  ZoomableImageView.swift
//  CatPrinter
//
//  Created by Mayank Agrawal on 06/12/25.
//


import SwiftUI

struct ZoomableImageView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in lastOffset = offset }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            if scale < 1 { scale = 1 }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation { scale = scale > 1 ? 1 : 2 }
                }
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
