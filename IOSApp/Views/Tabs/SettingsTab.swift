//
//  SettingsTab.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-08.
//
//  Rebuilt off the stock Form (which was rendering in the system's default
//  light/dark chrome, disconnected from the rest of the app) into the same
//  card-based dark language as Home/Stats/Map, with a working notification
//  toggle, an accent color picker, and a real, confirmed "Clear All Game
//  Data" / "Reset High Scores" action.

import SwiftUI
import UserNotifications

struct SettingsTab: View {
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var themeManager: ThemeManager

    // Persisted reminder settings. Date isn't natively AppStorage-compatible,
    // so the time is stored as hour/minute ints and rebuilt into a Date only
    // for the DatePicker binding below.
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0

    // Light It Up round length — read directly by LightItUpView/LightItUpVM
    @AppStorage("lightItUpRoundLength") private var roundLength = 60

    // Quiz Rush accessibility preference — read directly by QuizRushView.
    // Off by default since most players don't want questions read aloud;
    // this is the single switch that turns the whole feature (auto-read +
    // the in-game speaker button) on for players who do.
    @AppStorage("quizRushVoiceEnabled") private var quizVoiceEnabled = false

    // Confirmation + feedback state for destructive data actions
    @State private var showClearConfirm = false
    @State private var showResetScoresConfirm = false
    @State private var toastMessage: String? = nil

    // Notification-permission edge case: user denied (or previously revoked)
    // system permission, so flipping the toggle can't silently succeed.
    @State private var showPermissionDeniedAlert = false

    @State private var appeared = false

    /// Rebuilds a Date from the stored hour/minute for the DatePicker, and
    /// writes back to storage (+ reschedules if active) when changed.
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute
                if notificationsEnabled {
                    NotificationService.scheduleDaily(at: newDate)
                }
            }
        )
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    settingsCard(
                        title: "Appearance",
                        icon: "paintpalette.fill",
                        tint: AppTheme.brand,
                        footer: "Sets the app's accent color — used for primary buttons, Quiz Rush's theme, and highlighted UI throughout the app."
                    ) {
                        accentColorPicker
                    }

                    settingsCard(
                        title: "Accessibility",
                        icon: "accessibility",
                        tint: AppTheme.quizRush,
                        footer: "When on, Quiz Rush automatically reads each question and its answer choices aloud, and announces whether you got it right — built for blind and low-vision players. A speaker button also appears in Quiz Rush so anyone can replay a question on demand."
                    ) {
                        Toggle(isOn: $quizVoiceEnabled.animation(.spring(response: 0.3))) {
                            Text("Read Quiz Questions Aloud")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.quizRush)
                    }

                    settingsCard(
                        title: "Light It Up",
                        icon: "lightbulb.max.fill",
                        tint: AppTheme.lightItUp,
                        footer: "Shorter rounds ramp through the same 5 levels faster; longer rounds give you more time in each one. High scores are tracked separately per round length."
                    ) {
                        roundLengthPicker
                    }

                    settingsCard(
                        title: "Daily Challenge Reminder",
                        icon: "bell.badge.fill",
                        tint: AppTheme.warning,
                        footer: "We'll remind you to play a round every day at this time. You can revoke this anytime from iOS Settings."
                    ) {
                        Toggle(isOn: $notificationsEnabled.animation(.spring(response: 0.3))) {
                            Text("Enable Notifications")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.warning)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                NotificationService.requestPermission { granted in
                                    if granted {
                                        NotificationService.scheduleDaily(at: reminderTimeBinding.wrappedValue)
                                    } else {
                                        notificationsEnabled = false
                                        showPermissionDeniedAlert = true
                                    }
                                }
                            } else {
                                NotificationService.cancelDaily()
                            }
                        }

                        if notificationsEnabled {
                            Divider().overlay(AppTheme.cardBorder)

                            DatePicker(
                                "Reminder Time",
                                selection: reminderTimeBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .environment(\.colorScheme, .dark)
                            .tint(AppTheme.warning)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                            Button {
                                NotificationService.sendTestNotification()
                                presentToast("Test notification sent")
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Test Notification")
                                    Spacer()
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.warning)
                            }
                            .transition(.opacity)
                        }
                    }

                    settingsCard(
                        title: "High Scores",
                        icon: "trophy.fill",
                        tint: AppTheme.warning,
                        footer: "Resets every best score across Tap Frenzy, Light It Up, and Quiz Rush back to zero. Session history and map pins are not affected."
                    ) {
                        Button {
                            showResetScoresConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset All High Scores")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .opacity(0.5)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.danger)
                        }
                    }

                    settingsCard(
                        title: "Data Management",
                        icon: "externaldrive.fill",
                        tint: AppTheme.danger,
                        footer: "Clears your session history and map pins. High scores are kept."
                    ) {
                        Button {
                            showClearConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Clear All Game Data")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .opacity(0.5)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.danger)
                        }
                    }

                    aboutFooter
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }

            if toastMessage != nil {
                clearedToast
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            appeared = true
            // If the toggle is on but the user revoked permission from iOS
            // Settings since last launch, reflect that instead of lying to them.
            if notificationsEnabled {
                NotificationService.checkAuthorizationStatus { authorized in
                    if !authorized {
                        notificationsEnabled = false
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear all game data?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Session History", role: .destructive) {
                withAnimation(.spring(response: 0.3)) {
                    statsVM.clearAllSessions()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                presentToast("Game data cleared")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every recorded session and map pin. High scores stay untouched. This can't be undone.")
        }
        .confirmationDialog(
            "Reset all high scores?",
            isPresented: $showResetScoresConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset High Scores", role: .destructive) {
                resetAllHighScores()
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                presentToast("High scores reset")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This sets every mode's best score back to 0. Session history stays untouched. This can't be undone.")
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications for this app in iOS Settings to get your daily challenge reminder.")
        }
    }

    // MARK: - Header

    var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.brand.opacity(0.18))
                    .frame(width: 50, height: 50)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Tune how the games play and remind you")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -10)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // MARK: - Card Container

    @ViewBuilder
    func settingsCard<Content: View>(
        title: String,
        icon: String,
        tint: Color,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }

            if let footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(AppTheme.radiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.easeOut(duration: 0.4).delay(0.08), value: appeared)
    }

    // MARK: - Accent Color Picker
    // Curated swatches (not a full color wheel) so every option stays
    // readable against the app's dark background and doesn't collide with
    // the fixed semantic colors (success/danger/warning).

    var accentColorPicker: some View {
        HStack(spacing: 14) {
            ForEach(AccentOption.allCases) { option in
                let isSelected = themeManager.accent == option

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3)) { themeManager.accent = option }
                } label: {
                    ZStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 36, height: 36)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .overlay(
                        Circle().stroke(Color.white.opacity(isSelected ? 0.9 : 0), lineWidth: 2)
                    )
                    .overlay(
                        Circle().stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                    .shadow(color: option.color.opacity(isSelected ? 0.5 : 0), radius: 8)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(option.displayName)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Round Length Picker

    var roundLengthPicker: some View {
        HStack(spacing: 6) {
            ForEach([30, 60, 90], id: \.self) { length in
                let isSelected = roundLength == length
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3)) { roundLength = length }
                } label: {
                    Text("\(length)s")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? AppTheme.lightItUp : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - About Footer

    var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("Game Center")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
            Text("Version \(appVersion)")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.16), value: appeared)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Toast

    var clearedToast: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.success)
                Text(toastMessage ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.success.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.top, 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1)
    }

    private func presentToast(_ message: String) {
        withAnimation(.spring(response: 0.35)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) { toastMessage = nil }
        }
    }

    // MARK: - Reset High Scores

    private func resetAllHighScores() {
        let keys = [
            "tapFrenzyHighScore", "tapFrenzyHighScore_easy", "tapFrenzyHighScore_medium", "tapFrenzyHighScore_hard",
            "lightItUpHighScore", "lightItUpHighScore_30", "lightItUpHighScore_60", "lightItUpHighScore_90",
            "quizRushHighScore"
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsTab()
            .environmentObject(StatsVM())
            .environmentObject(ThemeManager())
    }
}
