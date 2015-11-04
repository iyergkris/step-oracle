//
//  ViewController.swift
//  FitnessFortuna
//
//  Created by Vikas Iyer on 10/31/15.
//  Copyright © 2015 VI. All rights reserved.
//


import UIKit
import HealthKit
import WatchConnectivity
import CocoaAsyncSocket




class ViewController: UIViewController, WCSessionDelegate, UITextFieldDelegate {
    @IBOutlet weak var challengeTestButtonText: UIButton!
    
    @IBOutlet weak var stepGoalField: UITextField!
    
    @IBOutlet weak var anotherRoundChallenge: UIButton!
    @IBOutlet var mainView: UIView!
    
    var stepGoalEntered:Float=0
    var actualStepsThisHour:Float = 66
    //let udpSocket = GCDAsyncUdpSocket.init()
    @IBOutlet weak var predictionLabel: UILabel!
   
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        self.stepGoalEntered = Float(textField.text!)!
        self.anotherRoundChallenge.hidden = true
        
        sendUDPData()
    
    
        return true
    }
    @IBAction func challengeTestPressed(sender: AnyObject) {
        
        if actualStepsThisHour < self.stepGoalEntered {

            predictionLabel.text = "Unfortunately, my prophecy came true. Try harder in the next hour and beat me!"
            
        }
        else {
           
            predictionLabel.text = "Wow, you beat me! Keep it up"
        
        }
        self.challengeTestButtonText.hidden = true
        self.anotherRoundChallenge.hidden = false
        
    }
    
    @IBAction func anotherRoundChallengeTapped(sender: AnyObject) {
        
        sendUDPData()
        self.anotherRoundChallenge.hidden = true
        self.challengeTestButtonText.hidden = false
        
    }
    func updatePredictionLabel(success:Bool){
        self.challengeTestButtonText.hidden = false
        if success {
            self.predictionLabel.text = "I have a hunch that you're goin to keep up with your goals. Prove me right! "
            
        }
        else {
            self.predictionLabel.text = "I feel that you may miss your hourly stepcount goals. Can you beat my prediction?"
            
        
        }
        
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("abc")
        stepGoalField.delegate = self
        self.challengeTestButtonText.hidden = true
        self.anotherRoundChallenge.hidden = true
        self.title = "Fitness Fortuna"
        //self.mainView.backgroundColor = UIColor(red: 241, green: 240, blue: 231, alpha: 1)
        
        
        
        
        
        
        
        
        
        
        if WCSession.isSupported(){
            let connectivitySession = WCSession.defaultSession()
            connectivitySession.delegate = self
            connectivitySession.activateSession()
        }
        
        
        
        
        getHealthKitStepCountData()
        
        
        
        
        
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int){
    
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!){
        
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!){
        
        let msg = String.init(data: data, encoding: NSUTF8StringEncoding)
    
        if (msg != nil) {
            print("RECV: \(msg!)")
            
            if let predictedStepCount:Float? = Float(msg!) {
                
                if predictedStepCount < stepGoalEntered {
                    updatePredictionLabel(false)
                }
                else {
                    updatePredictionLabel(true)
                }
            
            }
         
        }
        else
        {
            var host:String? = nil
            
            var port:UInt16 = 0
            
            
            //GCDAsyncUdpSocket.getHost(host, port: &port, fromAddress: address)
         
            
            //[self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
            print("RECV: Unknown message from: \(host) \(port)")

        }

    
    }
    
    func sendUDPData(){
        
        let udpSocket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        var error:NSError?
        
        do {
            try udpSocket.bindToPort(0)
        }catch {
            print("error binding: \(error)")
        }
        
        do{
            try udpSocket.beginReceiving()
        } catch {
            
            print("error: \(error)")
            
            
            
        }
        
        
        let amazonIP = "52.32.221.84"
        let port = 8888
        let timeStamp = "2015/10/1 0:00:00,109"
        let data = timeStamp.dataUsingEncoding(NSUTF8StringEncoding)
        udpSocket.sendData(data, toHost: amazonIP, port: 8888, withTimeout: -1, tag: 1)
        
    
    }
    
    
    
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("sessionDelegate called")
        
    }
    
    
    func getHealthKitStepCountData(){
        
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else{
            //displayNotAllowed()
            return
        }
        
        let dataTypesToRead = Set(arrayLiteral: quantityType)
        healthStore!.requestAuthorizationToShareTypes(nil, readTypes: dataTypesToRead) {(success, error) -> Void in
            if success {
                print("SUCCESS")
            } else {
                print(error!.description)
            }
        }
        
        let date:NSDate = NSDate()
        
      
        newStatQueryFetch()
        
        
    }
    
    func newStatQueryFetch()
    {
        //NSDate *startDate, *endDate, *anchorDate; // Whatever you need in your case
        
        let startDate, endDate, anchorDate:NSDate
        
        
        var compsStart:NSDateComponents = NSDateComponents.init()
        
        compsStart.day = 23
        compsStart.month = 10
        compsStart.year = 2015
        
        startDate = NSCalendar.currentCalendar().dateFromComponents(compsStart)!
        
        
        endDate = NSDate()
        
        anchorDate = startDate
        
        let calendar = NSCalendar.currentCalendar()
        
        let type:HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        
        let intervalComponents = NSDateComponents.init()
        intervalComponents.minute = 15
        
        let predicate:NSPredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: HKQueryOptions.StrictStartDate)
        
        let query = HKStatisticsCollectionQuery.init(quantityType: type, quantitySamplePredicate: predicate, options: HKStatisticsOptions.CumulativeSum, anchorDate: anchorDate, intervalComponents: intervalComponents)
        
        query.initialResultsHandler  = {
            query, results, error in
            // [healthStore executeQuery:query];
            
            if error != nil {
                // Perform proper error handling here
                print("*** An error occurred while calculating the statistics: \(error!.localizedDescription) ***")
                abort()
            }
            
            let endDate = NSDate()
            let startDate =
            calendar.dateByAddingUnit(NSCalendarUnit.Day,
                value: -9, toDate: endDate, options: NSCalendarOptions.MatchLast)
            
            // Plot the weekly step counts over the past 3 months
            results!.enumerateStatisticsFromDate(startDate!, toDate: endDate) {
                statistics, stop in
                
                if let quantity = statistics.sumQuantity() {
                    let date = statistics.startDate
                    let value = quantity.doubleValueForUnit(HKUnit.countUnit())
                    
                    //print(date, value)///////////////////////////
                    //self.plotData(value, forDate: date)
                }
            }
            
            
        }
        
        
        
        
        // HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        
        
        // Your interval: sum by hour
        //NSDateComponents *intervalComponents = [[NSDateComponents alloc] init];
        //intervalComponents.hour = 1;
        
        // Example predicate
        //NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:fromDate endDate:toDate options:HKQueryOptionStrictStartDate];
        
        //        HKStatisticsCollectionQuery *query = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum anchorDate:anchorDate intervalComponents:intervalComponents];
        //        query.initialResultsHandler  = {
        //            query, results, error in
        //       // [healthStore executeQuery:query];
        //        }
        healthStore?.executeQuery(query)
        
    }
    
    func statQueryFetch()
    {
        
        let calendar = NSCalendar.currentCalendar()
        
        let interval = NSDateComponents()
        interval.minute = 15
        
        
        let anchorComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: NSDate())
        
        
        let anchorDate = calendar.dateFromComponents(anchorComponents)
        
        let quantityType =
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantityType!,
            quantitySamplePredicate: nil,
            options: .CumulativeSum,
            anchorDate: anchorDate!,
            intervalComponents: interval)
        
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            if error != nil {
                // Perform proper error handling here
                print("*** An error occurred while calculating the statistics: \(error!.localizedDescription) ***")
                abort()
            }
            
            let endDate = NSDate()
            let startDate =
            calendar.dateByAddingUnit(NSCalendarUnit.Day,
                value: -9, toDate: endDate, options: NSCalendarOptions.MatchLast)
            
            // Plot the weekly step counts over the past 3 months
            results!.enumerateStatisticsFromDate(startDate!, toDate: endDate) {
                statistics, stop in
                
                if let quantity = statistics.sumQuantity() {
                    let date = statistics.startDate
                    let value = quantity.doubleValueForUnit(HKUnit.countUnit())
                    
                    print(date, value)
                    //self.plotData(value, forDate: date)
                }
            }
        }
        
        healthStore?.executeQuery(query)
        
    }
    
    
    func quickSampleFetch(){
        let stepsCount = HKQuantityType.quantityTypeForIdentifier(
            HKQuantityTypeIdentifierStepCount)
        
        let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount!,
            predicate: nil,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: nil)
            { [unowned self] (query, results, error) in
                if let results = results as? [HKQuantitySample] {
                    
                    
                    // Formatting to ""yy/MM/dd HH:mm"
                    let dateFormatter:NSDateFormatter = NSDateFormatter.init()
                    //dateFormatter.dateFormat = "yy/MM/dd HH:mm"
                    dateFormatter.dateFormat = "yy/MM/dd"
                    
                    
                    
                    // Get components?
                    
                    
                    
                    let calendar:NSCalendar = NSCalendar.currentCalendar()
        
                    
                    let componentsStartDate = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: (results.first?.startDate)!)
                    let componentsEndDate = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: (results.first?.endDate)!)
                    
                    
                    
                    let stepCountUnit = HKUnit(fromString: "")
                    
                    
                    for result in results{
                        
                        let formattedDateString:String = dateFormatter.stringFromDate(result.startDate)
                        //print("\(formattedDateString), \(result.quantity.doubleValueForUnit(stepCountUnit))")
                        let componentResult = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: (result.startDate))
                        
                        //for var currentYear = componentsStartDate.year; currentYear <= componentsEndDate.year; currentYear++ {
                        let currentYear = componentsStartDate.year
                        
                        
                        //for var currentMonth = componentResult.month; currentMonth <= 12; currentMonth++ {
                        let currentMonth = componentResult.month
                        
                        var lastDayOfMonth = 0
                        switch currentMonth {
                        case 1,3,5,7,8,10,12:
                            lastDayOfMonth = 31
                        case 4, 6, 9, 11:
                            lastDayOfMonth = 30
                        case 2:
                            if (currentYear % 4 == 0){
                                lastDayOfMonth = 29
                            }else{
                                lastDayOfMonth = 28
                            }
                        default:
                            lastDayOfMonth = 0
                        }
                        
                        //for var currentDay = componentResult.day; currentDay <= lastDayOfMonth; currentDay++ {
                        
                        var sameQuarter:Bool = true
                        var hourTemp = componentResult.hour
                        var hourTempStepCount = 0.0
                        var minuteFloor = 0
                        if componentResult.minute >= 0 && componentResult.minute <= 14{
                            hourTempStepCount += result.quantity.doubleValueForUnit(stepCountUnit)
                            minuteFloor = 0
                        }
                        else if componentResult.minute >= 15 && componentResult.minute <= 29{
                            hourTempStepCount += result.quantity.doubleValueForUnit(stepCountUnit)
                            minuteFloor = 15
                        }
                        else if componentResult.minute >= 30 && componentResult.minute <= 44{
                            hourTempStepCount += result.quantity.doubleValueForUnit(stepCountUnit)
                            minuteFloor = 30
                        }
                        else if componentResult.minute >= 45 && componentResult.minute <= 59{
                            hourTempStepCount += result.quantity.doubleValueForUnit(stepCountUnit)
                            minuteFloor = 45
                        }
                        
                        print("\(formattedDateString) \(componentResult.hour):\(minuteFloor), \(result.quantity.doubleValueForUnit(stepCountUnit))")
                        
                        
                        
                        
                        
                    }// end of result in results loop
                }
                //self.activityIndicator.stopAnimating()
        }// end of completionBlock
        
        // Don't forget to execute the Query!
        healthStore?.executeQuery(stepsSampleQuery)
        
    }// end of method
    
    func createStepCountStreamingQuery(workoutStartDate:NSDate) -> HKQuery? {
        var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else { return nil}
        
        let past = NSDate.distantPast()
        let now   = NSDate()
        
        //let timePredicate = NSPredicate.init();
        let timePredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: now, options: .None)
        
        // let timePredicate:NSPredicate = NSPredicate.init(format: "(date <= %@) AND (date >= %@)", workoutStartDate, workoutStartDate.dateByAddingTimeInterval(-900))
        
        let stepCountQuery = HKAnchoredObjectQuery(type:quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit))
            { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                print("sampledObjects \(sampleObjects)")
                guard let newAnchor = newAnchor else {return}
                anchor = newAnchor
                self.updateStepCount(sampleObjects)
        }
        
        stepCountQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            anchor = newAnchor!
            self.updateStepCount(samples)
        }
        
        return stepCountQuery
        
        
    }
    
    
    func updateStepCount(samples: [HKSample]?){
        let stepCountUnit = HKUnit(fromString: "")
        var content:String = String.init("")
        
        guard let stepCountSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()){
            guard let sample = stepCountSamples.first else {return}
            let value = sample.quantity.doubleValueForUnit(stepCountUnit)
            // update label
            print("value \(value)")
            
            
            let timeStamp = sample.startDate
            let endTimeStamp = sample.endDate
            
            let dateFormatter:NSDateFormatter = NSDateFormatter.init()
            dateFormatter.dateFormat = "yy/MM/dd HH:mm"
            
            let formattedDateString:String = dateFormatter.stringFromDate(sample.startDate)
            //self.dateLabel.setText(formattedDateString)
            
            
            print("Printing from phone:",formattedDateString, value)
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let fileName:String = "\(documentsPath)/textfile.txt"
            print("fileName: \(fileName)")
            
            content.appendContentsOf("\(formattedDateString), \(value)\n")
            //content.append("\(formattedDateString), \(value)")
            //content.writeToFile(fileName, atomically: false, encoding: <#T##NSStringEncoding#>)
            
            do {
                try content.writeToFile(fileName, atomically: false, encoding: NSUTF8StringEncoding)
            }catch {
                print("error writingToFile")
                
                
            }
            
            // retrieve source from apple?
            let name = sample.sourceRevision.source.name
            //update name? 
            //print("name \(name)")
        }
        
    }
    
    
  
    
    
}



