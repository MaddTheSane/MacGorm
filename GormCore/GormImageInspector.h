/* All Rights reserved */

#import <AppKit/AppKit.h>
#import <GormLib/IBInspector.h>

@interface GormImageInspector : IBInspector
{
  id name;
  id imageView;
  id width;
  id height;
  id _currentImage;
}
@end
