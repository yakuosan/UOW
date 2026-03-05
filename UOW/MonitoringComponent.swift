//
//  MonitoringComponent.swift
//  UOW
//
//  Created by 阪上八雲 on 2026/03/05.
//

import SwiftUI

// MARK: - Gauge View

struct IrritationGaugeView: View {
    let score: Double
    let level: IrritationLevel

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: score)

                VStack(spacing: 4) {
                    Text("\(Int(score))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(gaugeColor)
                        .animation(.easeInOut, value: score)
                    Text(level.description)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Text("イライラ度スコア")
                .font(.caption)
                .foregroundColor(.secondary)

            LevelIndicatorRow(level: level)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var gaugeColor: Color {
        switch level {
        case .calm:    return .green
        case .caution: return .yellow
        case .warning: return .orange
        case .danger:  return .red
        }
    }
}

struct LevelIndicatorRow: View {
    let level: IrritationLevel
    private let levels: [(IrritationLevel, String, Color)] = [
        (.calm,    "平常",  .green),
        (.caution, "注意",  .yellow),
        (.warning, "警告",  .orange),
        (.danger,  "危険",  .red),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(levels, id: \.1) { l, name, color in
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(level == l ? 1.4 : 1.0)
                        .animation(.spring(), value: level)
                    Text(name)
                        .font(.caption2)
                        .fontWeight(level == l ? .bold : .regular)
                        .foregroundColor(level == l ? color : .secondary)
                }
            }
        }
    }
}

// MARK: - Control Buttons

struct ControlButtons: View {
    @ObservedObject var viewModel: IrritationViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if viewModel.isMonitoring {
                    viewModel.stopMonitoring()
                } else {
                    viewModel.startMonitoring()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isMonitoring ? "mic.slash.fill" : "mic.fill")
                    Text(viewModel.isMonitoring ? "停止" : "監視開始")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(viewModel.isMonitoring ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Transcription Card

struct TranscriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("音声認識", systemImage: "waveform")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

// MARK: - Event Log

struct EventLogView: View {
    let events: [DetectionEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("検知ログ", systemImage: "list.bullet")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(events.prefix(10)) { event in
                HStack {
                    Text(event.icon)
                    Text(event.description)
                        .font(.caption)
                    Spacer()
                    Text(event.timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.6))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
    }
}

// MARK: - Advice Modal

struct AdviceModal: View {
    let advice: String
    let level: IrritationLevel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(level == .danger ? "⚠️ 危険レベル" : "💡 アドバイス")
                    .font(.title2.bold())
                Text(advice)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                Image(systemName: "lungs.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Button("閉じる") { onDismiss() }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

// MARK: - Permission Warning

struct PermissionWarningView: View {
    @ObservedObject var viewModel: IrritationViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("マイク・音声認識の許可が必要です")
                .font(.headline)
            Text("設定アプリからこのアプリのマイクと音声認識の使用を許可してください。")
                .font(.caption)
                .multilineTextAlignment(.center)
            Button("許可をリクエスト") {
                viewModel.requestPermissions()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(40)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255)
    }
}
