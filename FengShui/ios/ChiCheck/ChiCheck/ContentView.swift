//
//  ContentView.swift
//  ChiCheck
//
//  Created by Benjamin Friesen on 2026-01-17.
//

import SwiftUI

// MARK: Welcome Page (landing page)
struct WelcomeView: View {
    var body: some View {
        NavigationStack{
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 224/255, green: 242/255, blue: 254/255),
                        Color(red: 204/255, green: 251/255, blue: 241/255),
                        Color(red: 209/255, green: 250/255, blue: 229/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 6/255, green: 182/255, blue: 212/255),
                                        Color(red: 20/255, green: 184/255, blue: 166/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 12) {
                        Text("Feng Shui")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))

                        Text("Room Planner")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
                    }

                    Text("Discover harmony and balance\nin your living space")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()

                    NavigationLink {
                        RoomQuestionnaireView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Begin Analysis")
                                .font(.system(size: 20, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 8/255, green: 145/255, blue: 178/255),
                                    Color(red: 13/255, green: 148/255, blue: 136/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color(red: 8/255, green: 145/255, blue: 178/255).opacity(0.3), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Models
struct Question {
    let id: String
    let title: String
    let description: String
}

struct RoomData {
    var roomType: String = ""
    var theme: String = ""
    var concept: String = ""
    var birthMonth: String = ""
    var birthDay: String = ""
    var birthYear: String = ""
}

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
}

enum Priority {
    case high, medium, low

    var color: Color {
        switch self {
        case .high: return Color(red: 220/255, green: 38/255, blue: 38/255)
        case .medium: return Color(red: 245/255, green: 158/255, blue: 11/255)
        case .low: return Color.gray
        }
    }

    var label: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

struct ElementModel: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

struct RoomQuestionnaireView: View {
    @State private var currentStep = 0
    @State private var formData = RoomData()
    @Environment(\.dismiss) private var dismiss

    let questions = [
        Question(id: "roomType", title: "What type of room?", description: "Select the room you'd like to analyze"),
        Question(id: "theme", title: "What's your style?", description: "Choose your preferred aesthetic theme"),
        Question(id: "concept", title: "What's your focus?", description: "Select your feng shui intention"),
        Question(id: "birthday", title: "When were you born?", description: "We'll calculate your Kua number")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 224/255, green: 242/255, blue: 254/255),
                    Color(red: 204/255, green: 251/255, blue: 241/255),
                    Color(red: 209/255, green: 250/255, blue: 229/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 6/255, green: 182/255, blue: 212/255),
                                                Color(red: 20/255, green: 184/255, blue: 166/255)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(radius: 8)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            Text("Feng Shui Analysis")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))

                            // Progress dots
                            HStack(spacing: 8) {
                                ForEach(0..<questions.count, id: \.self) { index in
                                    Capsule()
                                        .fill(getProgressColor(for: index))
                                        .frame(width: getProgressWidth(for: index), height: 8)
                                        .animation(.spring(response: 0.3), value: currentStep)
                                }
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                        questionCard
                                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                }.scrollIndicators(.visible)
                  .scrollIndicatorsFlash(onAppear: true)

                navigationButtons
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if currentStep > 0 {
                        withAnimation(.spring(response: 0.3)) {
                            currentStep -= 1
                        }
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color(red: 8/255, green: 145/255, blue: 178/255))
                }
            }
        }
    }

    @ViewBuilder
    private var questionCard: some View {
        VStack(spacing: 0) {

            // Header (fixed)
            VStack(spacing: 8) {
                Text(questions[currentStep].title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))
                    .multilineTextAlignment(.center)

                Text(questions[currentStep].description)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

                VStack(spacing: 12) {
                    switch currentStep {
                    case 0: roomTypeOptions
                    case 1: themeOptions
                    case 2: conceptOptions
                    case 3: birthdayPickers
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 20)
        .padding(.horizontal, 16)
    }


    @ViewBuilder
    private var roomTypeOptions: some View {
        let rooms = [
            ("bedroom", "Bedroom",
             [Color(red: 224/255, green: 242/255, blue: 254/255),
              Color(red: 204/255, green: 251/255, blue: 241/255)]),

            ("living-room", "Living Room",
             [Color(red: 204/255, green: 251/255, blue: 241/255),
              Color(red: 209/255, green: 250/255, blue: 229/255)]),

            ("office", "Office",
             [Color(red: 224/255, green: 242/255, blue: 254/255),
              Color(red: 219/255, green: 234/255, blue: 254/255)]),

            ("kitchen", "Kitchen",
             [Color(red: 254/255, green: 243/255, blue: 199/255),
              Color(red: 254/255, green: 249/255, blue: 195/255)]),

            ("dining-room", "Dining Room",
             [Color(red: 254/255, green: 215/255, blue: 170/255),
              Color(red: 254/255, green: 235/255, blue: 200/255)]),

            ("bathroom", "Bathroom",
             [Color(red: 219/255, green: 234/255, blue: 254/255),
              Color(red: 224/255, green: 231/255, blue: 255/255)]),

            ("meditation-room", "Meditation Room",
             [Color(red: 220/255, green: 252/255, blue: 231/255),
              Color(red: 187/255, green: 247/255, blue: 208/255)])
        ]

        VStack(spacing: 12) {

            ForEach(rooms, id: \.0) { room in
                OptionButton(
                    title: room.1,
                    isSelected: formData.roomType == room.0,
                    gradientColors: room.2,
                    action: { formData.roomType = room.0 }
                )
            }
        }
    }

    @ViewBuilder
    private var themeOptions: some View {
        let themes = [
            ("minimalist", "Minimalist", [Color(red: 204/255, green: 251/255, blue: 241/255), Color(red: 224/255, green: 242/255, blue: 254/255)]),
            ("modern", "Modern", [Color(red: 204/255, green: 251/255, blue: 241/255), Color(red: 224/255, green: 242/255, blue: 254/255)]),
            ("zen", "Zen", [Color(red: 204/255, green: 251/255, blue: 241/255), Color(red: 209/255, green: 250/255, blue: 229/255)]),
            ("luxury", "Luxury", [Color(red: 254/255, green: 243/255, blue: 199/255), Color(red: 254/255, green: 249/255, blue: 195/255)])
        ]

        ForEach(themes, id: \.0) { theme in
            OptionButton(
                title: theme.1,
                isSelected: formData.theme == theme.0,
                gradientColors: theme.2,
                action: { formData.theme = theme.0 }
            )
        }
    }

    @ViewBuilder
    private var conceptOptions: some View {
        let concepts = [
        ("wealth", "Wealth & Prosperity", "💰"),
        ("health", "Health & Wellbeing", "🌿"),
        ("love", "Love & Relationships", "💖"),
        ("career", "Career & Success", "🎯"),
        ("creativity", "Creativity & Children", "🎨"),
        ("knowledge", "Knowledge & Wisdom", "📚"),
        ("family", "Family & Community", "🏡"),
        ("balance", "Overall Balance", "☯️")
        ]


        VStack(spacing: 12) {
        ForEach(concepts, id: \.0) { concept in
        OptionButtonWithIcon(
        title: concept.1,
        icon: concept.2,
        isSelected: formData.concept == concept.0,
        gradientColors: gradientForConcept(concept.0),
        action: { formData.concept = concept.0 }
        )
        }
        }
    }

    private func gradientForConcept(_ id: String) -> [Color] {
    switch id {
    case "wealth": return [.yellow.opacity(0.3), .orange.opacity(0.3)]
    case "health": return [.green.opacity(0.3), .mint.opacity(0.3)]
    case "love": return [.pink.opacity(0.3), .red.opacity(0.2)]
    case "career": return [.blue.opacity(0.3), .indigo.opacity(0.3)]
    case "creativity": return [.purple.opacity(0.3), .pink.opacity(0.3)]
    case "knowledge": return [.indigo.opacity(0.3), .cyan.opacity(0.3)]
    case "family": return [.green.opacity(0.3), .teal.opacity(0.3)]
    default: return [.gray.opacity(0.2), .gray.opacity(0.1)]
    }
    }

    @ViewBuilder
    private var birthdayPickers: some View {
        VStack(spacing: 16) {
            // Month Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Month")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))

                Picker("Month", selection: $formData.birthMonth) {
                    Text("Select month").tag("")
                    ForEach(1...12, id: \.self) { month in
                        Text(monthName(month)).tag(String(month))
                    }
                }
                .pickerStyle(.menu)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 224/255, green: 242/255, blue: 254/255),
                            Color(red: 204/255, green: 251/255, blue: 241/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 2)
                )
            }

            // Day Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Day")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))

                Picker("Day", selection: $formData.birthDay) {
                    Text("Select day").tag("")
                    ForEach(1...31, id: \.self) { day in
                        Text(String(day)).tag(String(day))
                    }
                }
                .pickerStyle(.menu)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 204/255, green: 251/255, blue: 241/255),
                            Color(red: 209/255, green: 250/255, blue: 229/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 2)
                )
            }

            // Year Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Year")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))

                Picker("Year", selection: $formData.birthYear) {
                    Text("Select year").tag("")
                    ForEach((1926...2026).reversed(), id: \.self) { year in
                        Text(String(year)).tag(String(year))
                    }
                }
                .pickerStyle(.menu)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 254/255, green: 243/255, blue: 199/255),
                            Color(red: 254/255, green: 249/255, blue: 195/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 2)
                )
            }
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                if currentStep < questions.count - 1 {
                    Button(action: handleNext) {
                        HStack {
                            Text("Continue")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: canProceed() ? [
                                    Color(red: 8/255, green: 145/255, blue: 178/255),
                                    Color(red: 13/255, green: 148/255, blue: 136/255)
                                ] : [Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!canProceed())
                } else {
                    NavigationLink {
                        RoomScannerView(roomData: formData)
                    } label: {
                        HStack {
                            Text("Start Scan")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: canProceed() ? [
                                    Color(red: 8/255, green: 145/255, blue: 178/255),
                                    Color(red: 13/255, green: 148/255, blue: 136/255)
                                ] : [Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!canProceed())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    // MARK: - Helpers
    private func getProgressColor(for index: Int) -> Color {
        if index == currentStep {
            return Color(red: 6/255, green: 182/255, blue: 212/255)
        } else if index < currentStep {
            return Color(red: 20/255, green: 184/255, blue: 166/255)
        } else {
            return Color(red: 203/255, green: 213/255, blue: 225/255)
        }
    }

    private func getProgressWidth(for index: Int) -> CGFloat {
        index == currentStep ? 32 : 8
    }

    private func canProceed() -> Bool {
        switch currentStep {
        case 0: return !formData.roomType.isEmpty
        case 1: return !formData.theme.isEmpty
        case 2: return !formData.concept.isEmpty
        case 3: return !formData.birthMonth.isEmpty && !formData.birthDay.isEmpty && !formData.birthYear.isEmpty
        default: return false
        }
    }

    private func handleNext() {
        withAnimation(.spring(response: 0.3)) {
            currentStep += 1
        }
    }

    private func monthName(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }
}

// MARK: - Room Scanner View
struct RoomScannerView: View {
    let roomData: RoomData

    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    @State private var scanStage: ScanStage = .idle
    @State private var detectedFeatures = DetectedFeatures()
    @State private var animationPhase: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    enum ScanStage {
        case idle, scanning, complete
    }

    struct DetectedFeatures {
        var walls: Int = 0
        var corners: Int = 0
        var openings: Int = 0
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 23/255, blue: 42/255),
                    Color(red: 30/255, green: 58/255, blue: 138/255),
                    Color(red: 15/255, green: 23/255, blue: 42/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                    if scanStage == .complete {
                        Spacer()
                        NavigationLink {
                            AnalysisResultsView(roomData: roomData)
                        } label: {
                            HStack(spacing: 8) {
                                Text("View Analysis")
                                    .font(.system(size: 17, weight: .medium))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 37/255, green: 99/255, blue: 235/255),
                                        Color(red: 22/255, green: 163/255, blue: 74/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                VStack(spacing: 16) {
                    scannerCard

                    if isScanning {
                        progressCard
                    }

                    if isScanning || scanStage == .complete {
                        detectedFeaturesCard
                    }

                    instructionsCard
                }
                .padding(.horizontal, 16)

                Spacer()
            }

            if scanStage == .idle {
                VStack {
                    Spacer()

                    Button(action: startScan) {
                        HStack(spacing: 12) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 20, weight: .medium))
                            Text("Start Room Scan")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 37/255, green: 99/255, blue: 235/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            startColorAnimation()
        }
    }

    @ViewBuilder
    private var scannerCard: some View {
        ZStack {
            Rectangle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hue: Double(animationPhase), saturation: 0.7, brightness: 0.6),
                            Color(hue: Double(animationPhase) + 0.33, saturation: 0.7, brightness: 0.5),
                            Color(hue: Double(animationPhase) + 0.66, saturation: 0.7, brightness: 0.4),
                            Color(hue: Double(animationPhase), saturation: 0.7, brightness: 0.6)
                        ],
                        center: .center
                    )
                )
                .aspectRatio(3/4, contentMode: .fit)
                .cornerRadius(12)

            if isScanning {
                scanningOverlay
            }

            if scanStage == .complete {
                completeOverlay
            }

            if scanStage == .idle {
                idleOverlay
            }
        }
        .background(Color.black)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 30/255, green: 58/255, blue: 138/255), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var scanningOverlay: some View {
        ZStack {
            Rectangle()
                .fill(overlayColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(overlayBorderColor, lineWidth: 4)
                )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(0..<9, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .opacity(0.3 + sin(Double(animationPhase) * 10 + Double(index) * 0.5) * 0.5)
                }
            }
            .padding(32)

            VStack {
                HStack {
                    CornerMarker(position: .topLeft)
                    Spacer()
                    CornerMarker(position: .topRight)
                }
                Spacer()
                HStack {
                    CornerMarker(position: .bottomLeft)
                    Spacer()
                    CornerMarker(position: .bottomRight)
                }
            }
            .padding(16)

            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 2)
                    .shadow(color: .white, radius: 10)
                    .offset(y: scanLineOffset(in: geometry.size.height))
            }
        }
        .cornerRadius(12)
    }

    @ViewBuilder
    private var completeOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 4)
                )

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundColor(.green)
                .scaleEffect(scanStage == .complete ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: scanStage)
        }
        .cornerRadius(12)
    }

    @ViewBuilder
    private var idleOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.6))

            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(red: 96/255, green: 165/255, blue: 250/255))

                Text("Ready to scan your room")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .cornerRadius(12)
    }

    @ViewBuilder
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Scanning Progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(scanProgress))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 251/255, green: 191/255, blue: 36/255))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 6/255, green: 182/255, blue: 212/255),
                                    Color(red: 20/255, green: 184/255, blue: 166/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (scanProgress / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 30/255, green: 58/255, blue: 138/255), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var detectedFeaturesCard: some View {
        HStack(spacing: 0) {
            FeatureCounter(value: detectedFeatures.walls, label: "Walls", color: .green)
            Divider()
                .background(Color.white.opacity(0.2))
            FeatureCounter(value: detectedFeatures.corners, label: "Corners", color: .blue)
            Divider()
                .background(Color.white.opacity(0.2))
            FeatureCounter(value: detectedFeatures.openings, label: "Openings", color: Color(red: 251/255, green: 191/255, blue: 36/255))
        }
        .frame(height: 80)
        .background(Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 30/255, green: 58/255, blue: 138/255), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var instructionsCard: some View {
        Group {
            switch scanStage {
            case .idle:
                InstructionCard(
                    text: "Point your device camera around the room slowly. The app will detect walls, corners, and openings.",
                    backgroundColor: Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.5)
                )
            case .scanning:
                InstructionCard(
                    text: "Move slowly. The overlay color shows scan quality: red → gold → green",
                    backgroundColor: Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.5)
                )
            case .complete:
                InstructionCard(
                    text: "✓ Room scan complete! Your space is ready for feng shui analysis.",
                    backgroundColor: Color.green.opacity(0.2),
                    textColor: Color(red: 187/255, green: 247/255, blue: 208/255)
                )
            }
        }
    }

    // MARK: - Helper
    private var overlayColor: Color {
        if scanProgress < 30 {
            return Color(red: 239/255, green: 68/255, blue: 68/255)
        } else if scanProgress < 70 {
            return Color(red: 234/255, green: 179/255, blue: 8/255)
        } else {
            return Color(red: 34/255, green: 197/255, blue: 94/255)
        }
    }

    private var overlayBorderColor: Color {
        if scanProgress < 30 {
            return Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.6)
        } else if scanProgress < 70 {
            return Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6)
        } else {
            return Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.6)
        }
    }

    private func scanLineOffset(in height: CGFloat) -> CGFloat {
        let progress = sin(Double(animationPhase) * 2) * 0.5 + 0.5
        return CGFloat(progress) * height
    }

    private func startColorAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if isScanning {
                animationPhase += 0.005
                if animationPhase > 1 {
                    animationPhase = 0
                }
            }
        }
    }

    private func startScan() {
        isScanning = true
        scanStage = .scanning
        scanProgress = 0
        detectedFeatures = DetectedFeatures()

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            guard isScanning else {
                timer.invalidate()
                return
            }

            scanProgress += Double.random(in: 2...4)

            if scanProgress >= 100 {
                scanProgress = 100
                isScanning = false
                scanStage = .complete
                timer.invalidate()
            }

            if Double.random(in: 0...1) > 0.7 {
                if detectedFeatures.walls < 4 && Double.random(in: 0...1) > 0.5 {
                    detectedFeatures.walls += 1
                }
                if detectedFeatures.corners < 4 && Double.random(in: 0...1) > 0.6 {
                    detectedFeatures.corners += 1
                }
                if detectedFeatures.openings < 3 && Double.random(in: 0...1) > 0.8 {
                    detectedFeatures.openings += 1
                }
            }
        }
    }
}

// MARK: - Analysis Results View
struct AnalysisResultsView: View {
    let roomData: RoomData
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 239/255, green: 246/255, blue: 255/255),
                    Color(red: 220/255, green: 252/255, blue: 231/255),
                    Color(red: 219/255, green: 234/255, blue: 254/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    resultsCard
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("New Analysis")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color(red: 29/255, green: 78/255, blue: 216/255))
                }
            }
        }
    }

    @ViewBuilder
    private var resultsCard: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 12) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)

                Text("Your Feng Shui Analysis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text("Personalized for your \(roomData.roomType.replacingOccurrences(of: "-", with: " "))")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 37/255, green: 99/255, blue: 235/255),
                        Color(red: 22/255, green: 163/255, blue: 74/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Summary Stats
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatCard(
                        label: "Kua Number",
                        value: "\(kuaNumber)",
                        backgroundColor: Color(red: 239/255, green: 246/255, blue: 255/255),
                        borderColor: Color(red: 191/255, green: 219/255, blue: 254/255),
                        textColor: Color(red: 29/255, green: 78/255, blue: 216/255)
                    )

                    StatCard(
                        label: "Theme",
                        value: roomData.theme.capitalized,
                        backgroundColor: Color(red: 236/255, green: 253/255, blue: 245/255),
                        borderColor: Color(red: 167/255, green: 243/255, blue: 208/255),
                        textColor: Color(red: 22/255, green: 163/255, blue: 74/255)
                    )
                }

                HStack {
                    Text("Your Focus")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)

                Text(roomData.concept.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 239/255, green: 246/255, blue: 255/255),
                                Color(red: 236/255, green: 253/255, blue: 245/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 191/255, green: 219/255, blue: 254/255), lineWidth: 1)
                    )
                    .padding(.horizontal, 12)

                Picker("", selection: $selectedTab) {
                    Text("Tips").tag(0)
                    Text("Elements").tag(1)
                    Text("Map").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Group {
                    switch selectedTab {
                    case 0:
                        recommendationsTab
                    case 1:
                        elementsTab
                    case 2:
                        mapTab
                    default:
                        EmptyView()
                    }
                }
                .padding(.top, 12)
            }
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 191/255, green: 219/255, blue: 254/255), lineWidth: 2)
        )
    }

    @ViewBuilder
    private var recommendationsTab: some View {
        VStack(spacing: 12) {
            ForEach(recommendations) { rec in
                RecommendationCard(recommendation: rec)
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var elementsTab: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(elements) { element in
                    ElementView(element: element)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your room has strong **Wood** and **Water** elements. Consider adding **Earth** elements to enhance \(roomData.concept.replacingOccurrences(of: "-", with: " ")) energy.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 239/255, green: 246/255, blue: 255/255),
                        Color(red: 236/255, green: 253/255, blue: 245/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 191/255, green: 219/255, blue: 254/255), lineWidth: 1)
            )
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var mapTab: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            BaguaCell(label: baguaLabels[index], color: baguaColors[index])
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 219/255, green: 234/255, blue: 254/255),
                        Color(red: 220/255, green: 252/255, blue: 231/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 147/255, green: 197/255, blue: 253/255), lineWidth: 2)
            )
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        Text("North")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
                            .position(x: geo.size.width / 2, y: -20)

                        Text("South")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
                            .position(x: geo.size.width / 2, y: geo.size.height + 20)

                        Text("West")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
                            .position(x: -30, y: geo.size.height / 2)

                        Text("East")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
                            .position(x: geo.size.width + 30, y: geo.size.height / 2)
                    }
                }
            )

            Text("Bagua map showing life areas. Align with your room's entrance facing down.")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Data & Helpers

    private var kuaNumber: Int {
        let year = Int(roomData.birthYear) ?? 2000
        let lastTwo = year % 100
        let sum = (lastTwo / 10) + (lastTwo % 10)
        let finalSum = sum > 9 ? (sum / 10) + (sum % 10) : sum
        return 11 - finalSum
    }

    private let recommendations: [Recommendation] = [
        Recommendation(title: "Place your bed in the East direction", description: "Based on your Kua number, East is your best direction for health and vitality.", priority: .high),
        Recommendation(title: "Add wooden elements", description: "Incorporate plants or wooden furniture to enhance positive energy flow.", priority: .high),
        Recommendation(title: "Use warm, earthy tones", description: "Colors like terracotta, beige, and soft greens will harmonize with your space.", priority: .medium),
        Recommendation(title: "Keep the center area clear", description: "The center of the room represents earth element and should remain open.", priority: .medium),
        Recommendation(title: "Add a water feature in the North", description: "A small fountain or water imagery can enhance career prospects.", priority: .low)
    ]

    private let elements: [ElementModel] = [
        ElementModel(name: "Wood", icon: "leaf.fill", color: Color.green),
        ElementModel(name: "Fire", icon: "flame.fill", color: Color.red),
        ElementModel(name: "Earth", icon: "mountain.2.fill", color: Color.orange),
        ElementModel(name: "Metal", icon: "wind", color: Color.gray),
        ElementModel(name: "Water", icon: "drop.fill", color: Color.blue)
    ]

    private let baguaLabels = ["Wealth", "Fame", "Love", "Family", "Center", "Children", "Knowledge", "Career", "Travel"]
    private let baguaColors: [Color] = [
        Color.purple.opacity(0.3),
        Color.red.opacity(0.3),
        Color.pink.opacity(0.3),
        Color.green.opacity(0.3),
        Color.orange.opacity(0.3),
        Color.white.opacity(0.3),
        Color.blue.opacity(0.3),
        Color.gray.opacity(0.3),
        Color(red: 156/255, green: 163/255, blue: 175/255).opacity(0.3)
    ]
}

// MARK: - Small Supporting Views (Option buttons, cards, etc.)

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(red: 30/255, green: 41/255, blue: 59/255))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    } else {
                        Color.white
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: isSelected ? Color.black.opacity(0.12) : Color.clear, radius: 6, x: 0, y: 4)
        }
        .padding(.vertical, 4)
    }
}

struct OptionButtonWithIcon: View {
    let title: String
    let icon: String    // emoji or SF symbol as String
    let isSelected: Bool
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon)
                    .font(.system(size: 18))            // nicer icon size
                    .padding(.trailing, 6)
                    .foregroundColor(isSelected ? .white : Color(red: 30/255, green: 41/255, blue: 59/255))

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(red: 30/255, green: 41/255, blue: 59/255))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                Group { // Group returns a single 'some View' type for the background
                    if isSelected {
                        LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
}


struct CornerMarker: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    let position: Position
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(rotation))
    }

    private var rotation: Double {
        switch position {
        case .topLeft: return 0
        case .topRight: return 90
        case .bottomLeft: return -90
        case .bottomRight: return 180
        }
    }
}

struct FeatureCounter: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

struct InstructionCard: View {
    let text: String
    var backgroundColor: Color = Color.black.opacity(0.4)
    var textColor: Color = .white

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let backgroundColor: Color
    let borderColor: Color
    let textColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(textColor.opacity(0.7))
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(textColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))
                Text(recommendation.description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255))
            }
            Spacer()
            VStack {
                Text(recommendation.priority.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(recommendation.priority.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 226/255, green: 232/255, blue: 240/255), lineWidth: 1)
        )
    }
}

struct ElementView: View {
    let element: ElementModel

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: element.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(8)
                .background(element.color)
                .cornerRadius(8)
            Text(element.name)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255))
        }
        .frame(minWidth: 64)
    }
}

struct BaguaCell: View {
    let label: String
    let color: Color

    var body: some View {
        ZStack {
            color
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 30/255, green: 41/255, blue: 59/255))
                .multilineTextAlignment(.center)
                .padding(4)
        }
        .border(Color.white.opacity(0.5), width: 0.5)
    }
}

// MARK: - Previews
struct App_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
            RoomQuestionnaireView()
            RoomScannerView(roomData: RoomData())
            AnalysisResultsView(roomData: RoomData(roomType: "bedroom", theme: "zen", concept: "sleep", birthMonth: "1", birthDay: "1", birthYear: "1996"))
        }
    }
}
