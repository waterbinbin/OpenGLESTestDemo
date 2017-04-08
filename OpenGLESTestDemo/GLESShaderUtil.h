//
//  GLESShaderUtil.h
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 17/4/6.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import <Foundation/Foundation.h>

//添加OpenGL ES 3.0版本， 必须是iphone 5s以上机型
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

//由于要兼容到ios9 所以一般使用OpenGL ES 2.0版本
//#import <OpenGLES/ES2/gl.h>
//#import <OpenGLES/ES2/glext.h>

@interface GLESShaderUtil : NSObject

@property (atomic) int programID;

//编译和加载着色器
//param type：shader的类型（GL_VERTEX_SHADER 或者 GL_FRAGMENT_SHADER）
//param shaderSrc：着色器源码字符串
//成功则返回一个新的着色器对象，失败则返回0
- (GLuint)glesLoadShader:(GLenum) type shaderSrc:(const char *)shaderSrc;

//编译和加载着色器,创建一个程序对象并链接着色器
//param vertShaderSrc：顶点着色器源码字符串
//param fragShaderSrc：片段着色器源码字符串
//成功则返回一个新的程序对象，失败则返回0
- (GLuint)glesLoadProgram:(const char *)vertShaderSrc andFragShaderSrc:(const char *)fragShaderSrc;

//加载和编译顶点着色器和片段着色器,创建一个程序对象并链接着色器
//param vertexShaderFileName:顶点着色器的文件名
//param vertexShaderOfType：顶点着色器的扩展名
//param fragmentShaderFileName：片段着色器的文件名
//param fragmentShaderOfType：片段着色器的扩展名
//成功则返回一个新的程序对象，失败则返回0
- (GLuint)setupShader:(NSString *)vertexShaderFileName
 vertexShaderOfType:(NSString *)vertexShaderOfType
fragmentShaderFileName:(NSString *)fragmentShaderFileName
fragmentShaderOfType:(NSString *)fragmentShaderOfType;

@end
