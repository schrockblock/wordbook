//
//  WatchConnectivityClient.swift
//  Wordbook
//
//  Created by Elliot Schrock on 9/21/23.
//

import Dependencies
import WatchConnectivity

class WatchConnectivityClient {
    var session: WCSession
    var delegate: WatchConnectivityDelegate?
    var start: @Sendable () -> AsyncThrowingStream<[String: Any], Error>
    
    init(session: WCSession = .default, didActivate: @escaping () -> Void) {
        self.session = session
        self.delegate = nil
        self.start = { AsyncThrowingStream { _ in }}
        self.start = {
            AsyncThrowingStream { continuation in
                let delegate = WatchConnectivityDelegate(didActivate) { message in
                    continuation.yield(message)
                }
                session.delegate = delegate
                session.activate()
                self.delegate = delegate
            }
        }
    }
}

class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    var didActivate: () -> Void
    var didReceiveMessage: ([String: Any]) -> Void
    
    init(_ didActivate: @escaping () -> Void, didReceiveMessage: @escaping ([String : Any]) -> Void) {
        self.didActivate = didActivate
        self.didReceiveMessage = didReceiveMessage
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        didReceiveMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        didReceiveMessage(message)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // NO OP
        print("active? \(activationState == .activated ? "yes" : "nope")")
        if activationState == .activated {
            didActivate()
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // NO OP
        print("inactive?")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // NO OP
        print("deactive?")
    }
    #endif
}

extension WatchConnectivityClient: DependencyKey {
    static let liveValue = WatchConnectivityClient { WCSession.default.sendMessage(["phrases": try? JSONEncoder().encode(loadData())], replyHandler: { _ in
        print("reply")
    }) }
}

extension DependencyValues {
    var watchConnectivityClient: WatchConnectivityClient {
        get { self[WatchConnectivityClient.self] }
        set { self[WatchConnectivityClient.self] = newValue }
    }
}

