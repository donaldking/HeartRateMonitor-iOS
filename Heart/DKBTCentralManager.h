//
//  DKBTCentralManager.h
//  AutoLayout
//
//  Created by Donald King on 11/07/2015.
//  Copyright (c) 2015 Tusk Solutions UK. All rights reserved.
//

typedef NS_ENUM(NSUInteger, CentralConnectionStatus)
{
    Idle = 0,
    Scanning,
    Disconnected,
    Connecting,
    Connected,
};

@interface DKBTCentralManager : NSObject

//------------------------------------------------------------------------------
// MARK: - Properties
//------------------------------------------------------------------------------

@property (nonatomic, readonly) CBPeripheral *currentPeripheral;
@property (nonatomic, readonly) CentralConnectionStatus status;
@property (nonatomic, readonly) NSUInteger currentHeartRate;

//------------------------------------------------------------------------------
// MARK: - Methods
//------------------------------------------------------------------------------

+ (instancetype)sharedManager;
- (void)startScanningForPeripherals;
- (void)stopScanningForPeripherals;

@end
