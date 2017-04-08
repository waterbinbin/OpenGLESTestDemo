//
//  GLESVideoView.h
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 2017/4/8.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLESVideoView : UIView

@property (nonatomic , assign) BOOL isFullYUVRange;

- (void)setupGL;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
