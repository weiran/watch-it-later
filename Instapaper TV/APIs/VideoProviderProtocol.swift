//
//  VideoProviderProtocol.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 29/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import PromiseKit

protocol VideoProviderProtocol {
    
    init(_ url: String) throws
    
    func streamURL() -> Promise<URL>
    func thumbnailURL() -> Promise<URL>
    func description() -> Promise<String>
    
}

enum VideoError: Error {
    
    case InvalidURL
    case NoStreamURLFound
    case NoThumbnailURLFound
    
}
