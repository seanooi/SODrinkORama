//
//  ViewController.m
//  EspressoBar
//
//  Created by Sean Ooi on 1/6/14.
//  Copyright (c) 2014 Sean Ooi. All rights reserved.
//

#import "ViewController.h"
#import <SDCAlertView.h>
#import <SDCAlertViewController.h>
#import <SDCAlertViewContentView.h>
#import <SDCAlertViewBackgroundView.h>
#import <SDCAutoLayout/UIView+SDCAutoLayout.h>

@interface ViewController ()
{
    IBOutlet ZCSlotMachine *espressoSlotMachine;
    IBOutlet UIButton *startButton;
    IBOutlet UIView *shadowView;
    IBOutlet UILabel *slotMachineTitle;
    NSArray *slotIcons;
}

- (IBAction)start:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *bgPattern = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tileable_wood_texture"]];
    self.view.backgroundColor = bgPattern;
    
    NSArray *slotArray1 = [NSArray arrayWithObjects:[UIImage imageNamed:@"coffee"], [UIImage imageNamed:@"teapot"], [UIImage imageNamed:@"espresso"], nil];
    NSArray *slotArray2 = [NSArray arrayWithObjects:[UIImage imageNamed:@"filter"], [UIImage imageNamed:@"strainer"], [UIImage imageNamed:@"tamper"], nil];
    NSArray *slotArray3 = [NSArray arrayWithObjects:[UIImage imageNamed:@"grounds"], [UIImage imageNamed:@"leaves"], [UIImage imageNamed:@"beans"], nil];
    
    slotIcons = [NSArray arrayWithObjects:slotArray1, slotArray2, slotArray3, nil];
    
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowRadius = 2.0;
    shadowView.backgroundColor = [UIColor clearColor];
    shadowView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    shadowView.layer.shadowOpacity = 0.8f;
    
    espressoSlotMachine.delegate = self;
    espressoSlotMachine.dataSource = self;
    espressoSlotMachine.layer.cornerRadius = 10;
    espressoSlotMachine.layer.masksToBounds = YES;
    espressoSlotMachine.contentInset = UIEdgeInsetsZero;
    espressoSlotMachine.backgroundImage = [UIImage imageNamed:@"bg"];
    espressoSlotMachine.coverImage = [UIImage imageNamed:@"cover"];
    
    UIImage *resizableButton = [[UIImage imageNamed:@"resizableButton.png" ] resizableImageWithCapInsets:UIEdgeInsetsMake(17, 5, 17, 5)];
    [startButton setBackgroundImage:resizableButton forState:UIControlStateNormal];
    [startButton setTitle:@"SPIN" forState:UIControlStateNormal];
    [startButton.titleLabel setFont:[UIFont fontWithName:@"Chalkduster" size:18.0f]];
    
    [slotMachineTitle setText:@"Drink-O-Rama"];
    [slotMachineTitle setTextAlignment:NSTextAlignmentCenter];
    [slotMachineTitle setFont:[UIFont fontWithName:@"Chalkduster" size:30.0f]];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [startButton.titleLabel setFont:[UIFont fontWithName:@"Chalkduster" size:28.0f]];
        [slotMachineTitle setFont:[UIFont fontWithName:@"Chalkduster" size:60.0f]];
    }
}

- (IBAction)start:(id)sender
{
    __block NSMutableArray *randomSlotIndex = [NSMutableArray array];
    
    // Randomly generate an integer for each column
    [slotIcons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [randomSlotIndex addObject:[NSNumber numberWithInt:arc4random_uniform((int)[obj count])]];
    }];
    
    espressoSlotMachine.slotResults = randomSlotIndex;
    [espressoSlotMachine startSliding];
}

#pragma mark - ZCSlotMachineDelegate

- (void)slotMachineWillStartSliding:(ZCSlotMachine *)slotMachine
{
    startButton.enabled = NO;
}

- (void)slotMachineDidEndSliding:(ZCSlotMachine *)slotMachine
{
    NSArray *slotResults = slotMachine.slotResults;
    NSString *alertTitle = nil;
    NSString *loseMessage = nil;
    UIImage *cupImage = nil;
    __block NSInteger slotNumber = 0;
    __block BOOL didWin = NO;
    
    // Enumerate through to check if items matched
    [slotResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // First element is to be compared to subsequent elements, so we assign it to a variable
        if (idx == 0) {
            slotNumber = [obj integerValue];
        }
        else {
            if (slotNumber != [obj integerValue]) {
                // If there is even 1 unmatched number, stop enumeration
                *stop = YES;
            }
            else if ([slotResults count] == idx+1) {
                didWin = YES;
            }
        }
    }];
    
    if (didWin) {
        switch (slotNumber) {
            case 0:
                NSLog(@"Coffee");
                alertTitle = @"You won a cup of joe!";
                cupImage = [UIImage imageNamed:@"coffee_cup"];
                break;
            case 1:
                NSLog(@"Tea");
                alertTitle = @"You won a cup of tea!";
                cupImage = [UIImage imageNamed:@"tea_cup"];
                break;
            case 2:
                NSLog(@"Espresso");
                alertTitle = @"You won a cup of espresso!";
                cupImage = [UIImage imageNamed:@"espresso_cup"];
                break;
            default:
                NSLog(@"This shouldn't happen");
                alertTitle = @"Oops!";
                break;
        }
    }
    else {
        NSLog(@"Try again");
        alertTitle = @"Oh no!";
        loseMessage = @"You did not win anything this time, but not to worry, just spin again!";
    }
    
    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:alertTitle
                                                      message:loseMessage
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    if(cupImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:cupImage];
        imageView.center = CGPointMake(270/2, imageView.center.y);
        
        [alert.contentView addSubview:imageView];
        [alert.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:NSDictionaryOfVariableBindings(imageView)]];
    }
    
    [alert show];
    
    startButton.enabled = YES;
}

#pragma mark - ZCSlotMachineDataSource

- (NSArray *)iconsForSlotsInSlotMachine:(ZCSlotMachine *)slotMachine
{
    return slotIcons;
}

- (NSUInteger)numberOfSlotsInSlotMachine:(ZCSlotMachine *)slotMachine
{
    return [slotIcons count];
}

- (CGFloat)slotWidthInSlotMachine:(ZCSlotMachine *)slotMachine
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240.0f;
    }
    return 90.0f;
}

- (CGFloat)slotSpacingInSlotMachine:(ZCSlotMachine *)slotMachine
{
    return 5.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
        
        //set all object on view controller to nil
        [self.view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            obj = nil;
        }];
    }
}

@end
