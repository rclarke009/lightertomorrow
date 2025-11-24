//
//  WatchDataSync.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import Foundation
import WatchConnectivity

class WatchDataSync: NSObject, ObservableObject {
    static let shared = WatchDataSync()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func openOniPhone(action: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["action": action],
                replyHandler: nil,
                errorHandler: { error in
                    print("Failed to send message to iPhone: \(error.localizedDescription)")
                }
            )
        }
    }
}

extension WatchDataSync: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle messages from iPhone
        }
    }
}

