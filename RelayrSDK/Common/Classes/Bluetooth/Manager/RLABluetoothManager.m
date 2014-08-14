#import "RLABluetoothManager.h"                 // Header
//#import "RLACBUUID.h"                           // Relayr.framework (utility)
//#import "RLAPeripheralnfo.h"                    // Relayr.framework (domain object)
//#import "RLAMappingInfo.h"                      // Relayr.framework (domain object)
//#import "RLAListenerInfo.h"                     // Relayr.framework (domain object)
//#import "RLAColorSensor.h"                      // Relayr.framework (sensor)
//#import "RLAProximitySensor.h"                  // Relayr.framework (sensor)
//#import "RLAWunderbarColorSensorBluetoothAdapter.h"     // Relayr.framework (adapter)
//#import "RLAWunderbarProximitySensorBluetoothAdapter.h" // Relayr.framework (adapter)
//#import "RLABluetoothAdapterController.h"       // Relayr.framework (controller)

@implementation RLABluetoothManager
{
    NSMutableArray* _genericListeners;
    NSMutableArray* _peripheralListeners;
    NSMutableSet* _detectedPeripherals;
    NSMutableSet* _connectedPeripherals;
//    RLABluetoothAdapterController* _bleAdapterController;
}

#pragma mark - Public API

- (instancetype)init
{
    self = [super init];
    if (self) {
        _genericListeners = [NSMutableArray array];
        _peripheralListeners = [NSMutableArray array];
        _detectedPeripherals = [NSMutableSet set];
        _connectedPeripherals = [NSMutableSet set];
//        _bleAdapterController = [[RLABluetoothAdapterController alloc] init];
    }
    return self;
}

- (NSArray*)connectedPeripherals
{
    return _connectedPeripherals.allObjects;
}

- (void)addListener:(id <RLABluetoothDelegate>)listener
{
    RLAErrorAssertTrueAndReturn(listener, RLAErrorCodeMissingArgument);
    [_genericListeners addObject:listener];
}

- (void)addListener:(id <RLABluetoothDelegate>)listener forPeripheral:(CBPeripheral *)peripheral
{
    RLAErrorAssertTrueAndReturn(listener, RLAErrorCodeMissingArgument);
    RLAErrorAssertTrueAndReturn(peripheral, RLAErrorCodeMissingArgument);
    
    RLAListenerInfo *info = [self RLA_listenerInfoForPeripheral:peripheral];
    if (info) {
        [info addListener:listener];
    } else {
        info = [[RLAListenerInfo alloc] initWithPeripheral:peripheral listener:listener];
        [_peripheralListeners addObject:info];
    }
}

- (void)removeListener:(id <RLABluetoothDelegate>)listener
{
    RLAErrorAssertTrueAndReturn(listener, RLAErrorCodeMissingArgument);
    [_genericListeners removeObject:listener];
}

- (void)removeListener:(id <RLABluetoothDelegate>)listener forPeripheral:(CBPeripheral *)peripheral
{
    RLAErrorAssertTrueAndReturn(listener, RLAErrorCodeMissingArgument);
    RLAErrorAssertTrueAndReturn(peripheral, RLAErrorCodeMissingArgument);
    
    RLAListenerInfo *info = [self RLA_listenerInfoForPeripheral:peripheral];
    if (info) {
        [info removeListener:listener];
        if (![[info listeners] count]) [_peripheralListeners removeObject:info];
    }
}

#pragma mark - <CBCentralManagerDelegate>

- (void)centralManagerDidUpdateState:(CBCentralManager*)central
{
    [RLALog debug:@"centralManagerDidUpdateState: %@", @(central.state)];
    
    // Callback gerneric listeners
    SEL const sel = @selector(manager:didUpdateState:);
    for (id <RLABluetoothDelegate> listener in _genericListeners) {
        if ([listener respondsToSelector:sel]) { [listener manager:self didUpdateState:central.state]; }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
{
    [RLALog debug:@"didDiscoverPeripheral peripheral: %@ - %@",
     peripheral.name, peripheral.identifier];
    
    [_detectedPeripherals addObject:peripheral];
    peripheral.delegate = self;
    
    // Callback appropriate listener
    SEL sel = @selector(manager:didDiscoverPeripheral:);
    for (RLAListenerInfo *info in _peripheralListeners) {
        if ([info peripheral] == peripheral) {
            for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
                if ([listener respondsToSelector:sel]) {
                    [listener manager:self didDiscoverPeripheral:peripheral];
                }
            }
        }
    }
    
    // Callback gerneric listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
        if ([listener respondsToSelector:sel]) {
            [listener manager:self didDiscoverPeripheral:peripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [RLALog debug:@"didConnectPeripheral peripheral: %@ - %@",
     peripheral.name, peripheral.identifier];
    
    // Store peripheral in order to prevent premature deallocation
    [_connectedPeripherals addObject:peripheral];
    
    // Receive RSSI updates
    [peripheral readRSSI];
    
    // Callback appropriate listener
    SEL sel = @selector(manager:didConnectPeripheral:);
    for (RLAListenerInfo *info in _peripheralListeners) {
        if ([info peripheral] == peripheral) {
            for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
                if ([listener respondsToSelector:sel]) {
                    [listener manager:self didConnectPeripheral:peripheral];
                }
            }
        }
    }
    
    // Callback generic listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
        if ([listener respondsToSelector:sel]) {
            [listener manager:self didConnectPeripheral:peripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    [RLALog debug:@"didFailToConnectPeripheral: %@ error: %@", peripheral.name, error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{    
    [RLALog debug:@"didDisconnectPeripheral peripheral: %@ - %@",
     peripheral.name, peripheral.identifier];
    
    [_connectedPeripherals removeObject:peripheral];
    
    // Callback appropriate listener
    SEL sel = @selector(manager:didDisconnectPeripheral:);
    for (RLAListenerInfo *info in _peripheralListeners) {
        if ([info peripheral] == peripheral) {
            for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
                if ([listener respondsToSelector:sel]) {
                    [listener manager:self didDisconnectPeripheral:peripheral];
                }
            }
        }
    }
    
    // Callback gerneric listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
        if ([listener respondsToSelector:sel]) {
            [listener manager:self didDisconnectPeripheral:peripheral];
        }
    }
}

#pragma mark - <CBPeripheralDelegate>

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // Discover characteristics for services
    NSArray *services = peripheral.services;
    
    for (CBService *service in services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Callback appropriate listener
    SEL sel = @selector(manager:peripheral:didDiscoverCharacteristicsForService:error:);
    for (RLAListenerInfo *info in _peripheralListeners) {
        if ([info peripheral] == peripheral) {
            for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
                if ([listener respondsToSelector:sel]) {
                    [listener manager:self
                           peripheral:peripheral
 didDiscoverCharacteristicsForService:service
                                error:error];
                }
            }
        }
    }
    
    // Callback gerneric listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
        if ([listener respondsToSelector:sel]) {
            [listener manager:self
                   peripheral:peripheral
didDiscoverCharacteristicsForService:service
                        error:error];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
  didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
  error:(NSError *)error
{
  [RLALog debug:@"didUpdateValueForCharacteristic: %@ value: %@ error: %@",
    peripheral.name, characteristic.value, error];

  // Cancel if data is invalid
  if (![characteristic.value length]) return;
  
  // Find matching mappings for peripheral
  RLAPeripheralnfo *info =
    [_bleAdapterController
     infoForPeripheralWithName:peripheral.name
     bleIdentifier:[peripheral.identifier UUIDString]
     serviceUUID:[[[characteristic service] UUID] UUIDString]
     characteristicUUID:[characteristic.UUID UUIDString]];
  NSArray *mappings = [info mappings];
  
  // No mappings available, callback listeners with data
  if (!mappings) {
    
    // Callback appropriate listener with sensor data
    SEL sel = @selector
    (manager:peripheral:didUpdateData:forCharacteristic:error:);
    for (RLAListenerInfo *linfo in _peripheralListeners) {
      if ([linfo peripheral] == peripheral) {
        for (NSObject <RLABluetoothDelegate>*listener in [linfo listeners]) {
          if ([listener respondsToSelector:sel]) {
            [listener manager:self
                   peripheral:peripheral
                didUpdateData:characteristic.value
            forCharacteristic:characteristic
                        error:error];
          }
        }
      }
    }
    
    // Callback gerneric listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
      if ([listener respondsToSelector:sel]) {
        [listener manager:self
               peripheral:peripheral
            didUpdateData:characteristic.value
        forCharacteristic:characteristic
                    error:error];
      }
    }
    
    // Cancel any further processing
    return;
  }

  // Kick off conversion for each mapping
  for (RLAMappingInfo *info in mappings) {
    
    // Cancel if the mapping does not provide an adapter class\
    // Only adapter classes make sense here since they need to
    // transform incoming values
    if (![info adapterClass]) return;
    
    // Convert sensor data
    RLABluetoothServiceAdapter *adapter =
      [[[info adapterClass] alloc] initWithData:characteristic.value];
    RLAErrorAssertTrueAndReturn(adapter, RLAErrorCodeMissingExpectedValue);
    NSDictionary *dict = [adapter dictionary];
    RLAErrorAssertTrueAndReturn(dict, RLAErrorCodeMissingExpectedValue);
    
    // Callback appropriate listener with sensor data
    SEL sel = @selector
    (manager:peripheral:didUpdateValue:withSensorClass:forCharacteristic:error:);
    for (RLAListenerInfo *linfo in _peripheralListeners) {
      if ([linfo peripheral] == peripheral) {
        for (NSObject <RLABluetoothDelegate>*listener in [linfo listeners]) {
          if ([listener respondsToSelector:sel]) {
            [listener manager:self
                   peripheral:peripheral
               didUpdateValue:dict
              withSensorClass:[info sensorClass]
            forCharacteristic:characteristic
                        error:error];
          }
        }
      }
    }
    
    // Callback gerneric listeners
    for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
      if ([listener respondsToSelector:sel]) {
        [listener manager:self
               peripheral:peripheral
           didUpdateValue:dict
          withSensorClass:[info sensorClass]
        forCharacteristic:characteristic
                    error:error];
      }
    }
  }
}

 - (void)peripheral:(CBPeripheral *)peripheral
   didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
   error:(NSError *)error
{
  [RLALog debug:@"peripheral: %@\ndidWriteValueForCharacteristic: %@\nerror: %@",
    peripheral, characteristic, error];
  
  // Callback appropriate listener with sensor data
  SEL sel = @selector(manager:peripheral:didWriteValueForCharacteristic:error:);
  for (RLAListenerInfo *info in _peripheralListeners) {
    if ([info peripheral] == peripheral) {
      for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
        if ([listener respondsToSelector:sel]) {
          [listener manager:self
            peripheral:peripheral
            didWriteValueForCharacteristic:characteristic
            error:error];
        }
      }
    }
  }
  
  // Callback gerneric listeners
  for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
    if ([listener respondsToSelector:sel]) {
      if ([listener respondsToSelector:sel]) {
        [listener manager:self
          peripheral:peripheral
          didWriteValueForCharacteristic:characteristic
          error:error];
      }
    }
  }
}

- (void)peripheral:(CBPeripheral *)peripheral
  didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
  error:(NSError *)error
{
  [RLALog debug:@"peripheral: %@ - characteristic: %@ - value: %@ - error: %@",
    peripheral.name,
    [RLACBUUID UUIDStringWithCBUUID:characteristic.UUID],
    characteristic.value,
    error];
  
  // Callback appropriate listener with sensor data
  SEL sel = @selector
    (manager:peripheral:didUpdateNotificationStateForCharacteristic:error:);
  for (RLAListenerInfo *info in _peripheralListeners) {
    if ([info peripheral] == peripheral) {
      for (NSObject <RLABluetoothDelegate>*listener in [info listeners]) {
        if ([listener respondsToSelector:sel]) {
          [listener manager:self
                 peripheral:peripheral
                 didUpdateNotificationStateForCharacteristic:characteristic
                      error:error];
        }
      }
    }
  }
  
  // Callback gerneric listeners
  for (NSObject <RLABluetoothDelegate>*listener in _genericListeners) {
    if ([listener respondsToSelector:sel]) {
      if ([listener respondsToSelector:sel]) {
        [listener manager:self
               peripheral:peripheral
               didUpdateNotificationStateForCharacteristic:characteristic
                    error:error];
      }
    }
  }
}

#pragma mark - Private helpers

- (RLAListenerInfo *)RLA_listenerInfoForPeripheral:(CBPeripheral *)peripheral
{
  for (RLAListenerInfo *info in _peripheralListeners) {
    if (info) {
      CBPeripheral *p = [info peripheral];
      if (p == peripheral) return info;
    }
  }
  return nil;
}

@end