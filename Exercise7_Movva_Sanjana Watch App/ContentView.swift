//
//  ContentView.swift
//  Exercise7_Movva_Sanjana Watch App
//
//  Created by Sanjana Movva on 10/26/23.
//

import SwiftUI
import HealthKit
import WatchConnectivity

class ConnectivityProvider: NSObject, WCSessionDelegate, ObservableObject {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            }
    
    var session: WCSession
    let healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit.count().unitDivided(by: HKUnit.minute())
    var heartRateQuery: HKQuery?
    @Published var isSimulating = false
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                if command == "start" {
                    self.startHeartRateQuery()
                } else if command == "stop" {
                    self.stopHeartRateQuery()
                }
            }
        }
    }
    
    func sendHeartRate(heartRate: Int) {
        session.sendMessage(["heartRate": "\(heartRate)"], replyHandler: nil, errorHandler: nil)
    }
    
    func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier = .heartRate) {
        isSimulating = true
        
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
        }

        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
        self.heartRateQuery = query
    }
    
    func stopHeartRateQuery() {
        isSimulating = false
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
        }
        
        let heartRateValue = Int(lastHeartRate)
        self.sendHeartRate(heartRate: heartRateValue)
    }
}

struct ContentView: View {
    let healthStore = HKHealthStore()
    @State private var value: Int = 0
    @StateObject var connectivityProvider = ConnectivityProvider()
    let heartRateQuantity = HKUnit.count().unitDivided(by: HKUnit.minute())

    
    var body: some View {
        VStack {
            Button(action: {
                
                if self.connectivityProvider.isSimulating {
                    self.connectivityProvider.stopHeartRateQuery()
                    self.createWorkoutEmulation()
                } else {
                    self.connectivityProvider.startHeartRateQuery()
                    self.createWorkoutEmulation()
                }
            }) {
                Text(connectivityProvider.isSimulating ? "❤️ Stop" : "❤️ Start")
                    .font(.system(size: 50))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            HStack {
                Text("\(value)")
                    .font(.system(size: 70, weight: .regular))
                Text("BPM")
                    .font(.headline)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.red)
                    .offset(y: -10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear(perform: start)
    }

    func start() {
        authorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }

    func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
        }

        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
        }
        
            self.value = Int(lastHeartRate)
        
    }

    private func createWorkoutEmulation() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        let healthStore = HKHealthStore()
        let session: HKWorkoutSession!
        let builder: HKWorkoutBuilder!
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in }
    }
    func authorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in
            
        }
    }
}



