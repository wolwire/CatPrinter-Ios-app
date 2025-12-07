import SwiftUI

struct TodoView: View {
    @State private var todoItems: [TodoItem] = []
    @State private var newItemText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onSendToPrint: (UIImage) -> Void
    
    // Theme
    let themeColor = Color(red: 0.6, green: 0.9, blue: 0.8) // Pastel Teal/Blue
    
    struct TodoItem: Identifiable {
        let id = UUID()
        var text: String
        var isDone: Bool = false
    }

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.98, blue: 0.98)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Handled by Nav but we can add a title card)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // INPUT CARD
                        VStack(spacing: 12) {
                            Text("New Task")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                TextField("Buy cat food...", text: $newItemText)
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(12)
                                    .environment(\.colorScheme, .light)
                                    .foregroundColor(.black)
                                
                                Button {
                                    addItem()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(themeColor)
                                        .cornerRadius(12)
                                }
                                .disabled(newItemText.isEmpty)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
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
                                                .foregroundColor(item.isDone ? themeColor : .gray)
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
