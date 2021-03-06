#import "AppInfo.h"
#import <AdSupport/ASIdentifierManager.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <sys/utsname.h>

#include "platform/settings.hpp"

extern string const kCountryCodeKey = "CountryCode";
extern string const kUniqueIdKey = "UniqueId";
extern string const kLanguageKey = "Language";

@interface AppInfo ()

@property(nonatomic) NSString * countryCode;
@property(nonatomic) NSString * uniqueId;
@property(nonatomic) NSString * bundleVersion;
@property(nonatomic) NSString * deviceInfo;
@property(nonatomic) NSUUID * advertisingId;
@property(nonatomic) NSDate * buildDate;

@end

@implementation AppInfo

+ (instancetype)sharedInfo
{
  static AppInfo * appInfo;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    appInfo = [[self alloc] init];
  });
  return appInfo;
}

- (instancetype)init
{
  self = [super init];
  return self;
}

#pragma mark - Properties

- (NSString *)countryCode
{
  if (!_countryCode)
  {
    CTTelephonyNetworkInfo * networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier * carrier = networkInfo.subscriberCellularProvider;
    if ([carrier.isoCountryCode length])  // if device can access sim card info
      _countryCode = [carrier.isoCountryCode uppercaseString];
    else  // else, getting system country code
      _countryCode = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] uppercaseString];

    std::string codeString;
    if (settings::Get(kCountryCodeKey, codeString))  // if country code stored in settings
    {
      if (carrier.isoCountryCode)  // if device can access sim card info
        settings::Set(kCountryCodeKey,
                      std::string([_countryCode UTF8String]));  // then save new code instead
      else
        _countryCode =
            @(codeString.c_str());  // if device can NOT access sim card info then using saved code
    }
    else
    {
      if (_countryCode)
        settings::Set(kCountryCodeKey,
                      std::string([_countryCode UTF8String]));  // saving code first time
      else
        _countryCode = @"";
    }
  }
  return _countryCode;
}

- (NSString *)uniqueId
{
  if (!_uniqueId)
  {
    string uniqueString;
    if (settings::Get(kUniqueIdKey, uniqueString))  // if id stored in settings
    {
      _uniqueId = @(uniqueString.c_str());
    }
    else  // if id not stored in settings
    {
      _uniqueId = [[UIDevice currentDevice].identifierForVendor UUIDString];
      if (_uniqueId)  // then saving in settings
        settings::Set(kUniqueIdKey, std::string([_uniqueId UTF8String]));
    }
  }
  return _uniqueId;
}

- (NSString *)bundleVersion
{
  if (!_bundleVersion)
    _bundleVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
  return _bundleVersion;
}

- (NSUUID *)advertisingId
{
  if (!_advertisingId)
  {
    ASIdentifierManager * m = [ASIdentifierManager sharedManager];
    if (m.isAdvertisingTrackingEnabled)
      _advertisingId = m.advertisingIdentifier;
  }
  return _advertisingId;
}

- (NSString *)languageId
{
  NSArray * languages = [NSLocale preferredLanguages];
  return languages.count == 0 ? nil : languages[0];
}

- (NSDate *)buildDate
{
  if (!_buildDate)
  {
    NSString * dateStr =
        [NSString stringWithFormat:@"%@ %@", [NSString stringWithUTF8String:__DATE__],
                                   [NSString stringWithUTF8String:__TIME__]];

    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"LLL d yyyy HH:mm:ss"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    _buildDate = [dateFormatter dateFromString:dateStr];
  }
  return _buildDate;
}

@end
