import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct GeminiChatView: View {
    @State private var messages: [Message] = []
    @State private var userInput = ""
    private let geminiService = GeminiService()

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .foregroundColor(.white)
                                        .background(Color.blue)
                                        .cornerRadius(16)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .foregroundColor(.black)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(16)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: messages.count) { _ in
                    // Автопрокрутка вниз
                    if let last = messages.last {
                        scrollView.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Задай вопрос ассистенту", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 44)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }

    func sendMessage() {
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        let userMessage = Message(text: trimmedInput, isUser: true)
        messages.append(userMessage)
        userInput = ""

        geminiService.sendMessage(trimmedInput) { reply in
            DispatchQueue.main.async {
                let responseText = reply ?? "Ошибка получения ответа"
                let botMessage = Message(text: responseText, isUser: false)
                messages.append(botMessage)
            }
        }
    }
}
