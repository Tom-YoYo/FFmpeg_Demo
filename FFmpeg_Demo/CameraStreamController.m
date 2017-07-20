//
//  CameraStreamController.m
//  FFmpeg_Demo
//
//  Created by 尚往文化 on 17/7/20.
//  Copyright © 2017年 YBing. All rights reserved.
//

#import "CameraStreamController.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale//swscale.h>
#include <libavutil/mathematics.h>
#include <libavutil/time.h>
#import <libavdevice/avdevice.h>

@interface CameraStreamController ()

@end

@implementation CameraStreamController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self clickStreamButton:nil];
}

- (void)clickStreamButton:(id)sender {
    
//    char output_str_full[500] = {0};
//    sprintf(output_str_full,"%s","rtmp://192.168.10.133:1990/liveApp/room");
    
    AVOutputFormat *ofmt = NULL;
    //Input AVFormatContext and Output AVFormatContext
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    char out_filename[500]="rtmp://192.168.10.133:1990/liveApp/room";
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
    av_dict_set(&options, "pixel_format", "bgr0", 0);
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
    
    for(i=0; i<ifmt_ctx->nb_streams; i++)
        if(ifmt_ctx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
//    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    //Output
    
    avformat_alloc_output_context2(&ofmt_ctx, NULL, "flv", out_filename); //RTMP
    //avformat_alloc_output_context2(&ofmt_ctx, NULL, "mpegts", out_filename);//UDP
    
    if (!ofmt_ctx) {
        printf( "Could not create output context\n");
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    ofmt = ofmt_ctx->oformat;
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        //        AVStream *stream = ifmt_ctx->streams[i];
        //        AVCodec *codec1 = avcodec_find_decoder(stream->codecpar->codec_id);
        //        AVCodecContext *codec_ctx = avcodec_alloc_context3(codec1);//需要使用avcodec_free_context释放
        //
        //        //事实上codecpar包含了大部分解码器相关的信息，这里是直接从AVCodecParameters复制到AVCodecContext
        //        avcodec_parameters_to_context(codec_ctx, stream->codecpar);
        //        av_codec_set_pkt_timebase(codec_ctx, stream->time_base);
        
        /*----------华丽的分割线----------*/
        
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, NULL);
        if (!out_stream) {
            printf( "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        
        
        
        AVCodec *codec = avcodec_find_encoder(ofmt_ctx->oformat->video_codec);//音频为audio_codec
        AVCodecContext *codec_ctx1 = avcodec_alloc_context3(codec);
        codec_ctx1->codec_type = AVMEDIA_TYPE_VIDEO;
        //        codec_ctx->video_type = AVMEDIA_TYPE_VIDEO;
        codec_ctx1->codec_id = ofmt->video_codec;
        
        codec_ctx1->width = 192;//你想要的宽度
        codec_ctx1->height = 144;//你想要的高度
        codec_ctx1->pix_fmt = AV_PIX_FMT_YUV420P;//受codec->pix_fmts数组限制
        codec_ctx1->gop_size = 12;
        AVRational AVRational;
        AVRational.den = 25;
        AVRational.num = 1;
        codec_ctx1->time_base = AVRational;//应该根据帧率设置
        codec_ctx1->bit_rate = 1400 * 1000;
        
        avcodec_open2(codec_ctx1, codec, NULL);
        //将AVCodecContext的成员复制到AVCodecParameters结构体。前后两行不能调换顺序
        ret = avcodec_parameters_from_context(out_stream->codecpar, codec_ctx1);
        
        
        
        //        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret < 0) {
            printf( "Failed to copy context from input to output stream codec context\n");
            goto end;
        }
        out_stream->codec->codec_tag = 0;
        if (ofmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
    //Dump Format------------------
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    //Open output URL
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf( "Could not open output URL '%s'", out_filename);
            goto end;
        }
    }
    
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf( "Error occurred when opening output URL\n");
        goto end;
    }
    
    start_time=av_gettime();
    while (1) {
        AVStream *in_stream, *out_stream;
        //Get an AVPacket
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0)
            break;
        //FIX：No PTS (Example: Raw H.264)
        //Simple Write PTS
        if(pkt.pts==AV_NOPTS_VALUE){
            //Write PTS
            AVRational time_base1=ifmt_ctx->streams[videoindex]->time_base;
            //Duration between 2 frames (us)
            int64_t calc_duration=(double)AV_TIME_BASE/av_q2d(ifmt_ctx->streams[videoindex]->r_frame_rate);
            //Parameters
            pkt.pts=(double)(frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
            pkt.dts=pkt.pts;
            pkt.duration=(double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        }
        //Important:Delay
        if(pkt.stream_index==videoindex){
            AVRational time_base=ifmt_ctx->streams[videoindex]->time_base;
            AVRational time_base_q={1,AV_TIME_BASE};
            int64_t pts_time = av_rescale_q(pkt.dts, time_base, time_base_q);
            int64_t now_time = av_gettime() - start_time;
//            if (pts_time > now_time)
//                av_usleep(pts_time - now_time);
            
        }
        in_stream  = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        /* copy packet */
        //Convert PTS/DTS
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        //Print to Screen
        if(pkt.stream_index==videoindex){
            printf("Send %8d video frames to output URL\n",frame_index);
            frame_index++;
        }
        //ret = av_write_frame(ofmt_ctx, &pkt);
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        
        if (ret < 0) {
            printf( "Error muxing packet\n");
            break;
        }
        
        av_free_packet(&pkt);
        
    }
    //写文件尾（Write file trailer）
    av_write_trailer(ofmt_ctx);
end:
    avformat_close_input(&ifmt_ctx);
    /* close output */
    if (ofmt_ctx && !(ofmt->flags & AVFMT_NOFILE))
        avio_close(ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
    
}


@end
