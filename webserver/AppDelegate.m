//
//  AppDelegate.m
//  webserver
//
//  Created by 　yangrui on 2017/8/1.
//  Copyright © 2017年 　yangrui. All rights reserved.
//

#import "AppDelegate.h"


//1. 导入头文件

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

//
#import "GCDWebUploader.h"

//
#import "GCDWebDAVServer.h"
@interface AppDelegate (){

    //1.
    GCDWebServer *_webServer;
    
    //2.
    GCDWebUploader *_webUploader;
    
    //3.
    GCDWebDAVServer *_webDAVServer;
}

@end

@implementation AppDelegate


///Users/yangrui/Library/Developer/CoreSimulator/Devices/1647D851-D3B8-42D6-BF04-FF49F5A584B5/data/Containers/Data/Application/D67168A3-B972-48C4-922B-3DC978A1B03F/Documents
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 
    //iOS http 服务器  --网络请求工具
    [self initSetupWebServer];
    
    //iOS http 服务器  --文件上传工具
//    [self initSetupWebUploader];
    
    
    //
//    [self initSetupWebDAVServer];
    
    return YES;
}


  /**
   GCDDAVWebServer 是GCDWebServer 的子类提供了一个兼容的webDAV 服务器. 使用任何的webDAV 服务器像Transmit(Mac),ForkLife(Mac)或者CyberDuck(Mac/windows) 一样可以在ISO 沙盒目录中让用户上传,下载,删除或者创建目录文件.
   
   */
// WebDAV  distributed Authoring and versioning
-(void)initSetupWebDAVServer{
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    
    _webDAVServer  = [[GCDWebDAVServer alloc]initWithUploadDirectory:docPath];
    
    [_webDAVServer start];
    
    NSLog(@"visit %@ in your webDAV client ",_webDAVServer.serverURL);
    
      /**
       serving a static website 服务于静态网站
       
       GCDWebServer 有一个固定的handler 用来递归的服务于一个目录(一个容许你控制并设置 http header 的 "cache-control",
       
       cache-control 用于控制http 缓存)
       
       */


}



// iOS APP 中基于web 的上传 可以通过这个工具将网页上的文件传到 iOS 或 mac osx  上
-(void)initSetupWebUploader{
    
    //1. 文件存储路径
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    //2. 创建文件上传
    _webUploader = [[GCDWebUploader alloc]initWithUploadDirectory:docPath];
    [_webUploader start];
    
    NSLog(@" 访问 : %@ 在 你的 浏览器", _webUploader.serverURL);

}

-(void)initSetupWebServer{
    
    //1. 创建服务器
    _webServer = [[GCDWebServer alloc]init];
    
    //2. add a handle to response to get request on any URL
    [_webServer addDefaultHandlerForMethod:@"GET" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(__kindof GCDWebServerRequest *request) {
        UIImage *img = [UIImage imageNamed:@"abc"];
        
        return   [GCDWebServerDataResponse responseWithData:UIImagePNGRepresentation(img) contentType:@"application/x-png" ];
 
        
        
//        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World  dsgasdfg </p></body></html>"];
        
        
        
    } ];
    
    
    //3. 开启服务 欧尼port 8080
    [_webServer startWithPort:8080 bonjourName:nil];
    
    NSLog(@"visit  %@  in your web browser", _webServer.serverURL);
    

}

@end

  /**
   
使用GCDWebServer
   
   你可以通过创建一个实例 GCDWebServer 类开始.注意: 你可以在同一个应用程序上运行多个web服务器,只要这些web服务器是挂在不同的端口的.
   
   然后你可以添加一个或者多个 "处理"给服务器:每一个处理都有机会处理传入的web请求并且提供相应.处理程序我们叫做LIFO队列,所以最新加入的"处理器"会覆盖之前所添加的"处理程序".
   
   
   
理解 GCDWebServer 的架构
   
   GCDWebserver 体系结构包括只有4个核心类:
   
   > GCDWebServer 负责管理监听新的http连接 和 服务器使用的一系列的处理程序列表的 接口 socket
   
   > GCDWebServerConnection  是由GCDWebServer来实例化处理每一个新的http连接.每一个GCDWebServerconnection 一直保持活跃状态一直到连接被关闭.
     你不能直接使用这个类,但是他是暴露的,所以你可以继承至他来写一些 hooks.
   
   > GCDWebServerRequest 由 GCDWebServerConnection 在接收到http 表头后实例化 创建. 他用来包装请求和处理http 主体(如果有主体的话).GCDWebServer 包含了几个 GCDWebServerRequest的子类来处理常见情况下的情况. 如果存储body 到内存或者传输到磁盘的一个文件中.
   
   > GCDWebServerResponse 由请求处理器创建 和 包装 该响应 http header 和一些可选择的body. GCDWebServer 也是通过由几个GCDWebServerResponser 的子类来处理常见的情况的如内存找那个的 html 文本或者从磁盘来传输一个文件时.
   
   
   
GCDWebServer 实现
   
   GCDWebServer的实现依赖于 "处理程序" 来处理传入的web 请求并作出响应.  "处理程序" 通过GCD 块来实现的使得GCDWebServer 方便你的使用. 然而, 由于在GCD 中 "处理程序"是在任意线程中执行,所以要注意的时线程安全和同一程序重复执行的问题.
   
   处理程序用到2个GCD块:
   GCDWebServerMatchBlock 会被添加到 GCDWebServer 中的每一个 "处理程序" 所调用 只要一个web 请求已经开始后(如: http 表头已经收到).他可以传递web 请求的基本信息( http method , URL , headers ) 而且必须要决定是否会处理这个请求.如果返回yes ,那么必须要返回一个新的zhe
   
   */
