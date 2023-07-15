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
                
                let url = URL(string: "http://localhost:3000/upload")!
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
//            .overlay(
//                Group {
//                    if showAlert {
//                        SnackbarView(message: alertMessage, duration: 3)
//                            .padding(.bottom, 100) // Adjust the position of the snackbar as needed
//                            .transition(.slide)
//                    }
//                }
//            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Upload Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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

//struct SnackbarView: View {
//    let message: String
//    let duration: Double
//    @State private var isShowing = true
//
//    var body: some View {
//        VStack {
//            Spacer()
//
//            HStack {
//                Text(message)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .background(Color.black)
//                    .cornerRadius(8)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.horizontal, 20)
//            .opacity(isShowing ? 1 : 0)
//            .animation(.easeInOut(duration: 0.3))
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//                isShowing = false
//            }
//        }
//    }
//}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

