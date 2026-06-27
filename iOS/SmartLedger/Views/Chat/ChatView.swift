import SwiftUI
import PhotosUI
import Speech
import AVFoundation

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var expenseStore: ExpenseStore

    @State private var inputText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var errorMessage: String?

    private let bailian = BailianService()
    private let intentService = ChatIntentService()
    private let queryService = SpendingQueryService()

    var body: some View {
        let theme = settings.themeColors

        VStack(spacing: 0) {
            header(theme: theme)
            messagesList(theme: theme)
            inputBar(theme: theme)
        }
        .background(Color.appBackground)
        .overlay(alignment: .bottomTrailing) {
            Button {
                appState.openManualEntry()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primary)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 150)
            .accessibilityIdentifier("chat.manualEntry")
        }
        .alert(String(localized: "common.error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            String(localized: "chat.photo_source_title"),
            isPresented: $showPhotoSourcePicker,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(String(localized: "chat.photo_take")) { showCamera = true }
            }
            Button(String(localized: "chat.photo_library")) { showPhotoLibrary = true }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                guard let data = image.jpegData(compressionQuality: 0.85) else { return }
                Task { await handlePhotoData(data) }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, item in
            Task { await handlePhoto(item) }
        }
    }

    private func header(theme: ThemeColors) -> some View {
        HStack {
            HStack(spacing: 12) {
                AIAssistantAvatar(theme: theme)
                VStack(alignment: .leading, spacing: 2) {
                    Text(GreetingProvider.current())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                    Text("chat.title")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .accessibilityIdentifier("chat.title")
                }
            }
            Spacer()
            CreditsBadge(credits: settings.credits, theme: theme) {
                appState.selectedTab = .settings
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.borderLight).frame(height: 1) }
    }

    private func messagesList(theme: ThemeColors) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(appState.chatMessages) { message in
                        messageView(message, theme: theme)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: appState.chatMessages.count) { _, _ in
                if let last = appState.chatMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: ChatMessage, theme: ThemeColors) -> some View {
        switch message.role {
        case .assistant:
            HStack(alignment: .bottom, spacing: 8) {
                AIAssistantAvatar(theme: theme, size: 32)
                VStack(alignment: .leading, spacing: 8) {
                    if message.isTyping {
                        typingIndicator(theme: theme)
                    } else {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(.textPrimary)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                    }
                    if message.extractedExpense != nil, !message.isTyping {
                        extractedCard(message, theme: theme)
                    }
                }
                Spacer(minLength: 40)
            }
        case .user:
            HStack {
                Spacer(minLength: 40)
                VStack(alignment: .trailing, spacing: 6) {
                    if let data = message.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 200, maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        case .system:
            EmptyView()
        }
    }

    private func typingIndicator(theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.15), value: appState.isProcessingAI)
                }
            }
            Text("chat.reading_receipt")
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
    }

    @ViewBuilder
    private func extractedCard(_ message: ChatMessage, theme: ThemeColors) -> some View {
        if let extracted = message.extractedExpense {
            VStack(spacing: 10) {
                VStack(spacing: 8) {
                    extractedRow("confirm.merchant", extracted.merchant)
                    extractedRow("confirm.amount", MoneyFormatter.string(Decimal(extracted.amount), currency: settings.currency))
                    extractedRow("confirm.category", String(localized: String.LocalizationValue(ExpenseCategory.fromAIValue(extracted.category).localizationKey)))
                    if !extracted.notes.isEmpty {
                        extractedRow("confirm.notes", extracted.notes)
                    }
                }
                .padding(12)
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if message.expenseSaved {
                    Label("chat.expense_saved", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(theme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityIdentifier("chat.confirmButton.saved")
                } else {
                    Button {
                        var draft = extracted.toDraft()
                        if let lastImage = appState.chatMessages.last(where: { $0.imageData != nil })?.imageData {
                            draft.receiptImageData = lastImage
                        }
                        appState.navigateToConfirm(with: draft, fromMessageID: message.id)
                    } label: {
                        Text("chat.confirm_save")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .accessibilityIdentifier("chat.confirmButton")
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
        }
    }

    private func extractedRow(_ titleKey: String, _ value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
        }
    }

    private func inputBar(theme: ThemeColors) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    showPhotoSourcePicker = true
                } label: {
                    Image(systemName: "camera")
                        .foregroundColor(.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))
                }
                .accessibilityIdentifier("chat.camera")

                TextField(String(localized: "chat.placeholder"), text: $inputText)
                    .font(.system(size: 14))
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("chat.input")

                Button {
                    Task { await toggleVoice() }
                } label: {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityIdentifier("chat.voice")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderLight, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .onSubmit { Task { await sendMessage() } }
        }
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(Color.borderLight).frame(height: 1) }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        appState.chatMessages.append(ChatMessage(role: .user, text: text))
        await processAI(text: text, imageData: nil)
    }

    private func handlePhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        selectedPhoto = nil
        await handlePhotoData(data)
    }

    private func handlePhotoData(_ data: Data) async {
        appState.chatMessages.append(ChatMessage(role: .user, text: String(localized: "chat.receipt_uploaded"), imageData: data))
        await processAI(text: String(localized: "chat.analyze_receipt"), imageData: data)
    }

    private func processAI(text: String, imageData: Data?) async {
        let intent = intentService.detectIntent(from: text, hasImage: imageData != nil)
        let creditCost: Int
        switch intent {
        case .querySpending: creditCost = 2
        case .recordExpense: creditCost = imageData == nil ? 5 : 10
        case .general: creditCost = 2
        }

        guard settings.consumeCredits(creditCost) else {
            errorMessage = String(localized: "error.insufficient_credits")
            return
        }

        appState.isProcessingAI = true
        let typing = ChatMessage(role: .assistant, text: "", isTyping: true)
        appState.chatMessages.append(typing)

        defer {
            appState.chatMessages.removeAll { $0.isTyping }
            appState.isProcessingAI = false
        }

        switch intent {
        case .querySpending:
            let answer = queryService.answer(
                text: text,
                expenses: expenseStore.expenses,
                currency: settings.currency,
                isChinese: settings.effectiveLanguage.isChinese
            )
            appState.chatMessages.append(ChatMessage(role: .assistant, text: answer))

        case .recordExpense:
            await extractAndPresentExpense(text: text, imageData: imageData)

        case .general:
            let reply = settings.effectiveLanguage.isChinese
                ? "你可以问我「这个月花了多少钱」，或告诉我一笔支出，例如「午餐花了35元」。"
                : "Ask me things like \"How much did I spend this month?\" or record an expense like \"Lunch cost 35 yuan\"."
            appState.chatMessages.append(ChatMessage(role: .assistant, text: reply))
        }
    }

    private func extractAndPresentExpense(text: String, imageData: Data?) async {
        do {
            let extracted: ExtractedExpense
            if settings.dashscopeAPIKey.isEmpty {
                extracted = bailian.mockExtract(from: text)
            } else if let imageData {
                extracted = try await bailian.extractExpense(from: imageData, apiKey: settings.dashscopeAPIKey, hint: text)
            } else {
                extracted = try await bailian.extractExpense(from: text, apiKey: settings.dashscopeAPIKey)
            }

            appState.chatMessages.append(
                ChatMessage(
                    role: .assistant,
                    text: String(localized: "chat.extracted_intro"),
                    extractedExpense: extracted
                )
            )
        } catch {
            let fallback = bailian.mockExtract(from: text)
            appState.chatMessages.append(
                ChatMessage(
                    role: .assistant,
                    text: String(localized: "chat.extracted_intro"),
                    extractedExpense: fallback
                )
            )
        }
    }

    private func toggleVoice() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    private func startRecording() async {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { return }
            DispatchQueue.main.async {
                do {
                    try beginRecording()
                    isRecording = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func beginRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result {
                inputText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                stopRecording()
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        if !inputText.isEmpty {
            Task { await sendMessage() }
        }
    }
}
