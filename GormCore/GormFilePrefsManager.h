/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface GormFilePrefsManager : NSObject <NSCoding>
{
  IBOutlet NSButton *showIncompatibilities;
  IBOutlet NSPopUpButton *targetVersion;
  IBOutlet NSTextField *gormAppVersion;
  IBOutlet NSPopUpButton *archiveType;
  IBOutlet NSWindow *iwindow;
  IBOutlet NSTableView *itable;
  IBOutlet NSTextField *fileType;

  // encoded ivars...
  int version;
  NSString *targetVersionName;
  NSString *archiveTypeName;

  // version profiles...
  NSDictionary *versionProfiles;
  NSDictionary *currentProfile;
}
/**
 * Show incompatibilities in the panel.
 */
- (IBAction) listIncompatibilities: (id)sender;

/**
 * Action called when the target version pulldown is selected.
 */
- (IBAction) selectTargetVersion: (id)sender;

/**
 * Action called when the archive type pulldown is selected.
 */
- (IBAction) selectArchiveType: (id)sender;

/**
 * Loads the encoded file info.
 */
- (BOOL) loadFromData: (NSData *)data;

/**
 * Loads the encoded file info.
 */
- (BOOL) loadFromFile: (NSString *)path;

/**
 * Saves the encoded file info.
 */
- (NSData *) data;

/**
 * Saves the encoded file info.
 */
- (NSData *) nibDataWithOpenItems: (NSArray *)openItems;

/**
 * Saves the encoded file info.
 */
- (BOOL) saveToFile: (NSString *)path;

/**
 * Loads the profile.
 */
- (void) loadProfile: (NSString *)version;

// accessors...

/**
 * Gorm Version of the current archive.
 */
- (int) version;

/**
 * Which version of the gui library, by name.
 */
- (NSString *)targetVersionName;

/**
 * Which achive type, by name.
 */
- (NSString *)archiveTypeName;

/**
 * Are we set to the latest version?  Returns YES, if so.
 */
- (BOOL) isLatest;

// set class versions
/**
 * Sets the version of the classes.
 */
- (void) setClassVersions;

/**
 * Restores the versions to the most current.
 */
- (void) restoreClassVersions;

/**
 * Returns the version of the class in the current profile.
 */
- (int) versionOfClass: (NSString *)className;

// file type...
@property (nonatomic, copy) NSString *fileTypeName;
/**
 * File type name...
 */
- (void) setFileTypeName: (NSString *)ft;

/**
 * return file type.
 */
- (NSString *) fileTypeName;

/**
 * The current Gorm version.
 */
+ (int) currentVersion;
@end
