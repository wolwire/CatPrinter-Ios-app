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
  @StateObject private var apiService = ZImageAPIService()
  
  init() {
    // Initialize model manager with API service after both are created
    DispatchQueue.main.async {
      if let mm = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
        .windows.first?.rootViewController?.children.first as? UIHostingController<ContentView> {
        // This won't work, we need a better approach
      }
    }
}
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(modelManager)
        .environmentObject(apiService)
        .onAppear {
          // Inject API service into model manager
          modelManager.apiService = apiService
        }
    }
  }
}
