import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';

class SettingsPage extends StatelessWidget {
  static String routeName = '/setting_page';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<WeatherProvider>(
          builder: (context, provider, child) => ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  SwitchListTile(
                      title: const Text('Show temperature in Fahrenheit'),
                      subtitle: const Text('Default is Celcius'),
                      value: provider.isFarenheight,
                      onChanged: (value) async {
                        provider.setTempUnit(value);
                        await provider.setTempUnitPreferenceValue(value);
                        provider.geWeatherData();
                      }),
                  SwitchListTile(
                    title: const Text('Set current city as Default'),
                    value: provider.isFarenheight,
                    onChanged: (value) async {

                    },
                  ),
                ],
              )),
    );
  }
}
