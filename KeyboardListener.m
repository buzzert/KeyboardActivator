#import <libactivator/libactivator.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <UIKit/UIApplication2.h>
#import <UIKit/UITextInputPrivate.h>
#import <UIKit/UIKeyboardImpl.h>

@interface KeyboardActivator : NSObject<LAListener>
- (void)toggleKeyboardWithNotification:(NSNotification*)note;
@end

static KeyboardActivator *_sharedInstance = nil;
static NSString * const bundleName = @"com.omegahern.keyboardactivator";
static NSString * const notificationName = @"KeyboardActivatorToggle";

void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@implementation KeyboardActivator

+ (KeyboardActivator*)sharedInstance {
	if (_sharedInstance == nil) {
		_sharedInstance = [[self alloc] init];
	}

	return _sharedInstance;
}

- (void)toggleKeyboardWithNotification:(NSNotification*)note {
	UIKeyboardImpl *keyboard = [UIKeyboardImpl activeInstance];

	// If keyboard is not nil, then this application has an active keyboard instance...
	if (keyboard != nil) {
		if ([keyboard isMinimized]) {
			[keyboard showKeyboard];
		} else {
			[keyboard hideKeyboard];
		}
	}
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	// SpringBoard receives the activator event, and fires of a notification to the
	// darwin notification center
	CFNotificationCenterPostNotification (
		CFNotificationCenterGetDarwinNotifyCenter(),
		(CFStringRef) notificationName,
		NULL,
		NULL,
		true
	);
}

- (void)dealloc {
	CFNotificationCenterRemoveObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		self,
		(CFStringRef) notificationName
		NULL
	);

	[super dealloc];
}

void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// SpringBoard sent us a lovely message! He talks to himself too.
	[[KeyboardActivator sharedInstance] toggleKeyboardWithNotification:nil];
}

+ (void)load {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Only springboard should register for this listener (handles event, posts notification)
	if ([[LAActivator sharedInstance] listenerForName:bundleName] == nil) {
		[[LAActivator sharedInstance] registerListener:[self sharedInstance] forName:bundleName];
	}

	// Now register for keyboard notification (including springboard)
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), 
		self, 
		&notificationCallback, 
		(CFStringRef) notificationName, 
		NULL, 
		0x0 	// This argument is ignored by the Darwin notification center
	);

	[pool release];
}

@end 