//
//  AppDelegate.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/07.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize data;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    data = [[SkyData alloc] init];
    [self configureAudioSession];
    return YES;
}

- (void)configureAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback
                                       mode:AVAudioSessionModeSpokenAudio
                                    options:AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth
                                      error:&error];
    if (!success) {
        NSLog(@"Failed to set audio session category: %@", error);
    }

    success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"Failed to activate audio session: %@", error);
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success) {
        NSLog(@"Failed to activate audio session in background: %@", error);
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (!success) {
        NSLog(@"Failed to activate audio session in foreground: %@", error);
    }
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

@end

