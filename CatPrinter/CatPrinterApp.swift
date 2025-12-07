//
//  CatPrinterApp.swift
//  CatPrinter
//
//  Created by Mayank Agrawal on 30/11/25.
//

import SwiftUI

@main
struct CatPrinterApp: App {
  @StateObject private var modelManager = ModelManager()
  var body: some Scene {
    WindowGroup {
      ContentView().environmentObject(modelManager)
    }
  }
}