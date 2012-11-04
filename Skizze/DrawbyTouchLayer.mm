//
//  DrawbyTouchLayer.m
//  Skizze
//
//  Created by Skizze Team on 10/20/55 BE.
//  Copyright 2012 Thomson Reuters. All rights reserved.
//

#include "baseapi.h"
#include "environ.h"
#import "DrawbyTouchLayer.h"
#import "pix.h"

@implementation DrawbyTouchLayer

// Helper class method that creates a Scene with the DrawbyTouchLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	DrawbyTouchLayer *layer = [DrawbyTouchLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    // always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) )
    {
        // Set up the tessdata path. This is included in the application bundle
        // but is copied to the Documents directory on the first run.
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
        NSError *error = nil;
        
        NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // If the expected store doesn't exist, copy the default store.
        if (![fileManager fileExistsAtPath:dataPath]) {
            // get the path to the app bundle (with the tessdata dir)
            NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
            NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
            if (tessdataPath)
            {
                if(![fileManager copyItemAtPath:tessdataPath toPath:dataPath error:&error])
                {
                    NSLog(@"Can't copy file %@", error);
                }
            }
        }
        
        setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);

        
        // init the tesseract engine.
        tesseract = new tesseract::TessBaseAPI();
        tesseract->Init([documentPath cStringUsingEncoding:NSUTF8StringEncoding], "bnv");
        
        self.isTouchEnabled = YES;
        
        CGSize screen_size = [[CCDirector sharedDirector] winSize];
		screenwidth_ = screen_size.width;
		screenheight_ = screen_size.height;
        
        bg_             = [CCSprite spriteWithFile:@"blackboard-bg.png"];
        bg_.position    = ccp(screenwidth_ / 2, screenheight_ / 2);
        
        recognized_txt = [CCLabelTTF labelWithString:@"" fontName:@"Georgia" fontSize:20];
        recognized_txt.position = ccp(70, 820);
        
        [self addChild:bg_];
        [self addChild: recognized_txt];
    }

    return self;
}

-(UIImage*) screenshotUIImage
{
	[CCDirector sharedDirector].nextDeltaTimeZero = YES;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    CCRenderTexture* rtx = [CCRenderTexture renderTextureWithWidth:winSize.width height:winSize.height];
    [rtx beginWithClear:0 g:0 b:0 a:1.0f];
    [[[CCDirector sharedDirector] runningScene] visit];
    [rtx end];
    
    return [rtx getUIImage];
}

- (void) takeScreenShot: (ccTime) dt
{
    UIImage *screenshot = [self screenshotUIImage];
    //NSString *savePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Screenshot.png"];
    //[UIImagePNGRepresentation(screenshot) writeToFile:savePath atomically:YES];
    [self unschedule:@selector(takeScreenShot:)];
    [self performSelectorInBackground:@selector(processOcrAt:) withObject:screenshot];
}

//Code by Ângelo Suzuki
//(http://tinsuke.wordpress.com/2011/11/01/how-to-compile-and-use-tesseract-3-01-on-ios-sdk-5/)

- (void)processOcrAt:(UIImage *)image
{
    [self setTesseractImage:image];
    
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}

- (void)ocrProcessingFinished:(NSString *)result
{
    NSLog(@"Recognize : %@", result);
    [recognized_txt setString:[NSString stringWithFormat:@"Recognize : %@", result]];
}

//Code by Ângelo Suzuki
//(http://tinsuke.wordpress.com/2011/11/01/how-to-compile-and-use-tesseract-3-01-on-ios-sdk-5/)

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}


//Schedule to remove all points we put in the last 1 second
- (void) removeLine: (ccTime) dt
{
    [bg_ removeAllChildrenWithCleanup:true];
    [self unschedule:@selector(removeLine:)];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self unschedule:@selector(takeScreenShot:)];
    [self unschedule:@selector(removeLine:)];
    [recognized_txt setString:[NSString stringWithFormat:@""]];
    
    UITouch *myTouch = [touches anyObject];
    startLocation_ = [myTouch locationInView:[myTouch view]];
    startLocation_ = [[CCDirector sharedDirector] convertToGL:startLocation_];
    
    line_ = [CCMotionStreak streakWithFade:100.0f minSeg:3 width:6 color:ccc3(255,255,255) textureFilename:@"streak_round.png"];
    line_.position = startLocation_;
    [bg_ addChild:line_];
    
    //NSLog(@"TOUCH BEGIN %f %f", startLocation_.x, startLocation_.y);   
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *myTouch = [touches anyObject];
    finalLocation_ = [myTouch locationInView:[myTouch view]];
    finalLocation_ = [[CCDirector sharedDirector] convertToGL:finalLocation_];
    
    line_.position = finalLocation_;
    
    //NSLog(@"TOUCH MOVE %f %f", finalLocation_.x, finalLocation_.y);
    //NSLog(@"LAST TOUCHED %f %f", startLocation_.x, startLocation_.y);
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"TOUCH CANCEL");
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self schedule:@selector(takeScreenShot:) interval:1.5f];
    [self schedule:@selector(removeLine:) interval:1.5f];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    delete tesseract;
    tesseract = nil;
    
    [recognized_txt release];
    [line_ release];
    [bg_ release];
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
