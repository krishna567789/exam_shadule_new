import 'dart:io' as io;
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DeviceHelper extends GetxController {
  static final DeviceHelper _instance = DeviceHelper.internal();
  factory DeviceHelper() => _instance;

  static Database? _db;

  // Internal constructor
  DeviceHelper.internal();

  // Get the database instance (lazy loading)
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  // Initialize the database
  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'devices_info.db');
    var theDb = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute(''' 
        CREATE TABLE devices_info (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          device_name TEXT NOT NULL,
          device_model TEXT NOT NULL
        )
      ''');

    });
    return theDb;
  }

  // Store device info both locally and remotely
  Future<void> storeDeviceInfo(String deviceName, String deviceModel) async {
    // First make the API call to store device info remotely
    bool isApiSuccess = await storeDeviceInfoRemote(deviceName, deviceModel);
    if (isApiSuccess) {
      var dbClient = await db;
      // If API call was successful, store the device info locally in the database
      try {
        await dbClient.insert(
          'devices_info',
          {'device_name': deviceName, 'device_model': deviceModel},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("Data inserted into the local database successfully");
      } catch (e) {
        print("Error storing device info locally: $e");
      }
    } else {
      print("API request failed, not inserting data locally.");
    }
  }

  // Make the API call to store the device info remotely
  Future<bool> storeDeviceInfoRemote(String deviceName, String deviceModel) async {
    try {
      var headers = {
        'Accept': 'application/json',
        "Authorization": "Bearer 2|6H9fbQTJ9s8Wl9bugCgQVWMOfuGt2Go6wYgasGzh93f6fa672"
      };
      final response = await http.post(
        Uri.parse("https://bio.ubrosoft.com/api/devices"),
        headers: headers,
        body: {
          'device_name': deviceName,
          'device_model': deviceModel,
        },
      );

      print("API URL: ${response.request?.url}");
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("Device info stored remotely successfully: ${response.body}");
        return true;
      } else {
        print("Error storing device info remotely: ${response.reasonPhrase}");
        return false;
      }
    } catch (e) {
      print("Error making API request: $e");
      return false;
    }
  }

}
