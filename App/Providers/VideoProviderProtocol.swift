//
//  VideoProviderProtocol.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import PromiseKit

protocol VideoProviderProtocol {
    
    init(_ url: String) throws
    
    func streamURL() -> Promise<URL>
    func thumbnailURL() -> Promise<URL>
    func duration() -> Promise<Double>
    
}

enum VideoError: Error {
    
    case InvalidURL
    case NoStreamURLFound
    case NoThumbnailURLFound
    
}
