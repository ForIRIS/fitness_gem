import Flutter
import UIKit
import CoreML

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var model: MLModel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let modelChannel = FlutterMethodChannel(name: "com.antigravity.fitness_gem/model_runner",
                                              binaryMessenger: controller.binaryMessenger)
    
    modelChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "loadModel" {
        self?.loadModel(call: call, result: result)
      } else if call.method == "runInference" {
        self?.runInference(call: call, result: result)
      } else if call.method == "dispose" {
        self?.model = nil
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func loadModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let modelPath = args["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "modelPath is required", details: nil))
      return
    }

    do {
      let modelURL = URL(fileURLWithPath: modelPath)
      var compiledURL = modelURL
      
      // CoreML models must be compiled (.mlmodelc) to be loaded at runtime
      if !modelPath.hasSuffix(".mlmodelc") {
          compiledURL = try MLModel.compileModel(at: modelURL)
      }
      
      let config = MLModelConfiguration()
      config.computeUnits = .all
      self.model = try MLModel(contentsOf: compiledURL, configuration: config)
      result(true)
    } catch {
      result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func runInference(call: FlutterMethodCall, result: @escaping FlutterResult) {
     guard let model = self.model else {
        result(FlutterError(code: "MODEL_NOT_LOADED", message: "Model is not loaded", details: nil))
        return
     }

     guard let args = call.arguments as? [String: Any],
           let inputData = args["input"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "input data is required", details: nil))
        return
     }

     let data = inputData.data
     // Input shape spec: batch(1) x frames(30) x joints(33) x coords(3)
     let shape: [NSNumber] = [1, 30, 33, 3]
     
     do {
         let inputArray = try MLMultiArray(shape: shape, dataType: .float32)
         data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
             let floatPtr = ptr.bindMemory(to: Float32.self)
             for i in 0..<inputArray.count {
                 inputArray[i] = NSNumber(value: floatPtr[i])
             }
         }

         let inputProvider = try MLDictionaryFeatureProvider(dictionary: ["input": inputArray])
         let output = try model.prediction(from: inputProvider)

         var response: [String: Any] = [:]
         
         // Mapping outputs: phase_probs, deviation_score, current_features
         if let phaseProbs = output.featureValue(for: "phase_probs")?.multiArrayValue {
             response["phase_probs"] = multiArrayToList(phaseProbs)
         }
         if let deviationScore = output.featureValue(for: "deviation_score")?.multiArrayValue {
             response["deviation_score"] = Double(truncating: deviationScore[0])
         }
         if let currentFeatures = output.featureValue(for: "current_features")?.multiArrayValue {
             response["current_features"] = multiArrayToList(currentFeatures)
         }

         result(response)
     } catch {
         result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
     }
  }

  private func multiArrayToList(_ multiArray: MLMultiArray) -> [Double] {
      var list: [Double] = []
      for i in 0..<multiArray.count {
          list.append(Double(truncating: multiArray[i]))
      }
      return list
  }
}
