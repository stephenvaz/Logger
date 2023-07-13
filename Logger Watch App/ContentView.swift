//
//  ContentView.swift
//  Logger Watch App
//
//  Created by Stephen Vaz on 13/07/23.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var logStarting = false
    @State private var showCSVData = false
    @State private var csvData = ""
  
    @ObservedObject var sensorLogger = SensorLogManager()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 18) {
                    HStack(spacing: 15) {
                        Button(action: {
                            self.logStarting.toggle()
                            
                            if self.logStarting {
                                self.sensorLogger.startUpdate(50.0)
                            } else {
                                self.sensorLogger.stopUpdate()
                            }
                        }) {
                            Image(systemName: self.logStarting ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        .frame(width: 45.0, height: 27.0)

                        
                        Button(action: {
                            showCSVData.toggle()
                            
                            if showCSVData {
                                csvData = readCSVFromFile()
                            }
                        }) {
                            Image(systemName: showCSVData ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.blue)
                                
                        }.frame(width: 45.0, height: 27.0)
                        
                        Button(action: {
                            clearCSVFile()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 25))
                                .foregroundColor(.red)
                                
                        }.frame(width: 45.0, height: 27.0)
                    }.padding(.top)
                    
                    VStack(spacing: 5) {
                        SensorDataView(title: "Accelerometer", value: "\(self.sensorLogger.accX), \(self.sensorLogger.accY), \(self.sensorLogger.accZ)")

                        
                        SensorDataView(title: "Gyroscope", value: "\(self.sensorLogger.gyrX), \(self.sensorLogger.gyrY), \(self.sensorLogger.gyrZ)")
                        
                        if showCSVData {
                            VStack(spacing: 5) {
                                Text("CSV Data")
                                    .font(.headline)
                                
                                Text(csvData)
                                    .font(.system(.body))
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .navigationBarTitle("Logger")
        }
    }
    
    private func readCSVFromFile() -> String {
        let fileName = "sensor_data.csv"
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Failed to access document directory.")
            return ""
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            let csvData = try String(contentsOf: fileURL, encoding: .utf8)
            return csvData
        } catch {
            print("Error while reading CSV file: \(error)")
            return ""
        }
    }
    
    private func clearCSVFile() {
        let fileName = "sensor_data.csv"
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Failed to access document directory.")
            return
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            try "".write(to: fileURL, atomically: false, encoding: .utf8)
            print("CSV file cleared: \(fileURL.absoluteString)")
        } catch {
            print("Error while clearing CSV file: \(error)")
        }
    }
}

struct SensorDataView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
            
            Spacer() // Occupies the remaining space
        }
        .padding(5)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

