import SwiftUI

struct TodoView: View {
    @State private var todoItems: [TodoItem] = []
    @State private var newItemText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onSendToPrint: (UIImage) -> Void
    
    struct TodoItem: Identifiable {
        let id = UUID()
        var text: String
        var isDone: Bool = false
    }

    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Handled by Nav but we can add a title card)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                    // INPUT CARD
                    AppCardWithPadding {
                        VStack(spacing: AppDesignSystem.Spacing.md) {
                            AppSectionHeader("New Task")
                            
                            HStack {
                                AppTextField("Buy cat food...", text: $newItemText)
                                
                                Button {
                                    addItem()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(AppDesignSystem.Colors.pastelTeal)
                                        .cornerRadius(AppDesignSystem.CornerRadius.medium)
                                }
                                .disabled(newItemText.isEmpty)
                            }
                        }
                    }
                        
                        // LIST CARD
                        if !todoItems.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach($todoItems) { $item in
                                    HStack {
                                        Button {
                                            item.isDone.toggle()
                                        } label: {
                                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundColor(item.isDone ? AppDesignSystem.Colors.pastelTeal : .gray)
                                        }
                                        
                                        Text(item.text)
                                            .strikethrough(item.isDone, color: .gray)
                                            .foregroundColor(item.isDone ? .gray : .black)
                                        
                                        Spacer()
                                        
                                        Button {
                                            if let idx = todoItems.firstIndex(where: { $0.id == item.id }) {
                                                todoItems.remove(at: idx)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.5))
                                                .font(.caption)
                                        }
                                    }
                                    .padding()
                                    
                                    if item.id != todoItems.last?.id {
                                        Divider().padding(.leading, 50)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        } else {
                            Text("No tasks yet! Add something to do.")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        }
                    }
                    .padding()
                }
                
                // PRINT BUTTON
                if !todoItems.isEmpty {
                    VStack {
                        Button {
                            let img = renderListToImage()
                            onSendToPrint(img)
                        } label: {
                            HStack {
                                Image(systemName: "printer.fill")
                                Text("Print Checklist")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(28)
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .shadow(radius: -5)
                }
            }
        }
        .navigationTitle("To-Do List")
    }
    
    func addItem() {
        guard !newItemText.isEmpty else { return }
        withAnimation {
            todoItems.append(TodoItem(text: newItemText))
            newItemText = ""
        }
    }
    
    // Simple Image Renderer for the list
    func renderListToImage() -> UIImage {
        // A simple renderer that draws the list on specific width (384px for printer)
        let width: CGFloat = 384
        // Estimate height
        let itemHeight: CGFloat = 40
        let headerHeight: CGFloat = 60
        let totalHeight = headerHeight + (CGFloat(todoItems.count) * itemHeight) + 40
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: totalHeight))
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: width, height: totalHeight)))
            
            // Draw Title
            let title = "MY CHECKLIST"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .heavy),
                .foregroundColor: UIColor.black
            ]
            (title as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttrs)
            
            // Draw Items
            var yOffset = headerHeight
            for item in todoItems {
                let box = item.isDone ? "[x]" : "[ ]"
                let text = "\(box) \(item.text)"
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
                (text as NSString).draw(at: CGPoint(x: 20, y: yOffset), withAttributes: attrs)
                yOffset += itemHeight
            }
        }
    }
}
