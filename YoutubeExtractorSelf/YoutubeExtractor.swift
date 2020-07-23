
//
//  Created by Nitin on 03/07/20.
//  Copyright © 2020 Nitin. All rights reserved.
//

import Foundation


public class YoutubeExtractor {
    
    private let infoBasePrefix = "https://www.youtube.com/get_video_info?video_id="
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"
   
    private var session: URLSession
    
    // MARK: - Public
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public convenience init() {
        self.init(session: URLSession.shared)
    }
    
    public func extractInfo(for source: ExtractionSource,
                            success: @escaping (VideoInfo) -> Void,
                            failure: @escaping (Swift.Error) -> Void) {
        
        extractRawInfo(for: source) { info, error in
            
            if let error = error {
                failure(error)
                return
            }
            
            guard info.count > 0 else {
                failure(Error.unkown)
                return
            }
            
            success(VideoInfo(rawInfo: info))
        }
    }
    
    // MARK: - Internal
    
    func extractRawInfo(for source: ExtractionSource,
                        completion: @escaping ([[String: String]], Swift.Error?) -> Void) {
        
        guard let id = source.videoId else {
            completion([], Error.cantExtractVideoId)
            return
        }
        
        guard let infoUrl = URL(string: "\(infoBasePrefix)\(id)") else {
            completion([], Error.cantConstructRequestUrl)
            return
        }
        
        let r = NSMutableURLRequest(url: infoUrl)
        r.httpMethod = "GET"
        r.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        session.dataTask(with: r as URLRequest) { data, response, error in

            guard let data = data else {
                completion([], error ?? Error.noDataInResponse)
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                completion([], Error.cantConvertDataToString)
                return
            }
            
            let extractionResult = self.extractInfo(from: dataString)
            completion(extractionResult.0, extractionResult.1)
            
        }.resume()
    }
    
    func extractInfo(from string: String) -> ([[String: String]], Swift.Error?) {
        let pairs = string.queryComponents()
        
        guard let playerResponse = pairs["player_response"], !playerResponse.isEmpty else {
            let error = YoutubeError(errorDescription: pairs["reason"])
            return ([], error ?? Error.cantExtractURLFromYoutubeResponse)
        }
        
        guard let playerResponseData = playerResponse.data(using: .utf8),
        let playerResponseJSON = (try? JSONSerialization.jsonObject(with: playerResponseData, options: [])) as? [String: Any],
        let streamingData = playerResponseJSON["streamingData"] as? [String: Any],
        let formats = streamingData["formats"] as? [[String: Any]] else {
            return ([], Error.cantExtractURLFromYoutubeResponse)
        }
        
        let arrayUrls: [[String: String]] = formats
        .compactMap { $0["url"] as? String }
        .map { ["url": $0] }

        return (arrayUrls, nil)
    }
}



public enum ExtractionSource {
    case url(URL)
    case urlString(String)
    case id(String)
    
    var videoId: String? {
        switch self {
            
        case .url(let url):
            return videoId(from: url)
            
        case .urlString(let string):
            guard let url = URL(string: string) else {
                return nil
            }
            return videoId(from: url)
            
        case .id(let videoId):
            return videoId
        }
    }
    
    private func videoId(from url: URL) -> String? {
        guard let host = url.host else {
            return nil
        }
        
        let components = url.pathComponents
        
        switch host {
            
        case _ where host.contains("youtu.be"):
            return components[safe: 1]
            
        case _ where host.contains("m.youtube.com"):
            return url.absoluteString.components(separatedBy: "?").last?.queryComponents()["v"]
            
        case _ where host.contains("youtube.com")
            && components[safe: 1] == "embed":
            return components[safe: 2]
            
        case _ where host.contains("youtube.com")
            && components[safe: 1] != "embed":
            return url.query?.queryComponents()["v"]
            
        default:
            return nil
        }
    }
}

extension Array {
    
    subscript (safe index: Int) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}


enum Error: String, LocalizedError {
    case cantExtractVideoId = "Couldn't extract video id from the url"
    case cantConstructRequestUrl = "Couldn't construct URL for youtube info request"
    case noDataInResponse = "No data in youtube info response"
    case cantConvertDataToString = "Couldn't convert response data to string"
    case cantExtractURLFromYoutubeResponse = "Couldn't extract url from youtube response"
    case unkown = "Unknown error occured"
    
    var errorDescription: String? {
        return self.rawValue
    }
}

struct YoutubeError: LocalizedError {
    var errorDescription: String?
    
    init?(errorDescription: String?) {
        guard let errorDescription = errorDescription else {
            return nil
        }
        
        self.errorDescription = errorDescription
    }
}


extension String {
    
    func queryComponents() -> [String: String] {
        var pairs: [String: String] = [:]
        
        for pair in self.components(separatedBy: "&") {
            let pairArr = pair.components(separatedBy: "=")
            
            guard pairArr.count == 2,
            let key = pairArr.first?.decodedFromUrl(),
            let value = pairArr.last?.decodedFromUrl() else {
                continue
            }
            
            pairs[key] = value
        }
        
        return pairs
    }
    
    func decodedFromUrl() -> String? {
        return self.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
}
