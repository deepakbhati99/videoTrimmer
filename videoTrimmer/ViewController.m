//
//  ViewController.m
//  videoTrimmer
//
//  Created by Himanshu Khatri on 1/26/16.
//  Copyright © 2016 bdAppManiac. All rights reserved.
//

#import "ViewController.h"
#import "NMRangeSlider.h"

@import MobileCoreServices;
@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>{
    

    
    
    IBOutlet UIImageView *startImage;
    IBOutlet UIImageView *endImage;
    
    IBOutlet UIView *movieView;
    
    NSURL *originalURL;
    NSInteger totalTime;
    
    CMTime startTime;
    CMTime endTime;
    
    AVPlayerViewController *videoPlayerVC;
    
    IBOutlet NMRangeSlider *cutter;
    
    NSMutableDictionary *dictionaryIP;
    
    CGFloat aspectRatio;/* width/height */
    
    IBOutlet UICollectionView *collectionViewThumbnails;

}

@end
static const NSString *lowerIndexPath=@"lowerIndexPath";
static const NSString *upperIndexPath=@"upperIndexPath";
NSNumber* videoDuration(NSURL *video){
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video options:nil];
    NSInteger duration = (int) round(CMTimeGetSeconds(asset.duration));
    
    
    return [NSNumber  numberWithInteger:duration];
    
}
UIImage* videoThumbnail(NSURL *videoUrl, NSInteger fromsec)
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = fromsec*time.timescale;
    //     CMTimeMake(<#int64_t value#>, int32_t timescale)
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumbnail;
}
void showAlertWithTitle(NSString *strMessage, UIViewController *sender){
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:strMessage message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Ok action");
                                   }];
    [alertController addAction:cancelAction];
    [sender presentViewController:alertController animated:YES completion:nil];
}
NSURL * dataFilePath(NSString *path){
    //creating a path for file and checking if it already exist if exist then delete it
    
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), path];
    
    BOOL success;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    success = [fileManager fileExistsAtPath:outputPath];
    
    if (success) {
        success=[fileManager removeItemAtPath:outputPath error:nil];
    }
    
    return [NSURL fileURLWithPath:outputPath];
    
}
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"3Dvideo"
                                                         ofType:@"mov"];
    
    originalURL = [NSURL fileURLWithPath:filePath];
    videoPlayerVC=[[AVPlayerViewController alloc]init];

    [self updateParameters];

}
-(void)updateParameters{
    totalTime=[videoDuration(originalURL) integerValue];
    AVAsset *myasset = [AVAsset assetWithURL:originalURL];
    
    startTime = CMTimeMake(0, myasset.duration.timescale);
    endTime = CMTimeMake(totalTime *myasset.duration.timescale,  myasset.duration.timescale);
    
    [self playTheVideo:originalURL];
    [self configureLabelSlider];
    
    UIImage *img=videoThumbnail(originalURL, 1);
    aspectRatio=img.size.width/img.size.height;
    
    [collectionViewThumbnails reloadData];
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark- ChooseVideo
- (IBAction)selectNewVideo:(id)sender {
    
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"select your prefered method" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Camera", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                                   
                                   UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                                   if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                                   {
                                       imagePicker.delegate = (id)self;
                                       imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                       imagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
                                       
                                       imagePicker.allowsEditing=NO;
                                       [self.navigationController presentViewController:imagePicker animated:YES completion:^{
                                           self.navigationController.navigationBarHidden=NO;
                                       }];
                                       
                                   }else{
                                   }
                               }];
    UIAlertAction *LibraryAction = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Library", @"OK action")
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action)
                                    {
                                        NSLog(@"OK action");
                                        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                                        imagePicker.delegate = (id)self;
                                        imagePicker.allowsEditing = NO;
                                        
                                        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                        imagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
                                        
                                        [self.navigationController presentViewController:imagePicker animated:YES completion:^{
                                            self.navigationController.navigationBarHidden=NO;
                                        }];
                                        
                                    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [alertController addAction:LibraryAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (IBAction)trim:(id)sender {
    [self trimVideo:originalURL];
}
#pragma mark -
#pragma mark UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    
    // 1 - Get media type
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    // 2 - Dismiss image picker
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)
    {
        // 3 - Play the video
        
        originalURL=[info objectForKey:UIImagePickerControllerMediaURL];
        
        [self updateParameters];
        // 4 - Register for the playback finished notification
        
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}



#pragma mark- Video Initialize
#pragma mark

-(void) playTheVideo:(NSURL *)videoURL{
    
    
    CGRect bounds = movieView.bounds; // get bounds of parent view
    CGRect subviewFrame = CGRectInset(bounds, 0, 0); // left and right margin of 0
    videoPlayerVC.view.frame = subviewFrame;
    videoPlayerVC.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    [movieView addSubview:videoPlayerVC.view];
    videoPlayerVC.player=[AVPlayer playerWithURL:videoURL];
    
    [videoPlayerVC.player play];
    
    
}
- (void)trimVideo:(NSURL*)videoToTrimURL{
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoToTrimURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset640x480];
    
    NSURL *outputVideoURL=dataFilePath(@"tmpPost.mp4");
    
    exportSession.outputURL = outputVideoURL;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    CMTimeRange range = CMTimeRangeMake(startTime, endTime);
    
    exportSession.timeRange = range;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status)
         {
             case AVAssetExportSessionStatusCompleted:
                 
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     NSURL *finalUrl=dataFilePath(@"trimmedVideo.mp4");
                     NSData *urlData = [NSData dataWithContentsOfURL:outputVideoURL];
                     NSError *writeError;
                     [urlData writeToURL:finalUrl options:NSAtomicWrite error:&writeError];
                     
                     if (!writeError) {
                         originalURL=finalUrl;
                         [self updateParameters];
                     }
                     NSLog(@"Trim Done %ld %@", (long)exportSession.status, exportSession.error);
                 });
                 
                 
             }
                 break;
                 
                 
             case AVAssetExportSessionStatusFailed:
                 
                 NSLog(@"Trim failed with error ===>>> %@",exportSession.error);
                 break;
                 
             case AVAssetExportSessionStatusCancelled:
                 
                 NSLog(@"Canceled:%@",exportSession.error);
                 break;
                 
             default:
                 break;
                 
                 
         }
     }];
    
    
}

// ------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - Label  Slider

- (void) configureLabelSlider
{
    cutter.minimumValue = 1;
    cutter.maximumValue = totalTime;
    
    cutter.lowerValue = 0;
    cutter.upperValue = totalTime;
    
    cutter.minimumRange = 5;
    
    startImage.hidden=YES;
    endImage.hidden=YES;
    
    dictionaryIP=[NSMutableDictionary new];
    
    [self updateLastSelectedIndexPath];
    
    
}

- (void) updateSliderThumbnails
{
    // You get get the center point of the slider handles and use this to arrange other subviews
    
    CGPoint lowerCenter;
    lowerCenter.x = (cutter.lowerCenter.x + cutter.frame.origin.x);
    lowerCenter.y = (cutter.center.y - 60.0f);
    startImage.center = lowerCenter;
    startImage.image = videoThumbnail(originalURL,(NSInteger)cutter.lowerValue);

    

    
    CGPoint upperCenter;
    upperCenter.x = (cutter.upperCenter.x + cutter.frame.origin.x);
    upperCenter.y = (cutter.center.y - 60.0f);
    endImage.center = upperCenter;
    
    
    endImage.image = videoThumbnail(originalURL,(NSInteger)cutter.upperValue);
    
    
    
    
    startTime = CMTimeMake((NSInteger)cutter.lowerValue * startTime.timescale, startTime.timescale);
    
    endTime = CMTimeMake(((NSInteger)cutter.upperValue)  * startTime.timescale, endTime.timescale);

    
    // Prepare for animation
    [collectionViewThumbnails.collectionViewLayout invalidateLayout];
    
    NSIndexPath *newIndexPathLower=[NSIndexPath indexPathForItem:cutter.lowerValue-1 inSection:0];
    NSIndexPath *newIndexPathUpper=[NSIndexPath indexPathForItem:cutter.upperValue-1 inSection:0];

    UICollectionViewCell * cellLowerValue = [collectionViewThumbnails cellForItemAtIndexPath:newIndexPathLower];
    UICollectionViewCell * cellUpperValue = [collectionViewThumbnails cellForItemAtIndexPath:newIndexPathUpper];
    
    UICollectionViewCell * oldCellLower = [collectionViewThumbnails cellForItemAtIndexPath:dictionaryIP[lowerIndexPath]];
    UICollectionViewCell * oldCellUpper = [collectionViewThumbnails cellForItemAtIndexPath:dictionaryIP[upperIndexPath]];

    [collectionViewThumbnails scrollToItemAtIndexPath:newIndexPathLower atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];

    
    
//    [self updateLastSelectedIndexPath];
    dictionaryIP=[@{
                    lowerIndexPath:newIndexPathLower,
                    upperIndexPath:newIndexPathUpper,
                    }mutableCopy];

    
    [collectionViewThumbnails performBatchUpdates:^{
        oldCellLower.backgroundColor=[UIColor clearColor];
        oldCellUpper.backgroundColor=[UIColor clearColor];
        
        
        cellLowerValue.backgroundColor=movieView.backgroundColor;
        cellUpperValue.backgroundColor=movieView.backgroundColor;

        [self removeAnimation:oldCellLower];
        [self removeAnimation:oldCellUpper];
        
        [self addAnimation:cellLowerValue];
        [self addAnimation:cellUpperValue];

        
    }completion:^(BOOL finish){
    }];
    
}
-(void)updateLastSelectedIndexPath{
    dictionaryIP=[@{
                    lowerIndexPath:[NSIndexPath indexPathForItem:cutter.lowerValue-1 inSection:0],
                    upperIndexPath:[NSIndexPath indexPathForItem:cutter.upperValue-1 inSection:0],
                    }mutableCopy];
}
// Handle control value changed events just like a normal slider
- (IBAction)labelSliderChanged:(NMRangeSlider*)sender{
    

    [self updateSliderThumbnails];
}

// ------------------------------------------------------------------------------------------------------


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    

    CGSize size;
    if (indexPath.item==((NSInteger)cutter.lowerValue-1) ||indexPath.item==((NSInteger)cutter.upperValue-1)) {

        size.height=52;

    }else{
        size.height=35;
    }
    size.width=aspectRatio*size.height;
    
    return size;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return totalTime;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    UIImageView *thumb=(UIImageView *)[cell.contentView viewWithTag:99];
    thumb.image = videoThumbnail(originalURL, indexPath.row+1);
    
    if (indexPath.item==((NSInteger)cutter.lowerValue-1) ||indexPath.item==((NSInteger)cutter.upperValue-1)) {
        cell.backgroundColor=movieView.backgroundColor;
        
        [self addAnimation:cell];
    }else{
        cell.backgroundColor=[UIColor clearColor];
        [self removeAnimation:cell];
    }
    
    return cell;
}

- (void)addAnimation:(id)sender {
    
    
    
    //creates a frame of animation for the particular property.
    CAKeyframeAnimation* widthAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderWidth"];
    //values of animation of particular property is added.
    NSArray* widthValues = [NSArray arrayWithObjects:@1.0,@0.7, @0.3, @0.5, @1.5, @1.2, @0.2,@0.5, nil];
    widthAnim.values = widthValues;
    widthAnim.calculationMode = kCAAnimationPaced;
    
    // Animation 2
    
    
    //creates a frame of animation for the particular property.
    CAKeyframeAnimation* colorAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    //values of animation of particular property is added.
    NSArray* colorValues = [NSArray arrayWithObjects:(id)[UIColor greenColor].CGColor,
                            (id)[UIColor redColor].CGColor, (id)[UIColor blueColor].CGColor,(id)[UIColor lightGrayColor].CGColor, (id)[UIColor darkGrayColor].CGColor, (id)[UIColor whiteColor].CGColor,(id)[UIColor cyanColor].CGColor,(id)[UIColor magentaColor].CGColor, nil];
    colorAnim.values = colorValues;
    colorAnim.calculationMode = kCAAnimationPaced;
    
    
    // Animation group
    //merging the individual animations and adding them
    CAAnimationGroup* group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithObjects:colorAnim, widthAnim, nil];//array of  the animations created.
    group.duration = 1.0;
    group.autoreverses = YES;
    group.repeatCount = (YES) ? HUGE_VALF : 0;
    
    
    // adding the animation to the layer
    [[sender layer] addAnimation:group forKey:@"constantHighlighterEffect"];
    
}
-(void)removeAnimation:(id)sender{
    // adding the animation to the layer
    [[sender layer] removeAllAnimations];

}

@end

