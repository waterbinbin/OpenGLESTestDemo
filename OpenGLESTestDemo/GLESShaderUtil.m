//
//  GLESShaderUtil.m
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 17/4/6.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import "GLESShaderUtil.h"

@interface GLESShaderUtil()
{
    NSMutableDictionary *_shaderHandleDictionary;
}
@end

@implementation GLESShaderUtil

//编译和加载着色器
//param type：shader的类型（GL_VERTEX_SHADER 或者 GL_FRAGMENT_SHADER）
//param shaderSrc：着色器源码字符串
//成功则返回一个新的着色器对象，失败则返回0
- (GLuint)glesLoadShader:(GLenum) type shaderSrc:(const char *)shaderSrc
{
    GLuint shader;
    GLint compiled;
    
    //创建shader对象
    shader = glCreateShader(type);
    if(shader == 0)
    {
        return 0;
    }
    
    //加载shader源代码
    glShaderSource(shader, 1, &shaderSrc, NULL);
    
    //编译shader
    glCompileShader(shader);
    
    //检查编译状态
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if(!compiled)
    {
        GLint infoLen = 0;
        
        //输出错误日志
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 1)
        {
            char *infoLog = malloc(sizeof(char) * infoLen);
            
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            NSLog(@"Load shader log:%s", infoLog);
            
            free(infoLog);
        }
        
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

//编译和加载着色器,创建一个程序对象并链接着色器
//param vertShaderSrc：顶点着色器源码字符串
//param fragShaderSrc：片段着色器源码字符串
//成功则返回一个新的程序对象，失败则返回0
- (GLuint)glesLoadProgram:(const char *)vertShaderSrc andFragShaderSrc:(const char *)fragShaderSrc
{
    GLuint vertexShader;
    GLuint fragmentShader;
    GLuint programObject;
    
    //编译和加载顶点和片段着色器
    vertexShader = [self glesLoadShader:GL_VERTEX_SHADER shaderSrc:vertShaderSrc];
    if(vertexShader == 0)
    {
        return 0;
    }
    
    fragmentShader = [self glesLoadShader:GL_FRAGMENT_SHADER shaderSrc:fragShaderSrc];
    if(fragmentShader == 0)
    {
        return 0;
    }
    
    //创建程序对象
    programObject = glCreateProgram();
    if(programObject == 0)
    {
        return 0;
    }
    
    //连接着色器和程序
    glAttachShader(programObject, vertexShader);
    glAttachShader(programObject, fragmentShader);
    
    if(![self linkProgram:programObject])
    {
        glDeleteShader(programObject);
        return 0;
    }
    
    //删除不使用的shader资源
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return programObject;
}

//加载和编译顶点着色器和片段着色器,创建一个程序对象并链接着色器
//param vertexShaderFileName:顶点着色器的文件名
//param vertexShaderOfType：顶点着色器的扩展名
//param fragmentShaderFileName：片段着色器的文件名
//param fragmentShaderOfType：片段着色器的扩展名
//成功则返回一个新的程序对象，失败则返回0
- (GLuint)setupShader:(NSString *)vertexShaderFileName
   vertexShaderOfType:(NSString *)vertexShaderOfType
fragmentShaderFileName:(NSString *)fragmentShaderFileName
 fragmentShaderOfType:(NSString *)fragmentShaderOfType
{
    GLuint programObject;
    //读取文件路径
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:vertexShaderFileName ofType:vertexShaderOfType];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:fragmentShaderFileName ofType:fragmentShaderOfType];
    
    //读取字符串
    NSString *vertShaderSrc = [NSString stringWithContentsOfFile:vertFile encoding:NSUTF8StringEncoding error:nil];
    const char* vertSource = (char *)[vertShaderSrc UTF8String];
    NSString *fragShaderSrc = [NSString stringWithContentsOfFile:fragFile encoding:NSUTF8StringEncoding error:nil];
    const char* fragSource = (char *)[fragShaderSrc UTF8String];
    
    //编译和加载shader,创建一个程序对象并链接着色器
    programObject = [self glesLoadProgram:vertSource andFragShaderSrc:fragSource];
    if(programObject == 0)
    {
        return 0;
    }
    
    return programObject;
}

#pragma mark 类内部使用函数

//链接程序
//param programObject:程序对象
//返回布尔值
- (BOOL)linkProgram:(GLuint)programObject
{
    GLint status;
    
    //链接程序对象
    glLinkProgram(programObject);
    
    GLint infoLen = 0;
    
    //输出错误日志
    glGetProgramiv(programObject, GL_INFO_LOG_LENGTH, &infoLen);
    if(infoLen > 1)
    {
        char *infoLog = malloc(sizeof(char) * infoLen);
        
        glGetProgramInfoLog(programObject, infoLen, NULL, infoLog);
        NSLog(@"Link program log:%s", infoLog);
        
        free(infoLog);
    }
    
    //检查链接状态
    glGetProgramiv(programObject, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }

    return YES;
}

//校验着色器等程序对象是否正确执行，效率很低，一般调试使用，发布的时候删除调用
//param programObject:程序对象
//返回布尔值
- (BOOL)validateProgram:(GLuint)programObject
{
    GLint infoLen, status;
    
    //校验着色器等程序对象是否正确执行
    glValidateProgram(programObject);
    
    //输出错误日志
    glGetProgramiv(programObject, GL_INFO_LOG_LENGTH, &infoLen);
    if (infoLen > 0)
    {
        GLchar *log = (GLchar *)malloc(infoLen);
        
        glGetProgramInfoLog(programObject, infoLen, &infoLen, log);
        NSLog(@"Program validate log:%s", log);
        
        free(log);
    }
    
    //检查校验状态
    glGetProgramiv(programObject, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}


//参考封装方法，后续使用可以参考增加
- (void) tearDown
{
    if (_programID)
    {
        glDeleteProgram(_programID);
        _programID = 0;
    }
}

- (void)dealloc
{
    [self tearDown];
}

- (void) use
{
    glUseProgram(_programID);
}

- (int) getHandle:(NSString *)name
{
    NSNumber *object = [_shaderHandleDictionary objectForKey:name];
    if (object != nil) {
        return [object intValue];
    }
    
    int handle = glGetAttribLocation(_programID, [name UTF8String]);
    if(handle == -1)
    {
        handle = glGetUniformLocation(_programID, [name UTF8String]);
    }
    
    if(handle == -1)
    {
        NSLog(@"Could not get attrib location for %@", name);
    }
    else
    {
        [_shaderHandleDictionary setObject:[NSNumber numberWithInt:handle] forKey:name];
    }
    
    return handle;
}

- (void) setUniform1i:(NSString*)name :(int)x
{
    int location = [self getHandle:name];
    glUniform1i(location, x);
}

- (void) setUniform2i:(NSString*)name :(int)x :(int)y
{
    int location = [self getHandle:name];
    glUniform2i(location, x, y);
}

- (void) setUniform1f:(NSString*)name :(float)x
{
    int location = [self getHandle:name];
    glUniform1f(location, x);
}

- (void) setUniform2f:(NSString*)name :(float)x :(float)y
{
    int location = [self getHandle:name];
    glUniform2f(location, x, y);
}

- (void) setUniformMatrix4fv:(NSString*)name :(int)count :(BOOL)transpose :(float*) value
{
    int location = [self getHandle:name];
    glUniformMatrix4fv(location, count, transpose, value);
}

- (void) setVertexAttribPointer:(NSString*)name :(int)size :(int)type :(BOOL)normalized :(int)stride : (void*)ptr
{
    int index = [self getHandle:name];
    glEnableVertexAttribArray(index);
    glVertexAttribPointer(index, size, type, normalized, stride, ptr);
}

- (void) setUniformTexture:(NSString*)name :(int)x :(int)textureID
{
    int location = [self getHandle:name];
    glUniform1i(location, x);
    glActiveTexture(GL_TEXTURE0 + x);
    glBindTexture(GL_TEXTURE_2D, textureID);
}

- (void) setUniformTexture:(NSString*)name :(int)x :(int)target :(int)textureID
{
    int location = [self getHandle:name];
    glUniform1i(location, x);
    glActiveTexture(GL_TEXTURE0 + x);
    glBindTexture(target, textureID);
}


@end
