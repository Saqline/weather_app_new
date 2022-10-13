import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/pages/settings_page.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/utils/location_service.dart';

import '../utils/constants.dart';
import '../utils/helper_function.dart';
import '../utils/text_style.dart';

class WeatherPage extends StatefulWidget {
  static String routeName='/';
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with WidgetsBindingObserver {
  late WeatherProvider provider;
  String loadingMsg = 'Please wait';
  late StreamSubscription<ConnectivityResult> subscription;


  bool isFirst=true;
  @override
  void didChangeDependencies() {
    if (isFirst) {
      provider = Provider.of<WeatherProvider>(context);
      isConnectedToInternet().then((value) {
        if(value) {
          _detectLocation();
        } else {
          setState(() {
            loadingMsg = 'No internet connection detected. Please turn on your wifi or mobile data';
          });
        }
      });
      isFirst = false;
    }
    super.didChangeDependencies();
  }

  void initState() {
    WidgetsBinding.instance.addObserver(this);
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      if(result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
        setState(() {
          loadingMsg = 'Please wait';
        });
        _detectLocation();
      }
    });

    super.initState();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state){
      case AppLifecycleState.resumed:
      _detectLocation();
      break;
    }
    super.didChangeAppLifecycleState(state);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Weather App'),
        actions: [
          IconButton(
              onPressed: (){},
              icon: Icon(Icons.my_location)
          ),
          IconButton(
              onPressed: ()async{
                final result= await showSearch(
                    context: context,
                    delegate: _CitySearchDelegate());
                if(result!=null && result.isNotEmpty){
                  provider.convertCityToLatLng(
                      result: result,
                      onError: (msg) {
                        showMsg(context, msg);
                      });
                }
              },
              icon: Icon(Icons.search)
          ),
          IconButton(
              onPressed: ()=>Navigator.pushNamed(context,SettingsPage.routeName),
              icon: Icon(Icons.settings)
          ),
        ],
      ),
      body: Center(
        child:provider.hasDataLooaded ? ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          children: [
            _currentWeatherSection(),
            _forecastWeatherSection(),
          ],
        ):
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(loadingMsg),
            ),
      ),
    );
  }

  void _detectLocation() async {
    final isLocationEnabled = await isLocationServiceEnabled;
    if (isLocationEnabled) {
      try {
        final position = await determinePosition();
        provider.setNewlocation(position.latitude, position.longitude);
        provider.setTempUnit(await provider.getTempUnitPreferenceValue());
        provider.geWeatherData();
      } catch (error) {
        showMsg(context, 'error');
      }
    } else {
      showMsgWithAction(
        context: context,
        msg: 'Please turn on your location',
        actionButtonTitle: 'Go to Settings',
        onPressedSettings: () async {
          await openLocationSettings;
        },
      );
    }
  }

  Widget _currentWeatherSection() {
    final current = provider.currentResponseModel;
    return Column(
      children: [
        Text(getFormattedDateTime(current!.dt!, 'MMM dd, yyyyy',), style: txtDateBig18,),
        Text('${current.name}, ${current.sys!.country}', style: txtAddress25,),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('$iconPrefix${current.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
              Text('${current.main!.temp!.round()}$degree${provider.unitSymbol}', style: txtTempBig80,),
            ],
          ),
        ),
        Text('feels like ${current.main!.feelsLike}$degree${provider.unitSymbol}', style: txtNormal16White54,),
        Text('${current.weather![0].main} ${current.weather![0].description}', style: txtNormal16White54,),
        const SizedBox(height: 20,),
        Wrap(
          direction: Axis.vertical,
          children: [
            Text('Humidity: ${current.main!.humidity}% ', style: txtNormal16,),
            Text('Pressure: ${current.main!.pressure}hPa ', style: txtNormal16,),
            Text('Visibility: ${current.visibility} meter ', style: txtNormal16,),
            Text('Wind Speed: ${current.wind!.speed} m/s ', style: txtNormal16,),
            Text('Degree ${current.wind!.deg}$degree ', style: txtNormal16,),
          ],
        ),
        const SizedBox(height: 20,),
        Wrap(
          children: [
            Text('Sunrise: ${getFormattedDateTime(current.sys!.sunrise!, 'hh:mm a')}', style: txtNormal16White54,),
            const SizedBox(width: 10,),
            Text('Sunset: ${getFormattedDateTime(current.sys!.sunset!, 'hh:mm a')}', style: txtNormal16White54,),
          ],
        )
      ],
    );
  }

  Widget _forecastWeatherSection() {
    return Column();
  }
}

class _CitySearchDelegate extends SearchDelegate<String>{
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: (){
            query='';
          },
          icon: Icon(Icons.clear)
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    IconButton(
      onPressed: (){},
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        close(context, query);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty
        ? cities
        : cities
        .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredList[index]),
        onTap: () {
          query = filteredList[index];
          close(context, query);
        },
      ),
    );
  }

}

