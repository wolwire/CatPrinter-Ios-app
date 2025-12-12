import SwiftUI

/// Model download view - extracted from CreateView
struct ModelDownloadView: View {
    @StateObject private var downloadManager = ModelDownloadManager()
    let onComplete: () -> Void
    
    var body: some View {
        AppCard(padding: AppDesignSystem.Spacing.xxxl) {
            VStack(spacing: AppDesignSystem.Spacing.xxl) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(AppDesignSystem.Colors.pastelPurple)
                
                Text("AI Models Missing")
                    .font(.title2)
                    .bold()
                    .foregroundColor(AppDesignSystem.Colors.textBlack)
                
                Text("To use AI features, you need to download the model pack (~2GB). This only needs to be done once.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppDesignSystem.Colors.textSecondary)
                    .padding(.horizontal)
                
                if downloadManager.isDownloading {
                    VStack {
                        ProgressView(value: downloadManager.combinedProgress, total: 1.0)
                            .scaleEffect(1.0)
                            .padding()
                            .tint(AppDesignSystem.Colors.pastelPurple)
                            
                        Text(downloadManager.statusMessage)
                            .foregroundColor(AppDesignSystem.Colors.pastelPurple)
                            .font(.caption)
                    }
                } else if downloadManager.statusMessage != "Ready!" {
                    AppPrimaryButton(
                        "Download Models",
                        themeColor: AppDesignSystem.Colors.pastelPurple
                    ) {
                        downloadManager.startDownload()
                    }
                }
                
                if let error = downloadManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.error)
                        .multilineTextAlignment(.center)
                }
                
                // Check for completion
                if downloadManager.statusMessage == "Ready!" {
                    AppPrimaryButton(
                        "Start Creating!",
                        themeColor: AppDesignSystem.Colors.success
                    ) {
                        onComplete()
                    }
                }
            }
        }
        .padding()
    }
}
