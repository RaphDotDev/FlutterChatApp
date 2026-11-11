import 'dart:convert';
import 'package:app/config.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> loginUser(String userName, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.API_URL}/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName': userName,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['userId'] != null && data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', data['userId'].toString());
          await prefs.setString('token', data['token'].toString());
          if (data['userName'] != null) {
            await prefs.setString('userName', data['userName'].toString());
          }

          await initializeChatPlugin();
          await Future.delayed(const Duration(milliseconds: 300));

          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> registerUser(String userName, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.API_URL}/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userName': userName, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['userId'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', data['userId'].toString());
          if (data['token'] != null) {
            await prefs.setString('token', data['token'].toString());
          }
          if (data['userName'] != null) {
            await prefs.setString('userName', data['userName'].toString());
          }

          await initializeChatPlugin();
          await Future.delayed(const Duration(milliseconds: 300));

          return true;
        }
      }
      return false;
    } catch (err) {
      return false;
    }
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future<bool?> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      if (ChatConfig.instance.userId != null) {
        ChatPlugin.chatService.fullDisconnect();
      }
    } catch (_) {}

    await prefs.remove('userId');
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.clear();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
    }
  }

  static Future<void> initializeChatPlugin() async {
    try {
      final userId = await AuthService.getUserId();
      final token = await AuthService.getUserToken();

      if (userId == null) return;

      await ChatPlugin.initialize(
        config: ChatConfig(
          apiUrl: Config.API_URL,
          userId: userId,
          token: token,
          enableTypingIndicators: true,
          enableOnlineStatus: true,
          enableReadReceipts: true,
          autoMarkAsRead: true,
          maxReconnectionAttempts: 5,
          debugMode: true,
        ),
      );

      await _setupChatAPIHandlers(userId, token ?? '');
      await ChatPlugin.chatService.initialize();
      await ChatPlugin.chatService.loadChatRooms();
    } catch (error) {
      debugPrint("Error Initializing Chat: $error");
    }
  }

  static Future<void> _setupChatAPIHandlers(String userId, String token) async {
    final apiHandlers = ChatApiHandlers(
      loadMessagesHandler: ({page = 1, limit = 20, searchText = ""}) async {
        final receiverId = ChatPlugin.chatService.receiverId;

        if (receiverId.isEmpty) return [];

        try {
          var url =
              "${Config.API_URL}/api/chat/messages?currentUserId=$userId&senderId=$userId&receiverId=$receiverId&page=$page&limit=$limit";

          if (searchText.isNotEmpty) {
            url += "&searchText=${Uri.encodeComponent(searchText)}";
          }

          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            return data.map((msg) => ChatMessage.fromMap(msg, userId)).toList();
          } else {
            return [];
          }
        } catch (err) {
          return [];
        }
      },
      loadChatRoomsHandler: () async {
        try {
          final url = "${Config.API_URL}/api/chat/chat-room";

          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            return data.map((room) => ChatRoom.fromMap(room)).toList();
          } else {
            return [];
          }
        } catch (err) {
          return [];
        }
      },
    );
    ChatPlugin.chatService.setApiHandlers(apiHandlers);
  }

  static Future<List<dynamic>> fetchUsers() async {
    try {
      final token = await getUserToken();
      final response = await http.get(
        Uri.parse('${Config.API_URL}/api/users/users'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
      }

      return [];
    } catch (err) {
      return [];
    }
  }
}
