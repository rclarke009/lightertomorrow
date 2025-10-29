//
//  WatchConnectivityManager.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var lastMessage: [String: Any]?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("⌚️ DEBUG: Watch WatchConnectivity session activated")
        } else {
            print("⚠️ DEBUG: WatchConnectivity not supported on watch")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("⚠️ Watch WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch WCSession activated successfully")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("⌚️ Received message from iOS: \(message)")
        
        DispatchQueue.main.async {
            self.lastMessage = message
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("⌚️ Received message with reply handler from iOS: \(message)")
        
        DispatchQueue.main.async {
            self.lastMessage = message
            replyHandler(["status": "received"])
        }
    }
    
    // MARK: - Helper Methods
    
    func sendMessageToiOS(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⚠️ iOS is not reachable")
            return
        }
        
        WCSession.default.sendMessage(
            message,
            replyHandler: { reply in
                print("✅ iOS replied: \(reply)")
            },
            errorHandler: { error in
                print("❌ Failed to send message to iOS: \(error.localizedDescription)")
            }
        )
    }
}
