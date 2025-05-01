import 'dart:convert';
import 'package:charusat_recruitment/const.dart';
import 'package:charusat_recruitment/screens/models/announcement_model.dart';
import 'package:charusat_recruitment/service/common_service/auth_service.dart';
import 'package:charusat_recruitment/service/users/faculty_service.dart';
import 'package:charusat_recruitment/service/users/student_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../Providers/announcement_provider.dart';

class AnnouncementService {
  // Replace with actual server URL
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<void> getAnnouncements(BuildContext context) async {
    print("Fetching announcements...");

    String? accessToken = await secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      bool tokenRefreshed =
          await AuthenticationService().regenerateAccessToken(context);
      if (!tokenRefreshed) return; // Redirected to login if refresh fails
      accessToken =
          await secureStorage.read(key: 'access_token'); // Get new token
    }

    var headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    try {
      var response = await http
          .get(
            Uri.parse('$serverurl/announcement/announcements/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
      List<dynamic> responseData = json.decode(response.body);
        print("Announcements received successfully with role $role");

        

        List<AnnouncementModel> announcements =
            responseData.map<AnnouncementModel>((item) {
          return AnnouncementModel(
            id: item['id'],
            title: item['title'],
            subtitle: item['description'],
            companyName: item['company_name'],
          );
        }).toList();

        if (context.mounted) {
          Provider.of<AnnouncementProvider>(context, listen: false)
              .announcements = announcements;
        }
      } else if (response.statusCode == 401) {
        print("Calling");
        // If Unauthorized, attempt to regenerate token and retry
        bool tokenRefreshed = await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          await getAnnouncements(context); // Retry fetching announcements
        }
      } else {
        _showErrorDialog(context, "Error loading announcements");
      }
    } catch (e) {
      print("Error fetching announcements: $e");
      _showErrorDialog(context, "Error loading announcements");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAnnouncement(BuildContext context, int id) async {
    print("Deleting announcement with ID: $id");

    String? accessToken = await secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      bool tokenRefreshed =
          await AuthenticationService().regenerateAccessToken(context);
      if (!tokenRefreshed) return; // Redirected to login if refresh fails
      accessToken =
          await secureStorage.read(key: 'access_token'); // Get new token
    }

    var headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    try {
      var response = await http
          .delete(
            Uri.parse('$serverurl/announcement/announcements/$id/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        print("Announcement deleted successfully");

        // Optionally, refresh the list of announcements
        await getAnnouncements(context);
      } else if (response.statusCode == 401) {
        // If Unauthorized, attempt to regenerate token and retry
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          await deleteAnnouncement(context, id); // Retry deletion
        }
      } else {
        _showErrorDialog(context, "Error deleting announcement");
      }
    } catch (e) {
      print("Error deleting announcement: $e");
      _showErrorDialog(context, "Error deleting announcement");
    }
  }

  Future<void> addAnnouncement(BuildContext context, String title,
      String description, String companyName) async {
    print("Started adding announcement...");

    String? accessToken = await secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      bool tokenRefreshed =
          await AuthenticationService().regenerateAccessToken(context);
      if (!tokenRefreshed) return; // Redirected to login if refresh fails
      accessToken =
          await secureStorage.read(key: 'access_token'); // Get new token
    }

    var headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    var body = json.encode({
      "title": title,
      "description": description,
      "company_name": companyName,
    });

    try {
      var response = await http
          .post(
            Uri.parse('$serverurl/announcement/announcements/'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Announcement added successfully");
        await getAnnouncements(context);
      } else if (response.statusCode == 401) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          await addAnnouncement(context, title, description, companyName);
        }
      } else {
        _showErrorDialog(context, "Error adding announcement");
      }
    } catch (e) {
      print("Error adding announcement: $e");
      _showErrorDialog(context, "Error adding announcement");
    }
  }
}
