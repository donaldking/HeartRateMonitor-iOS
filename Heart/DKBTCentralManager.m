//
//  DKBTCentralManager.m
//  AutoLayout
//
//  Created by Donald King on 11/07/2015.
//  Copyright (c) 2015 Tusk Solutions UK. All rights reserved.
//

#import "DKBTCentralManager.h"

/* Heart Rate Monitor Service */
#define HEART_RATE_SERVICE_UUID @"180D"

/* HRM Characteristics */
#define HEART_RATE_MEASUREMENT_CHARACHTERISTIC_UUID @"2A37"
#define BODY_SENSOR_LOCATION_CHARACHTERISTIC_UUID @"2A38"

@interface DKBTCentralManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, readwrite) CBCentralManager *centralManager;
@property (nonatomic, readwrite) CBPeripheral *currentPeripheral;
@property (nonatomic, readwrite, getter=isCentralManagerReady) BOOL centralManagerReady;
@property (nonatomic, readwrite) CentralConnectionStatus status;
@property (nonatomic, readwrite) NSMutableArray *peripherals;
@property (nonatomic, readwrite) NSUInteger currentHeartRate;

@end

@implementation DKBTCentralManager


//------------------------------------------------------------------------------
// MARK: - Public methods
//------------------------------------------------------------------------------

+ (instancetype)sharedManager
{
    static dispatch_once_t once;
    static DKBTCentralManager *instance = nil;
    
    dispatch_once(&once, ^{
        
        instance = [DKBTCentralManager new];
        instance.centralManager = [[CBCentralManager alloc] initWithDelegate:instance queue:nil];
        instance.peripherals = [NSMutableArray new];
    
    });
    
    return instance;
}

- (void)startScanningForPeripherals
{
    if (!self.isCentralManagerReady)
        
        return;
    
    self.status = Scanning;
    [self registerAndScannForServices];
}

- (void)stopScanningForPeripherals
{
    if (self.currentPeripheral)
    {
        [self.centralManager cancelPeripheralConnection:self.currentPeripheral];
    }
    self.status = Disconnected;
}

//------------------------------------------------------------------------------
// MARK: - Internal
//------------------------------------------------------------------------------

- (void)registerAndScannForServices
{
    NSArray *servicesArray = @[[CBUUID UUIDWithString:HEART_RATE_SERVICE_UUID]];
    [self.centralManager scanForPeripheralsWithServices:servicesArray options:nil];
}

- (BOOL)isCentralManagerReady
{
    return _centralManagerReady;
}


//------------------------------------------------------------------------------
// MARK: - Bluetooth Central Delegate
//------------------------------------------------------------------------------

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"BLE hardware is powered off");
            self.centralManagerReady = NO;
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"BLE hardware is powered on");
            self.centralManagerReady = YES;
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"BLE hardware is resetting");
            self.centralManagerReady = NO;
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"BLE hardware is unauthorized");
            self.centralManagerReady = NO;
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"BLE hardware is unsupported");
            self.centralManagerReady = NO;
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"BLE hardware is state is unknown");
            self.centralManagerReady = NO;
            break;
            
        default:
            self.centralManagerReady = NO;
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if (![self.peripherals containsObject:peripheral])
    {
        [self.peripherals addObject:peripheral];
    }
    
    self.currentPeripheral = peripheral;
    self.status = Connecting;
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    self.status = Connected;
    [self.centralManager stopScan];
    
    for (CBService *service in peripheral.services)
    {
        /* Heart rate service */
        if ([service.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_SERVICE_UUID]])
        {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_SERVICE_UUID]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Heart rate measurement */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_MEASUREMENT_CHARACHTERISTIC_UUID]])
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
            }
            
            /* Body sensor location */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BODY_SENSOR_LOCATION_CHARACHTERISTIC_UUID]])
            {
                [peripheral readValueForCharacteristic:aChar];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
        return;
    
    NSData *value = [characteristic value];
    
    /* Heart rate measurement */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_MEASUREMENT_CHARACHTERISTIC_UUID]])
    {
        [self updateHRMWithValue:value];
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BODY_SENSOR_LOCATION_CHARACHTERISTIC_UUID]])
    {
        /* Get body sensor reading */
        NSLog(@"Bytes: %@\nValue in NSData: %@",[value bytes],value);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.status = Disconnected;
    peripheral.delegate = nil;
}

//------------------------------------------------------------------------------
// MARK: - Private implementation
//------------------------------------------------------------------------------

- (void)updateHRMWithValue:(NSData *)value
{
    const uint8_t *reportData = [value bytes];
    uint16_t bmp = 0;
    
    if ((reportData[0] & 0x01) == 0)
    {
        bmp = reportData[1];
    }
    else
    {
        bmp = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    self.currentHeartRate = bmp;
}

@end
