//
// HCVimeoVideo.swift
// HCVimeoVideoExtractor
//
// Created by Mo Cariaga on 13/02/2018.
// Copyright (c) 2018 Mo Cariaga <hermoso.cariaga@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit

public enum HCVimeoThumbnailQuality: String {
   case quality640 = "640"
   case quality960 = "960"
   case quality1280 = "1280"
   case qualityBase = "base"
   case qualityUnknown = "unknown"
}

public enum HCVimeoVideoQuality: String {
   case quality360p = "360p"
   case quality540p = "540p"
   case quality640p = "640p"
   case quality720p = "720p"
   case quality960p = "960p"
   case quality1080p = "1080p"
   case qualityUnknown = "unknown"
}

public class HCVimeoVideo: NSObject {
   public var title = ""
   public var thumbnailURL = [HCVimeoThumbnailQuality: URL]()
   public var videoURL = [HCVimeoVideoQuality: URL]()
   public var duration = 0
}
