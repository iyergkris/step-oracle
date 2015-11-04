//
//  InterfaceController.swift
//  FitnessFortuna WatchKit Extension
//
//  Created by Vikas Iyer on 11/3/15.
//  Copyright © 2015 VI. All rights reserved.
//
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity



class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, WCSessionDelegate {
    
    @IBOutlet var dateLabel: WKInterfaceLabel!
    let healthStore = HKHealthStore()
    let workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Walking, locationType: HKWorkoutSessionLocationType.Indoor)
    
    let stepCountUnit = HKUnit(fromString: "")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    var content:String = String.init("")
    
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        workoutSession.delegate = self
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //if WCSession.isSupported(){
        //let connectivitySession = WCSession.defaultSession()
        //connectivitySession.delegate = self
        //connectivitySession.activateSession()
        //}
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            //label.setText("not available")
            print("healthdata not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else{
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) {(success, error) -> Void in
            if success == false {
                // displayNotAllowed
                print(error)
                self.displayNotAllowed()
                
            }
        }
    }
    
    func displayNotAllowed(){
        print("displayNotAllowed")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate){
        switch toState {
            
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidStop(date)
        default:
            print("Unexpected statev\(toState)")
            
            
            
            
            
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError){
        
        
    }
    
    func workoutDidStart(date:NSDate){
        
        if let query = createStepCountStreamingQuery(date){
            healthStore.executeQuery(query)
        } else {
            // cannot start
        }
        
    }
    
    func workoutDidStop(date:NSDate){
        if let query = createStepCountStreamingQuery(date){
            healthStore.stopQuery(query)
        }
        else {
            // cannot stop
        }
        
    }
    
    func createStepCountStreamingQuery(workoutStartDate:NSDate) -> HKQuery? {
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else { return nil}
        
        let past = NSDate.distantPast()
        let now   = NSDate()
        
        //let timePredicate = NSPredicate.init();
        let timePredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: now, options: .None)
        
        // let timePredicate:NSPredicate = NSPredicate.init(format: "(date <= %@) AND (date >= %@)", workoutStartDate, workoutStartDate.dateByAddingTimeInterval(-900))
        
        let stepCountQuery = HKAnchoredObjectQuery(type:quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit))
            { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                //print("sampledObjects \(sampleObjects)")
                guard let newAnchor = newAnchor else {return}
                self.anchor = newAnchor
                self.updateStepCount(sampleObjects)
        }
        
        stepCountQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateStepCount(samples)
        }
        
        return stepCountQuery
        
        
    }
    
    func updateStepCount(samples: [HKSample]?){
        guard let stepCountSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()){
            guard let sample = stepCountSamples.first else {return}
            let value = sample.quantity.doubleValueForUnit(self.stepCountUnit)
            // update label
            //print("value \(value)")
            
            
            let timeStamp = sample.startDate
            let endTimeStamp = sample.endDate
            
            let dateFormatter:NSDateFormatter = NSDateFormatter.init()
            dateFormatter.dateFormat = "yy/MM/dd HH:mm"
            
            let formattedDateString:String = dateFormatter.stringFromDate(sample.startDate)
            self.dateLabel.setText(formattedDateString)
            
            
            print(formattedDateString, value)
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let fileName:String = "\(documentsPath)/textfile.txt"
            print("fileName: \(fileName)")
            //var content:String = "\(formattedDateString), \(value)"
            self.content.appendContentsOf("\(formattedDateString), \(value)\n")
            //content.append("\(formattedDateString), \(value)")
            //content.writeToFile(fileName, atomically: false, encoding: <#T##NSStringEncoding#>)
            
            do {
                try self.content.writeToFile(fileName, atomically: false, encoding: NSUTF8StringEncoding)
            }
            catch {
                print("error writingToFile")
                
                
            }
            
            
            
            
            
            
                       
            // retrieve source from apple?
            let name = sample.sourceRevision.source.name
            //update name?
            //print("name \(name)")
        }
        
    }
    
    @IBAction func trackStepCount() {
        healthStore.startWorkoutSession(workoutSession)
    }
    
    @IBAction func stopTracking() {
        healthStore.endWorkoutSession(workoutSession)
        let connectivitySession:WCSession = WCSession.defaultSession()
        //var error:NSError
        connectivitySession.sendMessage(["getHealthData":"message"], replyHandler: nil, errorHandler: nil)
        
    }
    
    func changeDateFormat(date:NSDate){
        
    }
}

