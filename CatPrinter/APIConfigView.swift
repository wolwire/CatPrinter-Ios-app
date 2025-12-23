import SwiftUI

struct APIConfigView: View {
    @EnvironmentObject var apiService: ZImageAPIService
    
    @State private var baseURL: String = ""
    @State private var apiKey: String = ""
    @State private var adminToken: String = ""
    @State private var showCreateKey = false
    @State private var isCheckingStatus = false
    @State private var isCreatingKey = false
    @State private var statusMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    let themeColor = Color(red: 0.5, green: 0.7, blue: 1.0)
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // HEADER
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "server.rack")
                                .font(.title)
                                .foregroundColor(themeColor)
                            Text("API Configuration")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text("Connect to zimage-server for cloud generation")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // STATUS INDICATOR
                    HStack {
                        Circle()
                            .fill(apiService.isConfigured ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(apiService.isConfigured ? "Connected" : "Not Configured")
                            .font(.subheadline)
                            .foregroundColor(apiService.isConfigured ? .green : .red)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
                    
                    // SERVER URL
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader("Server URL", color: themeColor)
                        
                        TextField("http://localhost:8000", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        
                        Button {
                            checkStatus()
                        } label: {
                            HStack {
                                if isCheckingStatus {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text(isCheckingStatus ? "Checking..." : "Test Connection")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColor.opacity(0.2))
                            .foregroundColor(themeColor)
                            .cornerRadius(12)
                        }
                        .disabled(isCheckingStatus || baseURL.isEmpty)
                        
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
                    
                    // API KEY SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader("API Key", color: themeColor)
                        
                        if !showCreateKey {
                            SecureField("Enter API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Button {
                                withAnimation {
                                    showCreateKey.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Create New API Key")
                                }
                                .font(.caption)
                                .foregroundColor(themeColor)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Admin Token")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                SecureField("Enter Admin Token", text: $adminToken)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                HStack {
                                    Button {
                                        createAPIKey()
                                    } label: {
                                        HStack {
                                            if isCreatingKey {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "key.fill")
                                            }
                                            Text(isCreatingKey ? "Creating..." : "Generate Key")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(themeColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isCreatingKey || adminToken.isEmpty)
                                    
                                    Button {
                                        withAnimation {
                                            showCreateKey = false
                                            adminToken = ""
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                }
                            }
                        }
                        
                        Text("Get your API key from the server admin or generate one with an admin token")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
                    
                    // SAVE BUTTON
                    Button {
                        saveConfiguration()
                    } label: {
                        Text("Save Configuration")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((baseURL.isEmpty || apiKey.isEmpty) ? Color.gray : themeColor)
                            .cornerRadius(16)
                    }
                    .disabled(baseURL.isEmpty || apiKey.isEmpty)
                    
                    // DOCUMENTATION
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(themeColor)
                            Text("Setup Instructions")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Install zimage-server on your machine or server")
                            Text("2. Start the server with: python start_pipeline.py")
                            Text("3. Generate an API key using admin token")
                            Text("4. Enter the server URL and API key above")
                            Text("5. Test connection and save")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
                }
                .padding()
            }
        }
        .navigationTitle("API Setup")
        .onAppear {
            baseURL = apiService.baseURL
            apiKey = apiService.apiKey
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Actions
    
    func checkStatus() {
        isCheckingStatus = true
        statusMessage = ""
        
        // Temporarily update service URL
        let originalURL = apiService.baseURL
        apiService.baseURL = baseURL
        
        Task {
            do {
                let status = try await apiService.checkStatus()
                await MainActor.run {
                    statusMessage = "✅ Connected: \(status.api_name ?? "zimage-server") v\(status.version ?? "unknown")"
                    isCheckingStatus = false
                }
            } catch {
                await MainActor.run {
                    apiService.baseURL = originalURL
                    statusMessage = ""
                    alertTitle = "Connection Failed"
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isCheckingStatus = false
                }
            }
        }
    }
    
    func createAPIKey() {
        isCreatingKey = true
        
        // Temporarily update service URL
        let originalURL = apiService.baseURL
        apiService.baseURL = baseURL
        
        Task {
            do {
                let newKey = try await apiService.createAPIKey(adminToken: adminToken)
                await MainActor.run {
                    apiKey = newKey
                    adminToken = ""
                    showCreateKey = false
                    alertTitle = "Success"
                    alertMessage = "API key created successfully!"
                    showAlert = true
                    isCreatingKey = false
                }
            } catch {
                await MainActor.run {
                    apiService.baseURL = originalURL
                    alertTitle = "Key Generation Failed"
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isCreatingKey = false
                }
            }
        }
    }
    
    func saveConfiguration() {
        apiService.baseURL = baseURL
        apiService.apiKey = apiKey
        
        alertTitle = "Saved"
        alertMessage = "API configuration saved successfully!"
        showAlert = true
    }
}
