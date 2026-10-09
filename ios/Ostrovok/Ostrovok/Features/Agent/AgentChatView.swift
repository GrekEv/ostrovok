import SwiftUI

struct AgentChatView: View {
    @EnvironmentObject private var session: AppSession
    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    private let agent = AgentService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                bubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if let replies = messages.last?.quickReplies, !replies.isEmpty, !(messages.last?.isFromUser ?? true) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(replies, id: \.self) { reply in
                                Button(reply) { send(reply) }
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Palette.mint)
                                    .foregroundStyle(Palette.forest)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }

                HStack(spacing: 10) {
                    TextField("Напишите агенту", text: $input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Palette.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Button {
                        send(input)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Palette.muted : Palette.leaf)
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(16)
                .background(Color.white)
            }
            .background(Palette.foam)
            .navigationTitle("Агент Островок")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: bootstrap)
            .onChange(of: session.pendingAgentPrompt) { _, prompt in
                if let prompt {
                    send(prompt)
                    session.pendingAgentPrompt = nil
                }
            }
        }
    }

    private func bootstrap() {
        if messages.isEmpty {
            messages = [agent.opening(likedCount: session.likedOffers.count)]
        }
        if let prompt = session.pendingAgentPrompt {
            send(prompt)
            session.pendingAgentPrompt = nil
        }
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(isFromUser: true, text: trimmed))
        input = ""
        Task {
            let reply = await session.agentReply(to: trimmed)
            messages.append(reply)
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 48) }
            if !message.isFromUser {
                OstrovokMascot(mood: .smile, size: 36)
            }
            Text(message.text)
                .padding(12)
                .background(message.isFromUser ? Palette.leaf : Color.white)
                .foregroundStyle(message.isFromUser ? Color.white : Palette.ink)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !message.isFromUser { Spacer(minLength: 48) }
        }
    }
}
