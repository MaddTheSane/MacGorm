//
//  PrivateCocoaClasses.h
//  MacGorm
//
//  Created by C.W. Betts on 4/2/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindowTemplate : NSObject <NSCoding, NSUserInterfaceItemIdentification>
{
	struct CGRect windowRect;
	int windowStyleMask;
	int windowBacking;
	NSString *windowTitle;
	id viewClass;
	NSString *windowClass;
	id windowView;
	NSWindow *realObject;
	id extension;
	struct CGSize minSize;
	struct __WtFlags {
		unsigned int _PADDING:9;
		unsigned int isRestorable:1;
		unsigned int hidesToolbarButton:1;
		unsigned int autorecalculatesKeyViewLoop:1;
		unsigned int hideShadow:1;
		unsigned int allowsToolTipsWhenInactive:1;
		unsigned int autoSetMiniaturizableMask:1;
		unsigned int autoSetZoomableMask:1;
		unsigned int :2;
		unsigned int savePosition:1;
		unsigned int autoPositionMask:6;
		unsigned int dynamicDepthLimit:1;
		unsigned int wantsToBeColor:1;
		unsigned int visible:1;
		unsigned int oneShot:1;
		unsigned int defer:1;
		unsigned int dontFreeWhenClosed:1;
		unsigned int hidesOnDeactivate:1;
	} _wtFlags;
	struct CGRect screenRect;
	NSString *frameAutosaveName;
	struct CGSize maxSize;
	struct CGSize contentMinSize;
	struct CGSize contentMaxSize;
	unsigned long long windowBackingLocation;
	unsigned long long windowSharingType;
	char autorecalculateContentBorderThicknesses[4];
	double contentBorderThicknesses[4];
	NSString *userInterfaceIdentifier;
	unsigned long long animationBehavior;
	unsigned long long collectionBehavior;
	BOOL isRestorableWasDecodedFromArchive;
	NSAppearance *appearance;
	NSViewController *_contentViewController;
	struct CGSize _minFullScreenContentSize;
	struct CGSize _maxFullScreenContentSize;
	BOOL _minFullScreenContentSizeIsSet;
	BOOL _maxFullScreenContentSizeIsSet;
	NSString *_tabbingIdentifier;
	long long _tabbingMode;
}

+ (void)initialize;
@property BOOL maxFullScreenContentSizeIsSet; // @synthesize maxFullScreenContentSizeIsSet=_maxFullScreenContentSizeIsSet;
@property BOOL minFullScreenContentSizeIsSet; // @synthesize minFullScreenContentSizeIsSet=_minFullScreenContentSizeIsSet;
@property long long tabbingMode; // @synthesize tabbingMode=_tabbingMode;
@property(copy, nonatomic) NSString *tabbingIdentifier; // @synthesize tabbingIdentifier=_tabbingIdentifier;
@property(retain, nonatomic) NSViewController *contentViewController; // @synthesize contentViewController=_contentViewController;
@property(retain, nonatomic) NSAppearance *appearance; // @synthesize appearance;
@property(copy) NSString *identifier;
- (void)setUserInterfaceItemIdentifier:(id)arg1;
- (id)userInterfaceItemIdentifier;
- (id)initWithCoder:(id)arg1;
- (id)init;
@property NSSize maxFullScreenContentSize;
@property NSSize minFullScreenContentSize;
- (void)encodeWithCoder:(id)arg1;
- (id)nibInstantiate;
- (BOOL)isRestorable;
- (void)setRestorable:(BOOL)arg1;
- (unsigned long long)collectionBehavior;
- (void)setCollectionBehavior:(unsigned long long)arg1;
- (long long)animationBehavior;
- (void)setAnimationBehavior:(long long)arg1;
- (double)contentBorderThicknessForEdge:(unsigned long long)arg1;
- (void)setContentBorderThickness:(double)arg1 forEdge:(unsigned long long)arg2;
- (BOOL)autorecalculatesContentBorderThicknessForEdge:(unsigned long long)arg1;
- (void)setAutorecalculatesContentBorderThickness:(BOOL)arg1 forEdge:(unsigned long long)arg2;
- (void)setShowsToolbarButton:(BOOL)arg1;
- (BOOL)showsToolbarButton;
- (void)setContentMinSize:(struct CGSize)arg1;
- (struct CGSize)contentMinSize;
- (void)setContentMaxSize:(struct CGSize)arg1;
- (struct CGSize)contentMaxSize;
- (void)setWindowBackingLocation:(unsigned long long)arg1;
- (unsigned long long)windowBackingLocation;
- (void)setWindowSharingType:(unsigned long long)arg1;
- (unsigned long long)windowSharingType;
- (void)setToolbar:(id)arg1;
- (id)toolbar;
- (BOOL)autorecalculatesKeyViewLoop;
- (void)setAutorecalculatesKeyViewLoop:(BOOL)arg1;
- (BOOL)hasShadow;
- (void)setHasShadow:(BOOL)arg1;
- (BOOL)allowsToolTipsWhenApplicationIsInactive;
- (void)setAllowsToolTipsWhenApplicationIsInactive:(BOOL)arg1;
- (void)setMaxSize:(struct CGSize)arg1;
- (struct CGSize)maxSize;
- (void)setMinSize:(struct CGSize)arg1;
- (struct CGSize)minSize;
- (id)frameAutosaveName;
- (void)setFrameAutosaveName:(id)arg1;
- (void)setInterfaceStyle:(unsigned long long)arg1;
- (unsigned long long)interfaceStyle;
- (void)setAutoPositionMask:(unsigned long long)arg1;
- (unsigned long long)autoPositionMask;
- (void)setWantsToBeColor:(BOOL)arg1;
- (BOOL)wantsToBeColor;
- (void)setHidesOnDeactivate:(BOOL)arg1;
- (BOOL)hidesOnDeactivate;
- (void)setReleasedWhenClosed:(BOOL)arg1;
- (BOOL)isReleasedWhenClosed;
- (void)setDeferred:(BOOL)arg1;
- (BOOL)isDeferred;
- (void)setDynamicDepthLimit:(BOOL)arg1;
- (BOOL)hasDynamicDepthLimit;
- (void)setOneShot:(BOOL)arg1;
- (BOOL)isOneShot;
- (void)setBackingType:(unsigned long long)arg1;
- (unsigned long long)backingType;
- (void)setStyleMask:(unsigned long long)arg1;
- (unsigned long long)styleMask;
- (Class)windowClassForNibInstantiate;
- (void)setClassName:(id)arg1;
- (id)className;
- (void)setTitle:(id)arg1;
- (id)title;
- (void)dealloc;
@end

@interface NSCustomResource : NSObject <NSCoding>
{
	NSString *className;
	NSString *resourceName;
}

+ (id)bundleForImageSearch;
+ (id)bundleForCurrentNib;
+ (void)popBundleForImageSearch;
+ (void)pushBundleForImageSearch:(id)arg1;
+ (void)initialize;
- (id)awakeAfterUsingCoder:(id)arg1;
- (id)loadSoundWithName:(id)arg1;
- (id)loadCIImageWithName:(id)arg1;
- (id)loadImageWithName:(id)arg1;
- (id)_loadImageWithName:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)setResourceName:(id)arg1;
- (id)resourceName;
- (void)setClassName:(id)arg1;
- (id)className;
- (void)dealloc;
- (id)init;

@end

@class NSIBObjectDataAuxilary;

@interface NSIBObjectData : NSObject <NSCoding>
{
	@private
	id rootObject;
	NSMapTable *objectTable;
	NSMapTable *nameTable;
	NSMutableSet *visibleWindows;
	NSMutableArray *connections;
	id firstResponder;
	id fontManager;
	NSMapTable *oidTable;
	unsigned long long nextOid;
	NSMapTable *classTable;
	NSMapTable *instantiatedObjectTable;
	NSString *targetFramework;
	id _document;
	NSIBObjectDataAuxilary *_objectDataAuxilary;
}

+ (void)initialize;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)_removeEarlyDecodingObjectConnectionsFromConnections:(id)arg1;
- (void)_addEarlyDecodingObjectsFromObjectList:(id)arg1 toConnections:(id)arg2;
- (void)nibInstantiateWithOwner:(id)arg1 options:(id)arg2 topLevelObjects:(id)arg3;
- (void)nibInstantiateWithOwner:(id)arg1 topLevelObjects:(id)arg2;
- (void)nibInstantiateWithOwner:(id)arg1;
- (id)instantiateObject:(id)arg1;
- (void)setShouldEncodeDesigntimeData:(BOOL)arg1;
- (BOOL)shouldEncodeDesigntimeData;
- (id)classTable;
- (id)oidTable;
- (id)nameTable;
- (id)objectTable;
- (void)setRootObject:(id)arg1;
- (id)rootObject;
- (void)setFirstResponder:(id)arg1;
- (id)firstResponder;
- (void)setNextObjectID:(unsigned long long)arg1;
- (long long)nextObjectID;
- (void)setTargetFramework:(id)arg1;
- (id)targetFramework;
- (void)setConnections:(id)arg1;
- (id)connections;
- (void)setVisibleWindows:(id)arg1;
- (id)visibleWindows;
- (void)dealloc;
- (id)init;
- (void)_assignObjectIds;
- (void)_readVersion0:(id)arg1;
- (void)_encodeMapTable:(id)arg1 forTypes:(const char *)arg2 withCoder:(id)arg3;
- (void)_encodeIntValuedMapTable:(id)arg1 withCoder:(id)arg2;
- (void)_encodeObjectValuedMapTable:(id)arg1 withCoder:(id)arg2;

@end

@interface NSCustomView : NSView
{
	NSString *className;
	NSView *view;
	id extension;
}

- (void)setClassName:(NSString *)arg1;
- (NSString *)className;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)nibInstantiateWithObjectInstantiator:(id)arg1;
- (BOOL)_descendantIsConstrainedByConstraint:(id)arg1;
- (void)_setAsClipViewDocumentViewIfNeeded;
- (id)initWithFrame:(NSRect)arg1;

@end

@interface NSViewTemplate : NSView
{
	NSString *_className;
}

+ (void)initialize;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)awakeAfterUsingCoder:(id)arg1;
- (id)createRealObject;
- (void)setClassName:(NSString *)arg1;
- (NSString *)className;
- (id)initWithFrame:(NSRect)arg1;
- (id)initWithView:(id)arg1 className:(NSString *)arg2;

@end

@interface NSClassSwapper : NSObject <NSCoding>
{
	NSString *className;
	id template;
}

+ (void)initialize;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)setClassName:(NSString *)arg1;
- (NSString *)className;
- (void)setTemplate:(id)arg1;
- (id)template;
- (void)dealloc;
- (id)init;

@end


@interface NSIBHelpConnector : NSObject <NSCoding>
{
	id _destination;
	NSString *_file;
	NSString *_marker;
}

+ (void)initialize;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)instantiateWithObjectInstantiator:(id)arg1;
- (void)establishConnection;
- (void)replaceObject:(id)arg1 withObject:(id)arg2;
- (void)setMarker:(NSString *)arg1;
- (NSString *)marker;
- (void)setFile:(NSString *)arg1;
- (NSString *)file;
- (void)setLabel:(id)arg1;
- (id)label;
- (void)setDestination:(id)arg1;
- (id)destination;
- (void)setSource:(id)arg1;
- (id)source;
- (void)dealloc;
- (id)init;

@end

@interface NSTextTemplate : NSViewTemplate
{
	id _contents;
	NSColor *_textColor;
	NSFont *_font;
	unsigned long long _alignment;
	NSColor *_backgroundColor;
	struct CGSize _minSize;
	struct CGSize _maxSize;
	id _delegate;
	struct __ttFlags {
		unsigned int drawsBackground:1;
		unsigned int selectable:1;
		unsigned int editable:1;
		unsigned int richText:1;
		unsigned int importsGraphics:1;
		unsigned int horizontallyResizable:1;
		unsigned int verticallyResizable:1;
		unsigned int fieldEditor:1;
		unsigned int usesFontPanel:1;
		unsigned int rulerVisible:1;
		unsigned int allowsUndo:1;
		unsigned int _pad:21;
	} _ttFlags;
}

+ (void)initialize;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)createRealObject;
- (void)dealloc;
- (id)initWithView:(id)arg1 className:(id)arg2;

@end

@interface NSTextViewTemplate : NSViewTemplate
{
	id _contents;
	NSColor *_backgroundColor;
	NSDictionary *_selectedTextAttributes;
	NSColor *_insertionPointColor;
	struct CGSize _containerSize;
	struct CGSize _minSize;
	struct CGSize _maxSize;
	id _delegate;
	struct __tvtFlags {
		unsigned int drawsBackground:1;
		unsigned int selectable:1;
		unsigned int editable:1;
		unsigned int richText:1;
		unsigned int importsGraphics:1;
		unsigned int horizontallyResizable:1;
		unsigned int verticallyResizable:1;
		unsigned int fieldEditor:1;
		unsigned int usesFontPanel:1;
		unsigned int rulerVisible:1;
		unsigned int containerTracksWidth:1;
		unsigned int containerTracksHeight:1;
		unsigned int usesRuler:1;
		unsigned int allowsUndo:1;
		unsigned int _pad:18;
	} _tvtFlags;
	NSDictionary *_typingAttrs;
}

+ (void)initialize;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)createRealObject;
- (void)dealloc;
- (id)initWithView:(id)arg1 className:(id)arg2;

@end

@interface NSCustomObject : NSObject <NSCoding>
{
	NSString *className;
	id object;
	id extension;
}

- (void)setClassName:(NSString *)arg1;
- (NSString *)className;
- (void)setObject:(id)arg1;
- (id)init;

@end
