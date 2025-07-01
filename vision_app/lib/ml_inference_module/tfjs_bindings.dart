import 'dart:js_interop';

/// JavaScript TensorFlow.js wrapper bindings
@JS('TFJSWrapper')
extension type TFJSWrapper._(JSObject _) implements JSObject {
  external TFJSWrapper();

  external bool get isLoaded;

  @JS('loadModel')
  external JSPromise<JSBoolean> loadModel(
    JSString modelUrl, [
    JSBoolean? useGpu,
  ]);

  @JS('runObjectDetection')
  external JSArray<JSDetection> runObjectDetection(JSAny imageData);

  @JS('dispose')
  external void dispose();
}

/// JavaScript object representing a detection result
@JS()
extension type JSDetection._(JSObject _) implements JSObject {
  external JSBoundingBox get boundingBox;
  external JSNumber get confidence;
  external JSNumber get classIndex;
  external JSString get className;
}

/// JavaScript object representing a bounding box
@JS()
extension type JSBoundingBox._(JSObject _) implements JSObject {
  external JSNumber get left;
  external JSNumber get top;
  external JSNumber get width;
  external JSNumber get height;
}

/// TensorFlow.js utility functions
@JS('tf.browser.fromPixels')
external JSAny fromPixels(JSAny imageElement);

@JS('tf.dispose')
external void dispose(JSAny tensor);

/// Canvas and ImageData utilities
@JS('document.createElement')
external JSAny createElement(JSString tagName);

@JS()
extension type CanvasRenderingContext2D._(JSObject _) implements JSObject {
  external void putImageData(JSAny imageData, JSNumber dx, JSNumber dy);
  external JSAny getImageData(
    JSNumber sx,
    JSNumber sy,
    JSNumber sw,
    JSNumber sh,
  );
  external void drawImage(
    JSAny image,
    JSNumber dx,
    JSNumber dy, [
    JSNumber? dw,
    JSNumber? dh,
  ]);
  external JSAny createImageData(JSNumber width, JSNumber height);
}

@JS()
extension type ImageData._(JSObject _) implements JSObject {
  external JSUint8Array get data;
  external JSNumber get width;
  external JSNumber get height;
}
