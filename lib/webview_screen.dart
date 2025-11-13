import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class DojahKYC {
  final String appId;
  final String publicKey;
  final String type;
  final int? amount;
  final String? referenceId;
  final String? title;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? metaData;
  final Map<String, dynamic>? govData;
  final Map<String, dynamic>? govId;
  final Map<String, dynamic>? config;
  final Function(dynamic)? onCloseCallback;

  DojahKYC({
    required this.appId,
    required this.publicKey,
    required this.type,
    this.title,
    this.userData,
    this.config,
    this.metaData,
    this.govData,
    this.govId,
    this.amount,
    this.referenceId,
    this.onCloseCallback,
  });

  Future<void> open(BuildContext context,
      {Function(dynamic result)? onSuccess,
      Function(dynamic close)? onClose,
      Function(dynamic error)? onError}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebviewScreen(
          appId: appId,
          publicKey: publicKey,
          type: type,
          userData: userData,
          metaData: metaData,
          govData: govData,
          govId: govId,
          config: config,
          amount: amount,
          referenceId: referenceId,
          title: title,
          success: (result) {
            onSuccess!(result);
          },
          close: (close) {
            onClose!(close);
          },
          error: (error) {
            onError!(error);
          },
        ),
      ),
    );
  }
}

class WebviewScreen extends StatefulWidget {
  final String appId;
  final String publicKey;
  final String type;
  final int? amount;
  final String? referenceId;
  final String? title;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? metaData;
  final Map<String, dynamic>? govData;
  final Map<String, dynamic>? govId;
  final Map<String, dynamic>? config;
  final Function(dynamic) success;
  final Function(dynamic) error;
  final Function(dynamic) close;
  const WebviewScreen({
    Key? key,
    required this.appId,
    required this.publicKey,
    required this.type,
    this.userData,
    this.metaData,
    this.govData,
    this.govId,
    this.config,
    this.amount,
    this.referenceId,
    this.title,
    required this.success,
    required this.error,
    required this.close,
  }) : super(key: key);

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  late InAppWebViewController _webViewController;
  double progress = 0;
  String url = '';
  late PullToRefreshController pullToRefreshController;

  // Enhanced webview settings to handle keyboard and scrolling
  InAppWebViewSettings options = InAppWebViewSettings(
    // Scroll settings
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
    supportZoom: false, // Disable zoom to prevent layout issues
    builtInZoomControls: false,
    displayZoomControls: false,
    
    // Keyboard handling settings
    disableHorizontalScroll: false,
    disableVerticalScroll: false,
    transparentBackground: true,
    javaScriptEnabled: true,
    
    // Additional settings for better keyboard handling
    useWideViewPort: true, // Important for responsive design
    loadWithOverviewMode: true, // Zoom out to fit content
    allowsInlineMediaPlayback: true,
    cacheEnabled: false,
    clearCache: true,
  );

  bool isGranted = false;
  bool isLocationGranted = false;
  bool isLocationPermissionGranted = false;
  dynamic locationData;
  dynamic timeZone;
  dynamic zoneOffset;
  dynamic locationObject;

  @override
  void initState() {
    super.initState();
    getPermissions();
    pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        if (Platform.isAndroid) {
          _webViewController.reload();
        } else if (Platform.isIOS) {
          _webViewController.loadUrl(
            urlRequest: URLRequest(url: await _webViewController.getUrl()),
          );
        }
      },
    );
  }

  Future getPermissions() async {
    await initPermissions();
  }

  Future initPermissions() async {
    await Permission.camera.request().then((value) {
      if (value.isPermanentlyDenied) {
        openAppSettings();
      }
    });
    if (await Permission.camera.request().isGranted) {
      setState(() {
        isGranted = true;
      });
    } else {
      Permission.camera.onDeniedCallback(() {
        Permission.camera.request();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // KEY FIX: Prevent resizing when keyboard appears
      resizeToAvoidBottomInset: false,
      
      appBar: widget.title != null
        ? AppBar(
            title: Text(widget.title!),
          )
        : null,
      
      body: isGranted
          ? Column(
              children: [
                // Progress indicator
                if (progress < 1.0)
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                
                // Expanded webview to take remaining space
                Expanded(
                  child: InAppWebView(
                    key: webViewKey,
                    initialSettings: options,
                    initialData: InAppWebViewInitialData(
                      baseUrl: WebUri("https://widget.dojah.io"),
                      historyUrl: WebUri("https://widget.dojah.io"),
                      mimeType: "text/html",
                      data: """
                            <html lang="en">
                              <head>
                                  <meta charset="UTF-8">
                                  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no"/>
                                  
                                  <!-- Additional CSS to handle keyboard and scrolling -->
                                  <style>
                                    body {
                                      margin: 0;
                                      padding: 0;
                                      overflow: auto;
                                      -webkit-overflow-scrolling: touch;
                                      height: 100%;
                                      position: relative;
                                    }
                                    html {
                                      height: 100%;
                                      overflow: auto;
                                    }
                                    /* Ensure scrollbars are visible */
                                    ::-webkit-scrollbar {
                                      width: 8px;
                                      height: 8px;
                                    }
                                    ::-webkit-scrollbar-track {
                                      background: #f1f1f1;
                                    }
                                    ::-webkit-scrollbar-thumb {
                                      background: #888;
                                      border-radius: 4px;
                                    }
                                    ::-webkit-scrollbar-thumb:hover {
                                      background: #555;
                                    }
                                  </style>
                                  
                                  <title>Dojah Inc.</title>
                              </head>
                              <body>
                                <script src="https://widget.dojah.io/widget.js"></script>
                                <script>
                                          const options = {
                                              app_id: "${widget.appId}",
                                              p_key: "${widget.publicKey}",
                                              type: "${widget.type}",
                                              reference_id: "${widget.referenceId}",
                                              config: ${json.encode(widget.config ?? {})},
                                              user_data: ${json.encode(widget.userData ?? {})},
                                              gov_data: ${json.encode(widget.govData ?? {})},
                                              gov_id: ${json.encode(widget.govId ?? {})},
                                              location: ${json.encode(locationObject ?? {})},
                                              metadata: ${json.encode(widget.metaData ?? {})},
                                              onSuccess: function (response) {
                                              window.flutter_inappwebview.callHandler('onSuccessCallback', response)
                                              },
                                              onError: function (error) {
                                                window.flutter_inappwebview.callHandler('onErrorCallback', error)
                                              },
                                              onClose: function () {
                                                window.flutter_inappwebview.callHandler('onCloseCallback', 'close')
                                              },
                                          }

                                            const connect = new Connect(options);
                                            connect.setup();
                                            connect.open();
                                      </script>
                              </body>
                            </html>
                        """,
                    ),
                    initialUrlRequest: URLRequest(
                      url: WebUri("https://widget.dojah.io"),
                    ),
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      _webViewController = controller;

                      _webViewController.addJavaScriptHandler(
                        handlerName: 'onSuccessCallback',
                        callback: (response) {
                          widget.success(response);
                        },
                      );

                      _webViewController.addJavaScriptHandler(
                        handlerName: 'onCloseCallback',
                        callback: (response) {
                          widget.close(response);
                        },
                      );

                      _webViewController.addJavaScriptHandler(
                        handlerName: 'onErrorCallback',
                        callback: (error) {
                          widget.error(error);
                        },
                      );
                    },
                    onPermissionRequest: Platform.isAndroid
                        ? null
                        : (controller, origin) async {
                            return PermissionResponse(
                              resources: [
                                PermissionResourceType.CAMERA,
                                PermissionResourceType.MICROPHONE,
                              ],
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      
                      // Inject additional JavaScript to handle keyboard behavior
                      await controller.evaluateJavascript(source: """
                        // Prevent page shift when keyboard appears
                        document.body.style.position = 'relative';
                        document.body.style.minHeight = '100%';
                        
                        // Ensure scroll behavior is proper
                        if (document.scrollingElement) {
                          document.scrollingElement.style.overflow = 'auto';
                        }
                        
                        // Add event listener for focus events to handle keyboard
                        document.addEventListener('focusin', function(e) {
                          // Let the webview handle scrolling naturally
                          setTimeout(function() {
                            if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
                              e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            }
                          }, 300);
                        });
                      """);
                    },
                    onReceivedError: (controller, url, code) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    androidOnGeolocationPermissionsShowPrompt:
                        (controller, origin) async {
                      return GeolocationPermissionShowPromptResponse(
                          allow: true, origin: origin, retain: true);
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      if (kDebugMode) {
                        print("WebView Console: ${consoleMessage.message}");
                      }
                    },
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}