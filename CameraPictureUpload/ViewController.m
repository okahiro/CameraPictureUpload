//
//  ViewController.m
//  CameraPictureUpload
//
//  Created by 岡内和博 on 12/10/29.
//  Copyright (c) 2012年 Okahiro. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

// アップロードURL
#define UPLOAD_URL @"http://test.example.com/upload"
// アップロードファイルのパラメーター名
#define UPLOAD_PARAM @"uploadFile"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ButtonAction

// カメラ起動
- (IBAction)cameraButtonTapped:(id)sender {
	// カメラが利用できるか確認
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
		// カメラかライブラリからの読込指定。カメラを指定。
		[imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
		// トリミングなどを行うか否か
		[imagePickerController setAllowsEditing:YES];
		// Delegate
		[imagePickerController setDelegate:self];
		
		// アニメーションをしてカメラUIを起動
		[self presentViewController:imagePickerController animated:YES completion:nil];
	}
	else
	{
		NSLog(@"Camera invalid.");
	}
}

// フォトライブラリー起動
- (IBAction)libraryButtonTapped:(id)sender {
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
		[imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[imagePickerController setAllowsEditing:YES];
		[imagePickerController setDelegate:self];
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			// iPadの場合はUIPopoverControllerを使う
			popOver = [[UIPopoverController alloc]initWithContentViewController:imagePickerController];
			[popOver presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
		else
		{
			[self presentViewController:imagePickerController animated:YES completion:nil];
		}
	}
	else
	{
		NSLog(@"Photo library invalid.");
	}
}

// 画像アップロード
- (IBAction)uploadButtonTapped:(id)sender {
	// 画像をNSDataに変換
	//NSData *imageData = [[[NSData alloc]initWithData:UIImagePNGRepresentation(self.pictureImage.image)] autorelease];
	NSData *imageData = [[[NSData alloc]initWithData:UIImageJPEGRepresentation(self.pictureImage.image, 0.5)]autorelease];
	
	// 送信データの境界
	NSString *boundary = @"1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	// アップロードする際のファイル名
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc]init]autorelease];
	[dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
	NSString *uploadFileName = [dateFormatter stringFromDate:[NSDate date]];
	// 送信するデータ（前半）
	NSMutableString *sendDataStringPrev = [NSMutableString stringWithString:@"--"];
	[sendDataStringPrev appendString:boundary];
	[sendDataStringPrev appendString:@"\r\n"];
	[sendDataStringPrev appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.jpg\"\r\n",UPLOAD_PARAM,uploadFileName]];
	[sendDataStringPrev appendString:@"Content-Type: image/jpeg\r\n\r\n"];
	// 送信するデータ（後半）
	NSMutableString *sendDataStringNext = [NSMutableString stringWithString:@"\r\n"];
	[sendDataStringNext appendString:@"--"];
	[sendDataStringNext appendString:boundary];
	[sendDataStringNext appendString:@"--"];
	
	// 送信データの生成
	NSMutableData *sendData = [NSMutableData data];
	[sendData appendData:[sendDataStringPrev dataUsingEncoding:NSUTF8StringEncoding]];
	[sendData appendData:imageData];
	[sendData appendData:[sendDataStringNext dataUsingEncoding:NSUTF8StringEncoding]];
	
	// リクエストヘッダー
	NSDictionary *requestHeader = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSString stringWithFormat:@"%d",[sendData length]],@"Content-Length",
								   [NSString stringWithFormat:@"multipart/form-data;boundary=%@",boundary],@"Content-Type",nil];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:UPLOAD_URL]];
	[request setAllHTTPHeaderFields:requestHeader];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:sendData];
	
	[NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark delegate
// 写真を撮影もしくはフォトライブラリーで写真を選択
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// オリジナル画像
	UIImage *originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
	// 編集画像
	UIImage *editedImage = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
	UIImage *saveImage;
	
	if(editedImage)
	{
		saveImage = editedImage;
	}
	else
	{
		saveImage = originalImage;
	}
	
	// UIImageViewに画像を設定
	self.pictureImage.image = saveImage;
	
	if(picker.sourceType == UIImagePickerControllerSourceTypeCamera)
	{
		// カメラから呼ばれた場合は画像をフォトライブラリに保存してViewControllerを閉じる
		UIImageWriteToSavedPhotosAlbum(saveImage, nil, nil, nil);
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else
	{
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			// フォトライブラリから呼ばれた場合はPopOverを閉じる（iPad）
			[popOver dismissPopoverAnimated:YES];
			[popOver release];
			popOver = nil;
		}
		else
		{
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	}
}

// popoverが閉じられるとき
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[popOver release];
	popOver = nil;
}

// 受け取ったレスポンス
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	NSLog(@"%d",httpResponse.statusCode);
	
	if(httpResponse.statusCode == 200)
	{
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"アップロード完了" message:@"アップロード完了しました"
													  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"エラー" message:@"レスポンスエラー"
													  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
}
// 受け取ったデータ
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	
}
// エラーが発生した場合
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"エラー" message:@"ネットワークエラー"
												  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

#pragma mark draw picture
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// タッチ開始座標をインスタンス変数touchPointに保持
	UITouch *touch = [touches anyObject];
	touchPoint = [touch locationInView:self.pictureImage];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// 現在のタッチ座標をローカル変数currentPointに保持
	UITouch *touch = [touches anyObject];
	CGPoint currentPoint = [touch locationInView:self.pictureImage];
	
	// 描画領域をUIImageViewの大きさで生成
	UIGraphicsBeginImageContext(self.pictureImage.frame.size);
	// pictureImageにセットされている画像を描画
	[self.pictureImage.image drawInRect:CGRectMake(0,0,self.pictureImage.frame.size.width, self.pictureImage.frame.size.height)];
	// 線の角を丸くする
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	// 線の太さを指定
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 4.0);
	// 線の色を指定
	CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
	// 線の描画開始座標をセット
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), touchPoint.x, touchPoint.y);
	// 線の描画終了座標をセット
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
	// 線を引く
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	// UIImageViewにセット
	self.pictureImage.image = UIGraphicsGetImageFromCurrentImageContext();
	// 描画領域のクリア
	UIGraphicsEndImageContext();
	
	// 現在のタッチ座標を次の開始座標にセット
	touchPoint = currentPoint;
}

#pragma mark

- (void)dealloc {
	[_pictureImage release];
	[super dealloc];
}
- (void)viewDidUnload {
	[self setPictureImage:nil];
	[super viewDidUnload];
}
@end
