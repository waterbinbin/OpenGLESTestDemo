//
//  GLESTextureUtil.m
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 2017/4/8.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import "GLESTextureUtil.h"

//添加OpenGL ES 3.0版本， 必须是iphone 5s以上机型
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <CoreVideo/CVPixelBuffer.h>
#import <UIKit/UIImage.h>

//由于要兼容到ios9 所以一般使用OpenGL ES 2.0版本
//#import <OpenGLES/ES2/gl.h>
//#import <OpenGLES/ES2/glext.h>

@interface GLESTextureUtil()
{
    CVPixelBufferRef renderPixelBufferRef;
    CVOpenGLESTextureRef renderTexture;
}
@end

@implementation GLESTextureUtil

@synthesize tempTextureCache = _tempTextureCache;

//param target:参数一般为GL_TEXTURE_2D
- (id) initWithTarget:(int)target
{
    if (!(self = [super init]))
        return nil;
    _target = target;
    _textureID = 0;
    GLuint textureHandles[1] = {0};
    glGenTextures(1, textureHandles);
    _textureID = textureHandles[0];
    
    glBindTexture(_target, _textureID);
    glTexParameterf(_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    _width = 0;
    _height = 0;
    return self;
}

- (void)dealloc
{
    [self tearDown];
}

- (void)tearDown
{
    if (_textureID) {
        glDeleteTextures(1, &_textureID);
        _textureID = 0;
    }
}

-(BOOL)ISFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
#endif
    
}
- (CVOpenGLESTextureCacheRef)coreTextureCache :(CVEAGLContext)ctx;
{
    if (_tempTextureCache == NULL)
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, ctx, NULL, &_tempTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)ctx, NULL, &_coreVideoTextureCache);
#endif
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
    }
    
    return _tempTextureCache;
}

-(CVPixelBufferRef)pixelBufferFormTxtCache;
{
    if (renderPixelBufferRef)
    {
        return renderPixelBufferRef;
    }
    return NULL;
}

- (void) createWithWidth:(int)width
               AndHeight:(int)height
               AndFormat:(int)format
            usingContext:(CVEAGLContext)ctx
{
    
    if ([self ISFastTextureUpload])
    {
        CVOpenGLESTextureCacheRef bufferTextureCache = [self coreTextureCache:ctx];
        
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &renderPixelBufferRef);
        if (err)
        {
            NSLog(@"FBO size: %d, %d", width, height);
            NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
        }
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                            bufferTextureCache,
                                                            renderPixelBufferRef,
                                                            NULL, // texture attributes
                                                            GL_TEXTURE_2D,
                                                            format, // opengl format
                                                            width,
                                                            height,
                                                            format, // native iOS format
                                                            GL_UNSIGNED_BYTE,
                                                            0,
                                                            &renderTexture);
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        CFRelease(attrs);
        CFRelease(empty);
    }
    
    _textureID = CVOpenGLESTextureGetName(renderTexture);
    
    glBindTexture(_target, _textureID);
    glTexParameterf(_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    _width = width;
    _height = height;
}

- (void) createWithWidth:(int)width
               AndHeight:(int)height
               AndFormat:(int)format
{
    glBindTexture(_target, _textureID);
    glTexImage2D(_target, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, nil);
    _width = width;
    _height = height;
}

//通过图像的方法添加纹理
//param image:获取图片的CGImageRef
//param pixelfmt:图像的数据格式，如GL_RGBA
- (void) createFromImage:(CGImageRef)image pixelFmt:(int)pixelfmt
{
    // 1获取图片的CGImageRef，如果是沙盒文件名可以通过此方法获得
//    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
//    if (!spriteImage) {
//        NSLog(@"Failed to load image %@", fileName);
//        exit(1);
//    }

    if (!image)
    {
        NSLog(@"Failed to load image");
        return;
    }
    
    // 2 读取图片的大小
    _width = (int)CGImageGetWidth(image);
    _height = (int)CGImageGetHeight(image);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    void *imageData = malloc( _height * _width * 4 );
    
    CGContextRef context = CGBitmapContextCreate(imageData, _width, _height, 8, 4 * _width,
                                                 colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease( colorSpace);
    CGContextClearRect( context, CGRectMake( 0, 0, _width, _height ));
    CGContextTranslateCTM( context, 0, _height - _height );
    // 3在CGContextRef上绘图
    CGContextDrawImage( context, CGRectMake( 0, 0, _width, _height ), image );
    
    glBindTexture(_target, _textureID);
    glTexParameterf(_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(_target, 0, GL_RGBA, _width, _height, 0, pixelfmt, GL_UNSIGNED_BYTE, imageData);
    
    CGContextRelease(context);
    
    free(imageData);
}

- (void) createFromPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    if (!pixelBuffer)
    {
        NSLog(@"Failed to load image");
        return;
    }
    //sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    GLubyte* imageData = CVPixelBufferGetBaseAddress( pixelBuffer );
    size_t dataSize = CVPixelBufferGetDataSize(pixelBuffer);
    _width  = (GLuint)CVPixelBufferGetWidth( pixelBuffer );
    _height = (GLuint)CVPixelBufferGetHeight( pixelBuffer );
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer); //2560 == (640 * 4)
    OSType pixelBufferType = CVPixelBufferGetPixelFormatType(pixelBuffer); //BGRA
    size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);    //0
    
    GLuint pixfmt = GL_RGBA;                                                                     ;
    glBindTexture(_target, _textureID);
    glTexParameterf(_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(_target, 0, GL_RGBA, bytesPerRow/4, dataSize/bytesPerRow, 0, pixfmt, GL_UNSIGNED_BYTE, imageData);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
}

- (void) createFromBuffer:(GLubyte*) imageData width:(int)width height:(int)height pixelFmt:(int)pixelfmt
{
    glBindTexture(_target, _textureID);
    glTexParameterf(_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(_target, 0, GL_RGBA, width, height, 0, pixelfmt, GL_UNSIGNED_BYTE, imageData);
    
}

- (void) bindFBO:(int)fbo
{
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glBindTexture(_target, _textureID);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _target, _textureID, 0);
}

@end
