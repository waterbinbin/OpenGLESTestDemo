//
//  GLESTextureUtil.h
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 2017/4/8.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreImage/CoreImage.h>

@interface GLESTextureUtil : NSObject

@property(readonly) CVOpenGLESTextureCacheRef tempTextureCache;
@property (atomic) unsigned int textureID;
@property (atomic) int target;
@property (atomic) int width;
@property (atomic) int height;

- (id) initWithTarget:(int)target;
- (void)tearDown;
- (void)createWithWidth:(int)width AndHeight:(int)height AndFormat:(int)format usingContext:(CVEAGLContext)ctx;
- (void)createWithWidth:(int)width AndHeight:(int)height AndFormat:(int)format;

//通过图像的方法添加纹理
//param image:获取图片的CGImageRef
//param pixelfmt:图像的数据格式，如GL_RGBA
- (void)createFromImage:(CGImageRef)image pixelFmt:(int)pixelFmt;

- (void)createFromPixelBuffer:(CVPixelBufferRef) pixelBuffer;
- (void)createFromBuffer:(GLubyte*) imageData width:(int)width height:(int)height pixelFmt:(int)pixelfmt;
- (void)bindFBO:(int)fbo;
//get renderbuffer for output
-(CVPixelBufferRef)pixelBufferFormTxtCache;

@end
