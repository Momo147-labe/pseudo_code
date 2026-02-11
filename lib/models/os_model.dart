import 'package:flutter/material.dart';

enum ProcessState { andReady, running, waiting, terminated }

class OSProcess {
  final String id;
  final String name;
  final int arrivalTime;
  final int burstTime;
  final Color color;
  int remainingTime;
  int completionTime = 0;
  int turnAroundTime = 0;
  int waitingTime = 0;
  ProcessState state = ProcessState.andReady;

  OSProcess({
    required this.id,
    required this.name,
    required this.arrivalTime,
    required this.burstTime,
    this.color = Colors.blue,
  }) : remainingTime = burstTime;

  OSProcess copyWith({
    ProcessState? state,
    int? remainingTime,
    int? completionTime,
    int? turnAroundTime,
    int? waitingTime,
  }) {
    final copy = OSProcess(
      id: id,
      name: name,
      arrivalTime: arrivalTime,
      burstTime: burstTime,
      color: color,
    );
    copy.remainingTime = remainingTime ?? this.remainingTime;
    copy.completionTime = completionTime ?? this.completionTime;
    copy.turnAroundTime = turnAroundTime ?? this.turnAroundTime;
    copy.waitingTime = waitingTime ?? this.waitingTime;
    copy.state = state ?? this.state;
    return copy;
  }
}

enum SchedulingAlgorithm { fcfs, sjf, roundRobin, priority }

class SimulationStep {
  final int time;
  final List<OSProcess> processes;
  final String? runningProcessId;
  final String description;

  SimulationStep({
    required this.time,
    required this.processes,
    this.runningProcessId,
    required this.description,
  });
}
