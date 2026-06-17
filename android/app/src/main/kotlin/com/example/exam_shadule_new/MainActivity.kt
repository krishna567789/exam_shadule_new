package com.example.exam_shadule_new

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ============================================================
// SecuGen FDx SDK Integration
// HU20 (Hamster IV) ke liye — koi RD Service, koi certificate nahi chahiye
// SDK download: https://www.secugen.com/products/sdk_android.htm
// ============================================================

// NOTE: Ye imports SDK add karne ke baad uncomment karo:
import SecuGen.FDxSDKPro.JSGFPLib
import SecuGen.FDxSDKPro.SGFDxDeviceName
import SecuGen.FDxSDKPro.SGFDxErrorCode

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.example.exam_shadule_new/rd_service"
    private val ACTION_USB_PERMISSION = "com.example.exam_shadule_new.USB_PERMISSION"

    // SecuGen SDK object (SDK add karne ke baad uncomment karo)
    private var sgfpLib: JSGFPLib? = null

    // USB image dimensions for HU20
    private val IMAGE_WIDTH  = 260
    private val IMAGE_HEIGHT = 300

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Flutter se fingerprint capture request ──
                    "captureFingerprint" -> {
                        captureWithSecuGenSDK(result)
                    }

                    // ── Flutter se capture cancel request ──
                    "cancelCapture" -> {
                        if (sgfpLib != null) {
                            sgfpLib!!.CloseDevice()
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }

                    // ── Connected USB devices ki list ──
                    "checkUsbDevices" -> {
                        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
                        val devices = usbManager.deviceList
                        val deviceNames = devices.values.map {
                            "VID:${it.vendorId.toString(16).uppercase()} PID:${it.productId.toString(16).uppercase()} — ${it.deviceName}"
                        }
                        result.success(mapOf(
                            "count" to devices.size,
                            "devices" to deviceNames
                        ))
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun captureWithSecuGenSDK(result: MethodChannel.Result) {
        Thread {
            try {
                val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

                if (sgfpLib == null) {
                    sgfpLib = JSGFPLib(this, usbManager)
                } else {
                    // Ensure previous device session is closed. 
                    // DO NOT call sgfpLib!!.Close() here! It destroys the JNI context and causes SIGSEGV on the second scan.
                    sgfpLib!!.CloseDevice()
                }

                var error = sgfpLib!!.Init(SGFDxDeviceName.SG_DEV_AUTO)
                
                if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread { result.error("SDK_INIT_FAILED", "SecuGen device create failed: $error", null) }
                    return@Thread
                }

                val finalDevice = sgfpLib!!.GetUsbDevice() ?: usbManager.deviceList.values.find { it.vendorId == 0x1162 }

                if (finalDevice == null) {
                    runOnUiThread { result.error("DEVICE_NOT_FOUND", "SecuGen device not found by Android USB Manager.", null) }
                    return@Thread
                }

                val hasPerm = usbManager.hasPermission(finalDevice)

                if (!hasPerm) {
                    val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                    val intent = Intent(ACTION_USB_PERMISSION).apply {
                        setPackage(packageName)
                    }
                    val permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flag)
                    usbManager.requestPermission(finalDevice, permissionIntent)
                    runOnUiThread { result.error("PERMISSION_REQUIRED", "OTG permission required. Prompting user...", null) }
                    return@Thread
                }

                error = sgfpLib!!.OpenDevice(0)
                
                if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread { result.error("DEVICE_OPEN_FAILED", "SecuGen HU20 open failed: $error. USB OTG connected hai?", null) }
                    return@Thread
                }

                // Brightness set karo
                sgfpLib!!.SetBrightness(50)

                // Image capture karo
                val imageBuffer = ByteArray(IMAGE_WIDTH * IMAGE_HEIGHT)
                error = sgfpLib!!.GetImage(imageBuffer)

                if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    sgfpLib!!.CloseDevice()
                    runOnUiThread { result.error("CAPTURE_FAILED", "Fingerprint capture failed: $error. Finger sensor pe rakhein.", null) }
                    return@Thread
                }

                // Template extract karo (matching ke liye)
                val templateBuffer = ByteArray(400) // MaxTemplateSize
                error = sgfpLib!!.CreateTemplate(null, imageBuffer, templateBuffer)

                sgfpLib!!.CloseDevice()

                if (error == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread {
                        result.success(mapOf(
                            "success"  to true,
                            "image"    to imageBuffer,
                            "template" to templateBuffer,
                            "width"    to IMAGE_WIDTH,
                            "height"   to IMAGE_HEIGHT
                        ))
                    }
                } else {
                    runOnUiThread { result.error("TEMPLATE_FAILED", "Template creation failed: $error", null) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("EXCEPTION", "SecuGen error: ${e.message}", null) }
            }
        }.start()
    }
}
