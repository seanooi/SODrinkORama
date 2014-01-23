#import <QuartzCore/QuartzCore.h>
#import "ZCSlotMachine.h"

static BOOL isSliding = NO;
static const NSUInteger kMinTurn = 3;
static const CGFloat iconMargin = 1.1f;

/********************************************************************************************/

@implementation ZCSlotMachine {
@private
    // UI
    UIImageView *_backgroundImageView;
    UIImageView *_coverImageView;
    UIView *_contentView;
    UIEdgeInsets _contentInset;
    NSMutableArray *_slotScrollLayerArray;
    NSArray *borderColorArray;
    
    // Data
    NSArray *_slotResults;
    NSArray *_currentSlotResults;
    
    __weak id <ZCSlotMachineDataSource> _dataSource;
}

#pragma mark - View LifeCycle

- (void)baseInit:(CGRect)frame
{
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:frame];
    _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_backgroundImageView];
    
    _contentView = [[UIView alloc] initWithFrame:frame];
    
    [self addSubview:_contentView];
    
    _coverImageView = [[UIImageView alloc] initWithFrame:frame];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_coverImageView];
    
    _slotScrollLayerArray = [NSMutableArray array];
    self.singleUnitDuration = 0.14f;
    _contentInset = UIEdgeInsetsZero;
    
    borderColorArray = [NSArray arrayWithObjects:
                        [UIColor colorWithRed:231/255.0f green:76/255.0f blue:60/255.0f alpha:1.0f],
                        [UIColor colorWithRed:46/255.0f green:204/255.0f blue:113/255.0f alpha:1.0f],
                        [UIColor colorWithRed:52/255.0f green:152/255.0f blue:219/255.0f alpha:1.0f],nil];
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit:self.frame];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit:self.bounds];
    }
    return self;
}

#pragma mark - Properties Methods

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImageView.image = backgroundImage;
}

- (void)setCoverImage:(UIImage *)coverImage {
    _coverImageView.image = coverImage;
}

- (UIEdgeInsets)contentInset {
    return _contentInset;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    
    CGRect viewFrame = self.frame;
    
    _contentView.frame = CGRectMake(_contentInset.left, _contentInset.top, viewFrame.size.width - _contentInset.left - _contentInset.right, viewFrame.size.height - _contentInset.top - _contentInset.bottom);
}

- (NSArray *)slotResults {
    return _slotResults;
}

- (void)setSlotResults:(NSArray *)slotResults {
    if (!isSliding) {
        _slotResults = slotResults;
        
        if (!_currentSlotResults) {
            NSMutableArray *currentSlotResults = [NSMutableArray array];
            
            for (int i = 0; i < [slotResults count]; i++) {
                [currentSlotResults addObject:[NSNumber numberWithUnsignedInteger:0]];
            }
            _currentSlotResults = [NSArray arrayWithArray:currentSlotResults];
        }
    }
}

- (id<ZCSlotMachineDataSource>)dataSource {
    return _dataSource;
}

- (void)setDataSource:(id<ZCSlotMachineDataSource>)dataSource {
    _dataSource = dataSource;
    
    [self reloadData];
}

- (void)reloadData {
    if (self.dataSource) {
        [ _contentView.layer.sublayers enumerateObjectsUsingBlock:^(CALayer *containerLayer, NSUInteger idx, BOOL *stop) {
            [containerLayer removeFromSuperlayer];
        }];
        
        if (!_slotScrollLayerArray) {
            _slotScrollLayerArray = [NSMutableArray array];
        }
        
        NSUInteger numberOfSlots = [self.dataSource numberOfSlotsInSlotMachine:self];
        CGFloat slotSpacing = 0;
        
        if ([self.dataSource respondsToSelector:@selector(slotSpacingInSlotMachine:)]) {
            slotSpacing = [self.dataSource slotSpacingInSlotMachine:self];
        }
        
        CGFloat slotWidth = _contentView.frame.size.width / numberOfSlots;
        if ([self.dataSource respondsToSelector:@selector(slotWidthInSlotMachine:)]) {
            slotWidth = [self.dataSource slotWidthInSlotMachine:self];
        }
        
        for (int i = 0; i < numberOfSlots; i++) {
            CALayer *slotContainerLayer = [[CALayer alloc] init];
            slotContainerLayer.frame = CGRectMake(i * (slotWidth + slotSpacing), 0, slotWidth, _contentView.frame.size.height);
            slotContainerLayer.masksToBounds = YES;
            
            CALayer *slotScrollLayer = [[CALayer alloc] init];
            slotScrollLayer.frame = CGRectMake(0, 0, slotWidth, _contentView.frame.size.height);
            
            [slotContainerLayer addSublayer:slotScrollLayer];
            [_contentView.layer addSublayer:slotContainerLayer];
            [_slotScrollLayerArray addObject:slotScrollLayer];
        }
        
        CGFloat singleUnitHeight = _contentView.frame.size.height / 3;
        
        NSArray *slotIcons = [self.dataSource iconsForSlotsInSlotMachine:self];
        NSUInteger iconCount = [slotIcons count];
        
        for (int i = 0; i < numberOfSlots; i++) {
            CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
            NSInteger scrollLayerTopIndex = - (i + kMinTurn + 3) * [slotIcons[i] count];
            
            for (int j = 0; j > scrollLayerTopIndex; j--) {
                UIImage *iconImage = [slotIcons[i] objectAtIndex:abs(j) % iconCount];
                CALayer *iconImageLayer = [[CALayer alloc] init];
                // adjust the beginning offset of the first unit
                NSInteger offsetYUnit = j + 1 + iconCount;
                iconImageLayer.frame = CGRectMake(singleUnitHeight/(numberOfSlots+1), offsetYUnit * singleUnitHeight * iconMargin, singleUnitHeight, singleUnitHeight);
                iconImageLayer.contents = (id)iconImage.CGImage;
                iconImageLayer.contentsScale = iconImage.scale;
                iconImageLayer.contentsGravity = kCAGravityResizeAspect;
                iconImageLayer.cornerRadius = iconImageLayer.frame.size.height/2;
                iconImageLayer.masksToBounds = YES;
                iconImageLayer.borderWidth = 3;
                iconImageLayer.borderColor = ((UIColor *)borderColorArray[abs(j) % iconCount]).CGColor;
                iconImageLayer.rasterizationScale = [UIScreen mainScreen].scale;
                iconImageLayer.shouldRasterize = YES;
                
                if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    iconImageLayer.borderWidth = 6;
                }
                
                [slotScrollLayer addSublayer:iconImageLayer];
            }
        }
    }
}

#pragma mark - Public Methods

- (void)startSliding {
    
    if (isSliding) {
        return;
    }
    else {
        isSliding = YES;
        
        if ([self.delegate respondsToSelector:@selector(slotMachineWillStartSliding:)]) {
            [self.delegate slotMachineWillStartSliding:self];
        }
        
        NSArray *slotIcons = [self.dataSource iconsForSlotsInSlotMachine:self];
        NSUInteger slotIconsCount = [slotIcons count];
        
        __block NSMutableArray *completePositionArray = [NSMutableArray array];
        
        [CATransaction begin];
        
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [CATransaction setDisableActions:YES];
        [CATransaction setCompletionBlock:^{
            isSliding = NO;
            
            if ([self.delegate respondsToSelector:@selector(slotMachineDidEndSliding:)]) {
                [self.delegate slotMachineDidEndSliding:self];
            }
            
            for (int i = 0; i < [_slotScrollLayerArray count]; i++) {
                CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
                
                slotScrollLayer.position = CGPointMake(slotScrollLayer.position.x, ((NSNumber *)[completePositionArray objectAtIndex:i]).floatValue);
                
                NSMutableArray *toBeDeletedLayerArray = [NSMutableArray array];
                
                NSUInteger resultIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
                NSUInteger currentIndex = [[_currentSlotResults objectAtIndex:i] unsignedIntegerValue];
                
                for (int j = 0; j < slotIconsCount * (kMinTurn + i) + resultIndex - currentIndex; j++) {
                    CALayer *iconLayer = [slotScrollLayer.sublayers objectAtIndex:j];
                    [toBeDeletedLayerArray addObject:iconLayer];
                }
                
                for (CALayer *toBeDeletedLayer in toBeDeletedLayerArray) {
                    CALayer *toBeAddedLayer = [CALayer layer];
                    toBeAddedLayer.frame = toBeDeletedLayer.frame;
                    toBeAddedLayer.contents = toBeDeletedLayer.contents;
                    toBeAddedLayer.contentsScale = toBeDeletedLayer.contentsScale;
                    toBeAddedLayer.contentsGravity = toBeDeletedLayer.contentsGravity;
                    toBeAddedLayer.cornerRadius = toBeDeletedLayer.cornerRadius;
                    toBeAddedLayer.masksToBounds = toBeDeletedLayer.masksToBounds;
                    toBeAddedLayer.borderWidth = toBeDeletedLayer.borderWidth;
                    toBeAddedLayer.borderColor = toBeDeletedLayer.borderColor;
                    toBeAddedLayer.rasterizationScale = toBeDeletedLayer.rasterizationScale;
                    toBeAddedLayer.shouldRasterize = toBeDeletedLayer.shouldRasterize;
                    
                    CGFloat shiftY = slotIconsCount * toBeAddedLayer.frame.size.height * (kMinTurn + i + 3) * iconMargin;
                    toBeAddedLayer.position = CGPointMake(toBeAddedLayer.position.x, toBeAddedLayer.position.y - shiftY);
                    
                    [toBeDeletedLayer removeFromSuperlayer];
                    [slotScrollLayer addSublayer:toBeAddedLayer];
                }
                [toBeDeletedLayerArray removeAllObjects];
            }
            
            _currentSlotResults = self.slotResults;
            completePositionArray = [NSMutableArray array];
        }];
        
        static NSString * const keyPath = @"position.y";
        
        for (int i = 0; i < [_slotScrollLayerArray count]; i++) {
            CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
            
            NSUInteger resultIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
            NSUInteger currentIndex = [[_currentSlotResults objectAtIndex:i] unsignedIntegerValue];
            
            NSUInteger howManyUnit = (i + kMinTurn) * slotIconsCount + resultIndex - currentIndex;
            CGFloat slideY = howManyUnit * (_contentView.frame.size.height / 3) * iconMargin;
            
            CABasicAnimation *slideAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
            slideAnimation.fillMode = kCAFillModeForwards;
            slideAnimation.duration = howManyUnit * self.singleUnitDuration;
            slideAnimation.toValue = [NSNumber numberWithFloat:slotScrollLayer.position.y + slideY];
            slideAnimation.removedOnCompletion = NO;
            
            [slotScrollLayer addAnimation:slideAnimation forKey:@"slideAnimation"];
            
            [completePositionArray addObject:slideAnimation.toValue];
        }
        
        [CATransaction commit];
    }
}

@end