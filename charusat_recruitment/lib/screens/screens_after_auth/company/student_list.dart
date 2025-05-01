import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:charusat_recruitment/const.dart';
import 'package:flutter/material.dart';

import '../../../service/common_service/auth_service.dart';

class StudentListManager extends StatefulWidget {
  final String companyName;
  const StudentListManager({super.key, required this.companyName});

  @override
  State<StudentListManager> createState() => _StudentListManagerState();
}

class _StudentListManagerState extends State<StudentListManager> {
  List<Map<String, String>> _students = [];
  final List<bool> _selected = [];
  bool _isLoading = true;  // Track loading state
  String? _errorMessage;   // Track error messages
  final TextEditingController _searchController = TextEditingController();
  final bool _isShortlistMode = (role == 'faculty');
  bool _isSubmitting = false;
  String _searchQuery = "";

  Future<void> submitUnselectedStudents() async {
    setState(() {
      _isSubmitting = true;
    });
    
    print("Submitting unselected students...");
    
    // Get access token from secure storage
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    String? accessToken = await secureStorage.read(key: 'access_token');
    
    // Check if token exists, refresh if needed
    if (accessToken == null) {
      bool tokenRefreshed = await AuthenticationService().regenerateAccessToken(context);
      if (!tokenRefreshed) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = "Authentication failed";
        });
        return; // Redirected to login if refresh fails
      }
      accessToken = await secureStorage.read(key: 'access_token'); // Get new token
    }
    
    // Get IDs of unselected students
    List<String> unselectedIds = [];
    for (int i = 0; i < _students.length; i++) {
      if (!_selected[i]) {
        unselectedIds.add(_students[i]['id']!);
      }
    }
    
    // If no students are unselected, show message and return
    if (unselectedIds.isEmpty) {
      setState(() {
        _isSubmitting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All students are selected"))
        );
      });
      return;
    }
    
    // Set headers with token
    var headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    // Prepare request body
    var body = json.encode({
      "student_ids": unselectedIds
    });
    
    try {
      var response = await http
          .post(
            Uri.parse('$serverurl/company/delete-sortlisted/${widget.companyName}/'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Unselected students submitted successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unselected students removed successfully"))
        );
       Navigator.of(context).pop();
      } else if (response.statusCode == 401) {
        // If Unauthorized, attempt to regenerate token and retry
        bool tokenRefreshed = await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          await submitUnselectedStudents(); // Retry submission
        } else {
          setState(() {
            _isSubmitting = false;
            _errorMessage = "Session expired. Please login again.";
          });
        }
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = "Error updating students";
        });
      }
    } catch (e) {
      print("Error submitting unselected students: $e");
      setState(() {
        _isSubmitting = false;
        _errorMessage = "Error updating students";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print("inside a student list");
    getStudents();
  }

  Future<void> getStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    print("Fetching students...");
    
    // Get access token from secure storage
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? accessToken = await secureStorage.read(key: 'access_token');
    
    // Check if token exists, refresh if needed
    if (accessToken == null) {
      bool tokenRefreshed = await AuthenticationService().regenerateAccessToken(context);
      if (!tokenRefreshed) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Authentication failed";
        });
        return; // Redirected to login if refresh fails
      }
      accessToken = await secureStorage.read(key: 'access_token'); // Get new token
    }
    
    // Set headers with token
    var headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    
    try {
      var response = await http
          .get(
            Uri.parse('$serverurl/company/sortlisted-students/${widget.companyName}/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      
      print("Response received ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> responseData = json.decode(response.body);
        print("Students data: $responseData");
        
        if (responseData.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = "No students found"; // Show message when no students are found
          });
          return;
        }
        
        List<Map<String, String>> students = responseData.map<Map<String, String>>((item) {
          return {
            'id': item['student_id'].toString(),
            'name': item['student_name'].toString()
          };
        }).toList();
        
        setState(() {
          _students = students;
          _selected.clear();
          // Initialize all students as selected by default
          _selected.addAll(List.generate(_students.length, (_) => true));
          _isLoading = false; // Data loaded successfully
        });
      } else if (response.statusCode == 401) {
        // If Unauthorized, attempt to regenerate token and retry
        bool tokenRefreshed = await AuthenticationService().regenerateAccessToken(context);
        if (tokenRefreshed) {
          await getStudents(); // Retry fetching students
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "Session expired. Please login again.";
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading students"; // Handle API error
        });
      }
    } catch (e) {
      print("Error fetching students: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading students"; // Handle request failure
      });
    }
  }
  
  List<Map<String, String>> _filteredStudents() {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    return _students.where((student) {
      final id = student["id"]!.toLowerCase();
      final name = student["name"]!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return id.contains(query) || name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isShortlistMode ? "Shortlist" : "Student List",
          style: const TextStyle(fontFamily: "pop"),
        ),
        backgroundColor: const Color(0xff0f1d2c),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 16)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Search by ID or Name",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final originalIndex = _students.indexWhere((s) => s['id'] == student['id']);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                student["id"]!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f1d2c)),
                              ),
                              subtitle: Text(
                                student["name"]!,
                                style: const TextStyle(color: Color(0xff0f1d2c)),
                              ),
                              trailing: _isShortlistMode
                                  ? Checkbox(
                                      value: originalIndex < _selected.length ? _selected[originalIndex] : true,
                                      onChanged: (value) {
                                        if (originalIndex < _selected.length) {
                                          setState(() {
                                            _selected[originalIndex] = value ?? true;
                                          });
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _isShortlistMode && _students.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSubmitting ? null : submitUnselectedStudents,
              backgroundColor: const Color(0xff0f1d2c),
              label: const Text(
                "Done",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.done),
            )
          : null,
    );
  }

  void _showShortlistDialog(List<Map<String, String>> shortlistedStudents) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Shortlisted Students", style: TextStyle(color: Color(0xff0f1d2c))),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: shortlistedStudents.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    "${shortlistedStudents[index]["id"]!}  | ${shortlistedStudents[index]["name"]!}",
                    style: const TextStyle(color: Color(0xff0f1d2c)),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}