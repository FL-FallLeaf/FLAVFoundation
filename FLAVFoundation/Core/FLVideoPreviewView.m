//
//  FLVideoPreviewView.m
//  FLAVFoundation
//
//  Created by Leaf on 2017/10/21.
//  Copyright © 2017年 leaf. All rights reserved.
//

#import "FLVideoPreviewView.h"
@import OpenGLES;

@interface FLVideoPreviewView ()

@property (nonatomic, strong) CAEAGLLayer *glLayer;
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) CIContext *ciContext;

@end

@implementation FLVideoPreviewView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

/**
 CAEAGLLayer作为OpenGL ES渲染图像的载体
 */
+ (Class)layerClass {
    
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupRenderbuffer];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupRenderbuffer];
    }
    return self;
}

- (void)setupLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.contentsScale = [UIScreen mainScreen].scale;
    eaglLayer.contentsGravity = kCAGravityResizeAspect;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                                     kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    self.glLayer = eaglLayer;
}

- (void)setupContext {
    //EAGLContext管理着OpenGL ES的渲染上下文
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //ciContext上所有的绘制都会渲染进glContext中
    self.ciContext = [CIContext contextWithEAGLContext:self.glContext];
    [EAGLContext setCurrentContext:self.glContext];
}

- (void)setupRenderbuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    //    GLuint depthbuffer;
    //    glGenRenderbuffers(1, &depthbuffer);
    //    glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
    //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    //    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthbuffer);
    
    GLuint colorbuffer;
    glGenRenderbuffers(1, &colorbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer);
    //    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, self.frame.size.width, self.frame.size.height);
//    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorbuffer);
}

/**
 呈现渲染缓冲区中的颜色缓存
 */
- (void)render:(CIImage *)ciImage
{
    [EAGLContext setCurrentContext:self.glContext];
    [self.ciContext drawImage:ciImage inRect:CGRectMake(0, 0, [self drawableWidth], [self drawableHeight]) fromRect:ciImage.extent];
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (NSInteger)drawableWidth
{
    GLint          backingWidth;
    
    glGetRenderbufferParameteriv(
                                 GL_RENDERBUFFER,
                                 GL_RENDERBUFFER_WIDTH,
                                 &backingWidth);
    
    return (NSInteger)backingWidth;
}

- (NSInteger)drawableHeight
{
    GLint          backingHeight;
    
    glGetRenderbufferParameteriv(
                                 GL_RENDERBUFFER,
                                 GL_RENDERBUFFER_HEIGHT,
                                 &backingHeight);
    
    return (NSInteger)backingHeight;
}

- (void)layoutSubviews {
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
}

@end
