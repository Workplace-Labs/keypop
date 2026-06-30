#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *KSProbeFrameworkPath(void);
FOUNDATION_EXPORT NSDictionary<NSString *, id> *KSProbeInspect(void);
FOUNDATION_EXPORT NSDictionary<NSString *, id> *KSProbeReadSources(NSError **error);
FOUNDATION_EXPORT NSArray<NSDictionary<NSString *, id> *> *KSTextReplacementList(NSError **error);
FOUNDATION_EXPORT BOOL KSPrivateCreate(NSString *shortcut, NSString *phrase, NSError **error);
FOUNDATION_EXPORT BOOL KSPrivateUpdate(NSString *shortcut, NSString *phrase, NSError **error);
FOUNDATION_EXPORT BOOL KSPrivateDelete(NSString *shortcut, NSError **error);

NS_ASSUME_NONNULL_END
