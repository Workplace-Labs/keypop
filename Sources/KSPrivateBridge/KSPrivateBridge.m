#import "KSPrivateBridge.h"
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>

static NSString *const KSBridgeErrorDomain = @"JF.KSPrivateBridge";

NSString *KSProbeFrameworkPath(void) {
    return @"/System/Library/PrivateFrameworks/KeyboardServices.framework/KeyboardServices";
}

static NSError *KSError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:KSBridgeErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static BOOL KSLoadFramework(NSError **error) {
    void *handle = dlopen(KSProbeFrameworkPath().UTF8String, RTLD_LAZY | RTLD_LOCAL);
    if (handle != NULL) {
        return YES;
    }

    if (error != NULL) {
        const char *dlError = dlerror();
        NSString *detail = dlError != NULL ? [NSString stringWithUTF8String:dlError] : @"unknown dlopen error";
        *error = KSError(1, [NSString stringWithFormat:@"Unable to load KeyboardServices: %@", detail]);
    }
    return NO;
}

static BOOL KSTry(BOOL (^block)(NSError **innerError), NSError **error) {
    NSError *innerError = nil;
    @try {
        BOOL result = block(&innerError);
        if (!result && error != NULL && innerError != nil) {
            *error = innerError;
        }
        return result;
    } @catch (NSException *exception) {
        if (error != NULL) {
            *error = KSError(99, [NSString stringWithFormat:@"%@: %@", exception.name, exception.reason]);
        }
        return NO;
    }
}

static NSArray<NSString *> *KSMethodNamesForClass(Class cls, BOOL metaClass) {
    if (cls == Nil) {
        return @[];
    }
    Class target = metaClass ? object_getClass(cls) : cls;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(target, &count);
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int index = 0; index < count; index += 1) {
        SEL selector = method_getName(methods[index]);
        if (selector != nil) {
            [names addObject:NSStringFromSelector(selector)];
        }
    }
    free(methods);
    return [names sortedArrayUsingSelector:@selector(compare:)];
}

static Class KSClass(NSString *name) {
    return NSClassFromString(name);
}

static id KSNew(NSString *className, NSError **error) {
    Class cls = KSClass(className);
    if (cls == Nil) {
        if (error != NULL) {
            *error = KSError(2, [NSString stringWithFormat:@"Missing class %@", className]);
        }
        return nil;
    }
    return [[cls alloc] init];
}

static id KSAllocInitWithString(NSString *className, NSString *selectorName, NSString *argument, NSError **error) {
    Class cls = KSClass(className);
    if (cls == Nil) {
        if (error != NULL) {
            *error = KSError(2, [NSString stringWithFormat:@"Missing class %@", className]);
        }
        return nil;
    }

    SEL selector = NSSelectorFromString(selectorName);
    id instance = [cls alloc];
    if (![instance respondsToSelector:selector]) {
        if (error != NULL) {
            *error = KSError(3, [NSString stringWithFormat:@"%@ does not respond to %@", className, selectorName]);
        }
        return nil;
    }

    id (*msgSend)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
    return msgSend(instance, selector, argument);
}

static NSString *KSKeyboardServicesDirectoryPath(void) {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/KeyboardServices"];
}

static NSArray *KSTextReplacementEntries(id store) {
    SEL selector = NSSelectorFromString(@"textReplacementEntries");
    if (![store respondsToSelector:selector]) {
        return @[];
    }

    id (*msgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
    id result = msgSend(store, selector);
    return [result isKindOfClass:NSArray.class] ? result : @[];
}

static NSArray *KSQueryEntries(id store, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (![store respondsToSelector:selector]) {
        return @[];
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSArray *entries = @[];
    void (^callback)(NSArray *, BOOL) = ^(NSArray *callbackEntries, BOOL ignored) {
        if ([callbackEntries isKindOfClass:NSArray.class]) {
            entries = callbackEntries;
        }
        dispatch_semaphore_signal(semaphore);
    };

    void (*msgSend)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
    msgSend(store, selector, callback);
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
    if (dispatch_semaphore_wait(semaphore, timeout) != 0) {
        return @[];
    }
    return entries;
}

static NSArray *KSCoreDataEntries(NSError **error) {
    id store = KSAllocInitWithString(@"_KSTextReplacementCoreDataStore",
                                    @"initWithDirectoryPath:",
                                    KSKeyboardServicesDirectoryPath(),
                                    error);
    if (store == nil) {
        return @[];
    }

    SEL selector = NSSelectorFromString(@"textReplacementEntriesWithLimit:");
    if (![store respondsToSelector:selector]) {
        return @[];
    }

    id (*msgSend)(id, SEL, NSUInteger) = (id (*)(id, SEL, NSUInteger))objc_msgSend;
    id result = msgSend(store, selector, NSUIntegerMax);
    return [result isKindOfClass:NSArray.class] ? result : @[];
}

static NSArray<NSDictionary<NSString *, id> *> *KSDictionariesFromEntries(NSArray *entries) {
    NSMutableArray *rows = [NSMutableArray array];
    for (id entry in entries) {
        NSString *shortcut = [entry valueForKey:@"shortcut"] ?: @"";
        NSString *phrase = [entry valueForKey:@"phrase"] ?: @"";
        [rows addObject:@{@"shortcut": shortcut, @"phrase": phrase}];
    }
    return rows;
}

static NSArray<NSDictionary<NSString *, id> *> *KSLegacyDefaultsRows(void) {
    NSArray *rawRows = [[NSUserDefaults standardUserDefaults] arrayForKey:@"NSUserDictionaryReplacementItems"];
    if (![rawRows isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray *rows = [NSMutableArray array];
    for (id raw in rawRows) {
        if (![raw isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *shortcut = [raw objectForKey:@"replace"] ?: @"";
        NSString *phrase = [raw objectForKey:@"with"] ?: @"";
        [rows addObject:@{@"shortcut": shortcut, @"phrase": phrase, @"source": @"NSUserDictionaryReplacementItems"}];
    }
    return rows;
}

static id KSEntry(NSString *shortcut, NSString *phrase, NSError **error) {
    id entry = KSNew(@"_KSTextReplacementEntry", error);
    if (entry == nil) {
        return nil;
    }
    [entry setValue:shortcut forKey:@"shortcut"];
    [entry setValue:phrase forKey:@"phrase"];
    return entry;
}

static id KSFabricatedEntryFromFallback(NSString *shortcut) {
    for (NSDictionary *row in KSLegacyDefaultsRows()) {
        if ([[row objectForKey:@"shortcut"] isEqualToString:shortcut]) {
            return KSEntry(shortcut, [row objectForKey:@"phrase"] ?: @"", nil);
        }
    }
    return nil;
}

static id KSFindEntry(NSString *shortcut, NSError **error) {
    id store = KSNew(@"_KSTextReplacementClientStore", error);
    if (store == nil) {
        return nil;
    }

    for (id entry in KSTextReplacementEntries(store)) {
        NSString *candidate = [entry valueForKey:@"shortcut"];
        if ([candidate isEqualToString:shortcut]) {
            return entry;
        }
    }

    for (id entry in KSCoreDataEntries(nil)) {
        NSString *candidate = [entry valueForKey:@"shortcut"];
        if ([candidate isEqualToString:shortcut]) {
            return entry;
        }
    }

    id fallbackEntry = KSFabricatedEntryFromFallback(shortcut);
    if (fallbackEntry != nil) {
        return fallbackEntry;
    }

    if (error != NULL) {
        *error = KSError(4, [NSString stringWithFormat:@"No text replacement exists for shortcut %@", shortcut]);
    }
    return nil;
}

static BOOL KSValidateEntry(id entry, NSError **error) {
    Class helper = KSClass(@"_KSTextReplacementHelper");
    SEL selector = NSSelectorFromString(@"validateTextReplacement:");
    if (helper == Nil || ![helper respondsToSelector:selector]) {
        return YES;
    }

    long long (*msgSend)(id, SEL, id) = (long long (*)(id, SEL, id))objc_msgSend;
    long long code = msgSend((id)helper, selector, entry);
    if (code == 0) {
        return YES;
    }

    NSString *message = [NSString stringWithFormat:@"KeyboardServices rejected entry with validation code %lld", code];
    SEL errorStringSelector = NSSelectorFromString(@"errorStringForCode:");
    if ([helper respondsToSelector:errorStringSelector]) {
        id (*errorMsgSend)(id, SEL, long long) = (id (*)(id, SEL, long long))objc_msgSend;
        id errorString = errorMsgSend((id)helper, errorStringSelector, code);
        if ([errorString isKindOfClass:NSString.class]) {
            message = errorString;
        }
    }

    if (error != NULL) {
        *error = KSError(5, message);
    }
    return NO;
}

static BOOL KSModifyEntry(id original, id replacement, NSError **error) {
    id store = KSNew(@"_KSTextReplacementClientStore", error);
    if (store == nil) {
        return NO;
    }

    SEL selector = NSSelectorFromString(@"modifyEntry:toEntry:withCompletionHandler:");
    if (![store respondsToSelector:selector]) {
        if (error != NULL) {
            *error = KSError(9, @"Missing modifyEntry:toEntry:withCompletionHandler:");
        }
        return NO;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *transactionError = nil;
    void (^completion)(NSError *) = ^(NSError *callbackError) {
        transactionError = callbackError;
        dispatch_semaphore_signal(semaphore);
    };

    void (*msgSend)(id, SEL, id, id, id) = (void (*)(id, SEL, id, id, id))objc_msgSend;
    msgSend(store, selector, original, replacement, completion);
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC);
    if (dispatch_semaphore_wait(semaphore, timeout) != 0) {
        if (error != NULL) {
            *error = KSError(10, @"Timed out waiting for KeyboardServices modifyEntry");
        }
        return NO;
    }

    if (transactionError != nil && transactionError.code != 0) {
        if (error != NULL) {
            *error = transactionError;
        }
        return NO;
    }
    return YES;
}

static BOOL KSAddRemoveEntries(NSArray *toAdd, NSArray *toRemove, NSError **error) {
    id store = KSNew(@"_KSTextReplacementClientStore", error);
    if (store == nil) {
        return NO;
    }

    SEL selector = NSSelectorFromString(@"addEntries:removeEntries:withCompletionHandler:");
    if (![store respondsToSelector:selector]) {
        if (error != NULL) {
            *error = KSError(11, @"Missing addEntries:removeEntries:withCompletionHandler:");
        }
        return NO;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *transactionError = nil;
    void (^completion)(NSError *) = ^(NSError *callbackError) {
        transactionError = callbackError;
        dispatch_semaphore_signal(semaphore);
    };

    void (*msgSend)(id, SEL, id, id, id) = (void (*)(id, SEL, id, id, id))objc_msgSend;
    msgSend(store, selector, toAdd, toRemove, completion);
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC);
    if (dispatch_semaphore_wait(semaphore, timeout) != 0) {
        if (error != NULL) {
            *error = KSError(12, @"Timed out waiting for KeyboardServices add/remove");
        }
        return NO;
    }

    if (transactionError != nil && transactionError.code != 0) {
        if (error != NULL) {
            *error = transactionError;
        }
        return NO;
    }
    return YES;
}

NSDictionary<NSString *, id> *KSProbeInspect(void) {
    NSError *loadError = nil;
    BOOL loaded = KSLoadFramework(&loadError);
    NSArray<NSString *> *classes = @[
        @"_KSTextReplacementClientStore",
        @"_KSTextReplacementEntry",
        @"_KSTextReplacementHelper",
        @"_KSTextReplacementCoreDataStore",
        @"_KSTextReplacementCKStore",
        @"_KSTextReplacementManager",
        @"_KSTextReplacementServer",
        @"_KSTextReplacementServerConnection"
    ];

    NSMutableDictionary *available = [NSMutableDictionary dictionary];
    NSMutableDictionary *methods = [NSMutableDictionary dictionary];
    for (NSString *className in classes) {
        Class cls = KSClass(className);
        available[className] = @(cls != Nil);
        methods[className] = @{
            @"instance": KSMethodNamesForClass(cls, NO),
            @"class": KSMethodNamesForClass(cls, YES)
        };
    }

    NSMutableDictionary *result = [@{
        @"frameworkPath": KSProbeFrameworkPath(),
        @"loaded": @(loaded),
        @"classes": available,
        @"methods": methods
    } mutableCopy];
    if (loadError != nil) {
        result[@"loadError"] = loadError.localizedDescription;
    }
    return result;
}

NSDictionary<NSString *, id> *KSProbeReadSources(NSError **error) {
    if (!KSLoadFramework(error)) {
        return @{};
    }

    id store = KSNew(@"_KSTextReplacementClientStore", error);
    if (store == nil) {
        return @{};
    }

    NSArray *direct = KSTextReplacementEntries(store);
    NSArray *query = KSQueryEntries(store, @"queryTextReplacementsWithCallback:");
    NSArray *coreData = KSCoreDataEntries(nil);
    NSArray *legacy = KSLegacyDefaultsRows();
    return @{
        @"textReplacementEntriesCount": @(direct.count),
        @"queryTextReplacementsWithCallbackCount": @(query.count),
        @"coreDataStoreCount": @(coreData.count),
        @"legacyDefaultsCount": @(legacy.count),
        @"usedForList": direct.count > 0 ? @"textReplacementEntries" : (query.count > 0 ? @"queryTextReplacementsWithCallback:" : (coreData.count > 0 ? @"_KSTextReplacementCoreDataStore" : @"NSUserDictionaryReplacementItems fallback"))
    };
}

NSArray<NSDictionary<NSString *, id> *> *KSTextReplacementList(NSError **error) {
    if (!KSLoadFramework(error)) {
        return @[];
    }

    id store = KSNew(@"_KSTextReplacementClientStore", error);
    if (store == nil) {
        return @[];
    }

    NSArray *entries = KSTextReplacementEntries(store);
    if (entries.count > 0) {
        return KSDictionariesFromEntries(entries);
    }

    entries = KSQueryEntries(store, @"queryTextReplacementsWithCallback:");
    if (entries.count > 0) {
        return KSDictionariesFromEntries(entries);
    }

    entries = KSCoreDataEntries(error);
    if (entries.count > 0) {
        return KSDictionariesFromEntries(entries);
    }

    return KSLegacyDefaultsRows();
}

BOOL KSPrivateCreate(NSString *shortcut, NSString *phrase, NSError **error) {
    return KSTry(^BOOL(NSError **innerError){
        if (!KSLoadFramework(innerError)) {
            return NO;
        }

        id entry = KSEntry(shortcut, phrase, innerError);
        if (entry == nil || !KSValidateEntry(entry, innerError)) {
            return NO;
        }

        return KSAddRemoveEntries(@[entry], @[], innerError);
    }, error);
}

BOOL KSPrivateUpdate(NSString *shortcut, NSString *phrase, NSError **error) {
    return KSTry(^BOOL(NSError **innerError){
        if (!KSLoadFramework(innerError)) {
            return NO;
        }

        id original = KSFindEntry(shortcut, innerError);
        if (original == nil) {
            return NO;
        }

        id replacement = KSEntry(shortcut, phrase, innerError);
        if (replacement == nil || !KSValidateEntry(replacement, innerError)) {
            return NO;
        }
        return KSModifyEntry(original, replacement, innerError);
    }, error);
}

BOOL KSPrivateDelete(NSString *shortcut, NSError **error) {
    return KSTry(^BOOL(NSError **innerError){
        if (!KSLoadFramework(innerError)) {
            return NO;
        }

        id entry = KSFindEntry(shortcut, innerError);
        if (entry == nil) {
            return NO;
        }

        return KSAddRemoveEntries(@[], @[entry], innerError);
    }, error);
}
