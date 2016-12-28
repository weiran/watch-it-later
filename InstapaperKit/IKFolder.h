//
//  IKFolder.h
//  InstapaperKit
//
//  Copyright (c) 2011 Matthias Plappert <matthiasplappert@me.com>
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute,
//  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>


enum {
    IKUnreadFolderID  = -1,
    IKStarredFolderID = -2,
    IKArchiveFolderID = -3
};


@interface IKFolder : NSObject {
    NSInteger _folderID;
    NSString *_title;
    BOOL _syncToMobile;
    NSUInteger _position;
}

@property (nonatomic, assign) NSInteger folderID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL syncToMobile;
@property (nonatomic, assign) NSUInteger position;

+ (IKFolder *)unreadFolder;
+ (IKFolder *)starredFolder;
+ (IKFolder *)archiveFolder;
+ (IKFolder *)folderWithFolderID:(NSInteger)folderID;
- (instancetype)initWithFolderID:(NSInteger)folderID NS_DESIGNATED_INITIALIZER;

@end
