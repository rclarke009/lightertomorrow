//
//  WatchConnectivityManager.swift
//  Coacher
//
//  Created on 9/6/25.
//

import Foundation
import WatchConnectivity
import UIKit

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
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("⚠️ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated successfully")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated - reactivating")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 Received message from watch: \(message)")
        
        DispatchQueue.main.async {
            self.lastMessage = message
            
            if let action = message["action"] as? String {
                switch action {
                case "openApp":
                    print("🎯 Watch requesting to open app")
                    // The app is already opening via the message
                case "successNote":
                    self.handleSuccessNote(message)
                case "cravingNote":
                    self.handleCravingNote(message)
                default:
                    break
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 Received message with reply handler from watch: \(message)")
        
        DispatchQueue.main.async {
            self.lastMessage = message
            
            if let action = message["action"] as? String {
                switch action {
                case "openApp":
                    print("🎯 Watch requesting to open app - sending reply")
                    replyHandler(["status": "app_opening"])
                case "successNote":
                    self.handleSuccessNote(message)
                    replyHandler(["status": "success_received"])
                case "cravingNote":
                    self.handleCravingNote(message)
                    replyHandler(["status": "craving_received"])
                default:
                    replyHandler(["status": "received"])
                }
            } else {
                replyHandler(["status": "received"])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessNote(_ message: [String: Any]) {
        guard let text = message["text"] as? String,
              let dateInterval = message["date"] as? TimeInterval,
              let typeRaw = message["type"] as? String else {
            print("❌ Invalid success note message")
            return
        }
        
        // Post notification with success note data
        let noteData: [String: Any] = [
            "text": text,
            "date": Date(timeIntervalSince1970: dateInterval),
            "type": typeRaw
        ]
        
        NotificationCenter.default.post(
            name: NSNotification.Name("WatchSuccessNoteReceived"),
            object: nil,
            userInfo: noteData
        )
        
        print("✅ Posted WatchSuccessNoteReceived notification with text: \(text)")
    }
    
    private func handleCravingNote(_ message: [String: Any]) {
        guard let text = message["text"] as? String,
              let dateInterval = message["date"] as? TimeInterval,
              let typeRaw = message["type"] as? String else {
            print("❌ Invalid craving note message")
            return
        }
        
        // Post notification with craving note data
        let noteData: [String: Any] = [
            "text": text,
            "date": Date(timeIntervalSince1970: dateInterval),
            "type": typeRaw
        ]
        
        NotificationCenter.default.post(
            name: NSNotification.Name("WatchCravingNoteReceived"),
            object: nil,
            userInfo: noteData
        )
        
        print("✅ Posted WatchCravingNoteReceived notification with text: \(text)")
    }
    
    func sendMessageToWatch(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⚠️ Watch is not reachable")
            return
        }
        
        WCSession.default.sendMessage(
            message,
            replyHandler: { reply in
                print("✅ Watch replied: \(reply)")
            },
            errorHandler: { error in
                print("❌ Failed to send message to watch: \(error.localizedDescription)")
            }
        )
    }
}

