import 'package:flutter/material.dart';
import 'package:presentation_displays/secondary_display.dart';

class ExternalDashboardView extends StatefulWidget {
  const ExternalDashboardView({super.key});

  @override
  State<ExternalDashboardView> createState() => _ExternalDashboardViewState();
}

class _ExternalDashboardViewState extends State<ExternalDashboardView> {
  String _exerciseName = "Ready";
  String _reps = "0";
  String _feedback = "Waiting for workout...";
  bool _isGoodPose = false;

  @override
  Widget build(BuildContext context) {
    return SecondaryDisplay(
      callback: (dynamic argument) {
        // Handle incoming data
        if (argument is Map<String, dynamic>) {
          setState(() {
            if (argument.containsKey('exercise')) {
              _exerciseName = argument['exercise'];
            }
            if (argument.containsKey('reps')) {
              _reps = argument['reps'].toString();
            }
            if (argument.containsKey('feedback')) {
              _feedback = argument['feedback'];
            }
            if (argument.containsKey('isGoodPose')) {
              _isGoodPose = argument['isGoodPose'];
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.blueGrey.shade900],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  _exerciseName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Main Counter
              Expanded(
                child: Center(
                  child: Text(
                    _reps,
                    style: TextStyle(
                      color: _isGoodPose ? Colors.greenAccent : Colors.white,
                      fontSize: 200,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: _isGoodPose
                              ? Colors.green.withOpacity(0.5)
                              : Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Feedback Area
              Container(
                padding: const EdgeInsets.all(48),
                color: _isGoodPose
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Text(
                  _feedback,
                  style: TextStyle(
                    color: _isGoodPose
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Bottom Logo
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "CoreFit AI Studio",
                  style: TextStyle(color: Colors.white24, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
