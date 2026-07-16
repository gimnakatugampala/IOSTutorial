//
//  SplashView.swift
//  IOSApp
//
//  Created by Gimna Katugampala on 2026-07-16.
//

//
//  SplashView.swift
//  IOSApp
//
//  Custom animated splash shown for a beat after launch, on top of the
//  native (static) launch screen. Reuses the same ambient-glow language as
//  HomeTab so the transition into the app feels continuous rather than like
//  two different screens bolted together.

import SwiftUI

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var glowPulse = false
    @State private var titleOffset: CGFloat = 12
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            // Ambient glow — same visual grammar as HomeTab's background,
            // so launching the app doesn't feel like a jump-cut into Home.
            ZStack {
                Circle()
                    .fill(AppTheme.brand.opacity(0.5))
                    .frame(width: 320, height: 320)
                    .blur(radius: 110)
                    .offset(x: glowPulse ? 80 : -100, y: glowPulse ? -120 : 90)

                Circle()
                    .fill(AppTheme.lightItUp.opacity(0.35))
                    .frame(width: 280, height: 280)
                    .blur(radius: 100)
                    .offset(x: glowPulse ? -100 : 100, y: glowPulse ? 100 : -110)
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppTheme.brandGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: AppTheme.brand.opacity(0.6), radius: 24, y: 10)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: 6) {
                    Text("Game Center")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Tap. Light. Answer. Repeat.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            glowPulse = true

            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                iconScale = 1.0
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.4)) {
                taglineOpacity = 1
            }
        }
    }
}

#Preview {
    SplashView()
}
