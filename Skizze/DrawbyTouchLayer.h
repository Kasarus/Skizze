//
//  DrawbyTouchLayer.h
//  Skizze
//
//  Created by Skizze Team on 10/20/55 BE.
//  Copyright 2012 Thomson Reuters. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "cocos2d.h"

namespace tesseract {
    class TessBaseAPI;
};

@interface DrawbyTouchLayer : CCLayer
{
    CGPoint                 startLocation_;
    CGPoint                 finalLocation_;
    CCSprite                *bg_;
    CCMotionStreak          *line_;
    float                   screenwidth_;
    float                   screenheight_;
    tesseract::TessBaseAPI  *tesseract;
}


// returns a CCScene that contains the DrawbyTouchLayer as the only child
+(CCScene *) scene;

@end
