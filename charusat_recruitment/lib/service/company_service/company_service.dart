import 'dart:convert';
import 'package:charusat_recruitment/screens/models/company_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:charusat_recruitment/const.dart';
import 'package:charusat_recruitment/service/common_service/auth_service.dart';

import '../../screens/models/company_round_model.dart';

class CompanyService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get companies method
  Future<Map<String, List<Map<String, String>>>> getCompanies(
      BuildContext context) async {
    try {
      // Get access token from secure storage
      String? accessToken = await _storage.read(key: 'access_token');

      // If token is null, attempt to regenerate it
      if (accessToken == null) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (!tokenRefreshed) {
          // If refresh fails, return empty lists
          return {
            'upcoming': [],
            'recent': [],
          };
        }
        // Get the newly generated token
        accessToken = await _storage.read(key: 'access_token');
      }

      // Set up headers with authorization token
      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var url = Uri.parse('$serverurl/company/companies-create&list/');
      var response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      List<Map<String, String>> upcomingCompanies = [];
      List<Map<String, String>> recentCompanies = [];
      print(json.decode(response.body).toString());
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);

        for (var company in jsonData) {
          String companyDateStr = company['date_placementdrive']?.toString() ??
              DateTime.now().toString();
          DateTime companyDate;

          try {
            companyDate = DateTime.parse(companyDateStr);
          } catch (e) {
            print("Error parsing date: $e for date string: $companyDateStr");
            companyDate =
                DateTime.now(); // Fallback to current date if parsing fails
          }

          DateTime currentDate = DateTime.now();
          print('response id ${company['company_id'].toString()}');
          // Use null-aware operators with defaults for all fields
          Map<String, String> companyDetails = {
            'id': company['company_id'].toString(),
            'name': company['company_name']?.toString() ?? 'Unknown Company',
            'date': companyDateStr,
            'location':
                company['job_location']?.toString() ?? 'Location not specified',
            'description': company['job_description']?.toString() ??
                'No description available',
            // Handle image_url carefully since it might be null
            'image': company['image'] != null
                ? serverurl + company['image']
                : "https://imgs.search.brave.com/k1t8JgjRYfQhusDtWN7xUa2E9wcewGf24E3CHYW4WJc/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9tZWRp/YS5pc3RvY2twaG90/by5jb20vaWQvMTg0/OTYyMDYxL3Bob3Rv/L2J1c2luZXNzLXRv/d2Vycy5qcGc_cz02/MTJ4NjEyJnc9MCZr/PTIwJmM9Z0xRTFE5/bG5mVzZPbkpWZTM5/cjUxNnZiWll1cE9v/RVBsN1BfMjJVbjZF/TT0"
          };
          print(companyDetails.toString());
          if (companyDate.isAfter(currentDate)) {
            upcomingCompanies.add(companyDetails);
          } else {
            recentCompanies.add(companyDetails);
          }
        }

        return {
          'upcoming': upcomingCompanies,
          'recent': recentCompanies,
        };
      } else if (response.statusCode == 401) {
        // If unauthorized, try to refresh token and retry
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          // Recursively call this method again with the new token
          return getCompanies(context);
        } else {
          _showErrorDialog(
              context, "Authentication failed", response.statusCode);
          return {
            'upcoming': [],
            'recent': [],
          };
        }
      } else {
        _showErrorDialog(
            context, "Failed to load companies", response.statusCode);
        return {
          'upcoming': [],
          'recent': [],
        };
      }
    } catch (e) {
      _showErrorDialog(context, "Error fetching companies: $e", null);
      return {
        'upcoming': [],
        'recent': [],
      };
    }
  }

  //update company field
  Future<bool> updateCompanyField(BuildContext context, int companyId,
      String fieldName, String newValue) async {
    print(
        "Updating company field: $fieldName to: $newValue for company ID: $companyId");

    try {
      // Retrieve JWT token
      String? accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        _showErrorDialog(context, "Error: No access token found", null);
        return false;
      }

      // Set up request headers
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // Create request
      var request = http.Request(
        'PATCH', // Use PATCH for partial updates
        Uri.parse('$serverurl/company/companies-detail-edit/$companyId/'),
      );

      // Create a simple JSON object with just the field being updated
      Map<String, dynamic> updateData = {
        fieldName: newValue,
      };

      request.body = json.encode(updateData);

      // Attach headers
      request.headers.addAll(headers);

      // Send request
      http.StreamedResponse streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));

      // Convert streamed response to standard response
      final response = await http.Response.fromStream(streamedResponse);

      print("Update request finished: ${response.body} ${response.statusCode}");

      if (response.statusCode == 200) {
        print("Company field updated successfully");
        return true;
      } else {
        _showErrorDialog(
            context, "Failed to update company field", response.statusCode);
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, "Error updating company field: $e", null);
      return false;
    }
  }

//update round status
  Future<bool> updateRounds(
      BuildContext context, int companyId, List<CompanyRound> rounds) async {
    print("Updating rounds for company ID: $companyId");

    try {
      // Retrieve JWT token
      String? accessToken = await _storage.read(key: 'access_token');

      // Add token refresh logic
      if (accessToken == null) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (!tokenRefreshed) {
          _showErrorDialog(
              context, "Error: Failed to refresh access token", null);
          return false; // Exit if token refresh fails
        }
        accessToken = await _storage.read(key: 'access_token'); // Get new token
      }

      // Set up request headers
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // Loop through rounds and update each one
      bool allSuccessful = true;
      for (int i = 0; i < rounds.length; i++) {
        CompanyRound round = rounds[i];

        // Create request with the new endpoint format
        var request = http.Request(
          'PATCH',
          Uri.parse(
              '$serverurl/company/interview-round/$companyId/${round.index}/'),
        );

        Map<String, dynamic> updateData = {
          'status': round.status,
        };

        request.body = json.encode(updateData);
        print('${request.body.toString()} for $companyId ${round.index} ');

        request.headers.addAll(headers);

        http.StreamedResponse streamedResponse =
            await request.send().timeout(const Duration(seconds: 10));

        // Convert streamed response to standard response
        final response = await http.Response.fromStream(streamedResponse);

        print(
            "Update round ${round.index} request finished: ${response.body} ${response.statusCode}");

        if (response.statusCode == 401) {
          // If Unauthorized, attempt to regenerate token and retry this specific round
          print("Token expired during round update. Refreshing token...");
          bool tokenRefreshed =
              await AuthenticationService().regenerateAccessToken(context);

          if (tokenRefreshed) {
            // Get new access token
            accessToken = await _storage.read(key: 'access_token');

            // Update headers with new token
            headers['Authorization'] = 'Bearer $accessToken';
            request.headers
                .update('Authorization', (value) => 'Bearer $accessToken');

            // Retry the request with new token
            streamedResponse =
                await request.send().timeout(const Duration(seconds: 10));
            final retryResponse =
                await http.Response.fromStream(streamedResponse);

            if (retryResponse.statusCode != 200) {
              _showErrorDialog(
                  context,
                  "Failed to update company round ${round.index} after token refresh",
                  retryResponse.statusCode);
              allSuccessful = false;
            }
          } else {
            _showErrorDialog(
                context, "Failed to refresh token while updating rounds", null);
            return false; // Exit early if token refresh fails
          }
        } else if (response.statusCode != 200) {
          _showErrorDialog(
              context,
              "Failed to update company round ${round.index}",
              response.statusCode);
          allSuccessful = false;
        }
      }

      if (allSuccessful) {
        print("All company rounds updated successfully");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, "Error updating company rounds: $e", null);
      return false;
    }
  }

  // Get single company details by ID
  Future<CompanyModel?> getCompanyDetails(
      BuildContext context, int companyId) async {
    print(companyId);
    try {
      // Get access token from secure storage
      String? accessToken = await _storage.read(key: 'access_token');

      // If token is null, attempt to regenerate it
      if (accessToken == null) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (!tokenRefreshed) {
          return null;
        }
        accessToken = await _storage.read(key: 'access_token');
      }

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      var url =
          Uri.parse('$serverurl/company/companies-detail-edit/$companyId/');
      var response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        print("Before : ${jsonData.toString()}");
        if (jsonData['interview_rounds'] != null) {
          List<CompanyRound> sortedRounds = CompanyRound.sortRounds(
            (jsonData['interview_rounds'] as List)
                .map((roundJson) => CompanyRound.fromJson(roundJson))
                .toList(),
          );

          // Convert sorted rounds back to JSON format
          jsonData['interview_rounds'] =
              sortedRounds.map((round) => round.toJson()).toList();
        }
        print("after : ${jsonData.toString()}");

        return CompanyModel.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        // If unauthorized, try to refresh token and retry
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          // Recursively call this method again with the new token
          return getCompanyDetails(context, companyId);
        } else {
          _showErrorDialog(
              context, "Authentication failed", response.statusCode);
          return null;
        }
      } else {
        _showErrorDialog(
            context, "Failed to get company details", response.statusCode);
        return null;
      }
    } catch (e) {
      _showErrorDialog(context, "Error fetching company details: $e", null);
      return null;
    }
  }

  // Add company method
  Future<bool> addCompany(BuildContext context, CompanyModel company) async {
    print("Calling addCompany... ${company.toJson().toString()}");

    try {
      // Retrieve JWT token
      String? accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        _showErrorDialog(context, "Error: No access token found", null);
        return false;
      }

      // Set up request headers
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // Create request
      var request = http.Request(
        'POST',
        Uri.parse('$serverurl/company/companies-create&list/'),
      );

      // Convert model to JSON using toJson method
      request.body = json.encode(company.toJson());

      // Attach headers
      request.headers.addAll(headers);

      // Send request
      http.StreamedResponse streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));

      // Convert streamed response to standard response
      final response = await http.Response.fromStream(streamedResponse);

      print("Request finished ${response.body} ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Company added successfully");
        return true;
      } else {
        _showErrorDialog(context, "Failed to add company", response.statusCode);
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, "Error adding company: $e", null);
      return false;
    }
  }

  Future<bool> registerstudent(
      BuildContext context, int companyId, String studentId) async {
    try {
      // Retrieve JWT token
      String? accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (!tokenRefreshed) {
          _showErrorDialog(
              context, "Authentication failed. Please log in again.", null);
          return false;
        }
        accessToken = await _storage.read(key: 'access_token');
      }

      // Set up request headers
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      // API Endpoint (Replace with actual API URL)
      var url = Uri.parse('$serverurl/company/company-registration/');

      // Request Body
      var body = json.encode(
          {"input_student_id": studentId, "input_company_id": companyId});

      // Make the POST request
      var response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      // Handle responses
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Student added successfully.");
        return true;
      } else if (response.statusCode == 400) {
        _showErrorDialog(context,
            "Invalid request. Please check the details and try again.", 400);
      } else if (response.statusCode == 401) {
        bool tokenRefreshed =
            await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          return registerstudent(
              context, companyId, studentId); // Retry with new token
        } else {
          _showErrorDialog(
              context, "Session expired. Please log in again.", 401);
        }
      } else if (response.statusCode == 403) {
        _showErrorDialog(
            context, "You do not have permission to perform this action.", 403);
      } else if (response.statusCode == 404) {
        _showErrorDialog(context, "Company or student not found.", 404);
      } else {
        _showErrorDialog(context, "Failed to add student. Please try again.",
            response.statusCode);
      }
    } catch (e) {
      _showErrorDialog(context, "An error occurred: $e", null);
    }
    return false;
  }

  void _showErrorDialog(BuildContext context, String message, int? statusCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(statusCode != null
            ? "$message\nStatus Code: $statusCode"
            : message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
