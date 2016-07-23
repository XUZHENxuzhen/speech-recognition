//
//  ViewController.m
//  语音demo
//
//  Created by angelwin on 16/7/19.
//  Copyright © 2016年 com@angelwin. All rights reserved.
//

#import "ViewController.h"
//带界面的语音识别控件
#import <iflyMSC/IFlyRecognizerViewDelegate.h>
#import <iflyMSC/IFlyRecognizerView.h>
#import <iflyMSC/iflyMSC.h>
#import <iflyMSC/IFlySpeechConstant.h>
#import "IATConfig.h"
#import "BViewController.h"
#import "ISRDataHelper.h"
#import "AninationView.h"

@interface ViewController ()<IFlyRecognizerViewDelegate,IFlySpeechRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong)IFlyRecognizerView*iflyRecognizerView;//带界面的识别对象;
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, strong) NSString * result;

@end

@implementation ViewController

- (IBAction)beganSayClick:(id)sender {
    
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        
        [_textView setText:@""];
        [_textView resignFirstResponder];
        
        if(_iFlySpeechRecognizer == nil)
        {
            [self initRecognizer];
        }
        
        [_iFlySpeechRecognizer cancel];
        
        //设置音频来源为麦克风
        [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
        [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [_iFlySpeechRecognizer setDelegate:self];
        
        BOOL ret = [_iFlySpeechRecognizer startListening];
        if (ret) {
            [self startAnimation];
           
        }
    }

}

#pragma mark - 开始加载图片

- (void)startAnimation{
    //开始说话  加载动画
    AninationView *view = [[[NSBundle mainBundle]loadNibNamed:@"AninationView" owner:self options:nil]objectAtIndex:0];
    CGRect tempFram = [UIScreen mainScreen].bounds;
    view.center = CGPointMake(tempFram.size.width/2, tempFram.size.height / 2);
    
    [self.view addSubview:view];
    //判断是否在播放动画
    if(view.imagViewS.isAnimating == 1 ){
        return;
    }
    int imageCount = 9;
    NSMutableArray *imageArr = [NSMutableArray array];
    for (int i = 1; i <=imageCount; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d%d%d",i,i,i]];
        [imageArr addObject:image];
    }
    [AninationView animateWithDuration:1 animations:^{
        view.imagViewS.animationImages = imageArr;
        view.imageViewIn.animationDuration = 1;

        view.imagViewS.animationRepeatCount = 10;
        [view.imagViewS startAnimating];
        view.imageViewIn.image = [UIImage imageNamed:@"点"];
 NSLog(@"imageViewIn");
    } completion:^(BOOL finished) {
        NSLog(@"finished");
            NSMutableArray *imageArr = [NSMutableArray array];
            for (int i = 1; i <=3; i++) {
                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"点点闪%d",i]];
                [imageArr addObject:image];
            }
            view.imageViewIn.animationImages = imageArr;
            view.imageViewIn.animationDuration = 1;
            view.imageViewIn.animationRepeatCount = 5;
            [view.imageViewIn startAnimating];

        }];

}
- (void)viewDidLoad {
    [super viewDidLoad];
   
    
}
-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s",__func__);
    
    [super viewWillAppear:animated];
    
    [self initRecognizer];//初始化识别对象
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.view = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        [_iFlySpeechRecognizer cancel]; //取消识别
        [_iFlySpeechRecognizer setDelegate:nil];
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    }
    
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    _result =[NSString stringWithFormat:@"%@%@", _textView.text,resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,resultFromJson];
    
    if (isLast){
       //isLast=1 表示最后一次
    }

    
    NSLog(@"isLast=%d,_textView.text=%@",isLast,_textView.text);
}



//初始化
/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    if ([IATConfig sharedInstance].haveView == NO) {//无界面
        
        //单例模式，无UI的实例
        if (_iFlySpeechRecognizer == nil) {
            _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
            
            [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
            //设置听写模式
            [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        }
        _iFlySpeechRecognizer.delegate = self;
        
        if (_iFlySpeechRecognizer != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            
            //设置最长录音时间
            [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //设置后端点
            [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //设置前端点
            [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //网络等待时间
            [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //设置采样率，推荐使用16K
            [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            if ([instance.language isEqualToString:[IATConfig chinese]]) {
                //设置语言
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                //设置方言
                [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }else if ([instance.language isEqualToString:[IATConfig english]]) {
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            //设置是否返回标点符号
            [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
            
        }
    }
//    //单例模式，UI的实例
//    if (_iflyRecognizerView == nil) {
//        //UI显示剧中
//        _iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
//        
//        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
//        
//        //设置听写模式
//        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
//        
//    }
//    _iflyRecognizerView.delegate = self;
//    
//    if (_iflyRecognizerView != nil) {
//        IATConfig *instance = [IATConfig sharedInstance];
//        //设置最长录音时间
//        [_iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
//        //设置后端点
//        [_iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
//        //设置前端点
//        [_iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
//        //网络等待时间
//        [_iflyRecognizerView setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
//        
//        //设置采样率，推荐使用16K
//        [_iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
//        if ([instance.language isEqualToString:[IATConfig chinese]]) {
//            //设置语言
//            [_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
//            //设置方言
//            [_iflyRecognizerView setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
//        }else if ([instance.language isEqualToString:[IATConfig english]]) {
//            //设置语言
//            [_iflyRecognizerView setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
//        }
//        //设置是否返回标点符号
//        [_iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
//        
//   }
}
#pragma mark - IFlySpeechRecognizerDelegate

/**
 音量回调函数
 volume 0－30
 ****/
- (void) onVolumeChanged: (int)volume
{
   
}



/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
    NSLog(@"onBeginOfSpeech");
   
}

/**
 停止录音回调
 ****/
- (void) onEndOfSpeech
{
    NSLog(@"onEndOfSpeech");
    

}


/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{
    
}

/**
 有界面，听写结果回调
 resultArray：听写结果
 isLast：表示最后一次
 ****/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    _textView.text = [NSString stringWithFormat:@"%@%@",_textView.text,result];
}



/**
 听写取消回调
 ****/
- (void) onCancel
{
    NSLog(@"识别取消");
}

-(void) showPopup
{
//    [_popUpView showText: @"正在上传..."];
}

#pragma mark - IFlyDataUploaderDelegate

/**
 上传联系人和词表的结果回调
 error ，错误码
 ****/
- (void) onUploadFinished:(IFlySpeechError *)error
{
//    NSLog(@"%d",[error errorCode]);
//    
//    if ([error errorCode] == 0) {
//        [_popUpView showText: @"上传成功"];
//    }
//    else {
//        [_popUpView showText: [NSString stringWithFormat:@"上传失败，错误码:%d",error.errorCode]];
//        
//    }
//    
//    _upWordListBtn.enabled = YES;
//    _upContactBtn.enabled = YES;
}





@end
