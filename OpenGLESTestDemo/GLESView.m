//
//  GLESView.m
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 17/4/6.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import "GLESView.h"

#import "GLESShaderUtil.h"
#import "GLESTextureUtil.h"

#define VERTEX_POS_SIZE       3 // x, y and z
#define VERTEX_COLOR_SIZE     4 // r, g, b, and a

#define VERTEX_POS_INDX       0
#define VERTEX_COLOR_INDX     1

#define VERTEX_STRIDE         ( sizeof(GLfloat) *     \
                              ( VERTEX_POS_SIZE +    \
                                VERTEX_COLOR_SIZE ) )

@interface GLESView()
{
    //设置视口宽高
    GLint _width;
    GLint _height;
    
    //VBO部分
    //顶点缓冲区ID VertexBufferObject Ids
    GLuint vboIds[2];
    //统一变量，代表x轴的偏移量x-offset uniform location
    GLuint offsetLoc;
    
    //VAO部分
    GLuint vboIdsOfVAO[2];
    //VertexArrayObject Id
    GLuint vaoId;

}
//OpenGL ES上下文
@property(nonatomic, strong) EAGLContext* myContext;
//用于显示的layer
@property(nonatomic, strong) CAEAGLLayer* myEagLayer;
//OpenGL ES程序对象
@property(nonatomic, assign) GLuint myProgram;
//OpenGL ES渲染缓冲区
@property(nonatomic, assign) GLuint myColorRenderBuffer;
//OpenGL ES帧缓冲区
@property(nonatomic, assign) GLuint myColorFrameBuffer;

//OpenGL ES程序对象 VBO
@property(nonatomic, assign) GLuint myProgramVBO;

//OpenGL ES程序对象 VAO
@property(nonatomic, assign) GLuint myProgramVAO;

//OpenGL ES程序对象 Texture
@property(nonatomic, assign) GLuint myProgramTex;

//实例方法

@end

@implementation GLESView

#pragma mark view相关方法

//layoutSubviews是UIView中的属性方法，即只要继承于UIView，就可以使用这个方法，
//以下是他的触发时机：
//1、init初始化不会触发layoutSubviews
//2、addSubview会触发layoutSubviews
//3、设置view的Frame会触发layoutSubviews，当然前提是frame的值设置前后发生了变化
//4、滚动一个UIScrollView会触发layoutSubviews
//5、旋转Screen会触发父UIView上的layoutSubviews事件
//6、改变一个UIView大小的时候也会触发父UIView上的layoutSubviews事件
- (void)layoutSubviews
{
    [self setupView];
}

//view方法
- (void)setupView
{
    //layer显示
    [self setupLayer];
    
    //初始化GLES相关
    [self InitGLES];
    
    //画三角形
    [self GLESDrawTriangle];
    
    //使用普通的顶点属性的结构数组方法与VBO方法对比
    [self GLESDrawVBO];
    
    //方法三：顶点数组对象方法（VAO）
    [self GLESDrawVAO];
    
    //渲染一个纹理图像
    [self GLESDrawTexture];
}

#pragma mark layer显示相关

//layer的类方法
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//layer显示
- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*)self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

#pragma mark OpenGL ES 相关

//初始化GLES相关
- (void)InitGLES
{
    //初始化上下文
    [self setupContext];
    
    //加载和编译顶点着色器和片段着色器,创建一个程序对象并链接着色器
    //红色三角形的shader
    GLESShaderUtil *glesShader = [[GLESShaderUtil alloc] init];
    self.myProgram = [glesShader setupShader:@"vertexShader"
                          vertexShaderOfType:@"vsh"
                      fragmentShaderFileName:@"fragmentShader"
                        fragmentShaderOfType:@"fsh"];
    //VBO的shader
    GLESShaderUtil *glesShader1 = [[GLESShaderUtil alloc] init];
    self.myProgramVBO = [glesShader1 setupShader:@"vertexShaderVBO"
                              vertexShaderOfType:@"vsh"
                          fragmentShaderFileName:@"fragmentShaderVBO"
                            fragmentShaderOfType:@"fsh"];
    //VAO的shader
    GLESShaderUtil *glesShader2 = [[GLESShaderUtil alloc] init];
    self.myProgramVAO = [glesShader2 setupShader:@"vertexShaderVAO"
                              vertexShaderOfType:@"vsh"
                          fragmentShaderFileName:@"fragmentShaderVAO"
                            fragmentShaderOfType:@"fsh"];
    
    //Texture的shader
    GLESShaderUtil *glesShader3 = [[GLESShaderUtil alloc] init];
    self.myProgramTex = [glesShader3 setupShader:@"vertexShaderTexture"
                              vertexShaderOfType:@"vsh"
                          fragmentShaderFileName:@"fragmentShaderTexture"
                            fragmentShaderOfType:@"fsh"];
    
    //销毁帧缓冲区和渲染缓冲区
    [self destoryRenderAndFrameBuffer];
    
    //创建渲染缓冲区
    [self setupRenderBuffer];
    
    //创建帧缓冲区
    [self setupFrameBuffer];
    
    //清除屏幕颜色，使用白色
    glClearColor (1.0f, 1.0f, 1.0f, 0.0f);
    
    //初始化视口宽高
    //获取视图放大倍数，可以把scale设置为1试试
    CGFloat scale = [[UIScreen mainScreen] scale];
    _width = self.frame.size.width * scale;
    _height = self.frame.size.height * scale;
    
    //获取统一变量部分
    //使用VBO
    offsetLoc = glGetUniformLocation(self.myProgramVBO, "u_offset");
    vboIds[0] = 0;
    vboIds[1] = 0;
    
    //方法三：顶点数组对象方法（VAO）
    //VBO还是需要每次在draw调用，VAO只需要调用一次，因此很多工作可以在初始化中完成
    //[self DrawPrimitiveWithVAOs];  //注意如果要和上边画单独的三角形和画VBO对比，不能在这里初始化，要放回GLESDrawVAO方法中，但是单独使用VAO就放在初始化中
}

//初始化上下文
- (void)setupContext
{
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 3.0，如果是iphone 5s以下要修改为2.0的版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context)
    {
        NSLog(@"Failed to initialize OpenGLES 3.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    self.myContext = context;
}

//创建渲染缓冲区
- (void)setupRenderBuffer
{
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //为颜色渲染缓冲区分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

//创建帧缓冲区
- (void)setupFrameBuffer
{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    //设置为当前framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //将_colorRenderBuffer装配到GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//销毁帧缓冲区和渲染缓冲区
- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

#pragma mark OpenGL ES 渲染Draw函数

//渲染一个三角形
- (void)GLESDrawTriangle
{
    //1. 初始化顶点等相关部分
    GLfloat vVertices[] = {
        -1.0f,  1.0f, 0.0f,
        0.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f
    };
    
    //2. 固定部分
    //设置视口大小
    glViewport(0, 0, _width, _height);
    
    //清除color buffer
    glClear(GL_COLOR_BUFFER_BIT);
    
    //使用程序对象
    glUseProgram(self.myProgram);
    
#pragma mark 以下是画图其他程序替换部分  开始
    //3. 添加统一变量传递部分
    
    //4. 画图部分
    //加载顶点数据，OpenGL ES 3.0使用方法
    glVertexAttribPointer (0, 3, GL_FLOAT, GL_FALSE, 0, vVertices);
    glEnableVertexAttribArray (0);
    
    //加载顶点数据，OpenGL ES 2.0使用方法
//    GLuint positionSlot = glGetAttribLocation(self.myProgram, "vPosition");
//    glVertexAttribPointer (positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vVertices);
//    glEnableVertexAttribArray (positionSlot);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
#pragma mark 以上是画图其他程序替换部分  结束
    
    //5. 显示部分
    if ([EAGLContext currentContext] == self.myContext)
    {
        [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

//使用普通的顶点属性的结构数组方法与VBO方法对比
- (void)GLESDrawVBO
{
    //1. 初始化顶点等相关部分
    //顶点缓存数据
    GLfloat vVertices[3 * (VERTEX_POS_SIZE + VERTEX_COLOR_SIZE)] = {
        0.0f,  1.0f, 0.0f,         // v0
        1.0f,  0.0f, 0.0f, 1.0f,   // c0
        0.5f,  0.0f, 0.0f,         // v1
        0.0f,  1.0f, 0.0f, 1.0f,   // c1
        0.0f,  0.0f, 0.0f,         // v2
        0.0f,  0.0f, 1.0f, 1.0f,   // c2
    };
    //索引缓存数据
    GLushort indices[3] = { 0, 1, 2 };
    
    //2. 固定部分
    //设置视口大小
    glViewport(0, 0, _width, _height);
    
    //清除color buffer,这里如果不执行glClear可以实现效果叠加
    //glClear(GL_COLOR_BUFFER_BIT);
    
    //使用程序对象
    glUseProgram(self.myProgramVBO);
    
    //3. 添加统一变量传递部分
    glUniform1f(offsetLoc, 0.0f );
    
    //4. 画图部分
    //加载顶点数据，OpenGL ES 3.0使用方法
    //方法一：使用普通的顶点属性的结构数组方法
    [self DrawPrimitiveWithoutVBOs:vVertices vtxStride:sizeof(GLfloat) * (VERTEX_POS_SIZE + VERTEX_COLOR_SIZE) numIndices:3 indices:indices];
    //方法二：顶点缓冲区对象方法（VBO）
    glUniform1f(offsetLoc, 0.5f );
    [self DrawPrimitiveWithVBOs:3 vtxBuf:vVertices vtxStride:sizeof(GLfloat) * (VERTEX_POS_SIZE + VERTEX_COLOR_SIZE) numIndices:3 indices:indices];

    
    //加载顶点数据，OpenGL ES 2.0使用方法
    //使用GLESDrawTriangle方法先获得顶点和颜色的location，后续流程一样
    
    //glDrawArrays (GL_TRIANGLES, 0, 3);
    
    //5. 显示部分
    if ([EAGLContext currentContext] == self.myContext)
    {
        [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

//方法三：顶点数组对象方法（VAO）
- (void)GLESDrawVAO
{
//    //1. 初始化顶点等相关部分
//    //顶点缓存数据
//    GLfloat vVertices[3 * (VERTEX_POS_SIZE + VERTEX_COLOR_SIZE)] = {
//        0.0f,  1.0f, 0.0f,         // v0
//        1.0f,  0.0f, 0.0f, 1.0f,   // c0
//        0.5f,  0.0f, 0.0f,         // v1
//        0.0f,  1.0f, 0.0f, 1.0f,   // c1
//        0.0f,  0.0f, 0.0f,         // v2
//        0.0f,  0.0f, 1.0f, 1.0f,   // c2
//    };
//    //索引缓存数据
//    GLushort indices[3] = { 0, 1, 2 };

    //注意如果单独使用VAO，该方法不要放这里，放在初始化中，现在是为了跟上边画单独的三角形和画VBO对比共存才放这里
    [self DrawPrimitiveWithVAOs];
    
    //2. 固定部分
    //设置视口大小
    glViewport(0, 0, _width, _height);
    
    //清除color buffer,这里如果不执行glClear可以实现效果叠加
    //glClear(GL_COLOR_BUFFER_BIT);
    
    //使用程序对象
    glUseProgram(self.myProgramVAO);
    
    //3. 添加统一变量传递部分
    
    //4. 画图部分
    //加载顶点数据，OpenGL ES 3.0使用方法
    //绑定VAO
    glBindVertexArray(vaoId);
    
    //VAO设置画图
    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_SHORT,(const void *) 0);
    
    //返回默认VAO
    glBindVertexArray(0);
    
    //加载顶点数据，OpenGL ES 2.0使用方法
    //使用GLESDrawTriangle方法先获得顶点和颜色的location，后续流程一样
    
    //5. 显示部分
    if ([EAGLContext currentContext] == self.myContext)
    {
        [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

//渲染一个纹理图像
- (void)GLESDrawTexture
{
    //获取图片的CGImageRef,若果是png后缀的可以省略不写
    CGImageRef spriteImage = [UIImage imageNamed:@"for_test.png"].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image for_test.png");
        exit(1);
    }
    
    //1. 初始化顶点等相关部分
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
//        1.0f, -1.0f, 0.0f,     1.0f, 0.0f,
//        0.0f, 0.0f, 0.0f,     0.0f, 1.0f,
//        0.0f, -1.0f, 0.0f,    0.0f, 0.0f,
//        1.0f, 0.0f, 0.0f,      1.0f, 1.0f,
//        0.0f, 0.0f, 0.0f,     0.0f, 1.0f,
//        1.0f, -1.0f, 0.0f,     1.0f, 0.0f,
        //纹理根原图上下颠倒，因此有如下对应关系
        1.0f, -1.0f, 0.0f,     1.0f, 1.0f,  //右下－右上
        0.0f, 0.0f, 0.0f,     0.0f, 0.0f,  //左上－左下
        0.0f, -1.0f, 0.0f,    0.0f, 1.0f,  //左下－左上
        1.0f, 0.0f, 0.0f,      1.0f, 0.0f,  //右上－右下
        0.0f, 0.0f, 0.0f,     0.0f, 0.0f,  //左上－左下
        1.0f, -1.0f, 0.0f,     1.0f, 1.0f,  //右下－右上
    };
    
    //2. 固定部分
    //设置视口大小
    glViewport(0, 0, _width, _height);
    
    //清除color buffer,这里如果不执行glClear可以实现效果叠加
    //glClear(GL_COLOR_BUFFER_BIT);
    
    //使用程序对象
    glUseProgram(self.myProgramTex);
    
    //3. 添加统一变量传递部分
    
    //4. 画图部分
    //加载顶点数据，OpenGL ES 3.0使用方法
    
    //加载顶点数据，OpenGL ES 2.0使用方法
    //使用vbo方法
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgramTex, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    GLuint textCoor = glGetAttribLocation(self.myProgramTex, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    //加载纹理
    GLESTextureUtil *glesTextureUtil = [[GLESTextureUtil alloc] initWithTarget:GL_TEXTURE_2D];
    [glesTextureUtil createFromImage:spriteImage pixelFmt:GL_BGRA];
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //5. 显示部分
    if ([EAGLContext currentContext] == self.myContext)
    {
        [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

#pragma mark 内部调用方法

//方法一：使用普通的顶点属性的结构数组方法
//param vertices：顶点缓存数据
//param vtxStride：顶点数组的大小 * sizeof（数组的类型）
//param numIndices：索引数组大小
//param indices：索引缓存数据
- (void)DrawPrimitiveWithoutVBOs:(GLfloat *)vertices
                       vtxStride:(GLint) vtxStride
                      numIndices:(GLint) numIndices
                         indices:(GLushort *)indices
{
    GLfloat *vtxBuf = vertices;
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    glEnableVertexAttribArray(VERTEX_POS_INDX);
    glEnableVertexAttribArray(VERTEX_COLOR_INDX);
    
    glVertexAttribPointer(VERTEX_POS_INDX, VERTEX_POS_SIZE,
                           GL_FLOAT, GL_FALSE, vtxStride,
                           vtxBuf);
    vtxBuf += VERTEX_POS_SIZE;
    
    glVertexAttribPointer(VERTEX_COLOR_INDX,
                           VERTEX_COLOR_SIZE, GL_FLOAT,
                           GL_FALSE, vtxStride, vtxBuf);
    
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, indices);
    
    glDisableVertexAttribArray(VERTEX_POS_INDX);
    glDisableVertexAttribArray(VERTEX_COLOR_INDX);
    
}

//方法二：顶点缓冲区对象方法（VBO）
//param numVertices：每个顶点包含的维数
//param vtxBuf:顶点缓存数据
//param vtxStride：顶点数组的大小 * sizeof（数组的类型）
//param numIndices：索引数组大小
//param indices：索引缓存数据
- (void)DrawPrimitiveWithVBOs:(GLint) numVertices
                       vtxBuf:(GLfloat *)vtxBuf
                    vtxStride:(GLint)vtxStride
                   numIndices:(GLint)numIndices
                      indices:(GLushort *)indices
{
    GLuint   offset = 0;
    // vboIds[0] - 用于存储顶点属性数据
    // vboIds[l] - 用于存储索引数据
    if (vboIds[0] == 0 && vboIds[1] == 0)
    {
        //仅在第一次使用的时候生成缓存 Only allocate on the first draw
        glGenBuffers(2, vboIds);
        
        glBindBuffer(GL_ARRAY_BUFFER, vboIds[0]);
        glBufferData(GL_ARRAY_BUFFER, vtxStride * numVertices,
                      vtxBuf, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIds[1] );
        glBufferData ( GL_ELEMENT_ARRAY_BUFFER,
                      sizeof ( GLushort ) * numIndices,
                      indices, GL_STATIC_DRAW );
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, vboIds[0]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIds[1]);
    
    glEnableVertexAttribArray(VERTEX_POS_INDX);
    glEnableVertexAttribArray(VERTEX_COLOR_INDX);
    
    glVertexAttribPointer(VERTEX_POS_INDX, VERTEX_POS_SIZE,
                           GL_FLOAT, GL_FALSE, vtxStride,
                           (const void *) offset);
    
    offset += VERTEX_POS_SIZE * sizeof (GLfloat);
    glVertexAttribPointer(VERTEX_COLOR_INDX,
                           VERTEX_COLOR_SIZE,
                           GL_FLOAT, GL_FALSE, vtxStride,
                           (const void *) offset);
    
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, 0);
    
    glDisableVertexAttribArray(VERTEX_POS_INDX);
    glDisableVertexAttribArray(VERTEX_COLOR_INDX);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

//方法三：顶点数组对象方法（VAO）
//VBO还是需要每次在draw调用，VAO只需要调用一次，因此很多工作可以在初始化中完成
- (void)DrawPrimitiveWithVAOs
{
    //顶点缓存数据
    GLfloat vertices[3 * (VERTEX_POS_SIZE + VERTEX_COLOR_SIZE)] =
    {
        -1.0f,  0.0f, 0.0f,        // v0
        1.0f,  0.0f, 0.0f, 1.0f,   // c0
        0.0f, -1.0f, 0.0f,         // v1
        0.0f,  1.0f, 0.0f, 1.0f,   // c1
        -1.0f, -1.1f, 0.0f,        // v2
        0.0f,  0.0f, 1.0f, 1.0f,   // c2
    };
    //索引缓存数据
    GLushort indices[3] = {0, 1, 2};
    
    //生成VBO IDS和加载VBO数据
    glGenBuffers(2, vboIdsOfVAO);
    
    glBindBuffer(GL_ARRAY_BUFFER, vboIdsOfVAO[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW );
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIdsOfVAO[1]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices),
                  indices, GL_STATIC_DRAW);
    
    //生成VAO Generate VAO Id
    glGenVertexArrays(1, &vaoId);
    
    // 绑定VAO， 设置顶点属性
    glBindVertexArray(vaoId);
    
    glBindBuffer(GL_ARRAY_BUFFER, vboIdsOfVAO[0]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIdsOfVAO[1]);
    
    glEnableVertexAttribArray(VERTEX_POS_INDX);
    glEnableVertexAttribArray(VERTEX_COLOR_INDX);
    
    glVertexAttribPointer(VERTEX_POS_INDX, VERTEX_POS_SIZE,
                           GL_FLOAT, GL_FALSE, VERTEX_STRIDE, (const void *) 0);
    
    glVertexAttribPointer(VERTEX_COLOR_INDX, VERTEX_COLOR_SIZE,
                           GL_FLOAT, GL_FALSE, VERTEX_STRIDE,
                           (const void *)(VERTEX_POS_SIZE * sizeof(GLfloat)));
    
    //重置默认VAO Reset to the default VAO
    glBindVertexArray(0);
}

@end
