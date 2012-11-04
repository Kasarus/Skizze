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
    float                   screenwidth_;
    float                   screenheight_;
    CGPoint                 startLocation_;
    CGPoint                 finalLocation_;
    CCSprite                *bg_;
    CCMotionStreak          *line_;
    CCLabelTTF              *recognized_txt;
    uint32_t                *pixels;
    tesseract::TessBaseAPI  *tesseract;
}


// returns a CCScene that contains the DrawbyTouchLayer as the only child
+(CCScene *) scene;

@end
