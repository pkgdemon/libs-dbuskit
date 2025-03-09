#include "GlobalMenuTheme.h"

/*
 * The class used by the DBus menu registry
 */
static Class _menuRegistryClass;

@implementation GlobalMenuTheme
- (Class)_findDBusMenuRegistryClass
{
  NSString	*path;
  NSBundle	*bundle;
  NSArray	*paths;
  NSUInteger	count;

  if (Nil != _menuRegistryClass)
    {
      return _menuRegistryClass;
    }
  paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
    NSAllDomainsMask, YES);
  count = [paths count];
  while (count-- > 0)
    {
       path = [paths objectAtIndex: count];
       path = [path stringByAppendingPathComponent: @"Bundles"];
       path = [path stringByAppendingPathComponent: @"DBusMenu"];
       path = [path stringByAppendingPathExtension: @"bundle"];
       bundle = [NSBundle bundleWithPath: path];
       if (bundle != nil)
         {
           if ((_menuRegistryClass = [bundle principalClass]) != Nil)
             {
               break;  
             }
         }
     }
  return _menuRegistryClass;
}

- (id)initWithBundle:(NSBundle *)bundle
{
  if ((self = [super initWithBundle: bundle]) != nil)
  {
    menuRegistry = [[self _findDBusMenuRegistryClass] new];

    NSLog(@"GlobalMenuTheme: menuRegistry initialized: %@", menuRegistry);

    // Listen for when a window becomes active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateGlobalMenu)
                                                 name:NSWindowDidBecomeMainNotification
                                               object:nil];
  }
  return self;
}

- (void)setMenu: (NSMenu*)m forWindow: (NSWindow*)w
{
  if (nil != menuRegistry)
    {
      [menuRegistry setMenu: m forWindow: w];
    }
  else
    {
      // Get normal in-window menus when the menu server is unavailable
      [super setMenu: m forWindow: w];
    }
}

// Called when switching windows or apps
- (void)updateGlobalMenu
{
  NSWindow *mainWindow = [NSApp mainWindow];
  if (!mainWindow)
  {
    NSArray *windows = [NSApp windows];
    if ([windows count] > 0)
    {
      mainWindow = [windows objectAtIndex:0]; // Pick the first window
    }
  }

  if (!mainWindow)
  {
    NSLog(@"GlobalMenuTheme: ERROR - No valid window found to attach menu.");
    return;
  }

  NSLog(@"GlobalMenuTheme: Updating global menu for window %ld", (long)[mainWindow windowNumber]);

  // Update the menu dynamically based on the focused window
  [self setMenu:[NSApp mainMenu] forWindow:mainWindow];
}

@end

@implementation NSMenuView (GlobalMenuOverride)

- (void)drawRect:(NSRect)rect
{
  if ([NSApp interfaceStyle] == NSMacintoshInterfaceStyle)
  {
    NSLog(@"GlobalMenuTheme: Blocking menu drawing.");
    return; // Completely stops visual rendering
  }

  [super drawRect: rect];
}

@end