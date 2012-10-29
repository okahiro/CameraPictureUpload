//
//  ViewController.h
//  CameraPictureUpload
//
//  Created by 岡内和博 on 12/10/29.
//  Copyright (c) 2012年 Okahiro. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate>
{
	UIPopoverController *popOver;
	CGPoint touchPoint;
}

- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)libraryButtonTapped:(id)sender;
- (IBAction)uploadButtonTapped:(id)sender;
@property (retain, nonatomic) IBOutlet UIImageView *pictureImage;

@end
