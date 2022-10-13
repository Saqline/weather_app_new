import 'dart:convert';

import 'package:geocoding/geocoding.dart' as Geo;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/current_response_model.dart';
import 'package:weather_app/models/forecast_response_model.dart';

import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier{
  CurrentResponseModel? currentResponseModel;
  ForecastResponseModel? forecastResponseModel;
  String unit='metric';
  double latitude=0.0,longitude=0.0;
  String unitSymbol=celcius;

  bool get isFarenheight=>unit==imperial;

  bool get hasDataLooaded=>
      currentResponseModel!= null && forecastResponseModel!=null;

  setNewlocation(double lat,double lng){
    latitude=lat;
    longitude=lng;
  }

  Future<bool>setTempUnitPreferenceValue(bool value) async{
    final pref= await SharedPreferences.getInstance();
    return pref.setBool('unit', value);
  }

  Future<bool>getTempUnitPreferenceValue() async{
    final pref= await SharedPreferences.getInstance();
    return pref.getBool('unit') ?? false;
  }

  Future<bool> getDefaultCity() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('defaultCity') ?? false;
  }

  Future<void> setDefaultCityLatLng() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setDouble('lat', latitude);
    await pref.setDouble('lng', longitude);
  }

  Future<Map<String, double>> getDefaultCityLatLng() async {
    final pref = await SharedPreferences.getInstance();
    final lat = await pref.getDouble('lat') ?? 0.0;
    final lng = await pref.getDouble('lng') ?? 0.0;
    return {'lat' : lat, 'lng' : lng};
  }


  geWeatherData(){
    _getCurrentData();
    _getForecastData();
  }

  void _getCurrentData() async{
    final uri=Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&&units=$unit&appid=$weatherApiKey');
    try{
      final response= await get(uri);
      final map= jsonDecode(response.body);
      if(response.statusCode==200){
        currentResponseModel=CurrentResponseModel.fromJson(map);
        notifyListeners();
      }
    }
    catch(error){
      rethrow;
    }
  }

  void _getForecastData() async{
    final uri=Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&&units=$unit&appid=$weatherApiKey');
    try{
      final response= await get(uri);
      final map= jsonDecode(response.body);
      if(response.statusCode==200){
        forecastResponseModel=ForecastResponseModel.fromJson(map);
        notifyListeners();
      }
    }
    catch(error){
      rethrow;
    }
  }

  void setTempUnit(bool value) {
    unit= value? imperial: metric;
    unitSymbol= value? farenheiht: celcius;
    notifyListeners();
  }

  void convertCityToLatLng({required String result, required Null Function(dynamic msg) onError})  async {
    try {
      final locList = await Geo.locationFromAddress(result);
      if(locList.isNotEmpty) {
        final location = locList.first;
        setNewlocation(location.latitude, location.longitude);
        geWeatherData();
      } else {
        onError('City not found');
      }
    } catch(error) {
      onError(error.toString());
    }
  }
}
