//
//  ContentView.swift
//  Logger Watch App
//
//  Created by Stephen Vaz on 13/07/23.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var logStarting = false
    @State private var showCSVData = false
    @State private var csvData = ""
    
    @State private var elapsedTime = 0  // <-- Add this line
        
        // Start or stop a timer based on the logStarting state
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
    @ObservedObject var sensorLogger = SensorLogManager()
    
//    upload
    private func exportData() {
            let fileName = "sensor_data.csv"
            guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Error: Failed to access document directory.")
                return
            }
            
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            do {
                let csvData = try Data(contentsOf: fileURL)
                
//                let url = URL(string: "http://localhost:3000/upload")!
                let url = URL(string: "https://thalla.serveo.net/upload")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                let boundary = UUID().uuidString
                let contentType = "multipart/form-data; boundary=\(boundary)"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                var body = Data()
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"csvFile\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
                body.append(csvData)
                body.append("\r\n".data(using: .utf8)!)
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = body
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        print("Error while uploading CSV file: \(error)")
                        alertMessage = "Upload Error"
                        showAlert = true
                    } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("CSV file uploaded successfully. Response: \(responseString)")
                        alertMessage = "Upload Successful"
                        showAlert = true
                    }
                }
                
                task.resume()
            } catch {
                print("Error while reading CSV file: \(error)")
            }
        }
//    upload
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        Button(action: {
                            self.logStarting.toggle()
                            
                            if self.logStarting {
                                self.sensorLogger.startUpdate(50.0)
                                self.elapsedTime = 0

                            } else {
                                self.sensorLogger.stopUpdate()
//                                self.timer.upstream.connect().cancel()

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
                        
                        Text("Time: \(timeString(time: elapsedTime))") // <-- Modify this line
                            .onReceive(timer) { _ in
                                if self.logStarting {
                                    self.elapsedTime += 1
                                }
                            }
                        
                        SensorDataView(title: "Accelerometer", value: "\(self.sensorLogger.accX), \(self.sensorLogger.accY), \(self.sensorLogger.accZ)")

                        
                        SensorDataView(title: "Gyroscope", value: "\(self.sensorLogger.gyrX), \(self.sensorLogger.gyrY), \(self.sensorLogger.gyrZ)")
                        
                        if showCSVData {
                            VStack(spacing: 5) {
                                HStack(spacing: 15) {
                                    Text("CSV Data")
                                        .font(.headline)
                                    Button(action: {
                                                            exportData()
                                                        }) {
                                                            Image(systemName: "square.and.arrow.up")
                                                                .font(.system(size: 15))
                                                                .foregroundColor(.green)
                                                        }
                                                        .frame(width: 40.0)
                                }
                                
                                
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Upload Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func timeString(time: Int) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
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
            
            Spacer()
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

