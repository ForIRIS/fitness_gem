package com.example.fitness_gem

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import ai.onnxruntime.*
import java.nio.FloatBuffer
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.fitness_gem/model_runner"
    private var ortEnvironment: OrtEnvironment? = null
    private var ortSession: OrtSession? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        loadModel(modelPath, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "modelPath is required", null)
                    }
                }
                "runInference" -> {
                    val input = call.argument<FloatArray>("input")
                    if (input != null) {
                        runInference(input, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "input data is required", null)
                    }
                }
                "dispose" -> {
                    disposeModel()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun loadModel(modelPath: String, result: MethodChannel.Result) {
        try {
            disposeModel()
            ortEnvironment = OrtEnvironment.getEnvironment()
            ortSession = ortEnvironment?.createSession(modelPath, OrtSession.SessionOptions())
            result.success(true)
        } catch (e: Exception) {
            result.error("LOAD_FAILED", e.message, null)
        }
    }

    private fun runInference(inputData: FloatArray, result: MethodChannel.Result) {
        val session = ortSession ?: run {
            result.error("MODEL_NOT_LOADED", "Model is not loaded", null)
            return
        }
        val env = ortEnvironment ?: run {
            result.error("ENV_NOT_INITIALIZED", "Environment is not initialized", null)
            return
        }

        try {
            // Input shape [1, 30, 33, 3]
            val shape = longArrayOf(1, 30, 33, 3)
            val floatBuffer = FloatBuffer.wrap(inputData)
            
            val inputTensor = OnnxTensor.createTensor(env, floatBuffer, shape)
            
            val inputName = session.inputNames.firstOrNull() ?: "input"
            val results = session.run(Collections.singletonMap(inputName, inputTensor))

            val response = mutableMapOf<String, Any>()
            
            results.forEach { entry ->
                val name = entry.key
                val value = entry.value
                when (name) {
                    "phase_probs" -> response["phase_probs"] = tensorToList(value as OnnxTensor)
                    "deviation_score" -> response["deviation_score"] = (value as OnnxTensor).floatBuffer.get(0).toDouble()
                    "current_features" -> response["current_features"] = tensorToList(value as OnnxTensor)
                }
            }
            
            result.success(response)
        } catch (e: Exception) {
            result.error("INFERENCE_FAILED", e.message, null)
        }
    }

    private fun tensorToList(tensor: OnnxTensor): List<Double> {
        val buffer = tensor.floatBuffer
        val list = mutableListOf<Double>()
        buffer.rewind()
        while (buffer.hasRemaining()) {
            list.add(buffer.get().toDouble())
        }
        return list
    }

    private fun disposeModel() {
        ortSession?.close()
        ortSession = null
        ortEnvironment?.close()
        ortEnvironment = null
    }
}
