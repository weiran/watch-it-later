//
//  VideoError.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 23/12/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

enum VideoError: Error {
    case InvalidURL
    case NoStreamURLFound
    case NoThumbnailURLFound
    case UnknownError
}
