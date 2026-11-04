//
//  ContentView.swift
//  CARPWatch Watch App
//
//  Created by Alireza Hajebrahimi on 17/08/2026.
//
import SwiftUI
import WatchKit

/// One glance: the CARP morph and what it means. Tapping it starts or sends; Stop is a scroll away.
struct ContentView: View {
    @ObservedObject var controller: CarpWatchSensorController

    private var mode: CarpMorphMode {
        if controller.isSyncing { return .syncing }
        if !controller.isRunning || !controller.isPhoneReachable { return .away }
        return controller.justSent ? .sent : .collecting
    }

    /// The state the phone mirrors: Stopped or Collecting - sending is part of collecting.
    private var title: String {
        if !controller.isRunning { return "Stopped" }
        return controller.isPhoneReachable ? "Collecting" : "Phone not nearby"
    }

    private var detail: String {
        if controller.isSyncing { return "Sending to phone \(Int(controller.syncProgress * 100))%" }
        if !controller.isRunning { return "Tap to start" }
        if controller.justSent { return "Sent to phone just now" }
        if !controller.isPhoneReachable { return "Saved on the watch · tap to send" }
        let sensors = "\(controller.activeSensorCount) sensors"
        guard let last = controller.lastTransferAt else { return sensors }
        return "\(sensors) · sent \(last.formatted(.relative(presentation: .named)))"
    }

    var body: some View {
        // No scrolling: the text keeps a fixed size and the sphere takes whatever height is left.
        NavigationStack {
            VStack(spacing: 2) {
                // The sphere is the action: start when stopped, otherwise send now.
                Button {
                    WKInterfaceDevice.current().play(.click)
                    controller.isRunning ? controller.transferNow() : controller.start()
                } label: {
                    CarpMorphView(mode: mode, progress: controller.syncProgress)
                        .aspectRatio(184 / 150, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(controller.isSyncing)
                .accessibilityLabel(controller.isRunning ? "Send data to phone" : "Start collecting")
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .contain)
            .toolbar {
                if controller.isRunning {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) { controller.stop() } label: {
                            Image(systemName: "stop.fill")
                        }
                        .accessibilityLabel("Stop collecting")
                    }
                }
            }
        }
    }
}
