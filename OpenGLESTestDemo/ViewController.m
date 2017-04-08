//
//  ViewController.m
//  OpenGLESTestDemo
//
//  Created by 王福滨 on 17/4/6.
//  Copyright © 2017年 HuYa. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "GLESView.h"
#import "GLESVideoView.h"

//添加打开摄像头相关代理
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

//负责输入和输出设备之间的数据传递
@property(nonatomic, strong) AVCaptureSession *mCaptureSession;
//负责从AVCaptureDevice获得输入数据
@property(nonatomic, strong) AVCaptureDeviceInput *mCaptureDeviceInput;
//获得输出数据
@property(nonatomic, strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput;
//用于显示相机采集的预览数据
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *mCaptureVideoPreviewLayer;

//OpenGL ES View渲染显示
@property(nonatomic, strong) GLESView *myGLESView;

//相机渲染部分
@property(nonatomic, strong) GLESVideoView *myGLESVideoView;
@property (nonatomic , strong) UILabel  *mLabel;

@end

@implementation ViewController
{
    //dispatch队列
    dispatch_queue_t mProcessQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //初始化渲染view
    self.myGLESView = (GLESView *)self.view;
    
    //默认使用普通画图渲染，要使用相机数据渲染需要切换storyboard的view换成GLESVideoView，打开如下注释即可
//    //使用相机渲染
//    self.myGLESVideoView = (GLESVideoView *)self.view;
//    [self.myGLESVideoView setupGL];
//    
//    //开启相机的设置
//    [self startCapture];
//    
//    //初始化label
//    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
//    self.mLabel.textColor = [UIColor redColor];
//    [self.view addSubview:self.mLabel];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//开始相机的设置
- (void)startCapture
{
    //新建会话，设置图像大小，创建处理队列
    self.mCaptureSession = [[AVCaptureSession alloc] init];
    self.mCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    mProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    //新建摄像头，并设为前置
    AVCaptureDevice *inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for(AVCaptureDevice *device in devices)
    {
        if([device position] == AVCaptureDevicePositionFront)
        {
            inputCamera = device;
        }
    }
    
    //创建设备输入，并添加到会话
    self.mCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    if([self.mCaptureSession canAddInput:self.mCaptureDeviceInput])
    {
        [self.mCaptureSession addInput:self.mCaptureDeviceInput];
    }
    
//    //创建预览
//    self.mCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.mCaptureSession];
//    self.mCaptureVideoPreviewLayer.frame = self.view.bounds;
//    [self.mCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//
//    //使用YUV渲染时注释预览
//    [self.view.layer addSublayer:self.mCaptureVideoPreviewLayer];
    
    //使用YUV渲染
    self.myGLESVideoView.isFullYUVRange = YES;
    
    //创建数据输出，输出格式，
    self.mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.mCaptureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    [self.mCaptureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    //设置delegate
    [self.mCaptureDeviceOutput setSampleBufferDelegate:self queue:mProcessQueue];
    //添加到会话
    if ([self.mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
        [self.mCaptureSession addOutput:self.mCaptureDeviceOutput];
    }
    
    //AVCaptureConnection的作用是使得录制出来的图像上下颠倒
    AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    
    //开始会话
    [self.mCaptureSession startRunning];
    
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate代理

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    static long frameID = 0;
    ++frameID;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.myGLESVideoView displayPixelBuffer:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mLabel.text = [NSString stringWithFormat:@"%ld", frameID];
    });

}

@end
