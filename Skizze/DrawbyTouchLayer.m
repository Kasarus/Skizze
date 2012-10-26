//
//  DrawbyTouchLayer.m
//  Skizze
//
//  Created by Skizze Team on 10/20/55 BE.
//  Copyright 2012 Thomson Reuters. All rights reserved.
//

#import "DrawbyTouchLayer.h"

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
        self.isTouchEnabled = YES;
        
        CGSize screen_size = [[CCDirector sharedDirector] winSize];
		screenwidth_ = screen_size.width;
		screenheight_ = screen_size.height;
        
        bg_             = [CCSprite spriteWithFile:@"blackboard-bg.png"];
        bg_.position    = ccp(screenwidth_ / 2, screenheight_ / 2);
        [self addChild:bg_];
        
    }

    return self;
}

//Schedule to remove all points we put in the last 1 second
-(void) removeLine: (ccTime) dt
{
    [bg_ removeAllChildrenWithCleanup:true];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self unschedule:@selector(removeLine:)];
    
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
    [self schedule:@selector(removeLine:) interval:2.0f];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    [line_ release];
    [bg_ release];
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
