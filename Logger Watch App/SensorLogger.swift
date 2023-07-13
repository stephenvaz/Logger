//
//  SensorLogger.swift
//  Logger Watch WatchKit Extension
//
//  Created by MacBook Pro on 2020/05/03.
//  Copyright © 2020 MacBook Pro. All rights reserved.
//

import Foundation
import CoreMotion
import Combine



class SensorLogManager: NSObject, ObservableObject {
    var motionManager: CMMotionManager?
    
    @Published var accX = 0.0
    @Published var accY = 0.0
    @Published var accZ = 0.0
    @Published var gyrX = 0.0
    @Published var gyrY = 0.0
    @Published var gyrZ = 0.0
    
    private var samplingFrequency = 50.0
    
    var timer = Timer()
    
    override init() {
        super.init()
        self.motionManager = CMMotionManager()
    }
    
    
    private var csvText = ""

    // ...

//    @objc private func startLogSensor() {
//        // ...
//
//        // Append the sensor data to the CSV text
//        let csvLine = "\(self.accX),\(self.accY),\(self.accZ),\(self.gyrX),\(self.gyrY),\(self.gyrZ)\n"
//        csvText.append(csvLine)
//
//        // ...
//
//        // Print the data
//        print("Watch: acc (\(self.accX), \(self.accY), \(self.accZ)), gyr (\(self.gyrX), \(self.gyrY), \(self.gyrZ))")
//    }

    // ...

//    func stopUpdate() {
//        // ...
//
//        // Save the CSV text to a file
//        saveCSVToFile()
//    }

    private func saveCSVToFile() {
        let fileName = "sensor_data.csv"
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Failed to access document directory.")
            return
        }

        let fileURL = documentDirectory.appendingPathComponent(fileName)

        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved: \(fileURL.absoluteString)")
        } catch {
            print("Error while saving CSV file: \(error)")
        }
    }
    
    @objc private func startLogSensor() {
        
        if let data = motionManager?.accelerometerData {
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            
            self.accX = x
            self.accY = y
            self.accZ = z
        }
        else {
            self.accX = 0
            self.accY = 0
            self.accZ = 0
        }
        
//        if let data = motionManager?.gyroData {
//            let x = data.rotationRate.x
//            let y = data.rotationRate.y
//            let z = data.rotationRate.z
//
//            self.gyrX = x
//            self.gyrY = y
//            self.gyrZ = z
//        }
//        else {
//            self.gyrX = Double.nan
//            self.gyrY = Double.nan
//            self.gyrZ = Double.nan
//        }
        
        if let data = motionManager?.deviceMotion {
            let x = data.rotationRate.x
            let y = data.rotationRate.y
            let z = data.rotationRate.z
            
            self.gyrX = x
            self.gyrY = y
            self.gyrZ = z
            
        }
        else {
            self.gyrX = 0
            self.gyrY = 0
            self.gyrZ = 0
        }
        
//        print("Watch: acc (\(self.accX), \(self.accY), \(self.accZ)), gyr (\(self.gyrX), \(self.gyrY), \(self.gyrZ))")
        let csvLine = "A: \(self.accX),\(self.accY),\(self.accZ)\nG: \(self.gyrX),\(self.gyrY),\(self.gyrZ)\n\n"
        csvText.append(csvLine)

        // ...

        // Print the data
        print("Watch: acc (\(self.accX), \(self.accY), \(self.accZ)), gyr (\(self.gyrX), \(self.gyrY), \(self.gyrZ))")
        
//       write this data to a csv
//        print("test")
       // db write
        // csv
        
    }
    
    func startUpdate(_ freq: Double) {
        if motionManager!.isAccelerometerAvailable {
            motionManager?.startAccelerometerUpdates()
        }
        
//        if motionManager!.isGyroAvailable {
//            motionManager?.startGyroUpdates()
//        }
        
        // Gyroscopeの生データの代わりにDeviceMotionのrotationRateを取得する
        if motionManager!.isDeviceMotionAvailable {
            motionManager?.startDeviceMotionUpdates()
        }
        
        self.samplingFrequency = freq
        
        // プル型でデータ取得
        self.timer = Timer.scheduledTimer(timeInterval: 1.0 / freq,
                           target: self,
                           selector: #selector(self.startLogSensor),
                           userInfo: nil,
                           repeats: true)
    }
    
    func stopUpdate() {
        self.timer.invalidate()
        
        if motionManager!.isAccelerometerActive {
            motionManager?.stopAccelerometerUpdates()
        }
        
        if motionManager!.isGyroActive {
            motionManager?.stopGyroUpdates()
        }
        saveCSVToFile()
    }
}



