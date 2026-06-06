# iOS Hybrid SDK — Contributor Guide

This repository provides the **iOS native bridge** for Salesforce Mobile SDK hybrid (Cordova) apps. It delivers the `SalesforceHybridSDK` CocoaPods pod and contains the Objective-C bootstrap files that are copied into the CordovaPlugin distribution.

**Minimum iOS deployment target:** 18.0

---

## SalesforceHybridSDK Pod

The primary deliverable is the `SalesforceHybridSDK` pod, declared in `SalesforceHybridSDK.podspec` at the repo root.

| Attribute | Value |
|-----------|-------|
| Pod name | `SalesforceHybridSDK` |
| Current version | 14.0.0 |
| Key dependency | `MobileSync ~> 14.0.0` (pulls the full iOS SDK chain) |
| Cordova dependency | `Cordova 7.1.1` |
| Source files | `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/**/*.{h,m,swift}` |

In **dev builds**, the CordovaPlugin's `plugin.xml` references this pod directly from the GitHub repo on the `dev` branch. In **GA releases**, it references the pod by version tag (e.g., `v14.0.0`).

---

## Plugin Classes

Located under `libs/SalesforceHybridSDK/SalesforceHybridSDK/Classes/Plugins/`:

| Plugin | Directory | Header | Purpose |
|--------|-----------|--------|---------|
| `SalesforceOAuthPlugin` | `SFOAuthPlugin/` | `SalesforceOAuthPlugin.h` | OAuth authentication and user management |
| `SFNetworkPlugin` | `SFNetworkPlugin/` | `SFNetworkPlugin.h` | REST API requests to Salesforce |
| `SFSDKInfoPlugin` | `SDKInfo/` | `SFSDKInfoPlugin.h` | SDK version and configuration info |
| `SFSmartStorePlugin` | `SFSmartStore/` | `SFSmartStorePlugin.h` | Encrypted local storage (SmartStore) |
| `SFMobileSyncPlugin` | `SFMobileSyncPlugin/` | `SFMobileSyncPlugin.h` | Data synchronization framework |
| `SFAccountManagerPlugin` | `SFAccountManagerPlugin/` | `SFAccountManagerPlugin.h` | Multi-user account management |
| `SFForcePlugin` | `SFForcePlugin/` | `SFForcePlugin.h` | Base class for Salesforce Cordova plugins |
| `CDVPlugin+SFAdditions` | `SFAdditions/` | `CDVPlugin+SFAdditions.h` | Category adding Salesforce helpers to CDVPlugin |

Each plugin is an Objective-C subclass of `CDVPlugin` (or `SFForcePlugin`) and exposes methods callable from JavaScript via the Cordova bridge.

---

## `shared/hybrid/` — Bootstrap Files Copied to CordovaPlugin

The `shared/hybrid/` directory contains Objective-C files that `tools/update.sh` in the CordovaPlugin repo copies to `src/ios/classes/`:

| File | Role |
|------|------|
| `AppDelegate.m` | Application entry point that bootstraps the Salesforce hybrid runtime (OAuth, SDK initialization, view controller setup) |
| `InitialViewController.h` / `.m` | Root view controller displayed before the Cordova WKWebView loads |
| `UIApplication+SalesforceHybridSDK.h` / `.m` | UIApplication category that tracks last-event timing for passcode inactivity |

The directory also contains `config.xml` and `cordova_plugins.js`, but only the Objective-C files are copied to the CordovaPlugin.

### Why `AppDelegate.m` lives here

When `cordova platform add ios` runs, Cordova generates its own `AppDelegate.m`. The CordovaPlugin's `postinstall-ios.js` hook patches `project.pbxproj` to redirect the AppDelegate reference to `Plugins/com.salesforce/AppDelegate.m` — the SDK version that initializes the Salesforce hybrid runtime (OAuth, SDK manager, hybrid view controller). Without this patch, none of the Salesforce Cordova plugins would function.

---

## `external/shared/` — Shared JavaScript Submodule

SalesforceMobileSDK-Shared is included as a git submodule at `external/shared/`. The hybrid sample apps reference JavaScript libraries (force.js, smartstore.js, mobilesync.js) from this submodule.

Other submodules:

| Path | Repository |
|------|------------|
| `external/SalesforceMobileSDK-iOS` | iOS native SDK |
| `external/cordova` | Apache Cordova iOS |
| `external/CocoaLumberjack` | Logging library |

---

## Sample Apps

Located under `hybrid/SampleApps/`:

- **AccountEditor** — Basic CRUD operations on Account records using Cordova plugins
- **MobileSyncExplorerHybrid** — Full MobileSync demo with offline sync and conflict resolution

Their JavaScript source comes from the `external/shared/` submodule.

---

## Version Management

`setversion.sh` updates the SDK version in both podspecs:

```bash
./setversion.sh -v 14.0.0
```

This updates `s.version` in `SalesforceHybridSDK.podspec` and `SalesforceFileLogger.podspec`. This script has no `-d` flag — the dev/GA distinction for iOS is controlled by CordovaPlugin's `plugin.xml` (which references the pod by `branch="dev"` or `tag="v14.0.0"` depending on the build type).

---

## Running Unit Tests

Open the workspace and run the `SalesforceHybridSDK` scheme tests:

```bash
# Setup (first time)
./install.sh

# Run tests
xcodebuild test \
  -workspace SalesforceMobileSDK-Hybrid.xcworkspace \
  -scheme SalesforceHybridSDK \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Always open `SalesforceMobileSDK-Hybrid.xcworkspace` (not individual `.xcodeproj` files) to ensure CocoaPods dependencies resolve correctly.

Most tests require a `test_credentials.json` file at `shared/test/test_credentials.json`. Without it, only tests that do not make authenticated Salesforce API calls will pass. Copy the sample and fill in your org details:

```bash
cp shared/test/test_credentials.json.sample shared/test/test_credentials.json
# then edit with your Connected App credentials and org details
```

The file must contain:

```json
{
  "test_client_id":    "<Connected App consumer key>",
  "test_login_domain": "<login URL, e.g. test.salesforce.com>",
  "test_redirect_uri": "<Connected App callback URL>",
  "refresh_token":     "<valid refresh token>",
  "instance_url":      "<org instance URL>",
  "identity_url":      "<identity URL>"
}
```

`test_credentials.json` is gitignored — never commit real credentials.
