//
//  IKEngine.m
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

#import "IKEngine.h"
#import "IKURLConnection.h"
#import "IKDeserializer.h"
#import "NSString+IKEncoding.h"
#import "IKUser.h"
#import "IKFolder.h"
#import "IKBookmark.h"
#import "IKConstants.h"
#import "IKURLConnection+Private.h"

#import "NSData+Base64.h"


@interface IKEngine ()

- (NSString *)_startConnectionWithAPIPath:(NSString *)path bodyArguments:(NSDictionary *)arguments type:(IKURLConnectionType)type userInfo:(id)userInfo context:(id)context;
- (NSString *)_signatureWithKey:(NSString *)key baseString:(NSString *)baseString;

@end


@implementation IKEngine

static NSString *_OAuthConsumerKey    = nil;
static NSString *_OAuthConsumerSecret = nil;

@synthesize delegate = _delegate, OAuthToken = _OAuthToken, OAuthTokenSecret = _OAuthTokenSecret;

+ (void)setOAuthConsumerKey:(NSString *)key andConsumerSecret:(NSString *)secret
{
    _OAuthConsumerKey = [key copy];
    
    _OAuthConsumerSecret = [secret copy];
}

- (instancetype)initWithDelegate:(id <IKEngineDelegate>)delegate
{
    if ((self = [super init])) {
        // Initial values
        _delegate         = delegate;
        _OAuthToken       = nil;
        _OAuthTokenSecret = nil;
        
        _connections = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithDelegate:nil];
}

#pragma mark -
#pragma mark Accessors

- (IKURLConnection *)connectionForIdentifier:(NSString *)identifier
{
    return _connections[identifier];
}

- (NSString *)identifierForConnection:(IKURLConnection *)connection
{
    return [_connections allKeysForObject:connection].lastObject;
}

- (NSUInteger)numberOfConnections
{
    return _connections.count;
}

#pragma mark -
#pragma mark Actions

- (NSString *)authTokenForUsername:(NSString *)username password:(NSString *)password userInfo:(id)userInfo
{
    NSDictionary *arguments = @{@"x_auth_username": username,
                                                                         @"x_auth_password": password,
                                                                         @"x_auth_mode": @"client_auth"};
    return [self _startConnectionWithAPIPath:@"/api/1/oauth/access_token"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeAuthAccessToken
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)verifyCredentialsWithUserInfo:(id)userInfo
{
    return [self _startConnectionWithAPIPath:@"/api/1/account/verify_credentials"
                               bodyArguments:nil
                                        type:IKURLConnectionTypeAuthVerifyCredentials
                                    userInfo:userInfo
                                     context:nil];
    return nil;
}

#pragma mark -

- (NSString *)bookmarksWithUserInfo:(id)userInfo
{
    return [self bookmarksInFolder:[IKFolder unreadFolder]
                             limit:25
                 existingBookmarks:nil
                          userInfo:userInfo];
}

- (NSString *)bookmarksInFolder:(IKFolder *)folder limit:(NSUInteger)limit existingBookmarks:(NSArray *)bookmarks userInfo:(id)userInfo
{
    NSNumber *limitObj = @(limit);
    
    NSString *folderID;
    switch (folder.folderID) {
        case IKUnreadFolderID:
            folderID = @"unread";
            break;
        case IKStarredFolderID:
            folderID = @"starred";
            break;
        case IKArchiveFolderID:
            folderID = @"archive";
            break;
        default:
            folderID = [NSString stringWithFormat:@"%ld", (long)folder.folderID];
            break;
    }
    
    NSMutableString *have = [NSMutableString string];
    if (bookmarks.count > 0) {
        for (IKBookmark *bookmark in bookmarks) {
            [have appendFormat:@"%ld", (long)bookmark.bookmarkID];
            if (bookmark.hashString) {
                [have appendFormat:@":%@", bookmark.hashString];
            }
            if (bookmark.progressDate && bookmark.progress != -1.0f) {
                int timestamp = (int)(bookmark.progressDate).timeIntervalSince1970;
                [have appendFormat:@":%f:%d", bookmark.progress, timestamp];
            }
            [have appendFormat:@","];
        }
        
        // Replace last ,
        [have replaceCharactersInRange:NSMakeRange(have.length - 1, 1) withString:@""];
    }
    
    NSDictionary *arguments = @{@"limit": limitObj,
                                                                         @"folder_id": folderID,
                                                                         @"have": have};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/list"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksList
                                    userInfo:userInfo
                                     context:folder];
}

- (NSString *)updateReadProgressOfBookmark:(IKBookmark *)bookmark toProgress:(CGFloat)progress userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSNumber *progressObj   = [NSNumber numberWithFloat:progress];
    NSNumber *timestampObj  = @((NSInteger)[NSDate date].timeIntervalSince1970);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj,
                               @"progress": progressObj,
                               @"progress_timestamp": timestampObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/update_read_progress"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksUpdateReadProgress
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)addBookmarkWithURL:(NSURL *)URL userInfo:(id)userInfo
{
    return [self addBookmarkWithURL:URL title:nil description:nil folder:nil resolveFinalURL:YES userInfo:userInfo];
}

- (NSString *)addBookmarkWithURL:(NSURL *)URL title:(NSString *)title description:(NSString *)description folder:(IKFolder *)folder resolveFinalURL:(BOOL)resolveFinalURL userInfo:(id)userInfo
{
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"url"] = URL.absoluteString;
    if (title != nil) {
        arguments[@"title"] = title;
    }
    if (description != nil) {
        arguments[@"description"] = description;
    }
    if (folder != nil) {
        arguments[@"folder_id"] = @(folder.folderID);
    }
    arguments[@"resolve_final_url"] = @(resolveFinalURL);
    
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/add"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksAdd
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)deleteBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/delete"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksDelete
                                    userInfo:userInfo
                                     context:bookmarkIDObj];
}

- (NSString *)starBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/star"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksStar
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)unstarBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/unstar"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksUnstar
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)archiveBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/archive"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksArchive
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)unarchiveBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/unarchive"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksUnarchive
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)moveBookmark:(IKBookmark *)bookmark toFolder:(IKFolder *)folder userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSNumber *folderIDObj   = @(folder.folderID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj,
                               @"folder_id": folderIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/move"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksMove
                                    userInfo:userInfo
                                     context:folderIDObj];
}

- (NSString *)textOfBookmark:(IKBookmark *)bookmark userInfo:(id)userInfo
{
    NSNumber *bookmarkIDObj = @(bookmark.bookmarkID);
    NSDictionary *arguments = @{@"bookmark_id": bookmarkIDObj};
    return [self _startConnectionWithAPIPath:@"/api/1/bookmarks/get_text"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeBookmarksText
                                    userInfo:userInfo
                                     context:bookmarkIDObj];
}

#pragma mark -

- (NSString *)foldersWithUserInfo:(id)userInfo
{
    return [self _startConnectionWithAPIPath:@"/api/1/folders/list"
                               bodyArguments:nil
                                        type:IKURLConnectionTypeFoldersList
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)addFolderWithTitle:(NSString *)title userInfo:(id)userInfo
{
    NSDictionary *arguments = @{@"title": title};
    
    return [self _startConnectionWithAPIPath:@"/api/1/folders/add"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeFoldersAdd
                                    userInfo:userInfo
                                     context:nil];
}

- (NSString *)deleteFolder:(IKFolder *)folder userInfo:(id)userInfo
{
    NSNumber *folderIDObj   = @(folder.folderID);
    NSDictionary *arguments = @{@"folder_id": folderIDObj};    
    return [self _startConnectionWithAPIPath:@"/api/1/folders/delete"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeFoldersDelete
                                    userInfo:userInfo
                                     context:folderIDObj];
}

- (NSString *)orderFolders:(NSArray *)folders userInfo:(id)userInfo
{
    if (folders.count == 0) {
        return nil;
    }
    
    NSMutableString *orderString = [NSMutableString string];
    for (NSUInteger i = 0; i < folders.count; i++) {
        IKFolder *folder = folders[i];
        [orderString appendFormat:@"%ld:%lu,", (long)folder.folderID, (unsigned long)i];
    }
    
    // Replace last ,
    [orderString replaceCharactersInRange:NSMakeRange(orderString.length - 1, 1) withString:@""];
    
    NSDictionary *arguments = @{@"order": orderString};
    
    return [self _startConnectionWithAPIPath:@"/api/1/folders/set_order"
                               bodyArguments:arguments
                                        type:IKURLConnectionTypeFoldersOrder
                                    userInfo:userInfo
                                     context:nil];
}

#pragma mark -

- (void)cancelConnection:(IKURLConnection *)connection
{
    NSString *identifier = [self identifierForConnection:connection];
    if (identifier != nil) {
        [connection cancel];
        
        if ([self.delegate respondsToSelector:@selector(engine:didCancelConnection:)]) {
            [self.delegate engine:self didCancelConnection:connection];
        }
        
        [_connections removeObjectForKey:identifier];
    }
}

- (void)cancelAllConnections
{
    NSDictionary *connectionsCopy = [[NSDictionary alloc] initWithDictionary:_connections];
    for (NSString *key in connectionsCopy) {
        IKURLConnection *connection = connectionsCopy[key];
        [self cancelConnection:connection];
    }
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(IKURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    [connection _setResponse:response];
}

- (void)connection:(IKURLConnection *)connection didReceiveData:(NSData *)data
{
    [connection _appendData:data];
}

- (void)connection:(IKURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(engine:didFailConnection:error:)]) {
        [self.delegate engine:self didFailConnection:connection error:error];
    }
    
    NSString *identifier = [self identifierForConnection:connection];
    [_connections removeObjectForKey:identifier];
}

- (void)connectionDidFinishLoading:(IKURLConnection *)connection
{
    NSString *responseString = [[NSString alloc] initWithData:connection.data
                                                     encoding:NSUTF8StringEncoding];
    
    NSError *responseError = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorBadServerResponse
                                             userInfo:nil];
    
    IKURLConnectionType type = connection.type;
    if (type == IKURLConnectionTypeAuthAccessToken) {
        NSInteger statusCode = connection.response.statusCode;
        if (statusCode != 200) {
            // Invalid response
            NSDictionary *userInfo = @{IKErrorMessageKey: responseString};
            NSError *error = [NSError errorWithDomain:IKErrorDomain code:statusCode userInfo:userInfo];
            [self connection:connection didFailWithError:error];
            return;
        }
        
        // Extract token & secret
        NSString *token  = nil;
        NSString *secret = nil;
        if (![IKDeserializer token:&token andTokenSecret:&secret fromQlineString:responseString]) {
            // Invalid response
            [self connection:connection didFailWithError:responseError];
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(engine:connection:didReceiveAuthToken:andTokenSecret:)]) {
            [self.delegate engine:self connection:connection didReceiveAuthToken:token andTokenSecret:secret];
        }
        
        // Assign
        self.OAuthToken       = token;
        self.OAuthTokenSecret = secret;
        
    } else if (type == IKURLConnectionTypeBookmarksText) {
        if (connection.response.statusCode == 200) {
            // Received text
            if ([self.delegate respondsToSelector:@selector(engine:connection:didReceiveText:ofBookmarkWithBookmarkID:)]) {
                NSInteger bookmarkID = [[connection _context] integerValue];
                [self.delegate engine:self connection:connection didReceiveText:responseString ofBookmarkWithBookmarkID:bookmarkID];
            }
            
        } else {
            NSError *result = [IKDeserializer objectFromJSONString:responseString];
            if (result != nil && [result isKindOfClass:[NSError class]]) {
                // Error object
                [self connection:connection didFailWithError:result];
            } else {
                // Invalid JSON
                [self connection:connection didFailWithError:responseError];
            }
            
            return;
        }
        
    } else {
        // Deserialize
        NSArray *result = [IKDeserializer objectFromJSONString:responseString];
        if (!result) {
            // Invalid JSON
            [self connection:connection didFailWithError:responseError];
            return;
        } else if ([result isKindOfClass:[NSError class]]) {
            // Error object
            [self connection:connection didFailWithError:(NSError *)result];
            return;
        }
        
        switch (type) {
            case IKURLConnectionTypeAuthVerifyCredentials: {
                // Get user
                IKUser *user = result.lastObject;
                if (!user || ![user isKindOfClass:[IKUser class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didVerifyCredentialsForUser:)]) {
                    [self.delegate engine:self connection:connection didVerifyCredentialsForUser:user];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksList: {
                // Get objects from array
                IKUser *user = nil;
                NSMutableArray *bookmarks = [NSMutableArray array];
                for (id object in result) {
                    if ([object isKindOfClass:[IKUser class]]) {
                        user = (IKUser *)object;
                    } else if ([object isKindOfClass:[IKBookmark class]]) {
                        [bookmarks addObject:object];
                    }
                }
                
                //  Retrieve folder ID from connection context
                IKFolder *folder = (IKFolder *)[connection _context];
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didReceiveBookmarks:ofUser:forFolder:)]) {
                    [self.delegate engine:self connection:connection didReceiveBookmarks:bookmarks ofUser:user forFolder:folder];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksUpdateReadProgress: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didUpdateReadProgressOfBookmark:)]) {
                    [self.delegate engine:self connection:connection didUpdateReadProgressOfBookmark:bookmark];
                }
                break;
            }
            
            case IKURLConnectionTypeBookmarksAdd: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didAddBookmark:)]) {
                    [self.delegate engine:self connection:connection didAddBookmark:bookmark];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksDelete: {
                // Get bookmark id
                NSInteger bookmarkID = [[connection _context] integerValue];
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didDeleteBookmarkWithBookmarkID:)]) {
                    [self.delegate engine:self connection:connection didDeleteBookmarkWithBookmarkID:bookmarkID];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksStar: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didStarBookmark:)]) {
                    [self.delegate engine:self connection:connection didStarBookmark:bookmark];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksUnstar: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didUnstarBookmark:)]) {
                    [self.delegate engine:self connection:connection didUnstarBookmark:bookmark];
                }
                break;
            }    
                
            case IKURLConnectionTypeBookmarksArchive: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didArchiveBookmark:)]) {
                    [self.delegate engine:self connection:connection didArchiveBookmark:bookmark];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksUnarchive: {
                // Get bookmark
                IKBookmark *bookmark = result.lastObject;
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didUnarchiveBookmark:)]) {
                    [self.delegate engine:self connection:connection didUnarchiveBookmark:bookmark];
                }
                break;
            }
                
            case IKURLConnectionTypeBookmarksMove: {
                // Get bookmark and folder ID
                IKBookmark *bookmark = result.lastObject;
                NSInteger folderID   = [[connection _context] integerValue];
                if (!bookmark || ![bookmark isKindOfClass:[IKBookmark class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didMoveBookmark:toFolderWithFolderID:)]) {
                    [self.delegate engine:self connection:connection didMoveBookmark:bookmark toFolderWithFolderID:folderID];
                }
                break;
            }
                
            case IKURLConnectionTypeFoldersList: {
                NSMutableArray *folders = [NSMutableArray array];
                for (id object in result) {
                    if ([object isKindOfClass:[IKFolder class]]) {
                        [folders addObject:object];
                    }
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didReceiveFolders:)]) {
                    [self.delegate engine:self connection:connection didReceiveFolders:folders];
                }
                break;
            }
                
            case IKURLConnectionTypeFoldersAdd: {
                // Get folder
                IKFolder *folder = result.lastObject;
                if (!folder || ![folder isKindOfClass:[IKFolder class]]) {
                    // Invalid response
                    [self connection:connection didFailWithError:responseError];
                    return;
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didAddFolder:)]) {
                    [self.delegate engine:self connection:connection didAddFolder:folder];
                }
                break;
            }
                
            case IKURLConnectionTypeFoldersDelete: {
                // Get folder id
                NSInteger folderID = [[connection _context] integerValue];
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didDeleteFolderWithFolderID:)]) {
                    [self.delegate engine:self connection:connection didDeleteFolderWithFolderID:folderID];
                }
                break;
            }
                
            case IKURLConnectionTypeFoldersOrder: {
                NSMutableArray *folders = [NSMutableArray array];
                for (id object in result) {
                    if ([object isKindOfClass:[IKFolder class]]) {
                        [folders addObject:object];
                    }
                }
                
                // Inform delegate
                if ([self.delegate respondsToSelector:@selector(engine:connection:didOrderFolders:)]) {
                    [self.delegate engine:self connection:connection didOrderFolders:folders];
                }
                break;
            }
            
            default:
                break;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(engine:didFinishConnection:)]) {
        [self.delegate engine:self didFinishConnection:connection];
    }
    
    NSString *identifier = [self identifierForConnection:connection];
    [_connections removeObjectForKey:identifier];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
    _delegate = nil;
    [self cancelAllConnections];
    
    
    
}

#pragma mark -
#pragma mark Private methods

- (NSString *)_startConnectionWithAPIPath:(NSString *)path bodyArguments:(NSDictionary *)arguments type:(IKURLConnectionType)type userInfo:(id)userInfo context:(id)context
{
    // Create full URL
    static NSURL *baseURL = nil;
    if (baseURL == nil) {
        baseURL = [[NSURL alloc] initWithString:@"https://www.instapaper.com"];
    }
    NSURL *URL = [NSURL URLWithString:path relativeToURL:baseURL];
    if (!URL) {
        return nil;
    }
    
    // Encode body
    NSMutableDictionary *encodedArguments = [NSMutableDictionary dictionary];
    for (NSString *key in arguments) {
        NSString *encodedKey   = [key URLEncodedStringUsingEncoding:NSUTF8StringEncoding];
        id argument = arguments[key];
        if (![argument isKindOfClass:[NSString class]]) {
            argument = [argument stringValue];
        }
        NSString *encodedValue = [argument URLEncodedStringUsingEncoding:NSUTF8StringEncoding];
        encodedArguments[encodedKey] = encodedValue;
    }
    
    // Create body
    NSMutableString *bodyString = [NSMutableString string];
    if (encodedArguments.count > 0) {
        for (NSString *key in encodedArguments) {
            NSString *value = encodedArguments[key];
            [bodyString appendFormat:@"%@=%@&", key, value];
        }
        
        // Remove last &
        [bodyString replaceCharactersInRange:NSMakeRange(bodyString.length - 1, 1) withString:@""];
    }
    
    // Request properties
    NSString *HTTPMethod = @"POST";
    NSString *encodedURL = [URL.absoluteString URLEncodedStringUsingEncoding:NSUTF8StringEncoding];
    
    // OAuth properties
    NSString *OAuthNonce = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *OAuthSignatureMethod = @"HMAC-SHA1";
    NSString *OAuthTimestamp = [NSString stringWithFormat:@"%d", (int)[NSDate date].timeIntervalSince1970];
    NSString *OAuthVersion = @"1.0";
    
    // Create oauth arguments
    NSMutableDictionary *OAuthArguments = [NSMutableDictionary dictionary];
    OAuthArguments[@"oauth_nonce"] = OAuthNonce;
    OAuthArguments[@"oauth_signature_method"] = OAuthSignatureMethod;
    OAuthArguments[@"oauth_timestamp"] = OAuthTimestamp;
    OAuthArguments[@"oauth_consumer_key"] = _OAuthConsumerKey;
    OAuthArguments[@"oauth_version"] = OAuthVersion;
    if (self.OAuthToken) {
        OAuthArguments[@"oauth_token"] = self.OAuthToken;
    }
    
    // Merge oauth request arguments
    NSMutableDictionary *mergedArguments = [NSMutableDictionary dictionaryWithDictionary:encodedArguments];
    [mergedArguments addEntriesFromDictionary:OAuthArguments];
    
    // Sort keys and generate signature base string
    NSArray *sortedKeys = [mergedArguments.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableString *signatureBaseString = [NSMutableString stringWithFormat:@"%@&%@&", HTTPMethod, encodedURL];
    for (NSString *key in sortedKeys) {
        NSString *encodedKey   = [key URLEncodedStringUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedValue = [mergedArguments[key] URLEncodedStringUsingEncoding:NSUTF8StringEncoding];
        [signatureBaseString appendFormat:@"%@%%3D%@%%26", encodedKey, encodedValue];
    }
    
    // Replace last %26
    [signatureBaseString replaceCharactersInRange:NSMakeRange(signatureBaseString.length - 3, 3) withString:@""];
    
    // Calculate signature
    NSString *key       = [NSString stringWithFormat:@"%@&%@", _OAuthConsumerSecret, (!_OAuthTokenSecret ? @"" : _OAuthTokenSecret)];
    NSString *signature = [self _signatureWithKey:key baseString:signatureBaseString];
    OAuthArguments[@"oauth_signature"] = signature;
    
    // Create request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Authorization header
    NSMutableString *authHeader = [NSMutableString stringWithString:@"OAuth "];
    for (NSString *key in OAuthArguments) {
        NSString *value = OAuthArguments[key];
        [authHeader appendFormat:@"%@=\"%@\", ", key, value];
    }
    
    // Replace last ", " and append to request
    [authHeader replaceCharactersInRange:NSMakeRange(authHeader.length - 2, 2) withString:@""];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    // Create connection
    IKURLConnection *connection = [[IKURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:NO];
    [connection _setType:type];
    [connection _setUserInfo:userInfo];
    [connection _setContext:context];
    
    // Add to dictionary
    NSString *identifier = [NSProcessInfo processInfo].globallyUniqueString;
    _connections[identifier] = connection;
    
    // Inform delegate
    if ([self.delegate respondsToSelector:@selector(engine:willStartConnection:)]) {
        [self.delegate engine:self willStartConnection:connection];
    }
    
    // Run
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
    
    return identifier;
}

- (NSString *)_signatureWithKey:(NSString *)key baseString:(NSString *)baseString
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [baseString cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    NSString *hash = [HMAC base64EncodedString];
    
    return hash;
}

@end
