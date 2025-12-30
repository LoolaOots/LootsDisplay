import Foundation

class NetworkManager {
    
    struct APIConfig {
        static let baseURL = "https://loola.ngrok.app/natasha"
        
        //Post
        static let saveFileURL = "\(baseURL)/save-json-file"
        
        //Get
        static let getUserFilesURL = "\(baseURL)/list-json-files"
        static let getFileURL = "\(baseURL)/json-file/:filename"
    }
    
    struct SaveResponse: Codable {
        let success: Bool
        let filename: String?
    }
    
    static func exportSession(_ session: RecordingSession, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: APIConfig.saveFileURL) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("46c36e1b-8bc2-4e98-9753-3d16050a3c51", forHTTPHeaderField: "x-api-key")
        
        do {
            let jsonData = try JSONEncoder().encode(session.frames)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Handle Network-level errors (e.g. timeout, no internet)
                if let error = error {
                    print("Network Error: \(error.localizedDescription)")
                    completion(false, "Export Failed: Network Error")
                    return
                }
                
                // Check HTTP Status Code
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard statusCode == 200, let data = data else {
                    print("Server Error: \(statusCode)")
                    completion(false, "Export Failed: Server Error")
                    return
                }
                
                // Decode the server's JSON response to check the "success" field
                do {
                    let decodedResponse = try JSONDecoder().decode(SaveResponse.self, from: data)
                    
                    if decodedResponse.success {
                        // Logic check: The server explicitly said it was successful
                        let serverFile = decodedResponse.filename ?? "File"
                        print("Successfully saved: \(serverFile)")
                        completion(true, "Export Successful")
                    } else {
                        // The request reached the server, but the server logic failed
                        print("Error: Server Rejected Data")
                        completion(false, "Export Failed")
                    }
                } catch {
                    // The server sent back something that wasn't valid JSON
                    print("JSON Decoding Error: \(error)")
                    completion(false, "Export Failed")
                }
            }.resume()
            
        } catch {
            print("Encoding Failure")
            completion(false, "Export Failed: Encoding Failure")
        }
    }
}
