import SwiftUI

struct PasteContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    var onSelect: (ClipboardItem) -> Void // Action to perform when an item is selected
    var onCancel: () -> Void            // Action to perform when Cancel is tapped

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Use spacing 0 for tighter layout if needed
            Text("Clipboard History (Paste)") // Placeholder Title
                .font(.headline)
                .padding(.bottom, 5)

            // We will add the list of clipboard items here later
            // For now, just a placeholder
            List {
                ForEach(clipboardManager.items, id: \.id) { item in
                     // Wrap Text in a Button for selection
                     Button(action: { onSelect(item) }) { // Call onSelect with the item
                         Text(item.content)
                             .lineLimit(1) // Limit to one line to keep rows uniform
                             .truncationMode(.tail)
                             .frame(maxWidth: .infinity, alignment: .leading) // Ensure button fills width
                             .contentShape(Rectangle()) // Make the whole area tappable
                     }
                     .buttonStyle(.plain) // Use plain style to look like a list item
                }
            }
            .frame(minWidth: 300, idealWidth: 350, maxWidth: 500, minHeight: 200, idealHeight: 300, maxHeight: 400) // Adjust size as needed

            Spacer() // Pushes content to the top
            
            // Add Cancel Button at the bottom
            HStack {
                Spacer() // Push button to the right
                Button("Cancel") {
                    onCancel() // Call the cancel action
                }
            }
            .padding(.top, 8) // Add some space above the button
            
        }
        .padding()
    }
}

// Preview Provider (Optional but helpful for UI development)
#Preview {
    PasteContentView(
        clipboardManager: ClipboardManager(), // Provide a dummy manager
        onSelect: { item in print("Preview: Selected \\(item.id)") }, // Dummy select action
        onCancel: { print("Preview: Cancelled") } // Dummy cancel action
    )
} 