//
//  ReadCameraController.m
//  FFmpeg_Demo
//
//  Created by 尚往文化 on 17/7/31.
//  Copyright © 2017年 YBing. All rights reserved.
//

#import "ReadCameraController.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale//swscale.h>
#include <libavutil/mathematics.h>
#include <libavutil/time.h>
#import <libavdevice/avdevice.h>
#include <libswscale//swscale.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

@interface ReadCameraController ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@end

@implementation ReadCameraController
{
    AVPicture           picture;
    AVFrame *pFrame,*pFrameYUV;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    [self clickStreamButton:nil];
    [self test];
}

- (void)clickStreamButton:(id)sender {
    
    //Input AVFormatContext and Output AVFormatContext
    AVFormatContext *ifmt_ctx = NULL;
    AVPacket pkt;
    int ret, i;
    int videoindex=-1;
    int frame_index=0;
    int64_t start_time=0;
    //    char out_filename = "rtmp://192.168.10.133:1990/liveApp/room";//Output URL[RTMP]
    //out_filename = "rtp://233.233.233.233:6666";//Output URL[UDP]
    //    strcpy(out_filename,output_str_full);
    
    av_register_all();
    avformat_network_init();
    avdevice_register_all();
    
    AVDictionary* options = NULL;
    //寻找设备
    //    av_dict_set(&options,"list_devices","true",0);
    AVInputFormat *iformat = av_find_input_format("avfoundation");
    printf("==AVFoundation Device Info===\n");
    
    av_dict_set(&options, "video_size", "192x144", 0);
    av_dict_set(&options, "framerate", "30", 0);
    av_dict_set(&options, "pixel_format", "nv12", 0);
    /*
     { "video_size", "set frame size", OFFSET(width), AV_OPT_TYPE_IMAGE_SIZE, {.str = NULL}, 0, 0, DEC },
     { "pixel_format", "set pixel format", OFFSET(pixel_format), AV_OPT_TYPE_STRING, {.str = "yuv420p"}, 0, 0, DEC },
     { "framerate", "set frame rate", OFFSET(framerate), AV_OPT_TYPE_VIDEO_RATE, {.str = "25"}, 0, 0, DEC },
     { NULL },
     */
    if (avformat_open_input(&ifmt_ctx,"0",iformat,&options)!=0) {
        printf("Couldn't open input");
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        printf( "Failed to retrieve input stream information");
        goto end;
    }
    
    for(i=0; i<ifmt_ctx->nb_streams; i++) {
        if(ifmt_ctx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    }
    
    
    AVCodecContext *pCodecCtx=ifmt_ctx->streams[videoindex]->codec;
    AVCodec *pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL)
    {
        printf("Codec not found.\n");
        goto end;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0)
    {
        printf("Could not open codec.\n");
        goto end;
    }
    
    pFrame=av_frame_alloc();
    pFrameYUV=av_frame_alloc();
    int got_picture;
    struct SwsContext *img_convert_ctx;
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    while (1) {
        //Get an AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;
        if(pkt.stream_index==videoindex){
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, &pkt);
            if(ret < 0){
                printf("Decode Error.\n");
                goto end;
            }
            
            sws_scale(img_convert_ctx, (const unsigned char* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
            
            self.imgView.image = [self imageFromAVPicture];
            
        }
        
        
        
        av_free_packet(&pkt);
        
        
    }
end:
    avformat_close_input(&ifmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
}

- (UIImage *)imageFromAVPicture
{
    avpicture_free(&picture);
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, 342, 300);
    struct SwsContext * imgConvertCtx = sws_getContext(pFrame->width,
                                                       pFrame->height,
                                                       AV_PIX_FMT_NV12,
                                                       342,
                                                       300,
                                                       AV_PIX_FMT_RGB24,
                                                       SWS_FAST_BILINEAR,
                                                       NULL,
                                                       NULL,
                                                       NULL);
    if(imgConvertCtx == nil) return nil;
    sws_scale(imgConvertCtx,
              pFrame->data,
              pFrame->linesize,
              0,
              pFrame->height,
              picture.data,
              picture.linesize);
    sws_freeContext(imgConvertCtx);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreate(kCFAllocatorDefault,
                                  picture.data[0],
                                  picture.linesize[0] * 300);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(342,
                                       300,
                                       8,
                                       24,
                                       picture.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    
    
    
    return image;
}

void show_dshow_device(){
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options,"list_devices","true",0);
    AVInputFormat *iformat = av_find_input_format("avfoundation");
    printf("Device Info=============\n");
    avformat_open_input(&pFormatCtx,"video=dummy",iformat,&options);
    printf("========================\n");
}

void show_dshow_device_option(){
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options,"list_options","true",0);
    AVInputFormat *iformat = av_find_input_format("dshow");
    printf("========Device Option Info======\n");
    
    avformat_open_input(&pFormatCtx,"video=1.3M WebCam",iformat,&options);
    printf("================================\n");
}

//定义BMP文件头



#ifndef _WINGDI_
#define _WINGDI_
typedef struct tagBITMAPFILEHEADER {
    NSUInteger    bfType;
    NSUInteger   bfSize;
    NSUInteger    bfReserved1;
    NSUInteger    bfReserved2;
    NSUInteger   bfOffBits;
} BITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER{
    NSUInteger      biSize;
    NSUInteger       biWidth;
    NSUInteger       biHeight;
    NSUInteger       biPlanes;
    NSUInteger       biBitCount;
    NSUInteger      biCompression;
    NSUInteger      biSizeImage;
    NSUInteger       biXPelsPerMeter;
    NSUInteger       biYPelsPerMeter;
    NSUInteger      biClrUsed;
    NSUInteger      biClrImportant;
} BITMAPINFOHEADER;
#endif
//保存BMP文件的函数
void SaveAsBMP (AVFrame *pFrameRGB, int width, int height, int index, int bpp)
{   char buf[5] = {0};   //bmp头
    BITMAPFILEHEADER bmpheader;
    BITMAPINFOHEADER bmpinfo;
    FILE *fp;
    char filename[255];  //文件存放路径，根据自己的修改
    sprintf(filename,"%s_%d.bmp","C:/test",index);
    if ( (fp=fopen(filename,"wb+")) == NULL )   {
        printf ("open file failed!\n");
        return;
    }
    bmpheader.bfType = 0x4d42;
    bmpheader.bfReserved1 = 0;
    bmpheader.bfReserved2 = 0;
    bmpheader.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);
    bmpheader.bfSize = bmpheader.bfOffBits + width*height*bpp/8;
    bmpinfo.biSize = sizeof(BITMAPINFOHEADER);
    bmpinfo.biWidth = width;
    bmpinfo.biHeight = height;
    bmpinfo.biPlanes = 1;
    bmpinfo.biBitCount = bpp;
    bmpinfo.biCompression = 255;
    bmpinfo.biSizeImage = (width*bpp+31)/32*4*height;
    bmpinfo.biXPelsPerMeter = 100;
    bmpinfo.biYPelsPerMeter = 100;
    bmpinfo.biClrUsed = 0;
    bmpinfo.biClrImportant = 0;
    fwrite (&bmpheader, sizeof(bmpheader), 1, fp);
    fwrite (&bmpinfo, sizeof(bmpinfo), 1, fp);
    fwrite (pFrameRGB->data[0], width*height*bpp/8, 1, fp);
    fclose(fp);
}

- (int)test
{
    AVFormatContext *pFormatCtx;
    unsigned int i = 0, videoStream = -1;
    AVCodecContext  *pCodecCtx;
    AVCodec         *pCodec;
    AVFrame *pFrameRGB;
    struct SwsContext *pSwsCtx;
    
    int frameFinished;
    int PictureSize;
    AVPacket packet;
    uint8_t *buf;
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    
    //Register Device
    avdevice_register_all();
    
    //Show Dshow Device
    show_dshow_device();
    //Show Device Options
    show_dshow_device_option();
    AVInputFormat *ifmt=av_find_input_format("avfoundation");
    //Set own video device's name
    AVDictionary* options = NULL;
    av_dict_set(&options, "video_size", "1280x720", 0);
    av_dict_set(&options, "framerate", "30", 0);
    av_dict_set(&options, "pixel_format", "nv12", 0);
    /*
     { "video_size", "set frame size", OFFSET(width), AV_OPT_TYPE_IMAGE_SIZE, {.str = NULL}, 0, 0, DEC },
     { "pixel_format", "set pixel format", OFFSET(pixel_format), AV_OPT_TYPE_STRING, {.str = "yuv420p"}, 0, 0, DEC },
     { "framerate", "set frame rate", OFFSET(framerate), AV_OPT_TYPE_VIDEO_RATE, {.str = "25"}, 0, 0, DEC },
     { NULL },
     */
    if (avformat_open_input(&pFormatCtx,"0",ifmt,&options)!=0) {
    
//    if(avformat_open_input(&pFormatCtx,"0",ifmt,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return -1;
    }
    
    if(avformat_find_stream_info(pFormatCtx,NULL)<0)
    {
        printf("Couldn't find stream information.\n");
        return -1;
    }
    
    //获取视频数据
    for(int i=0;i<pFormatCtx->nb_streams;i++)
        
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoStream = i ;
        }
    
    if(videoStream == -1){
        printf("%s\n","find video stream failed");
        exit(1);
    }
    pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    
    if(pCodec ==NULL){
        printf("%d\n","avcode find decoder failed!");
        exit(1);
    }
    //打开解码器
    if(avcodec_open2(pCodecCtx,pCodec,NULL)<0){
        printf("avcode open failed!\n");
        exit(1);
    }
    
    //为每帧图像分配内存
    pFrame = av_frame_alloc();
    pFrameRGB = av_frame_alloc();
    
    if(pFrame==NULL||pFrameRGB==NULL){
        printf("av frame alloc failed!\n");
        exit(1);
    }
    //获得帧图大小
    PictureSize = avpicture_get_size(AV_PIX_FMT_BGR24,pCodecCtx->width,pCodecCtx->height);
    buf = (uint8_t*)av_malloc(PictureSize);
    if(buf ==NULL){
        printf("av malloc failed!\n");
        exit(1);
    }
    
    avpicture_fill((AVPicture *)pFrameRGB,buf,AV_PIX_FMT_BGR24,pCodecCtx->width,pCodecCtx->height);
    //设置图像转换上下文
    pSwsCtx = sws_getContext(pCodecCtx->width,pCodecCtx->height,pCodecCtx->pix_fmt,pCodecCtx->width,pCodecCtx->height,AV_PIX_FMT_BGR24,SWS_BICUBIC,NULL,NULL,NULL);
    i = 0;
    
    while(av_read_frame(pFormatCtx,&packet)>=0){
        if(packet.stream_index==videoStream){
            //真正的解码
            avcodec_decode_video2(pCodecCtx,pFrame,&frameFinished,&packet);
            if(frameFinished){
                //饭庄图像，否则是上下颠倒的
                pFrame->data[0]+=pFrame->linesize[0]*(pCodecCtx->height-1);
                pFrame->linesize[0]*=-1;
                pFrame->data[1]+=pFrame->linesize[1]*(pCodecCtx->height/2-1);
                pFrame->linesize[1]*=-1;
                pFrame->data[2]+=pFrame->linesize[2]*(pCodecCtx->header_bits/2-1);
                pFrame->linesize[2]*=-1;
                
                //转换图像格式，将解压出来的YUV420P的图像转换为BRG24的图像
//                sws_scale(pSwsCtx,pFrame->data,pFrame->linesize,0,pCodecCtx->height,pFrameRGB->data,pFrameRGB->linesize);
                //保存为bmp图
//                SaveAsBMP(pFrameRGB,pCodecCtx->width,pCodecCtx->height,i,24);
                
                self.imgView.image = [self imageFromAVPicture];
                i++;
            }
            av_free_packet(&packet);
        }
    }
    sws_freeContext(pSwsCtx);
    av_free(pFrame);
    av_free(pFrameRGB);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    return 0;
}


@end
