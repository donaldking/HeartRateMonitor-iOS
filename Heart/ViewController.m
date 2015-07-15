//
//  ViewController.m
//  Heart
//
//  Created by Donald King on 14/07/2015.
//  Copyright (c) 2015 Tusk Solutions UK. All rights reserved.
//

#import "ViewController.h"
#import "DKBTCentralManager.h"

static NSString *kCurrentHeartRateKeyPath = @"currentHeartRate";
static NSString *kCentralManagerStatusKeyPath = @"status";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectDisconnectButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[DKBTCentralManager sharedManager] addObserver:self
                                         forKeyPath:kCentralManagerStatusKeyPath
                                            options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew)
                                            context:nil];
    
    [[DKBTCentralManager sharedManager] addObserver:self
                                         forKeyPath:kCurrentHeartRateKeyPath
                                            options:NSKeyValueObservingOptionNew
                                            context:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[DKBTCentralManager sharedManager] removeObserver:self forKeyPath:kCentralManagerStatusKeyPath];
    [[DKBTCentralManager sharedManager] removeObserver:self forKeyPath:kCurrentHeartRateKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kCentralManagerStatusKeyPath])
    {
        NSString *peripheralName = [DKBTCentralManager sharedManager].currentPeripheral.name;
        switch ([DKBTCentralManager sharedManager].status)
        {
            case Idle:
                self.statusLabel.text = @"Idle";
                [self.connectDisconnectButton setTitle:@"Scan for Peripherals" forState:UIControlStateNormal];
                break;
            case Scanning:
                self.statusLabel.text = @"Scanning...";
                [self.connectDisconnectButton setTitle:@"Stop Scanning for Peripherals" forState:UIControlStateNormal];
                break;
            case Disconnected:
                self.statusLabel.text = @"Idle";
                [self.connectDisconnectButton setTitle:@"Scan for Peripherals" forState:UIControlStateNormal];
                break;
            case Connecting:
                self.statusLabel.text = [NSString stringWithFormat:@"Conneting to [%@]",peripheralName];
                break;
            case Connected:
                self.statusLabel.text = [NSString stringWithFormat:@"Connected to [%@]",peripheralName];
                [self.connectDisconnectButton setTitle:@"Disconnect from Peripheral" forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
    if([keyPath isEqualToString:kCurrentHeartRateKeyPath])
    {
        self.heartRateLabel.text = [NSString stringWithFormat:@"%@ bpm",[[change valueForKey:@"new"] stringValue]];
    }
}

//------------------------------------------------------------------------------
// MARK: - IBAction
//------------------------------------------------------------------------------

- (IBAction)connectDisconnectAction:(UIButton *)sender
{
    if ([DKBTCentralManager sharedManager].status == Idle || [DKBTCentralManager sharedManager].status == Disconnected)
    {
        [[DKBTCentralManager sharedManager] startScanningForPeripherals];
    }
    else if ([DKBTCentralManager sharedManager].status == Scanning || [DKBTCentralManager sharedManager].status == Connected)
    {
        [[DKBTCentralManager sharedManager] stopScanningForPeripherals];
        self.heartRateLabel.text = @"0 bpm";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
