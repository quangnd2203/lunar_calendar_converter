import 'package:flutter/material.dart';
import 'package:luna_calendar_converter/luna_calendar_converter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late final LunaCalendarConverter lunaCalendarConverter;

  @override
  void initState(){
    LunaCalendarConverter.instance().then((value) => lunaCalendarConverter = value);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const Center(
          child: Text('Running on:'),
        ),
      ),
    );
  }
}
