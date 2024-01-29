import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AddEvent extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  const AddEvent({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.selectedDate,
  });

  @override
  State<AddEvent> createState() => _AddEventState();
}

class _AddEventState extends State<AddEvent> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _repeatFrequency;
  late tz.Location _local;
  late tz.TZDateTime _scheduledDateTime;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedTime = TimeOfDay.now();
    _repeatFrequency = 'None';
    _initializeLocalNotifications();
    _initializeTimezone();
    _scheduledDateTime =
        tz.TZDateTime.now(_local); // Initialize _scheduledDateTime
  }

  void _initializeTimezone() async {
    tzdata.initializeTimeZones();
    const String timeZoneName = 'Asia/Jakarta';
    _local = tz.getLocation(timeZoneName);
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ElevatedButton(
            onPressed: () {
              _selectDate(context);
            },
            child: const Text("Select Date"),
          ),
          Text(
            'Selected Date: ${DateFormat('d MMMM y').format(_selectedDate)}',
            style: const TextStyle(fontSize: 16),
          ),
          TextField(
            controller: _titleController,
            maxLines: 1,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          ElevatedButton(
            onPressed: () {
              _selectTime(context);
            },
            child: const Text("Select Time"),
          ),
          Text(
            'Selected Time: ${_selectedTime.format(context)}',
            style: const TextStyle(fontSize: 16),
          ),
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text('Repeat event'),
          DropdownButton<String>(
            value: _repeatFrequency,
            onChanged: (String? newValue) {
              setState(() {
                _repeatFrequency = newValue!;
              });
            },
            items: <String>['None', 'Weekly', 'Monthly', 'Yearly']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              _addEvent();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addEvent() async {
    final title = _titleController.text;
    final description = _descController.text;

    if (title.isEmpty) {
      print('Title cannot be empty');
      return;
    }

    final DateTime eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    _scheduledDateTime = tz.TZDateTime.from(
      eventDateTime,
      _local,
    );

    await _scheduleNotification(
      title,
      description,
      _scheduledDateTime,
    );

    await FirebaseFirestore.instance.collection('events').add({
      "title": title,
      "description": description,
      "date": Timestamp.fromDate(eventDateTime),
      "repeatFrequency": _repeatFrequency,
    });

    if (mounted) {
      Navigator.pop<bool>(context, true);
    }
  }

  Future<void> _scheduleNotification(String title, String? description,
      tz.TZDateTime scheduledDateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = scheduledDateTime.isAfter(now)
        ? scheduledDateTime
        : now.add(const Duration(minutes: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      description,
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'item x',
    );
  }
}
