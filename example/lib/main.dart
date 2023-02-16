import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Datepicker Example'),
        ),
        body: MyHomePage(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _date = DateTime.now();

  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DatePickerWidget(
            dateFormat: DatePickerConstants.DATETIME_PICKER_DATE_FORMAT,
            locale: DateTimePickerLocale.ru,
            onChanged: (value) {
              setState(() {
                _date = DateTime(
                  value.year,
                  value.month,
                  value.day,
                  _date.hour,
                  _date.minute,
                );
              });
            },
            initialDate: _date,
          ),
          DatePickerWidget(
            dateFormat: DatePickerConstants.DATETIME_PICKER_TIME_FORMAT,
            locale: DateTimePickerLocale.ru,
            onChanged: (value) {
              setState(() {
                _date = DateTime(
                  _date.year,
                  _date.month,
                  _date.day,
                  value.hour,
                  value.minute,
                );
              });
            },
            initialDate: _date,
          ),
          const SizedBox(height: 16),
          Text('$_date'),
        ],
      ),
    );
  }
}
