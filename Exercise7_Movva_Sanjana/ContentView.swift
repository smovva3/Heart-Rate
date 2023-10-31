//
//  ContentView.swift
//  Exercise7_Movva_Sanjana
//
//  Created by Sanjana Movva on 10/26/23.
//

import SwiftUI
import WatchConnectivity

class ConnectivityProvider: NSObject, WCSessionDelegate, ObservableObject {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    
    }
    
    var session: WCSession
    @Published var heartRate: String = "--"
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? String {
                self.heartRate = heartRate
            }
        }
    }
    
    func sendCommand(command: String) {
        session.sendMessage(["command": command], replyHandler: nil, errorHandler: nil)
    }
}

struct ContentView: View {
    @StateObject var connectivityProvider = ConnectivityProvider()
    
    var body: some View {
        VStack {
            Image("Unknown-2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text("Heart Rate")
                .font(.title)
            Text("\(connectivityProvider.heartRate) BPM")
                .font(.largeTitle)
                .foregroundColor(.red)
                .padding()
            
            HStack {
                Button(action: {
                    self.connectivityProvider.sendCommand(command: "start")
                }) {
                    Text("Start")
                }
                .padding()
                
                Button(action: {
                    self.connectivityProvider.sendCommand(command: "stop")
                }) {
                    Text("Stop")
                }
                .padding()
            }
        }
    }
}



