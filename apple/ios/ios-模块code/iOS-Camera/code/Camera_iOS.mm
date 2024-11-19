#import "Log.h"
#import "Native_iOS.h"
#import "App.h"

#import <QDebug>
#import <QFile>
#import <QImage>
#import <QStandardPaths>
#import <QQmlEngine>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

Q_LOGGING_CATEGORY(LOG_SFE_IOS_DEVICE_RESOURCE, "sfe-ios-device-resource", QtWarningMsg);

@interface CameraCaptureController : UIImagePickerController
@end

@implementation CameraCaptureController
- (void)dealloc {
    qCDebug(LOG_SFE_IOS_MEM, "CameraCaptureController dealloc");
    [super dealloc];
}
@end


#pragma mark - CameraViewController
@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation CameraViewController

- (void)openCamera {
    // 检查相机是否可用
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        CameraCaptureController *imagePickerController = [[CameraCaptureController new] autorelease];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
        imagePickerController.allowsEditing = NO;
        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
        imagePickerController.videoMaximumDuration = 60.0;
        imagePickerController.showsCameraControls = true;

        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootViewController presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        qCDebug(LOG_SFE_IOS_DEVICE_RESOURCE, "Camera Unavailable");
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSString *mediaType = info[UIImagePickerControllerMediaType];

    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        QImage* tmpImg = new QImage();
        tmpImg->loadFromData((const unsigned char *)[data bytes], [data length], "*.jpg");
        QMatrix matrix;
        switch (image.imageOrientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                matrix.rotate(180);
                break;
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
                matrix.rotate(270);
            break;
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                matrix.rotate(90);
                break;
            default:
                break;
        }

        NSDate *now = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] autorelease];
        [dateFormatter setDateFormat:@"yyyyMMdd_HH_mm_ss_SSS"];
        NSString *dateString = [dateFormatter stringFromDate:now];
        NSString *fileNSString = [NSString stringWithFormat:@"%@.jpg", dateString];
        QString fileName = QString::fromNSString(fileNSString);
        QString imagePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + fileName;

        QImage rotateImg = tmpImg->transformed(matrix, Qt::FastTransformation);
        rotateImg.save(imagePath);

        QString imageUrl = "file://" + imagePath;
        QString localImagePath = QUrl(imageUrl).toLocalFile();
        QFile ff(localImagePath);
        QVariantMap imageInfo =  Native::instance()->getFileInfo(imagePath);
        emit IosMedia::instance()->imagePicked(imageUrl, imageInfo);
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];

        if (videoURL) {
            [self video2MP4:videoURL completion:^(NSURL *outputURL, NSError *error) {
                if (outputURL) {
                    QString videoPath = QString::fromNSString([outputURL absoluteString]);
                    QVariantMap fileInfo = Native::instance()->getFileInfo(videoPath);
                    AVURLAsset *movAsset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
                    int duration = CMTimeGetSeconds([movAsset duration]);
                    emit IosMedia::instance()->videoPicked(videoPath, fileInfo, duration);
                } else {
                    qCDebug(LOG_SFE_IOS_DEVICE_RESOURCE, "Failed to convert MP4");
                }
            }];
        }
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
    picker.delegate = nil;
    [self release];
}

- (void)video2MP4:(NSURL *)inputURL completion:(void (^)(NSURL *outputURL, NSError *error))completion {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputFileType = AVFileTypeMPEG4;

    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"mp4"]];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputURL = outputURL;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(outputURL, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, exportSession.error);
                });
            }
        }];
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    emit IosMedia::instance()->cancelClicked();
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self release];
}

- (void)dealloc {
    qCDebug(LOG_SFE_IOS_MEM, "objective-c CameraViewController dealloc");
    [super dealloc];
}

@end

void IosMedia::openCamera()
{
    CameraViewController *viewController = [[CameraViewController new] autorelease];
    [viewController retain];
    [viewController openCamera];
}
