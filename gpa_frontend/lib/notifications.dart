import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class UserNotification {
  final int id;
  final String header;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  UserNotification({
    required this.id,
    required this.header,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      header: json['header'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'],
    );
  }
}

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final storage = FlutterSecureStorage();
  List<UserNotification> _notifications = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authToken = await storage.read(key: 'auth_token');
      if (authToken == null) {
        setState(() {
          _error = 'Authentication token is missing. Please log in again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/notifications/'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications =
              data.map((json) => UserNotification.fromJson(json)).toList();
        });
      } else {
        setState(() {
          _error = 'Failed to load notifications: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching notifications: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final authToken = await storage.read(key: 'auth_token');
      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token is missing.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2:8000/api/notifications/$notificationId/read/'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index =
              _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = UserNotification(
              id: _notifications[index].id,
              header: _notifications[index].header,
              content: _notifications[index].content,
              createdAt: _notifications[index].createdAt,
              isRead: true,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color.fromARGB(255, 20, 53, 89),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications available'))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return InkWell(
                          onTap: () {
                            if (!notification.isRead) {
                              _markAsRead(notification.id);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            color: notification.isRead
                                ? Colors.white
                                : Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notification.header,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: notification.isRead
                                              ? Colors.grey[600]
                                              : Colors.blue[900],
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'New',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(notification.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
