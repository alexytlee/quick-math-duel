//
//  ContentView.swift
//  Quick Math Challenge
//
//  Created by Alex Lee on 17/6/2025.
//

import SwiftUI
import StoreKit
import UserNotifications
import AudioToolbox
import GoogleMobileAds
import GameKit

// MARK: - Device Size Classification
enum DeviceSize {
    case compact    // iPhone SE, iPhone 12 mini
    case regular    // iPhone 14, iPhone 15
    case large      // iPhone 14 Pro Max, iPhone 15 Pro Max
    case iPad       // iPad
    
    static func classify(geometry: GeometryProxy) -> DeviceSize {
        let width = geometry.size.width
        let height = geometry.size.height
        let screenSize = max(width, height)
        
        if width > 768 {
            return .iPad
        } else if screenSize >= 926 { // Pro Max sizes
            return .large
        } else if screenSize >= 844 { // Regular iPhone sizes
            return .regular
        } else {
            return .compact // SE, mini sizes
        }
    }
}

struct ContentView: View {
    @StateObject private var gameModel = GameModel()
    @StateObject private var adManager = AdManager()
    @StateObject private var iapManager = IAPManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var gameCenterManager = GameCenterManager()
    
    private func contentMaxWidth(for deviceSize: DeviceSize) -> CGFloat {
        deviceSize == .iPad ? 600 : .infinity
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Retro 8-bit background
                Color.black
                    .ignoresSafeArea()
                
                // Pixel grid pattern overlay (scaled for device)
                VStack(spacing: 0) {
                    ForEach(0..<Int(geometry.size.height / 15), id: \.self) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<Int(geometry.size.width / 20), id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.green.opacity(0.05))
                                    .frame(width: 20, height: 15)
                                    .border(Color.green.opacity(0.1), width: 0.5)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                contentView(geometry: geometry)
            }
        }
        .onAppear {
            adManager.loadAds()
            iapManager.loadProducts()
            notificationManager.requestPermissions()
            gameModel.setNotificationManager(notificationManager)
            gameModel.setGameCenterManager(gameCenterManager)
        }
    }
    
    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        let deviceSize = DeviceSize.classify(geometry: geometry)
        let maxWidth: CGFloat = contentMaxWidth(for: deviceSize)
            
        if gameModel.gameState == .menu {
            MenuView(gameModel: gameModel, iapManager: iapManager, notificationManager: notificationManager, gameCenterManager: gameCenterManager, deviceSize: deviceSize)
                .frame(maxWidth: maxWidth, maxHeight: .infinity)
        } else if gameModel.gameState == .playing {
            GameView(gameModel: gameModel, deviceSize: deviceSize)
                .frame(maxWidth: maxWidth, maxHeight: .infinity)
        } else {
            GameOverView(gameModel: gameModel, adManager: adManager, iapManager: iapManager, deviceSize: deviceSize)
                .frame(maxWidth: maxWidth, maxHeight: .infinity)
        }
    }
}

struct MenuView: View {
    @ObservedObject var gameModel: GameModel
    @ObservedObject var iapManager: IAPManager
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var gameCenterManager: GameCenterManager
    let deviceSize: DeviceSize
    @State private var showingShop = false
    @State private var titlePulse = false
    @State private var buttonScale = 1.0
    @State private var powerUpsVisible = false
    
    // Pre-calculate all device-specific values to avoid complex expressions
    private var taglineFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 14
        case .large: return 16
        case .iPad: return 18
        }
    }
    
    private var buttonWidth: CGFloat {
        switch deviceSize {
        case .compact: return 200
        case .regular: return 220
        case .large: return 250
        case .iPad: return 300
        }
    }
    
    private var buttonHeight: CGFloat {
        switch deviceSize {
        case .compact: return 55
        case .regular: return 60
        case .large: return 65
        case .iPad: return 80
        }
    }
    
    private var buttonFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 18
        case .regular: return 20
        case .large: return 22
        case .iPad: return 28
        }
    }
    
    private var logoSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 3
        case .regular: return 5
        case .large: return 6
        case .iPad: return 8
        }
    }
    
    private var logoMaxWidth: CGFloat {
        switch deviceSize {
        case .compact: return 800
        case .regular: return 1000
        case .large: return 1200
        case .iPad: return 1400
        }
    }
    
    private var logoMaxHeight: CGFloat {
        switch deviceSize {
        case .compact: return 220
        case .regular: return 280
        case .large: return 320
        case .iPad: return 400
        }
    }
    
    private var logoPaddingTop: CGFloat {
        switch deviceSize {
        case .compact: return -10
        case .regular: return -15
        case .large: return -15
        case .iPad: return -20
        }
    }
    
    private var middleSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 20
        case .regular: return 25
        case .large: return 30
        case .iPad: return 35
        }
    }
    
    private var shadowHeight: CGFloat {
        switch deviceSize {
        case .compact: return 3
        case .regular: return 4
        case .large: return 4
        case .iPad: return 6
        }
    }
    
    private var strokeWidth: CGFloat {
        switch deviceSize {
        case .compact: return 2
        case .regular: return 3
        case .large: return 3
        case .iPad: return 4
        }
    }
    
    private var powerUpSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 10
        case .large: return 12
        case .iPad: return 15
        }
    }
    
    private var powerUpFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        case .iPad: return 16
        }
    }
    
    private var powerUpHSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 15
        case .large: return 20
        case .iPad: return 25
        }
    }
    
    private var powerUpIconSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 3
        case .regular: return 5
        case .large: return 5
        case .iPad: return 8
        }
    }
    
    private var powerUpIconSize: CGFloat {
        switch deviceSize {
        case .compact: return 16
        case .regular: return 20
        case .large: return 20
        case .iPad: return 28
        }
    }
    
    private var powerUpCountSize: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 16
        case .large: return 16
        case .iPad: return 22
        }
    }
    
    private var powerUpLabelSize: CGFloat {
        switch deviceSize {
        case .compact: return 7
        case .regular: return 9
        case .large: return 9
        case .iPad: return 12
        }
    }
    
    private var powerUpHPadding: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 12
        case .large: return 12
        case .iPad: return 18
        }
    }
    
    private var powerUpVPadding: CGFloat {
        switch deviceSize {
        case .compact: return 6
        case .regular: return 8
        case .large: return 8
        case .iPad: return 12
        }
    }
    
    private var highScoreFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 12
        case .large: return 12
        case .iPad: return 16
        }
    }
    
    private var highScoreNumberSize: CGFloat {
        switch deviceSize {
        case .compact: return 24
        case .regular: return 28
        case .large: return 28
        case .iPad: return 36
        }
    }
    
    private var rankFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 6
        case .regular: return 7
        case .large: return 7
        case .iPad: return 9
        }
    }
    
    private var smallButtonWidth: CGFloat {
        switch deviceSize {
        case .compact: return 95
        case .regular: return 105
        case .large: return 120
        case .iPad: return 140
        }
    }
    
    private var smallButtonHeight: CGFloat {
        switch deviceSize {
        case .compact: return 45
        case .regular: return 50
        case .large: return 55
        case .iPad: return 65
        }
    }
    
    private var smallButtonFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        case .iPad: return 16
        }
    }
    
    private var smallButtonIconSize: CGFloat {
        switch deviceSize {
        case .compact: return 14
        case .regular: return 16
        case .large: return 16
        case .iPad: return 20
        }
    }
    
    private var buttonSpacing: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 12
        case .large: return 12
        case .iPad: return 20
        }
    }
    
    private var smallShadowHeight: CGFloat {
        switch deviceSize {
        case .compact: return 2
        case .regular: return 3
        case .large: return 3
        case .iPad: return 4
        }
    }
    
    private var smallStrokeWidth: CGFloat {
        switch deviceSize {
        case .compact: return 1
        case .regular: return 2
        case .large: return 2
        case .iPad: return 3
        }
    }
    
    private var mainPadding: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 15
        case .large: return 15
        case .iPad: return 30
        }
    }
    
    private var bottomPadding: CGFloat {
        switch deviceSize {
        case .compact: return 30
        case .regular: return 40
        case .large: return 40
        case .iPad: return 60
        }
    }
    
    private var gcStatusFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 10
        case .large: return 10
        case .iPad: return 12
        }
    }
    
    // Top menu button sizing functions
    private func topMenuFontSize(for deviceSize: DeviceSize) -> CGFloat {
        switch deviceSize {
        case .compact: return 20
        case .regular: return 24
        case .large: return 24
        case .iPad: return 32
        }
    }
    
    private func topMenuButtonSize(for deviceSize: DeviceSize) -> CGFloat {
        switch deviceSize {
        case .compact: return 35
        case .regular: return 40
        case .large: return 40
        case .iPad: return 55
        }
    }
    
    private func topMenuHorizontalPadding(for deviceSize: DeviceSize) -> CGFloat {
        switch deviceSize {
        case .compact: return 15
        case .regular: return 20
        case .large: return 20
        case .iPad: return 30
        }
    }
    
    private func topMenuTopPadding(for deviceSize: DeviceSize) -> CGFloat {
        switch deviceSize {
        case .compact: return 8
        case .regular: return 10
        case .large: return 10
        case .iPad: return 15
        }
    }
    
    @ViewBuilder
    private var powerUpsSection: some View {
        if powerUpsVisible {
            VStack(spacing: powerUpSpacing) {
                Text("⚡ YOUR POWER-UPS")
                    .font(.system(size: powerUpFontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .tracking(1)
                
                HStack(spacing: powerUpHSpacing) {
                    // Hints Power-up (tappable to open shop)
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingShop = true
                        }
                    }) {
                        VStack(spacing: powerUpIconSpacing) {
                            Text("💡")
                                .font(.system(size: powerUpIconSize))
                            Text("\(gameModel.hintsAvailable)")
                                .font(.system(size: powerUpCountSize, weight: .bold, design: .monospaced))
                                .foregroundColor(gameModel.hintsAvailable <= 2 ? .red : .yellow)
                            Text("HINTS")
                                .font(.system(size: powerUpLabelSize, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, powerUpHPadding)
                        .padding(.vertical, powerUpVPadding)
                        .background(Color.orange.opacity(gameModel.hintsAvailable <= 2 ? 0.8 : 0.3))
                        .overlay(Rectangle().stroke(gameModel.hintsAvailable <= 2 ? Color.red : Color.orange, lineWidth: gameModel.hintsAvailable <= 2 ? 2 : 1))
                        .scaleEffect(gameModel.hintsAvailable <= 2 ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameModel.hintsAvailable <= 2)
                    }
                
                    // Slow Timers Power-up (tappable to open shop)
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingShop = true
                        }
                    }) {
                        VStack(spacing: powerUpIconSpacing) {
                            Text("🐌")
                                .font(.system(size: powerUpIconSize))
                            Text("\(gameModel.slowTimersAvailable)")
                                .font(.system(size: powerUpCountSize, weight: .bold, design: .monospaced))
                                .foregroundColor(gameModel.slowTimersAvailable <= 2 ? .red : .green)
                            Text("SLOW")
                                .font(.system(size: powerUpLabelSize, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, powerUpHPadding)
                        .padding(.vertical, powerUpVPadding)
                        .background(Color.green.opacity(gameModel.slowTimersAvailable <= 2 ? 0.8 : 0.3))
                        .overlay(Rectangle().stroke(gameModel.slowTimersAvailable <= 2 ? Color.red : Color.green, lineWidth: gameModel.slowTimersAvailable <= 2 ? 2 : 1))
                        .scaleEffect(gameModel.slowTimersAvailable <= 2 ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: gameModel.slowTimersAvailable <= 2)
                    }
                }
                
                // Low power-up warning
                if gameModel.hintsAvailable <= 2 || gameModel.slowTimersAvailable <= 2 {
                    Text("⚠️ RUNNING LOW! TAP POWER-UPS TO REFILL")
                        .font(.system(size: powerUpFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        }
    }
    


    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section with title and tagline - moved up to give more space below
                VStack(spacing: logoSpacing) {
                    // Logo image (centered)
                    Image("QuickMathChallenge_Logo_CleanTransparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: logoMaxWidth, maxHeight: logoMaxHeight)
                        .padding(.vertical, 0)
                        .scaleEffect(titlePulse ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: titlePulse)
                    
                    Text("TAP FAST. THINK FASTER.")
                        .font(.system(size: taglineFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .tracking(2)
                }
                .padding(.top, logoPaddingTop)
            
            Spacer()
            
                // Middle section with start button and power-ups
                VStack(spacing: middleSpacing) {
                    // Retro start button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            buttonScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                buttonScale = 1.0
                            }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                gameModel.startGame()
                            }
                        }
                    }) {
                        VStack(spacing: 5) {
                            Text("▶ START GAME")
                                .font(.system(size: buttonFontSize, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(
                            ZStack {
                                Rectangle()
                                    .fill(Color.green)
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: shadowHeight)
                                    .offset(y: -(buttonHeight / 2.4))
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(height: shadowHeight)
                                    .offset(y: (buttonHeight / 2.4))
                            }
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: strokeWidth)
                        )
                    }
                    .scaleEffect(buttonScale)
                    .animation(.easeInOut(duration: 0.1), value: buttonScale)
                
                    // Power-ups display (moved from shop for conversion)
                    powerUpsSection
            }
            
            Spacer()
            
                        // Bottom section with scores and achievements
            VStack(spacing: 15) {
                // High Score Display
                VStack(spacing: 3) {
                    Text("🏆 HIGH SCORE")
                        .font(.system(size: highScoreFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .tracking(1)
                    Text("\(gameModel.bestScore)")
                        .font(.system(size: highScoreNumberSize, weight: .black, design: .monospaced))
                        .foregroundColor(gameModel.bestScore > 0 ? .white : .gray)
                        .animation(.easeInOut(duration: 0.3), value: gameModel.bestScore)
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .background(gameModel.bestScore > 0 ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                .overlay(Rectangle().stroke(gameModel.bestScore > 0 ? Color.white : Color.gray, lineWidth: strokeWidth))
                .animation(.easeInOut(duration: 0.3), value: gameModel.bestScore > 0)
                
                // Share and Leaderboard buttons
                HStack(spacing: buttonSpacing) {
                    ShareLink(item: shareMessage()) {
                        VStack(spacing: 2) {
                            Text("📤")
                                .font(.system(size: smallButtonIconSize))
                            Text("SHARE")
                                .font(.system(size: smallButtonFontSize, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        .frame(width: smallButtonWidth, height: smallButtonHeight)
                        .background(Color.cyan.opacity(gameModel.bestScore > 0 ? 1.0 : 0.6))
                        .overlay(Rectangle().stroke(Color.white, lineWidth: smallStrokeWidth))
                    }
                    .disabled(gameModel.bestScore == 0)
                    
                    Button(action: { 
                        if gameCenterManager.isAuthenticated {
                            gameCenterManager.showLeaderboard()
                        } else {
                            // Retry authentication
                            gameCenterManager.authenticateUser()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text(gameCenterManager.isAuthenticated ? "🏆" : "🔄")
                                .font(.system(size: smallButtonIconSize))
                            Text(gameCenterManager.isAuthenticated ? "LEADERBOARD" : "SIGN IN")
                                .font(.system(size: smallButtonFontSize, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(width: smallButtonWidth, height: smallButtonHeight)
                        .background(Color.yellow.opacity(gameCenterManager.isAuthenticated ? 1.0 : 0.6))
                        .overlay(Rectangle().stroke(Color.white, lineWidth: smallStrokeWidth))
                    }
                }
            }
            }
            .padding(.bottom, bottomPadding)
            .padding(mainPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .top) {
            GeometryReader { geo in
                let topDeviceSize = DeviceSize.classify(geometry: geo)
                HStack {
                    Spacer()
                    Button(action: {
                        showingShop = true
                    }) {
                        Text("⋯")
                            .font(.system(size: topMenuFontSize(for: topDeviceSize), weight: .black))
                            .foregroundColor(.white)
                            .frame(width: topMenuButtonSize(for: topDeviceSize), 
                                   height: topMenuButtonSize(for: topDeviceSize))
                            .background(Color.gray.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    }
                }
                .padding(.horizontal, topMenuHorizontalPadding(for: topDeviceSize))
                .padding(.top, topMenuTopPadding(for: topDeviceSize))
                .background(Color.clear)
            }
            .frame(height: 60)
        }
        .sheet(isPresented: $showingShop) {
            ShopView(gameModel: gameModel, iapManager: iapManager)
        }
        .onAppear {
            // Start title pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                titlePulse = true
            }
            
            // Animate power-ups section in after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    powerUpsVisible = true
                }
            }
            
            // Refresh global rank when returning to menu
            if gameCenterManager.isAuthenticated && gameModel.bestScore > 0 {
                gameCenterManager.fetchUserRank()
            }
        }
    }
    
    private func shareMessage() -> String {
        let streakText = notificationManager.weeklyStreak > 0 ? " (🔥 \(notificationManager.weeklyStreak) week streak!)" : ""
        let appStoreLink = "📱 Get it: https://bit.ly/QuickMathChallenge"
        
        if gameModel.bestScore > 0 {
            return "🎮 Just scored \(gameModel.bestScore) in Quick Math Challenge! Can you beat my high score?\(streakText)\n\n\(appStoreLink) #QuickMathChallenge #BrainTraining"
        } else {
            return "🎮 Check out Quick Math Challenge - the ultimate fast-paced math game! How high can you score?\(streakText)\n\n\(appStoreLink) #QuickMathChallenge #BrainTraining"
        }
    }
}

struct ShopView: View {
    @ObservedObject var gameModel: GameModel
    @ObservedObject var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same retro background as main app
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("💳 SHOP")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                        .tracking(2)
                    
                    // Loading/Error state indicator
                    if !iapManager.pricesLoaded {
                        VStack(spacing: 10) {
                            if iapManager.removeAdsPrice == "Error" {
                                VStack(spacing: 8) {
                                    Text("⚠️ FAILED TO LOAD PRICES")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red)
                                    
                                    Button(action: {
                                        iapManager.retryLoadingProducts()
                                    }) {
                                        Text("🔄 RETRY")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.8))
                                            .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text("⏳")
                                        .font(.system(size: 16))
                                    Text("LOADING PRICES...")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    VStack(spacing: 20) {
                        // Remove Ads Button (if not purchased)
                        if !iapManager.adsRemoved {
                            Button(action: {
                                iapManager.purchaseRemoveAds()
                            }) {
                                HStack(spacing: 15) {
                                    Text("🚫")
                                        .font(.system(size: 24))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("REMOVE ADS")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(.yellow)
                                        Text("No more interruptions!")
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Group {
                                        if iapManager.pricesLoaded {
                                            Text(iapManager.removeAdsPrice)
                                        } else {
                                            Text("Loading...")
                                                .opacity(0.7)
                                        }
                                    }
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(Color.purple.opacity(0.8))
                                .overlay(Rectangle().stroke(Color.yellow, lineWidth: 2))
                            }
                            .disabled(iapManager.isLoading || !iapManager.pricesLoaded)
                            .opacity(iapManager.isLoading || !iapManager.pricesLoaded ? 0.6 : 1.0)
                        }
                        
                        // Hints IAP
                        Button(action: {
                            iapManager.purchaseHints { count in
                                gameModel.addHints(count)
                            }
                        }) {
                            HStack(spacing: 15) {
                                Text("💡")
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("10 HINTS")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                    Text("Auto-removes wrong answers at 2s!")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Group {
                                    if iapManager.pricesLoaded {
                                        Text(iapManager.hintsPrice)
                                    } else {
                                        Text("Loading...")
                                            .opacity(0.7)
                                    }
                                }
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.orange.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                        }
                        .disabled(iapManager.isLoading || !iapManager.pricesLoaded)
                        .opacity(iapManager.isLoading || !iapManager.pricesLoaded ? 0.6 : 1.0)
                        
                        // Slow Timers IAP
                        Button(action: {
                            iapManager.purchaseSlowTimers { count in
                                gameModel.addSlowTimers(count)
                            }
                        }) {
                            HStack(spacing: 15) {
                                Text("🐌")
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("10 SLOW TIMERS")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("Slows down timer by 20%!")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Group {
                                    if iapManager.pricesLoaded {
                                        Text(iapManager.slowTimersPrice)
                                    } else {
                                        Text("Loading...")
                                            .opacity(0.7)
                                    }
                                }
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.green.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                        }
                        .disabled(iapManager.isLoading || !iapManager.pricesLoaded)
                        .opacity(iapManager.isLoading || !iapManager.pricesLoaded ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Restore Purchases Button (moved to bottom with same styling as other buttons)
                    Button(action: {
                        iapManager.restorePurchases()
                    }) {
                        HStack(spacing: 15) {
                            Text("🔄")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RESTORE PURCHASES")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Get back your previous purchases")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.gray.opacity(0.8))
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    }
                    .disabled(iapManager.isLoading)
                    .opacity(iapManager.isLoading ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("✕")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Color.red.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .background(Color.clear)
            }
        }
    }
}

struct GameView: View {
    @ObservedObject var gameModel: GameModel
    let deviceSize: DeviceSize
    @State private var flashRed = false
    @State private var questionScale = 1.0
    @State private var answerButtonsVisible = false
    
    // Computed properties for responsive design
    private var gameViewMainPadding: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 15
        case .large: return 15
        case .iPad: return 30
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = {
                switch deviceSize {
                case .compact: return 20.0
                case .regular: return 25.0
                case .large: return 30.0
                case .iPad: return 35.0
                }
            }()
            let fontSize: CGFloat = {
                switch deviceSize {
                case .compact: return 48.0
                case .regular: return 56.0
                case .large: return 62.0
                case .iPad: return 68.0
                }
            }()
            let buttonHeight: CGFloat = {
                switch deviceSize {
                case .compact: return 50.0
                case .regular: return 55.0
                case .large: return 60.0
                case .iPad: return 65.0
                }
            }()
            let horizontalPadding: CGFloat = {
                switch deviceSize {
                case .compact: return 15.0
                case .regular: return 20.0
                case .large: return 25.0
                case .iPad: return 40.0
                }
            }()
            
            VStack(spacing: spacing) {
            // Retro HUD
            let hudSpacing: CGFloat = {
                switch deviceSize {
                case .compact: return 8
                case .regular: return 10
                case .large: return 12
                case .iPad: return 15
                }
            }()
            let hudItemSpacing: CGFloat = {
                switch deviceSize {
                case .compact: return 12
                case .regular: return 16
                case .large: return 18
                case .iPad: return 20
                }
            }()
            
            let hudBoxWidth: CGFloat = {
                switch deviceSize {
                case .compact: return 60
                case .regular: return 80
                case .large: return 80
                case .iPad: return 120
                }
            }()
            let hudBoxHeight: CGFloat = {
                switch deviceSize {
                case .compact: return 40
                case .regular: return 50
                case .large: return 50
                case .iPad: return 70
                }
            }()
            let hudLabelFont: CGFloat = {
                switch deviceSize {
                case .compact: return 8
                case .regular: return 10
                case .large: return 10
                case .iPad: return 14
                }
            }()
            let hudValueFont: CGFloat = {
                switch deviceSize {
                case .compact: return 16
                case .regular: return 20
                case .large: return 20
                case .iPad: return 28
                }
            }()
            
            VStack(spacing: hudSpacing) {
                HStack(spacing: hudItemSpacing) {
                    // Score display
                    VStack(spacing: 2) {
                        Text("SCORE")
                            .font(.system(size: hudLabelFont, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text("\(gameModel.score)")
                            .font(.system(size: hudValueFont, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: hudBoxWidth, height: hudBoxHeight)
                    .background(Color.blue.opacity(0.8))
                    .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    
                    Spacer()
                    
                    // Lives display (8-bit hearts) - FIXED FOR COMPRESSION
                    let heartSpacing: CGFloat = {
                        switch deviceSize {
                        case .compact: return 4
                        case .regular: return 8
                        case .large: return 10
                        case .iPad: return 12
                        }
                    }()
                    let heartSize: CGFloat = {
                        switch deviceSize {
                        case .compact: return 20
                        case .regular: return 24
                        case .large: return 26
                        case .iPad: return 32
                        }
                    }()
                    let heartHPadding: CGFloat = {
                        switch deviceSize {
                        case .compact: return 8
                        case .regular: return 15
                        case .large: return 20
                        case .iPad: return 25
                        }
                    }()
                    let heartVPadding: CGFloat = {
                        switch deviceSize {
                        case .compact: return 6
                        case .regular: return 10
                        case .large: return 12
                        case .iPad: return 15
                        }
                    }()
                    
                    HStack(spacing: heartSpacing) {
                        ForEach(0..<3, id: \.self) { index in
                            Text(index < gameModel.lives ? "♥" : "♡")
                                .font(.system(size: heartSize, weight: .black))
                                .foregroundColor(index < gameModel.lives ? .red : .gray)
                        }
                    }
                    .padding(.horizontal, heartHPadding)
                    .padding(.vertical, heartVPadding)
                    .background(Color.black.opacity(0.8))
                    .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    
                    Spacer()
                    
                    // Timer display
                    VStack(spacing: 2) {
                        Text("TIME")
                            .font(.system(size: hudLabelFont, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        Text("\(Int(gameModel.timeRemaining))")
                            .font(.system(size: hudValueFont, weight: .black, design: .monospaced))
                            .foregroundColor(gameModel.timeRemaining <= 2 ? .red : .white)
                    }
                    .frame(width: hudBoxWidth, height: hudBoxHeight)
                    .background(Color.purple.opacity(0.8))
                    .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                }
                
                // Power-ups HUD
                HStack(spacing: 15) {
                    // Hints display
                    HStack(spacing: 5) {
                        Text("💡")
                            .font(.system(size: 16))
                        Text("\(gameModel.hintsAvailable)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.8))
                    .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
                    
                    Spacer()
                    
                    // Slow Timer Button
                    Button(action: {
                        gameModel.activateSlowTimer()
                    }) {
                        HStack(spacing: 5) {
                            Text("🐌")
                                .font(.system(size: 16))
                            if gameModel.slowTimerActive {
                                Text("\(gameModel.slowTimerQuestionsRemaining)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(gameModel.slowTimersAvailable)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(gameModel.slowTimerActive ? Color.green.opacity(0.8) : Color.gray.opacity(0.8))
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
                    }
                    .disabled(gameModel.slowTimersAvailable <= 0 || gameModel.slowTimerActive)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Math Question Display
            VStack(spacing: 15) {
                let questionVPadding: CGFloat = {
                    switch deviceSize {
                    case .compact: return 10
                    case .regular: return 15
                    case .large: return 17
                    case .iPad: return 20
                    }
                }()
                let questionStroke: CGFloat = {
                    switch deviceSize {
                    case .compact: return 2
                    case .regular: return 3
                    case .large: return 3
                    case .iPad: return 4
                    }
                }()
                
                Text(gameModel.currentQuestion.questionText)
                    .font(.system(size: fontSize, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, questionVPadding)
                    .background(Color.black.opacity(0.9))
                    .overlay(
                        Rectangle()
                            .stroke(Color.cyan, lineWidth: questionStroke)
                    )
                    .scaleEffect(questionScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: questionScale)
                
                // Retro timer bar
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { index in
                        Rectangle()
                            .fill(index < Int(gameModel.timeRemaining * 4) ?
                                  (gameModel.timeRemaining <= 2 ? Color.red : Color.green) :
                                  Color.gray.opacity(0.3))
                            .frame(width: 12, height: 8)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Retro Answer Buttons
            VStack(spacing: 12) {
                ForEach(Array(gameModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            questionScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                questionScale = 1.0
                            }
                            gameModel.selectAnswer(option)
                        }
                    }) {
                        let answerFontSize: CGFloat = {
                            switch deviceSize {
                            case .compact: return 20
                            case .regular: return 24
                            case .large: return 26
                            case .iPad: return 32
                            }
                        }()
                        
                        Text("[\(String(option))]")
                            .font(.system(size: answerFontSize, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(height: buttonHeight)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, horizontalPadding)
                            .background(
                                ZStack {
                                    Rectangle()
                                        .fill(retroButtonColor(for: index))
                                    // 8-bit button highlight
                                    Rectangle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(height: 4)
                                        .offset(y: -22)
                                    // 8-bit button shadow
                                    Rectangle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(height: 4)
                                        .offset(y: 22)
                                }
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    }
                    .disabled(gameModel.gameState != .playing)
                    .opacity(answerButtonsVisible ? 1.0 : 0.0)
                    .offset(x: answerButtonsVisible ? 0 : -50)
                    .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.1), value: answerButtonsVisible)
                }
            }
            .padding(.horizontal, horizontalPadding)
            
                Spacer()
            }
            .padding(gameViewMainPadding)
            .overlay(
                // Red flash effect for wrong answers
                Rectangle()
                    .fill(Color.red.opacity(flashRed ? 0.3 : 0))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: flashRed)
            )
            .onChange(of: gameModel.wrongAnswerTrigger) {
                // Flash red when wrong answer
                flashRed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    flashRed = false
                }
            }
            .onChange(of: gameModel.currentQuestion.questionText) {
                // Animate new question
                withAnimation(.easeInOut(duration: 0.2)) {
                    answerButtonsVisible = false
                    questionScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        questionScale = 1.0
                        answerButtonsVisible = true
                    }
                }
            }
            .onAppear {
                // Initial animation when game starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        answerButtonsVisible = true
                        questionScale = 1.0
                    }
                }
            }
        }
    }
    
    private func retroButtonColor(for index: Int) -> Color {
        let colors: [Color] = [.orange, .pink, .cyan]
        return colors[index % colors.count]
    }
}

struct GameOverView: View {
    @ObservedObject var gameModel: GameModel
    @ObservedObject var adManager: AdManager
    @ObservedObject var iapManager: IAPManager
    let deviceSize: DeviceSize
    
    // Computed properties for responsive design
    private var gameOverTitleFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 14
        case .regular: return 16
        case .large: return 16
        case .iPad: return 22
        }
    }
    
    private var gameOverHPadding: CGFloat {
        switch deviceSize {
        case .compact: return 20
        case .regular: return 30
        case .large: return 30
        case .iPad: return 40
        }
    }
    
    private var gameOverVPadding: CGFloat {
        switch deviceSize {
        case .compact: return 10
        case .regular: return 15
        case .large: return 15
        case .iPad: return 20
        }
    }
    
    private var gameOverStrokeWidth: CGFloat {
        switch deviceSize {
        case .compact: return 2
        case .regular: return 3
        case .large: return 3
        case .iPad: return 4
        }
    }
    
    private var continueButtonFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 14
        case .regular: return 16
        case .large: return 16
        case .iPad: return 22
        }
    }
    
    private var continueButtonHPadding: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 15
        case .large: return 15
        case .iPad: return 20
        }
    }
    
    private var continueButtonVPadding: CGFloat {
        switch deviceSize {
        case .compact: return 6
        case .regular: return 8
        case .large: return 8
        case .iPad: return 12
        }
    }
    
    private var continueButtonStrokeWidth: CGFloat {
        switch deviceSize {
        case .compact: return 1
        case .regular: return 2
        case .large: return 2
        case .iPad: return 3
        }
    }
    
    private var continueButtonScale: CGFloat {
        switch deviceSize {
        case .compact: return 1.05
        case .regular: return 1.1
        case .large: return 1.1
        case .iPad: return 1.1
        }
    }
    
    private var actionButtonFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 12
        case .regular: return 14
        case .large: return 14
        case .iPad: return 18
        }
    }
    
    private var menuButtonFontSize: CGFloat {
        switch deviceSize {
        case .compact: return 13
        case .regular: return 16
        case .large: return 16
        case .iPad: return 20
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let titleFontSize: CGFloat = {
                switch deviceSize {
                case .compact: return 28
                case .regular: return 32
                case .large: return 38
                case .iPad: return 44
                }
            }()
            let scoreFontSize: CGFloat = {
                switch deviceSize {
                case .compact: return 32
                case .regular: return 40
                case .large: return 48
                case .iPad: return 56
                }
            }()
            let buttonWidth: CGFloat = {
                switch deviceSize {
                case .compact: return 200
                case .regular: return 220
                case .large: return 250
                case .iPad: return 280
                }
            }()
            let buttonHeight: CGFloat = {
                switch deviceSize {
                case .compact: return 45
                case .regular: return 50
                case .large: return 55
                case .iPad: return 65
                }
            }()
            let spacing: CGFloat = {
                switch deviceSize {
                case .compact: return 25
                case .regular: return 35
                case .large: return 40
                case .iPad: return 45
                }
            }()
            
            VStack(spacing: spacing) {
                let titleSpacing: CGFloat = {
                    switch deviceSize {
                    case .compact: return 15
                    case .regular: return 20
                    case .large: return 22
                    case .iPad: return 25
                    }
                }()
                let scoreSpacing: CGFloat = {
                    switch deviceSize {
                    case .compact: return 8
                    case .regular: return 10
                    case .large: return 12
                    case .iPad: return 15
                    }
                }()
                
                VStack(spacing: titleSpacing) {
                    Text("GAME OVER")
                        .font(.system(size: titleFontSize, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                    
                    VStack(spacing: scoreSpacing) {
                        Text("FINAL SCORE")
                            .font(.system(size: gameOverTitleFontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        
                        Text("\(gameModel.score)")
                            .font(.system(size: scoreFontSize, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, gameOverHPadding)
                            .padding(.vertical, gameOverVPadding)
                            .background(Color.blue.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.white, lineWidth: gameOverStrokeWidth))
                    }
                
                    if gameModel.score == gameModel.bestScore && gameModel.score > 0 {
                        Text("★ NEW HIGH SCORE! ★")
                            .font(.system(size: continueButtonFontSize, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, continueButtonHPadding)
                            .padding(.vertical, continueButtonVPadding)
                            .background(Color.red.opacity(0.8))
                            .overlay(Rectangle().stroke(Color.yellow, lineWidth: continueButtonStrokeWidth))
                            .scaleEffect(continueButtonScale)
                    }
                }
                
                let buttonSpacing: CGFloat = {
                    switch deviceSize {
                    case .compact: return 12
                    case .regular: return 15
                    case .large: return 17
                    case .iPad: return 20
                    }
                }()
                
                VStack(spacing: buttonSpacing) {
                    // Share Score Button
                    ShareLink(item: shareGameOverMessage()) {
                        Text("📤 SHARE SCORE")
                            .font(.system(size: actionButtonFontSize, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .background(
                                ZStack {
                                    Rectangle()
                                        .fill(Color.cyan)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                        .offset(y: -(buttonHeight / 2.5))
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                        .offset(y: (buttonHeight / 2.5))
                                }
                            )
                            .overlay(Rectangle().stroke(Color.white, lineWidth: deviceSize == .iPad ? 4 : deviceSize == .compact ? 2 : 3))
                    }
                
                    // Continue with Ad Button (if ads not removed and haven't used extra life yet)
                    // Debug: Show current state
                    if !iapManager.adsRemoved && !gameModel.hasUsedExtraLife {
                        if adManager.rewardedAdReady {
                            Button(action: {
                                adManager.showRewardedAd { success in
                                    if success {
                                        gameModel.continueWithExtraLife()
                                    }
                                }
                            }) {
                                Text("📺 CONTINUE (+1 LIFE)")
                                    .font(.system(size: menuButtonFontSize, weight: .black, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: buttonWidth, height: buttonHeight)
                                    .background(
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.yellow)
                                            Rectangle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                                .offset(y: -(buttonHeight / 2.5))
                                            Rectangle()
                                                .fill(Color.black.opacity(0.3))
                                                .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                                .offset(y: (buttonHeight / 2.5))
                                        }
                                    )
                                    .overlay(Rectangle().stroke(Color.white, lineWidth: deviceSize == .iPad ? 4 : deviceSize == .compact ? 2 : 3))
                            }
                        } else {
                            // Show debug message when ad not ready
                            VStack(spacing: 5) {
                                Text("📺 AD LOADING...")
                                    .font(.system(size: deviceSize == .iPad ? 16 : deviceSize == .compact ? 10 : 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.yellow)
                                Text("Please wait for ad to load")
                                    .font(.system(size: deviceSize == .iPad ? 12 : deviceSize == .compact ? 8 : 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.2))
                            .overlay(Rectangle().stroke(Color.yellow, lineWidth: 2))
                        }
                    } else if !iapManager.adsRemoved && gameModel.hasUsedExtraLife {
                        // Show message that they've already used their continuation
                        VStack(spacing: 5) {
                            Text("⚠️ CONTINUATION USED")
                                .font(.system(size: deviceSize == .iPad ? 16 : deviceSize == .compact ? 10 : 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                            Text("ONE EXTRA LIFE PER GAME")
                                .font(.system(size: deviceSize == .iPad ? 12 : deviceSize == .compact ? 8 : 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.2))
                        .overlay(Rectangle().stroke(Color.orange, lineWidth: 2))
                    }
                
                    // Try Again Button
                    Button(action: {
                        // Show interstitial ad before restarting (if ads not removed)
                        if !iapManager.adsRemoved {
                            adManager.showInterstitialAd {
                                gameModel.startGame()
                            }
                        } else {
                            gameModel.startGame()
                        }
                    }) {
                        Text("◄ TRY AGAIN ►")
                            .font(.system(size: deviceSize == .iPad ? 24 : deviceSize == .compact ? 15 : 18, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(width: buttonWidth, height: buttonHeight)
                            .background(
                                ZStack {
                                    Rectangle()
                                        .fill(Color.green)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                        .offset(y: -(buttonHeight / 2.5))
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(height: deviceSize == .iPad ? 6 : deviceSize == .compact ? 3 : 4)
                                        .offset(y: (buttonHeight / 2.5))
                                }
                            )
                            .overlay(Rectangle().stroke(Color.white, lineWidth: deviceSize == .iPad ? 4 : deviceSize == .compact ? 2 : 3))
                    }
                
                    // Menu Button
                    Button(action: {
                        gameModel.backToMenu()
                    }) {
                        Text("MAIN MENU")
                            .font(.system(size: deviceSize == .iPad ? 18 : deviceSize == .compact ? 12 : 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .underline()
                    }
                }
            }
            .padding(deviceSize == .iPad ? 30 : deviceSize == .compact ? 10 : 15)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load ads when game over screen appears
            print("🎮 Game Over screen appeared - loading ads")
            adManager.loadAds()
            
            // Also try to load ads again after a short delay if not ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !adManager.rewardedAdReady {
                    print("🔄 Rewarded ad still not ready - trying again")
                    adManager.loadRewardedAd()
                }
            }
        }
    }
    
    private func shareGameOverMessage() -> String {
        let isNewRecord = gameModel.score == gameModel.bestScore && gameModel.score > 0
        let recordText = isNewRecord ? " 🎉 NEW RECORD!" : ""
        let appStoreLink = "📱 Get it: https://bit.ly/QuickMathChallenge"
        return "🎮 Just scored \(gameModel.score) in Quick Math Challenge!\(recordText) Can you beat my score?\n\n\(appStoreLink) #QuickMathChallenge #BrainTraining #MathGame"
    }
}

// MARK: - Game Model

enum GameState {
    case menu, playing, gameOver
}

struct MathQuestion {
    let questionText: String
    let correctAnswer: Int
    let options: [Int]
}

class GameModel: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var timeRemaining: Double = 5.0
    @Published var currentQuestion: MathQuestion = MathQuestion(questionText: "", correctAnswer: 0, options: [])
    @Published var wrongAnswerTrigger: Bool = false
    @Published var hintsAvailable: Int {
        didSet {
            UserDefaults.standard.set(hintsAvailable, forKey: "HintsAvailable")
        }
    }
    @Published var slowTimersAvailable: Int {
        didSet {
            UserDefaults.standard.set(slowTimersAvailable, forKey: "SlowTimersAvailable")
        }
    }
    @Published var slowTimerActive: Bool = false
    @Published var slowTimerQuestionsRemaining: Int = 0
    @Published var hintUsedThisQuestion: Bool = false
    @Published var hasUsedExtraLife: Bool = false // Track if player used ad continuation this session
    @Published var achievedNewBestThisSession: Bool = false // Track if best score was updated this session
    @Published var bestScore: Int {
        didSet {
            UserDefaults.standard.set(bestScore, forKey: "BestScore")
        }
    }
    
    private var timer: Timer?
    private var notificationManager: NotificationManager?
    private var gameCenterManager: GameCenterManager?
    
    init() {
        self.bestScore = UserDefaults.standard.integer(forKey: "BestScore")
        self.hintsAvailable = UserDefaults.standard.integer(forKey: "HintsAvailable")
        self.slowTimersAvailable = UserDefaults.standard.integer(forKey: "SlowTimersAvailable")
        generateNewQuestion()
    }
    
    func setNotificationManager(_ manager: NotificationManager) {
        self.notificationManager = manager
    }
    
    func setGameCenterManager(_ manager: GameCenterManager) {
        self.gameCenterManager = manager
    }
    
    func startGame() {
        gameState = .playing
        score = 0
        lives = 3
        timeRemaining = 5.0
        slowTimerActive = false
        slowTimerQuestionsRemaining = 0
        hintUsedThisQuestion = false
        hasUsedExtraLife = false // Reset extra life tracking for new game
        achievedNewBestThisSession = false // Reset best score tracking for new game
        
        // Track play session for weekly streak
        trackPlaySession()
        
        generateNewQuestion()
        startTimer()
    }
    
    private func trackPlaySession() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: "LastPlayDate")
        notificationManager?.updateStreakOnPlay()
    }
    
    func backToMenu() {
        // If coming from game over and hasn't used extra life, submit score now
        if gameState == .gameOver && !hasUsedExtraLife {
            submitFinalScore()
        }
        
        gameState = .menu
        stopTimer()
    }
    
    private func submitFinalScore() {
        // Submit the current session's score to Game Center
        let sessionScore = score
        print("🎮 Submitting final session score to Game Center: \(sessionScore)")
        
        if achievedNewBestThisSession {
            print("🏆 New best score achieved this session!")
        }
        
        Task { @MainActor in
            gameCenterManager?.submitScore(sessionScore)
        }
    }
    
    func continueWithExtraLife() {
        // Continue game with one extra life from rewarded ad
        lives = 1
        gameState = .playing
        hasUsedExtraLife = true // Mark that player has used extra life continuation
        stopTimer() // Ensure any existing timer is stopped
        nextQuestion()
    }
    
    func activateSlowTimer() {
        guard slowTimersAvailable > 0 && !slowTimerActive && gameState == .playing else { return }
        slowTimersAvailable -= 1
        slowTimerActive = true
        slowTimerQuestionsRemaining = 3 // Slow timer lasts for 3 questions
        playCorrectSound() // Give positive feedback
        playHapticFeedback(.success)
    }
    
    func addHints(_ count: Int) {
        hintsAvailable += count
    }
    
    func addSlowTimers(_ count: Int) {
        slowTimersAvailable += count
    }
    
    func selectAnswer(_ answer: Int) {
        guard gameState == .playing else { return }
        
        stopTimer()
        
        if answer == currentQuestion.correctAnswer {
            // Correct answer - Play success sound & haptic
            playCorrectSound()
            playHapticFeedback(.success)
            score += 1
            if score > bestScore {
                bestScore = score
                achievedNewBestThisSession = true
                // Don't submit to Game Center immediately - wait for session end
                // This prevents multiple submissions during a single game session
            }
            nextQuestion()
        } else {
            // Wrong answer - Play error sound, haptic, and trigger red flash
            playWrongSound()
            playHapticFeedback(.error)
            triggerWrongAnswerFlash()
            lives -= 1
            if lives <= 0 {
                gameOver()
            } else {
                nextQuestion()
            }
        }
    }
    
    private func nextQuestion() {
        generateNewQuestion()
        hintUsedThisQuestion = false
        
        // Manage slow timer duration
        if slowTimerActive {
            slowTimerQuestionsRemaining -= 1
            if slowTimerQuestionsRemaining <= 0 {
                slowTimerActive = false
                slowTimerQuestionsRemaining = 0
            }
        }
        
        // Progressive timer difficulty - gets faster as score increases
        let difficultyLevel = min(score / 5, 4)
        let baseTime = 5.0 - (Double(difficultyLevel) * 0.3) // 5.0→4.7→4.4→4.1→3.8 seconds
        timeRemaining = max(baseTime, 3.0) // Never go below 3 seconds
        startTimer()
    }
    
    private func generateNewQuestion() {
        // Progressive difficulty based on score
        let difficultyLevel = min(score / 5, 4) // Increase difficulty every 5 points, max level 4
        let baseRange = 10 + (difficultyLevel * 5) // Range grows: 10→15→20→25→30
        let multiRange = 5 + (difficultyLevel * 2) // Multiplication range: 5→7→9→11→13
        
        // Add division at higher levels
        var operations = ["+", "-", "×"]
        if difficultyLevel >= 2 {
            operations.append("÷")
        }
        
        let num1 = Int.random(in: 1...baseRange)
        let num2 = Int.random(in: 1...baseRange)
        let operation = operations.randomElement()!
        
        let correctAnswer: Int
        let questionText: String
        
        switch operation {
        case "+":
            correctAnswer = num1 + num2
            questionText = "\(num1) + \(num2)"
        case "-":
            let larger = max(num1, num2)
            let smaller = min(num1, num2)
            correctAnswer = larger - smaller
            questionText = "\(larger) - \(smaller)"
        case "×":
            let smallNum1 = Int.random(in: 1...multiRange)
            let smallNum2 = Int.random(in: 1...multiRange)
            correctAnswer = smallNum1 * smallNum2
            questionText = "\(smallNum1) × \(smallNum2)"
        case "÷":
            // Generate division problems that result in whole numbers
            let divisor = Int.random(in: 2...10)
            let quotient = Int.random(in: 2...15)
            let dividend = divisor * quotient
            correctAnswer = quotient
            questionText = "\(dividend) ÷ \(divisor)"
        default:
            correctAnswer = num1 + num2
            questionText = "\(num1) + \(num2)"
        }
        
        // Generate wrong answers
        var options: [Int] = [correctAnswer]
        
        while options.count < 3 {
            let wrongAnswer = correctAnswer + Int.random(in: -10...10)
            if wrongAnswer != correctAnswer && wrongAnswer > 0 && !options.contains(wrongAnswer) {
                options.append(wrongAnswer)
            }
        }
        
        options.shuffle()
        
        currentQuestion = MathQuestion(
            questionText: questionText,
            correctAnswer: correctAnswer,
            options: options
        )
    }
    
    private func startTimer() {
        stopTimer() // Always stop any existing timer first
        let interval = slowTimerActive ? 0.125 : 0.1 // 20% slower when power-up active
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                self.timeRemaining -= 0.1
                
                // Auto-activate hint at 2 seconds if available and not used
                if self.timeRemaining <= 2.0 && !self.hintUsedThisQuestion && self.hintsAvailable > 0 && self.currentQuestion.options.count > 2 {
                    self.activateHint()
                }
                
                if self.timeRemaining <= 0 {
                    self.timeUp()
                }
            }
        }
    }
    
    private func activateHint() {
        guard !hintUsedThisQuestion && hintsAvailable > 0 && currentQuestion.options.count > 2 else { return }
        
        hintsAvailable -= 1
        hintUsedThisQuestion = true
        
        // Remove one wrong answer
        var newOptions = currentQuestion.options
        if let wrongAnswerIndex = newOptions.firstIndex(where: { $0 != currentQuestion.correctAnswer }) {
            newOptions.remove(at: wrongAnswerIndex)
            currentQuestion = MathQuestion(
                questionText: currentQuestion.questionText,
                correctAnswer: currentQuestion.correctAnswer,
                options: newOptions
            )
        }
        
        // Give feedback
        playCorrectSound()
        playHapticFeedback(.success)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeUp() {
        stopTimer()
        // Timeout - same feedback as wrong answer
        playWrongSound()
        playHapticFeedback(.error)
        triggerWrongAnswerFlash()
        lives -= 1
        if lives <= 0 {
            gameOver()
        } else {
            nextQuestion()
        }
    }
    
    private func gameOver() {
        gameState = .gameOver
        stopTimer()
        
        // Only submit score if this is the final game over
        // (either they haven't used extra life, or they have and this is their second death)
        if !hasUsedExtraLife {
            // This is their first death - don't submit yet, they might watch an ad
            print("🎮 First death - not submitting score yet (might continue with ad)")
        } else {
            // They already used extra life and died again - submit final score
            print("🎮 Final death after ad continuation - submitting score: \(score)")
            Task { @MainActor in
                gameCenterManager?.submitScore(score)
            }
        }
        
        // Game over sound - "Sad trombone" effect
        playGameOverSound()
        playHapticFeedback(.error)
    }
    
    // MARK: - Sound & Feedback Effects
    
    private func playCorrectSound() {
        // iOS system sound for success - "Ding"
        AudioServicesPlaySystemSound(1103) // Tink sound
    }
    
    private func playWrongSound() {
        // iOS system sound for error - "Buzz"
        AudioServicesPlaySystemSound(1107) // Tock sound
    }
    
    private func playGameOverSound() {
        // iOS system sound for game over - "Sad trombone" effect
        AudioServicesPlaySystemSound(1006) // Camera shutter (closest to "sad trombone")
    }
    
    private func playHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(type)
    }
    
    private func triggerWrongAnswerFlash() {
        wrongAnswerTrigger.toggle()
    }
}

// MARK: - Ad Manager

class AdManager: NSObject, ObservableObject {
    @Published var interstitialAdReady = false
    @Published var rewardedAdReady = false
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    
    // Real AdMob Ad Unit IDs
    private let interstitialAdUnitID = "ca-app-pub-4564366280351525/6480774092"
    private let rewardedAdUnitID = "ca-app-pub-4564366280351525/6480774092" // Using same ID - create separate rewarded ad unit if needed
    
    override init() {
        super.init()
        
        // Initialize AdMob
        MobileAds.shared.start(completionHandler: { _ in })
        loadAds()
    }
    
    func loadAds() {
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    private func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.interstitialAdReady = false
                } else {
                    print("✅ Interstitial ad loaded successfully")
                    self?.interstitialAd = ad
                    self?.interstitialAdReady = true
                    ad?.fullScreenContentDelegate = self
                }
            }
        }
    }
    
    func loadRewardedAd() {
        #if targetEnvironment(simulator)
        // In simulator, ads don't load properly, so simulate ready state
        print("🔧 Simulator detected - simulating rewarded ad ready")
        DispatchQueue.main.async {
            self.rewardedAdReady = true
        }
        return
        #endif
        
        print("🔄 Loading rewarded ad...")
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to load rewarded ad: \(error.localizedDescription)")
                    self?.rewardedAdReady = false
                    
                    // Retry loading after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        print("🔄 Retrying rewarded ad load...")
                        self?.loadRewardedAd()
                    }
                } else {
                    print("✅ Rewarded ad loaded successfully")
                    self?.rewardedAd = ad
                    self?.rewardedAdReady = true
                    ad?.fullScreenContentDelegate = self
                }
            }
        }
    }
    
    func showInterstitialAd(completion: @escaping () -> Void) {
        guard let interstitialAd = interstitialAd else {
            print("⚠️ Interstitial ad not ready")
            completion()
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion()
            return
        }
        
        // Store completion for later use
        self.interstitialCompletion = completion
        interstitialAd.present(from: rootViewController)
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        // In simulator, ads don't work properly, so simulate successful ad watch
        print("🔧 Simulator detected - simulating successful ad watch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true)
        }
        return
        #endif
        
        guard let rewardedAd = rewardedAd else {
            print("⚠️ Rewarded ad not ready")
            completion(false)
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        // Store completion for later use
        self.rewardedCompletion = completion
        rewardedAd.present(from: rootViewController) { [weak self] in
            // User earned reward
            print("✅ User earned reward!")
            self?.rewardedCompletion?(true)
        }
    }
    
    // Store completion handlers
    private var interstitialCompletion: (() -> Void)?
    private var rewardedCompletion: ((Bool) -> Void)?
}

// MARK: - GADFullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Ad dismissed")
        
        if ad is InterstitialAd {
            interstitialCompletion?()
            interstitialCompletion = nil
            loadInterstitialAd() // Load next ad
        } else if ad is RewardedAd {
            // Rewarded ad completion is handled in showRewardedAd
            loadRewardedAd() // Load next ad
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        
        if ad is InterstitialAd {
            interstitialCompletion?()
            interstitialCompletion = nil
        } else if ad is RewardedAd {
            rewardedCompletion?(false)
            rewardedCompletion = nil
        }
    }
}

// MARK: - IAP Manager

class IAPManager: NSObject, ObservableObject {
    @Published var adsRemoved: Bool {
        didSet {
            UserDefaults.standard.set(adsRemoved, forKey: "AdsRemoved")
        }
    }
    @Published var isLoading = false
    @Published var pricesLoaded = false
    @Published var removeAdsPrice = "Loading..."
    @Published var hintsPrice = "Loading..."
    @Published var slowTimersPrice = "Loading..."
    
    private let removeAdsProductID = "com.quickmathchallenge.removeads"
    private let hintsProductID = "com.quickmathchallenge.hintsten"
    private let slowTimersProductID = "com.quickmathchallenge.slowtimersten"
    
    private var products: [SKProduct] = []
    private var hintsCompletion: ((Int) -> Void)?
    private var slowTimersCompletion: ((Int) -> Void)?
    
    override init() {
        self.adsRemoved = UserDefaults.standard.bool(forKey: "AdsRemoved")
        super.init()
        
        SKPaymentQueue.default().add(self)
        loadProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func loadProducts() {
        pricesLoaded = false
        let productIDs = Set([removeAdsProductID, hintsProductID, slowTimersProductID])
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
        print("📱 Loading IAP Products from StoreKit")
    }
    
    func retryLoadingProducts() {
        print("🔄 Retrying to load IAP products...")
        removeAdsPrice = "Loading..."
        hintsPrice = "Loading..."
        slowTimersPrice = "Loading..."
        loadProducts()
    }
    
    func purchaseRemoveAds() {
        guard !isLoading else { return }
        guard let product = products.first(where: { $0.productIdentifier == removeAdsProductID }) else {
            print("❌ Remove Ads product not found")
            return
        }
        
        purchase(product: product)
    }
    
    func purchaseHints(completion: @escaping (Int) -> Void) {
        guard !isLoading else { return }
        guard let product = products.first(where: { $0.productIdentifier == hintsProductID }) else {
            print("❌ Hints product not found")
            return
        }
        
        hintsCompletion = completion
        purchase(product: product)
    }
    
    func purchaseSlowTimers(completion: @escaping (Int) -> Void) {
        guard !isLoading else { return }
        guard let product = products.first(where: { $0.productIdentifier == slowTimersProductID }) else {
            print("❌ Slow Timers product not found")
            return
        }
        
        slowTimersCompletion = completion
        purchase(product: product)
    }
    
    private func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            print("❌ Payments not allowed")
            return
        }
        
        isLoading = true
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("💳 Processing purchase for: \(product.localizedTitle)")
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
        print("🔄 Restoring Purchases...")
    }
    
    private func priceString(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "$0.00"
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            
            // Update prices with actual StoreKit prices
            for product in response.products {
                let price = self.priceString(for: product)
                
                switch product.productIdentifier {
                case self.removeAdsProductID:
                    self.removeAdsPrice = price
                case self.hintsProductID:
                    self.hintsPrice = price
                case self.slowTimersProductID:
                    self.slowTimersPrice = price
                default:
                    break
                }
            }
            
            // Mark prices as loaded
            self.pricesLoaded = true
            
            print("✅ Loaded \(response.products.count) products with prices")
            
            if !response.invalidProductIdentifiers.isEmpty {
                print("⚠️ Invalid product IDs: \(response.invalidProductIdentifiers)")
                // Set fallback prices for invalid products
                if response.invalidProductIdentifiers.contains(self.removeAdsProductID) {
                    self.removeAdsPrice = "N/A"
                }
                if response.invalidProductIdentifiers.contains(self.hintsProductID) {
                    self.hintsPrice = "N/A"
                }
                if response.invalidProductIdentifiers.contains(self.slowTimersProductID) {
                    self.slowTimersPrice = "N/A"
                }
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Failed to load products: \(error.localizedDescription)")
            
            // Set error state for prices
            self.removeAdsPrice = "Error"
            self.hintsPrice = "Error"
            self.slowTimersPrice = "Error"
            self.pricesLoaded = false
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction)
            case .restored:
                handleRestored(transaction)
            case .failed:
                handleFailed(transaction)
            case .purchasing:
                print("💳 Processing payment...")
            case .deferred:
                print("⏳ Payment deferred")
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchased(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch transaction.payment.productIdentifier {
            case self.removeAdsProductID:
                self.adsRemoved = true
                print("✅ Remove Ads Purchase Successful!")
                
            case self.hintsProductID:
                self.hintsCompletion?(10)
                self.hintsCompletion = nil
                print("✅ Hints Purchase Successful! +10 Hints")
                
            case self.slowTimersProductID:
                self.slowTimersCompletion?(10)
                self.slowTimersCompletion = nil
                print("✅ Slow Timers Purchase Successful! +10 Slow Timers")
                
            default:
                break
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleRestored(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            if transaction.payment.productIdentifier == self.removeAdsProductID {
                self.adsRemoved = true
                print("✅ Remove Ads Restored!")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleFailed(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.hintsCompletion = nil
            self.slowTimersCompletion = nil
            
            if let error = transaction.error as? SKError {
                if error.code != .paymentCancelled {
                    print("❌ Purchase failed: \(error.localizedDescription)")
                } else {
                    print("⚠️ Purchase cancelled by user")
                }
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    @Published var weeklyStreak: Int {
        didSet {
            UserDefaults.standard.set(weeklyStreak, forKey: "WeeklyStreak")
        }
    }
    
    init() {
        self.weeklyStreak = UserDefaults.standard.integer(forKey: "WeeklyStreak")
        updateWeeklyStreak()
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.scheduleWeeklyReminder()
                }
            }
        }
    }
    
    private func updateWeeklyStreak() {
        guard let lastPlayDate = UserDefaults.standard.object(forKey: "LastPlayDate") as? Date else {
            // First time playing
            weeklyStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let daysSinceLastPlay = calendar.dateComponents([.day], from: lastPlayDate, to: today).day ?? 0
        
        if daysSinceLastPlay <= 7 {
            // Played within the last week, maintain streak
            let weeksPlayed = UserDefaults.standard.integer(forKey: "WeeksPlayed")
            let currentWeek = calendar.component(.weekOfYear, from: today)
            let lastPlayWeek = calendar.component(.weekOfYear, from: lastPlayDate)
            
            if currentWeek != lastPlayWeek {
                // New week, increment streak
                weeklyStreak += 1
                UserDefaults.standard.set(weeksPlayed + 1, forKey: "WeeksPlayed")
            }
        } else if daysSinceLastPlay > 14 {
            // Missed more than 2 weeks, reset streak
            weeklyStreak = 0
        }
        // If between 7-14 days, maintain current streak but don't increment
    }
    
    func scheduleWeeklyReminder() {
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "🧠 Brain Training Time!"
        content.body = weeklyStreak > 0 ?
            "Keep your \(weeklyStreak)-week streak alive! Quick math exercises boost your cognitive skills. 🎮" :
            "Time for some brain exercise! Quick math games improve memory and focus. Ready for the challenge? 🎯"
        content.sound = .default
        content.badge = 1
        
        // Schedule for every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Weekly reminder scheduled!")
            }
        }
    }
    
    func updateStreakOnPlay() {
        updateWeeklyStreak()
        scheduleWeeklyReminder() // Update notification message with current streak
    }
}

// MARK: - Game Center Manager

@MainActor
class GameCenterManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var showingLeaderboard = false
    @Published var globalRank: Int? = nil
    @Published var totalPlayers: Int? = nil
    
    static let leaderboardID = "quick_math_challenge_leaderboard"
    
    init() {
        authenticateUser()
    }
    
    func authenticateUser() {
        print("🔄 Attempting Game Center authentication...")
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Game Center authentication failed: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                    
                    // Retry after a delay if it's a network error
                    if error.localizedDescription.contains("network") || error.localizedDescription.contains("Network") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            print("🔄 Retrying Game Center authentication...")
                            self?.authenticateUser()
                        }
                    }
                } else if let viewController = viewController {
                    // Present authentication view controller
                    print("📱 Presenting Game Center authentication view")
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    print("✅ Game Center authenticated successfully!")
                    self?.isAuthenticated = true
                    // Fetch user's current rank
                    self?.fetchUserRank()
                } else {
                    print("⚠️ Game Center authentication cancelled or unavailable")
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func submitScore(_ score: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit score - not authenticated with Game Center")
            return
        }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.leaderboardID]
                )
                
                await MainActor.run {
                    print("✅ Score \(score) submitted to Game Center successfully!")
                    // Fetch updated rank after score submission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchUserRank()
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error submitting score to Game Center: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func showLeaderboard() {
        guard isAuthenticated else {
            print("⚠️ Cannot show leaderboard - not authenticated with Game Center")
            return
        }
        
        let leaderboardVC = GKGameCenterViewController(state: .leaderboards)
        leaderboardVC.gameCenterDelegate = GameCenterDelegate.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(leaderboardVC, animated: true)
        }
    }
    
    func fetchUserRank() {
        guard isAuthenticated else {
            print("⚠️ Cannot fetch rank - not authenticated with Game Center")
            return
        }
        
        Task {
            do {
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
                
                guard let leaderboard = leaderboards.first else {
                    await MainActor.run {
                        print("⚠️ No leaderboard found")
                        self.globalRank = nil
                        self.totalPlayers = nil
                    }
                    return
                }
                
                let (localEntry, _, totalPlayerCount) = try await leaderboard.loadEntries(
                    for: .global,
                    timeScope: .allTime,
                    range: NSRange(location: 1, length: 1)
                )
                
                await MainActor.run {
                    if let localEntry = localEntry {
                        self.globalRank = localEntry.rank
                        self.totalPlayers = totalPlayerCount
                        print("✅ User rank fetched: #\(localEntry.rank) out of \(totalPlayerCount)")
                    } else {
                        print("⚠️ No score found for local player")
                        self.globalRank = nil
                        self.totalPlayers = nil
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error fetching user rank: \(error.localizedDescription)")
                    self.globalRank = nil
                    self.totalPlayers = nil
                }
            }
        }
    }
}

// MARK: - Game Center Delegate

class GameCenterDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegate()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}

#Preview {
    ContentView()
}
