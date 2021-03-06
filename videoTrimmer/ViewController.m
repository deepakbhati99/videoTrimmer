//
//  ViewController.m
//  videoTrimmer
//
//  Created by Himanshu Khatri on 1/26/16.
//  Copyright © 2016 bdAppManiac. All rights reserved.
//

#import "ViewController.h"
#import "NMRangeSlider.h" // a slider with two thumbs
@import MobileCoreServices;
@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>{

    
    IBOutlet UIView *movieView;
    
    NSURL *originalURL;
    NSInteger totalTime;
    
    CMTime startTime;
    CMTime endTime;
    
    AVPlayerViewController *videoPlayerVC;
    
    IBOutlet NMRangeSlider *cutter;
    
    NSMutableDictionary *dictionaryIP;
    
    CGFloat aspectRatio;        /*/    aspectRatio = width:height    /*/
    
    IBOutlet UICollectionView *collectionViewThumbnails;

}

@end
static const NSString *lowerIndexPath=@"lowerIndexPath";
static const NSString *upperIndexPath=@"upperIndexPath";
#pragma mark- C Functions
/* c function for geting Length of Video */
NSNumber* videoDuration(NSURL *video){
    
    //from AVURLAsset calculating total time
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video options:nil];
    NSInteger duration = (int) round(CMTimeGetSeconds(asset.duration));
    
    return [NSNumber  numberWithInteger:duration];
    
}
/* c function for geting thumbnail at particular second */
UIImage* videoThumbnail(NSURL *videoUrl, NSInteger fromsec)
{
    // creating the asset from url
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    
    //calculating time for which frame is needed
    CMTime time = [asset duration];         //totalTime of video.
    time.value = fromsec*time.timescale;    //frame at time Fromsec
    
    //AVAssetImageGenerator is created to extract the image from the video
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    

    NSError *error = nil;
    CMTime actualTime;
    
    //copy image CGImageRef from the AVAssetImageGenerator at required time
    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    //cretaing UIImage
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    //return
    return thumbnail;
}

/* c function for cretaing url from name */
NSURL * dataFilePath(NSString *path){
    //creating a path for file and checking if it already exist if exist then delete it
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), path];
    
    BOOL success;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //check if file exist at outputPath
    success = [fileManager fileExistsAtPath:outputPath];
    
    if (success) {
        //delete if file exist at outputPath
        success=[fileManager removeItemAtPath:outputPath error:nil];
    }
    
    return [NSURL fileURLWithPath:outputPath];
    
}
#pragma mark-

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //creting video path
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"3Dvideo"
                                                         ofType:@"mov"];
    
    originalURL = [NSURL fileURLWithPath:filePath];
    
    //AVPlayerViewController
    videoPlayerVC=[[AVPlayerViewController alloc]init];

    //update video Properties
    [self updateParameters];

}
-(void)updateParameters{
    
    //video Duration
    totalTime=[videoDuration(originalURL) integerValue];
    
    //creting videoAsset
    AVAsset *myasset = [AVAsset assetWithURL:originalURL];
    
    //update Start time with first Frame
    startTime = CMTimeMake(0, myasset.duration.timescale);
    
    //update End time with Last Frame
    endTime = CMTimeMake(totalTime *myasset.duration.timescale,  myasset.duration.timescale);
    
    //play Video
    CGRect bounds = movieView.bounds; // get bounds of parent view
    CGRect subviewFrame = CGRectInset(bounds, 0, 0); // left and right margin of 0
    videoPlayerVC.view.frame = subviewFrame;
    
    //adding autoresizing for player
    videoPlayerVC.view.autoresizingMask = (
                                           UIViewAutoresizingFlexibleWidth
                                           | UIViewAutoresizingFlexibleHeight
                                           );
    //add to view
    [movieView addSubview:videoPlayerVC.view];
    
    //play
    videoPlayerVC.player=[AVPlayer playerWithURL:originalURL];
    [videoPlayerVC.player play];
    
    //configure NMRangeSlider
    [self configureSlider];
    
    UIImage *img=videoThumbnail(originalURL, 1);
    aspectRatio=img.size.width/img.size.height;
    
    [collectionViewThumbnails reloadData];
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark- IBActions
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

#pragma mark -
#pragma mark UIImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    // 1 - Get media type
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    // 2 - Dismiss image picker
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)
    {
        originalURL=[info objectForKey:UIImagePickerControllerMediaURL];
        
        // 3 - Play the video
        [self updateParameters];

    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark-
#pragma mark- videoTrim

- (IBAction)trimVideo:(id)sender {
    
    //create asset of the video
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:originalURL options:nil];
    //create exportSession and exportVideo Quality
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset640x480];
    
    NSURL *outputVideoURL=dataFilePath(@"tmpPost.mp4"); //url of exportedVideo
    
    exportSession.outputURL = outputVideoURL;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    /**
     creating the time range i.e. make startTime and endTime.
     startTime should be the first frame time at which your exportedVideo should start.
     endTime is the time of last frame at which your exportedVideo should stop. OR it should be the duration of the excpected exportedVideo length
    **/
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
                     //write exportedVideo to path/trimmedVideo.mp4
                     [urlData writeToURL:finalUrl options:NSAtomicWrite error:&writeError];
                     
                     if (!writeError) {
                         
                         //update Original URL
                         originalURL=finalUrl;
                         
                         //update video Properties
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

//------------------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark - NMRangeSlider

- (void) configureSlider
{
    //setting minimum and maximum values
    cutter.minimumValue = 1;
    cutter.maximumValue = totalTime;
    
    
    cutter.lowerValue = 1;
    cutter.upperValue = totalTime;
    
    
    //minimum length of video is the minimum range
    cutter.minimumRange = 5;
    
    
    dictionaryIP=[NSMutableDictionary new];
    
    dictionaryIP=[@{
                    lowerIndexPath:[NSIndexPath indexPathForItem:cutter.lowerValue-1 inSection:0],
                    upperIndexPath:[NSIndexPath indexPathForItem:cutter.upperValue-1 inSection:0],
                    }mutableCopy];
    
}


// Handle control value changed events just like a normal slider
- (IBAction)sliderValueChanged:(NMRangeSlider*)sender{
    
    // updating our startTime and EndTime of the trimmed Video.
    
    startTime = CMTimeMake((NSInteger)cutter.lowerValue * startTime.timescale, startTime.timescale);
    
    endTime = CMTimeMake(((NSInteger)cutter.upperValue-(NSInteger)cutter.lowerValue) * startTime.timescale, endTime.timescale);
    
    // Prepare for animation
    [collectionViewThumbnails.collectionViewLayout invalidateLayout];
    
    //newIndexPaths
    NSIndexPath *newIndexPathLower=[NSIndexPath indexPathForItem:cutter.lowerValue-1 inSection:0];
    NSIndexPath *newIndexPathUpper=[NSIndexPath indexPathForItem:cutter.upperValue-1 inSection:0];
    
    //newCellsSelected
    UICollectionViewCell * cellLowerValue = [collectionViewThumbnails cellForItemAtIndexPath:newIndexPathLower];
    UICollectionViewCell * cellUpperValue = [collectionViewThumbnails cellForItemAtIndexPath:newIndexPathUpper];
    
    //lastSelectedCell
    UICollectionViewCell * oldCellLower = [collectionViewThumbnails cellForItemAtIndexPath:dictionaryIP[lowerIndexPath]];
    UICollectionViewCell * oldCellUpper = [collectionViewThumbnails cellForItemAtIndexPath:dictionaryIP[upperIndexPath]];
    


    BOOL isLowerUnchanged=[dictionaryIP[lowerIndexPath] isEqual:newIndexPathLower];
    BOOL isUpperUnchanged=[dictionaryIP[upperIndexPath] isEqual:newIndexPathUpper];
    
    if (isLowerUnchanged && !isUpperUnchanged) {

        //if upperHandle moves animate upper cell in center
        
        [collectionViewThumbnails scrollToItemAtIndexPath:newIndexPathUpper atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
    }else if(isUpperUnchanged && !isLowerUnchanged){
        
        //if lowerHandle moves animate lower cell in center
        
        [collectionViewThumbnails scrollToItemAtIndexPath:newIndexPathLower atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
    }
    
    
    //update our dictionary with newIndexPaths
    dictionaryIP=[@{
                    lowerIndexPath:newIndexPathLower,
                    upperIndexPath:newIndexPathUpper,
                    }mutableCopy];
    
    
    
    [collectionViewThumbnails performBatchUpdates:^{
        
        //adding Animations to first and Last Frames
        [self removeAnimation:oldCellLower];
        [self removeAnimation:oldCellUpper];
        
        //removing animations From previous cells
        [self addAnimation:cellLowerValue];
        [self addAnimation:cellUpperValue];
        
    }completion:^(BOOL finish){
    }];
}

// ------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark- UICollectionView
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    

    //size For individual Cells
    CGSize size;
    if (indexPath.item==((NSInteger)cutter.lowerValue-1) ||indexPath.item==((NSInteger)cutter.upperValue-1)) {

        //cell of selected first frame and last frame
        size.height=52;

    }else{
        
        //other cells
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
    
    // simply extracting the imageView
    UIImageView *thumb=(UIImageView *)[cell.contentView viewWithTag:99];
    thumb.image = videoThumbnail(originalURL, indexPath.row+1);
    
    if (indexPath.item==((NSInteger)cutter.lowerValue-1) ||indexPath.item==((NSInteger)cutter.upperValue-1)) {
        
        //adding Animations to first and Last Frames
        [self addAnimation:cell];

    }else{
        
        //removing animations From previous cells
        [self removeAnimation:cell];
    }
    
    return cell;
}

#pragma mark -
#pragma mark- UICustomAnimation
- (void)addAnimation:(id)sender {

    //creates a frame of animation for the particular property.
    CAKeyframeAnimation* widthAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderWidth"];
    //values of animation of particular property is added.
    NSArray* widthValues = [NSArray arrayWithObjects:@1.0,@0.7, @0.3, @0.5, @1.5, @1.2, @0.2,@0.5,@1.0,@0.5,@1.5,@1.2,@1.0,@0.7,@0.3,@0.2,@1.5, nil];
    widthAnim.values = widthValues;
    widthAnim.calculationMode = kCAAnimationPaced;
    
    // Animation 2
    
    
    //creates a frame of animation for the particular property.
    CAKeyframeAnimation* colorAnim = [CAKeyframeAnimation animationWithKeyPath:@"borderColor"];
    //values of animation of particular property is added.
    NSArray* colorValues = [NSArray arrayWithObjects:
                            (id)[UIColor blackColor].CGColor,
                            (id)[UIColor greenColor].CGColor,
                            (id)[UIColor clearColor].CGColor,
                            (id)[UIColor brownColor].CGColor,
                            (id)[UIColor blueColor].CGColor,
                            (id)[UIColor darkGrayColor].CGColor,
                            (id)[UIColor redColor].CGColor,
                            (id)[UIColor lightGrayColor].CGColor,
                            (id)[UIColor cyanColor].CGColor,
                            (id)[UIColor grayColor].CGColor,
                            (id)[UIColor yellowColor].CGColor,
                            (id)[UIColor whiteColor].CGColor,
                            (id)[UIColor purpleColor].CGColor,
                            (id)[UIColor orangeColor].CGColor,
                            (id)[UIColor magentaColor].CGColor,nil];
    
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

