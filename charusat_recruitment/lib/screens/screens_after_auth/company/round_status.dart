import 'package:charusat_recruitment/screens/screens_after_auth/company/student_list.dart';
import 'package:flutter/material.dart';
import 'package:charusat_recruitment/screens/models/company_round_model.dart';
import 'package:charusat_recruitment/service/company_service/company_service.dart';

class RoundStatus extends StatefulWidget {
  final int companyId;
  final String companyName;
  final List<CompanyRound> rounds;

  const RoundStatus({
    super.key,
    required this.companyId,
    required this.rounds,
    required this.companyName,
  });

  @override
  State<RoundStatus> createState() => _RoundStatusState();
}

class _RoundStatusState extends State<RoundStatus> {
  final CompanyService _companyService = CompanyService();
  List<CompanyRound> _rounds = [];
  bool _isLoading = true;
  late int _companyId;
  late String _companyName = '';

  @override
  void initState() {
    print("inside a Round update management");

    super.initState();
    _companyName = widget.companyName;
    _companyId = widget.companyId;
    _rounds = List.from(widget.rounds);
    _isLoading = false;
  }

  // Method to cycle through round statuses: pending -> running -> compeleted -> pending
  void _cycleRoundStatus(int index) {
    setState(() {
      String currentStatus = _rounds[index].status.toLowerCase();
      String newStatus;

      if (currentStatus == "pending") {
        newStatus = "running";
      } else if (currentStatus == "running") {
        newStatus = "compeleted"; // Using the typo as mentioned
      } else {
        newStatus = "pending";
      }

      _rounds[index] = CompanyRound(
          roundName: _rounds[index].roundName, status: newStatus, index: index);
      print("status updated ${_rounds[index].toJson()}");
    });
  }

  // Method to update rounds
  Future<void> _updateRounds() async {
    setState(() {
      _isLoading = true;
    });

    // Update indices for all rounds before submitting
    for (int i = 0; i < _rounds.length; i++) {
      _rounds[i] = CompanyRound(
          roundName: _rounds[i].roundName, status: _rounds[i].status, index: i);
    }

    // Call the service to update rounds
    bool success =
        await _companyService.updateRounds(context, _companyId, _rounds);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rounds updated successfully!')),
      );

      // Navigate back to the previous screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => StudentListManager(
                  companyName: _companyName ,
                )),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update rounds. Please try again.')),
      );
    }
  }

  // Get appropriate color based on status
  Color _getStatusColor(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus == "compeleted" || lowerStatus == "completed") {
      return const Color(0xff0f5a36); // Green color for completed rounds
    } else if (lowerStatus == "running") {
      return const Color(0xff1976D2); // Blue color for running rounds
    } else {
      return const Color(0xff0f1d2c); // Dark blue for pending rounds
    }
  }

  // Get appropriate icon based on status
  IconData _getStatusIcon(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus == "compeleted" || lowerStatus == "completed") {
      return Icons.check_circle;
    } else if (lowerStatus == "running") {
      return Icons.autorenew;
    } else {
      return Icons.pending_actions;
    }
  }

  // Get appropriate icon color based on status
  Color _getIconColor(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus == "compeleted" || lowerStatus == "completed") {
      return Colors.white;
    } else if (lowerStatus == "running") {
      return Colors.lightBlueAccent;
    } else {
      return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Round Status Manager",
          style: TextStyle(fontFamily: "pop"),
        ),
        backgroundColor: const Color(0xff0f1d2c),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Manage Round Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: "pop",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      _statusIndicator("Pending", const Color(0xff0f1d2c)),
                      const SizedBox(width: 16),
                      _statusIndicator("Running", const Color(0xff1976D2)),
                      const SizedBox(width: 16),
                      _statusIndicator("Completed", const Color(0xff0f5a36)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _rounds.length,
                    onReorder: (oldIndex, newIndex) {
                      // Prevent reordering first and last items
                      if (oldIndex == 0 ||
                          oldIndex == _rounds.length - 1 ||
                          newIndex == 0 ||
                          (newIndex == _rounds.length &&
                              oldIndex != _rounds.length - 1)) {
                        return;
                      }

                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _rounds.removeAt(oldIndex);
                        _rounds.insert(newIndex, item);

                        // Update indices for all rounds after reordering
                        for (int i = 0; i < _rounds.length; i++) {
                          _rounds[i] = CompanyRound(
                              roundName: _rounds[i].roundName,
                              status: _rounds[i].status,
                              index: i);
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final bool isStaticItem =
                          index == 0 || index == _rounds.length - 1;

                      return Card(
                        key: ValueKey(
                            _rounds[index].roundName + index.toString()),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: isStaticItem
                            ? Colors.white
                            : _getStatusColor(_rounds[index].status),
                        child: ListTile(
                          title: Text(
                            _rounds[index].roundName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontFamily: "pop",
                              color: isStaticItem
                                  ? const Color(0xff0f1d2c)
                                  : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            _rounds[index].status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isStaticItem
                                  ? const Color(0xff0f1d2c)
                                  : Colors.white70,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status toggle button
                              IconButton(
                                icon: Icon(
                                  _getStatusIcon(_rounds[index].status),
                                  color: _getIconColor(_rounds[index].status),
                                ),
                                onPressed: () => _cycleRoundStatus(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Update Rounds Button
                Center(
                  child: ElevatedButton(
                    onPressed: _updateRounds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0f1d2c),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Update Rounds",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "pop",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // Helper method to create status indicator
  Widget _statusIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: "pop",
          ),
        ),
      ],
    );
  }
}
