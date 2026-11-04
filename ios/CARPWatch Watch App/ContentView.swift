//
//  ContentView.swift
//  CARPWatch Watch App
//
//  Created by Alireza Hajebrahimi on 17/08/2026.
//
import SwiftUI

/// One glance: the CARP morph and what it means. Start/Stop is a scroll away.
struct ContentView: View {
    @ObservedObject var controller: CarpWatchSensorController

    private var mode: CarpMorphMode {
        if controller.isSyncing { return .syncing }
        if !controller.isRunning || !controller.isPhoneReachable { return .away }
        return controller.justSent ? .sent : .collecting
    }

    private var title: String {
        if !controller.isRunning { return "Stopped" }
        switch mode {
        case .syncing: return "Sending to phone"
        case .sent: return "Sent to phone"
        case .away: return "Phone not nearby"
        case .collecting: return "Collecting"
        }
    }

    private var detail: String {
        if !controller.isRunning { return controller.statusMessage }
        switch mode {
        case .syncing: return "\(Int(controller.syncProgress * 100))% · keep CARP open"
        case .sent: return "Just now"
        case .away: return "Saved on the watch · sends later"
        case .collecting:
            let sensors = "\(controller.activeSensorCount) sensors"
            guard let last = controller.lastTransferAt else { return sensors }
            return "\(sensors) · sent \(last.formatted(.relative(presentation: .named)))"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                CarpMorphView(mode: mode, progress: controller.syncProgress)
                    .aspectRatio(184 / 150, contentMode: .fit)
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(controller.isRunning ? "Stop" : "Start") {
                    controller.toggle()
                }
                .tint(controller.isRunning ? .red : CarpMorphView.red)
                .padding(.top, 16)
            }
            .accessibilityElement(children: .contain)
        }
    }
}
