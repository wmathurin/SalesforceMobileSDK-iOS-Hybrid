/*
 Copyright (c) 2025-present, salesforce.com, inc. All rights reserved.

 Bridging header for hybrid sample apps. Provides ObjC visibility for
 Cordova and Salesforce SDK classes used by AppDelegate.swift and ViewController.swift.
 */

#import <Cordova/Cordova.h>

#define __CORDOVA_SILENCE_HEADER_DEPRECATIONS
#import "AppDelegate.h"
#import "MainViewController.h"
#undef __CORDOVA_SILENCE_HEADER_DEPRECATIONS

#import "InitialViewController.h"
