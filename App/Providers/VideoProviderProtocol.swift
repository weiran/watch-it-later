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
    
    func videoStream(preferredFormatType: VideoFormatType?) -> Promise<VideoStream>
}

extension VideoProviderProtocol {
    func videoStream(preferredFormatType: VideoFormatType? = nil) -> Promise<VideoStream> {
        return videoStream(preferredFormatType: preferredFormatType)
    }
}
