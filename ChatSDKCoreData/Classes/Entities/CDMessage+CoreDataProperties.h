//
//  CDMessage+CoreDataProperties.h
//  Pods
//
//  Created by Benjamin Smiley-andrews on 05/09/2016.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "CDMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CDMessage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSNumber *delivered;
@property (nullable, nonatomic, retain) NSNumber *dirty;
@property (nullable, nonatomic, retain) NSString *entityID;
@property (nullable, nonatomic, retain) NSNumber *flagged;
@property (nullable, nonatomic, retain) NSData *placeholder;
@property (nullable, nonatomic, retain) NSNumber *read;
@property (nullable, nonatomic, retain) NSData *resource;
@property (nullable, nonatomic, retain) NSString *resourcePath;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSNumber *type;
@property (nullable, nonatomic, retain) CDThread *thread;
@property (nullable, nonatomic, retain) CDUser *user;
@property (nullable, nonatomic, retain) id status;
@property (nullable, nonatomic, retain) id meta;
@property (nullable, nonatomic, retain) id json;
@property (nullable, nonatomic, retain) CDMessage * lastMessage;
@property (nullable, nonatomic, retain) CDMessage * nextMessage;
@property (nullable, nonatomic, retain) CDThread * lastMessageThread;

@end

NS_ASSUME_NONNULL_END
