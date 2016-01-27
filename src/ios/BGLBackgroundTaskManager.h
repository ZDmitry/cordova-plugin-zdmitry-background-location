//
//  BackgroundTaskManager.h
//
//  Created by Puru Shukla on 20/02/13.
//  Copyright (c) 2013 Puru Shukla. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BackgroundTaskManagerDelegate <NSObject>

-(void)backgroundTaskExpired:(unsigned long)taskId;

@end

@interface BackgroundTaskManager : NSObject

@property (nonatomic,weak) id<BackgroundTaskManagerDelegate> delegate;

+(instancetype)sharedBackgroundTaskManager;

-(UIBackgroundTaskIdentifier)beginNewBackgroundTask;
-(void)endAllBackgroundTasks;

@end
