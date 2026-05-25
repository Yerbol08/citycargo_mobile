package kz.citycargo.citycargo_mobile

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i("CityCargoOsm", "packageName=$packageName")
        Log.i("CityCargoOsm", "OpenStreetMap mode enabled; Google Play Services are not required")
    }
}
