import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/os_model.dart';

enum OSStudioMode { simulation, theory }

enum SimulationCategory {
  scheduling,
  io,
  states,
  internal,
  sync,
  memoryAdvanced,
  fileSystem,
  security,
  network,
  virtualization,
}

class OSQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  OSQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class OSFlashcard {
  final String term;
  final String definition;

  OSFlashcard({required this.term, required this.definition});
}

class OSProvider with ChangeNotifier {
  // --- Simulation Global State ---
  OSStudioMode _activeMode = OSStudioMode.simulation;
  SimulationCategory _activeCategory = SimulationCategory.scheduling;

  // --- Scheduling Simulation State ---
  List<OSProcess> _processes = [];
  SchedulingAlgorithm _algorithm = SchedulingAlgorithm.fcfs;
  List<SimulationStep> _steps = [];
  int _currentStepIndex = -1;
  bool _isPlaying = false;
  Timer? _playTimer;

  // --- I/O Simulation State ---
  String? _activeIOData; // Label of the data being moved
  String? _ioSource; // "Keyboard", "Micro", etc.
  String? _ioTarget; // "CPU", "RAM", "Screen"
  double _ioProgress = 0; // 0 to 1 for animation

  // --- Process State Simulation State ---
  String _processCurrentState = "Prêt"; // "Prêt", "Élu", "Bloqué"
  String? _stateLastTransition;

  // --- Theory State ---
  Map<String, dynamic>? _theoryData;
  bool _isLoadingTheory = false;

  // --- Quiz State ---
  List<OSQuizQuestion> _quizQuestions = [];
  int _currentQuizIndex = 0;
  int _quizScore = 0;
  bool _quizFinished = false;
  bool _lastAnswerCorrect = false;
  bool _showExplanation = false;

  // --- Internal Architecture State ---
  Map<int, String?> _ramMapping = {}; // Address -> Process ID
  String _instructionStep = "IDLE"; // "IDLE", "FETCH", "DECODE", "EXECUTE"
  String? _activeBus; // "ADDRESS", "DATA"

  // Advanced Architecture State
  int _pc = 0; // Program Counter
  String _ir = "NOP"; // Instruction Register (NOP: No Operation)
  int _acc = 0; // Accumulator

  List<String> _pipeline = [
    "IDLE",
    "IDLE",
    "IDLE",
  ]; // Fetch, Decode, Execute stages

  bool _l1Hit = false;
  bool _l2Hit = false;
  bool _isIrqActive = false;
  String _lastIrqSource = "";

  // --- Flashcards State ---
  List<OSFlashcard> _flashcards = [];
  int _currentFlashcardIndex = 0;
  bool _isFlipped = false;

  // --- Synchronization Simulation State ---
  int _semaphoreValue = 1;
  List<String> _syncLog = [];

  // --- Memory Advanced State ---
  Map<int, int> _pageTable = {}; // Page -> Frame

  // --- File System State ---
  String _currentFilePath = "/root";
  List<String> _fileSystemNodes = ["bin", "home", "usr", "etc", "var"];

  // --- Security State ---
  Map<String, String> _permissions = {
    "user_data": "r--",
    "system": "rwx",
    "config": "rw-",
  };

  // --- Network State ---
  int _packetHops = 0;
  String _networkStatus = "IDLE";

  // --- Virtualization State ---
  int _vmCount = 0;
  bool _hypervisorActive = false;

  List<OSProcess> get processes => _processes;
  SchedulingAlgorithm get algorithm => _algorithm;
  List<SimulationStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  bool get isPlaying => _isPlaying;

  OSStudioMode get activeMode => _activeMode;
  SimulationCategory get activeCategory => _activeCategory;

  // I/O Getters
  String? get activeIOData => _activeIOData;
  String? get ioSource => _ioSource;
  String? get ioTarget => _ioTarget;
  double get ioProgress => _ioProgress;

  // State Getters
  String get processCurrentState => _processCurrentState;
  String? get stateLastTransition => _stateLastTransition;

  // Internal Getters
  Map<int, String?> get ramMapping => _ramMapping;
  String get instructionStep => _instructionStep;
  String? get activeBus => _activeBus;

  int get pc => _pc;
  String get ir => _ir;
  int get acc => _acc;
  List<String> get pipeline => _pipeline;
  bool get l1Hit => _l1Hit;
  bool get l2Hit => _l2Hit;
  bool get isIrqActive => _isIrqActive;
  String get lastIrqSource => _lastIrqSource;
  int get vmCount => _vmCount;
  bool get hypervisorActive => _hypervisorActive;

  // Additional Getters for new simulations
  int get semaphoreValue => _semaphoreValue;
  List<String> get syncLog => _syncLog;
  Map<int, int> get pageTable => _pageTable;
  String get currentFilePath => _currentFilePath;
  List<String> get fileSystemNodes => _fileSystemNodes;
  Map<String, String> get permissions => _permissions;
  int get packetHops => _packetHops;
  String get networkStatus => _networkStatus;

  Map<String, dynamic>? get theoryData => _theoryData;
  bool get isLoadingTheory => _isLoadingTheory;

  void setActiveCategory(SimulationCategory category) {
    _activeCategory = category;
    notifyListeners();
  }

  // Quiz Getters
  List<OSQuizQuestion> get quizQuestions => _quizQuestions;
  int get currentQuizIndex => _currentQuizIndex;
  int get quizScore => _quizScore;
  bool get quizFinished => _quizFinished;
  bool get lastAnswerCorrect => _lastAnswerCorrect;
  bool get showExplanation => _showExplanation;

  // Flashcards Getters
  List<OSFlashcard> get flashcards => _flashcards;
  int get currentFlashcardIndex => _currentFlashcardIndex;
  bool get isFlipped => _isFlipped;
  OSFlashcard? get currentFlashcard =>
      (_flashcards.isNotEmpty && _currentFlashcardIndex < _flashcards.length)
      ? _flashcards[_currentFlashcardIndex]
      : null;

  OSQuizQuestion? get currentQuizQuestion =>
      (_quizQuestions.isNotEmpty && _currentQuizIndex < _quizQuestions.length)
      ? _quizQuestions[_currentQuizIndex]
      : null;

  SimulationStep? get currentStep =>
      (_currentStepIndex >= 0 && _currentStepIndex < _steps.length)
      ? _steps[_currentStepIndex]
      : null;

  void setActiveMode(OSStudioMode mode) {
    _activeMode = mode;
    if (mode == OSStudioMode.theory && _theoryData == null) {
      loadTheoryData();
    }
    notifyListeners();
  }

  Future<void> loadTheoryData() async {
    _isLoadingTheory = true;
    notifyListeners();
    try {
      final String response = await rootBundle.loadString(
        'assets/resume_os.json',
      );
      _theoryData = json.decode(response);
    } catch (e) {
      debugPrint("Erreur lors du chargement de la théorie OS: $e");
    } finally {
      _isLoadingTheory = false;
      _generateQuiz();
      _generateFlashcards();
      notifyListeners();
    }
  }

  void _generateFlashcards() {
    if (_theoryData == null) return;
    _flashcards = [];

    // Extract from definitions_de_base
    final base = _theoryData!['definitions_de_base'];
    if (base != null) {
      _flashcards.add(
        OSFlashcard(term: "Informatique", definition: base['informatique']),
      );
      _flashcards.add(
        OSFlashcard(term: "Ordinateur", definition: base['ordinateur']),
      );
    }

    // Extract from memory concepts
    final mem = _theoryData!['gestion_memoire'];
    if (mem != null && mem['concepts_cles'] != null) {
      for (var c in mem['concepts_cles']) {
        _flashcards.add(
          OSFlashcard(term: c['nom'], definition: c['description']),
        );
      }
    }
  }

  void toggleFlashcard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void nextFlashcard() {
    if (_flashcards.isEmpty) return;
    _currentFlashcardIndex = (_currentFlashcardIndex + 1) % _flashcards.length;
    _isFlipped = false;
    notifyListeners();
  }

  void previousFlashcard() {
    if (_flashcards.isEmpty) return;
    _currentFlashcardIndex =
        (_currentFlashcardIndex - 1 + _flashcards.length) % _flashcards.length;
    _isFlipped = false;
    notifyListeners();
  }

  void loadPresetSimulation(SchedulingAlgorithm algo) {
    _processes = [];
    _activeMode = OSStudioMode.simulation;
    _algorithm = algo;

    if (algo == SchedulingAlgorithm.fcfs) {
      _processes = [
        OSProcess(
          id: "P1",
          name: "P1",
          arrivalTime: 0,
          burstTime: 4,
          color: Colors.blue,
        ),
        OSProcess(
          id: "P2",
          name: "P2",
          arrivalTime: 2,
          burstTime: 3,
          color: Colors.green,
        ),
        OSProcess(
          id: "P3",
          name: "P3",
          arrivalTime: 5,
          burstTime: 2,
          color: Colors.orange,
        ),
      ];
    } else if (algo == SchedulingAlgorithm.sjf) {
      _processes = [
        OSProcess(
          id: "P1",
          name: "P1",
          arrivalTime: 0,
          burstTime: 5,
          color: Colors.blue,
        ),
        OSProcess(
          id: "P2",
          name: "P2",
          arrivalTime: 1,
          burstTime: 2,
          color: Colors.green,
        ),
        OSProcess(
          id: "P3",
          name: "P3",
          arrivalTime: 2,
          burstTime: 1,
          color: Colors.orange,
        ),
      ];
    } else if (algo == SchedulingAlgorithm.roundRobin) {
      _processes = [
        OSProcess(
          id: "P1",
          name: "P1",
          arrivalTime: 0,
          burstTime: 8,
          color: Colors.blue,
        ),
        OSProcess(
          id: "P2",
          name: "P2",
          arrivalTime: 1,
          burstTime: 4,
          color: Colors.green,
        ),
        OSProcess(
          id: "P3",
          name: "P3",
          arrivalTime: 2,
          burstTime: 9,
          color: Colors.orange,
        ),
      ];
    }

    runSimulation();
    notifyListeners();
  }

  // --- I/O Simulation Logic ---
  Future<void> simulateIO(String source, String data, String target) async {
    _ioSource = source;
    _activeIOData = data;
    _ioTarget = target;
    _ioProgress = 0;
    notifyListeners();

    // Simple manual animation simulation (or we'll use AnimationController in UI)
    // Here we just set the state to trigger the UI animation
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _ioProgress = i / 10.0;
      notifyListeners();
    }

    await Future.delayed(const Duration(seconds: 1));
    _activeIOData = null;
    notifyListeners();
  }

  // --- State Transition Logic ---
  void transitionTo(String newState) {
    _stateLastTransition = "$_processCurrentState -> $newState";
    _processCurrentState = newState;
    notifyListeners();
  }

  // --- Internal Logic ---
  Future<void> cycleInstruction() async {
    const steps = ["FETCH", "DECODE", "EXECUTE", "IDLE"];
    for (var step in steps) {
      _instructionStep = step;
      _activeBus = (step == "FETCH")
          ? "ADDRESS"
          : (step == "EXECUTE" ? "DATA" : null);
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void initializeRAM() {
    _ramMapping = {
      0x00: "Kernel",
      0x10: null,
      0x20: null,
      0x30: null,
      0x40: "OS_Shell",
    };
    notifyListeners();
  }

  void allocateRAM(int address, String processId) {
    _ramMapping[address] = processId;
    notifyListeners();
  }

  // --- Advanced Architecture Logic ---
  Future<void> triggerInterrupt(String source) async {
    _isIrqActive = true;
    _lastIrqSource = source;
    notifyListeners();

    // Simulate ISR (Interrupt Service Routine) saving context
    await Future.delayed(const Duration(seconds: 2));

    _isIrqActive = false;
    notifyListeners();
  }

  Future<void> runPipelineStep() async {
    // Shift pipeline: Execute <- Decode <- Fetch <- New
    _pipeline = [
      "LOAD 0x${(_pc * 4).toRadixString(16)}", // New Fetch
      _pipeline[0], // Moving to Decode
      _pipeline[1], // Moving to Execute
    ];

    // Update Registers based on current "execution"
    if (_pipeline[2].startsWith("LOAD")) {
      _ir = _pipeline[2];
      _pc++;
      // Randomly simulate cache hit for demo
      _l1Hit = _pc % 2 == 0;
      _l2Hit = !_l1Hit && _pc % 3 == 0;
      _acc += 10;
    }

    notifyListeners();

    // Reset cache indicators after a delay
    await Future.delayed(const Duration(milliseconds: 1500));
    _l1Hit = false;
    _l2Hit = false;
    notifyListeners();
  }

  // --- Synchronization Logic ---
  void setSemaphore(int val) {
    _semaphoreValue = val;
    _syncLog.insert(0, "Sémaphore réglé à $val");
    notifyListeners();
  }

  Future<void> simulateSyncAccess(String processName) async {
    _syncLog.insert(0, "$processName demande l'accès...");
    notifyListeners();

    if (_semaphoreValue > 0) {
      _semaphoreValue--;
      _syncLog.insert(
        0,
        "$processName a acquis le verrou. (S=$_semaphoreValue)",
      );
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      _semaphoreValue++;
      _syncLog.insert(
        0,
        "$processName a libéré le verrou. (S=$_semaphoreValue)",
      );
    } else {
      _syncLog.insert(0, "$processName est BLOQUÉ (S=0)");
    }
    notifyListeners();
  }

  // --- Memory Advanced Logic ---
  void initializePageTable() {
    _pageTable = {0: 5, 1: 12, 2: 8, 3: 20};
    notifyListeners();
  }

  int? translateAddress(int page) {
    return _pageTable[page];
  }

  // --- File System Logic ---
  void navigateTo(String node) {
    _currentFilePath = "/root/$node";
    notifyListeners();
  }

  // --- Security Logic ---
  void togglePermission(String resource, int index) {
    String current = _permissions[resource]!;
    List<String> parts = current.split('');
    String targetChar = (index == 0) ? 'r' : (index == 1 ? 'w' : 'x');

    if (parts[index] == '-') {
      parts[index] = targetChar;
    } else {
      parts[index] = '-';
    }

    _permissions[resource] = parts.join('');
    notifyListeners();
  }

  // --- Network Logic ---
  Future<void> sendNetworkPacket() async {
    _networkStatus = "ENVOI...";
    _packetHops = 0;
    notifyListeners();

    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      _packetHops = i;
      notifyListeners();
    }

    _networkStatus = "REÇU";
    await Future.delayed(const Duration(seconds: 1));
    _networkStatus = "IDLE";
    notifyListeners();
  }

  // --- Virtualization Logic ---
  void toggleHypervisor() {
    _hypervisorActive = !_hypervisorActive;
    if (!_hypervisorActive) _vmCount = 0;
    notifyListeners();
  }

  void addVM() {
    if (_hypervisorActive && _vmCount < 4) {
      _vmCount++;
      notifyListeners();
    }
  }

  void _generateQuiz() {
    if (_theoryData == null) return;

    _quizQuestions = [
      OSQuizQuestion(
        question: "Qu'est-ce qu'un système d'exploitation ?",
        options: [
          "Un matériel physique de l'ordinateur",
          "Un ensemble de logiciels permettant d'utiliser l'ordinateur",
          "Un virus informatique",
          "Une application de traitement de texte",
        ],
        correctIndex: 1,
        explanation:
            "Le SE est l'intermédiaire indispensable entre l'homme et la machine.",
      ),
      OSQuizQuestion(
        question: "Quelle génération a introduit les microprocesseurs ?",
        options: ["2ème", "3ème", "4ème", "5ème"],
        correctIndex: 2,
        explanation:
            "La 4ème génération est marquée par l'invention des microprocesseurs, le 'cerveau' de l'ordinateur.",
      ),
      OSQuizQuestion(
        question: "Que signifie RAM en français ?",
        options: [
          "Mémoire à lecture seule",
          "Mémoire de masse",
          "Mémoire à accès aléatoire (ou vive)",
          "Mémoire virtuelle",
        ],
        correctIndex: 2,
        explanation:
            "RAM signifie Random Access Memory, soit Mémoire à Accès Aléatoire.",
      ),
      OSQuizQuestion(
        question:
            "Quel algorithme d'ordonnancement fonctionne sur le principe 'le premier arrivé est le premier servi' ?",
        options: ["SJF", "Round Robin", "FCFS", "Priorité"],
        correctIndex: 2,
        explanation:
            "FCFS (First-Come, First-Served) traite les processus dans leur ordre d'arrivée.",
      ),
      OSQuizQuestion(
        question: "Qu'est-ce que la mémoire virtuelle (swap) ?",
        options: [
          "Une mémoire plus rapide que la RAM",
          "Un espace sur le disque dur utilisé quand la RAM est pleine",
          "Une clé USB utilisée comme RAM",
          "Une mémoire qui s'efface quand on éteint l'ordinateur",
        ],
        correctIndex: 1,
        explanation:
            "Le swap permet d'étendre artificiellement la RAM en utilisant le disque dur.",
      ),
    ];
  }

  void startQuiz() {
    _currentQuizIndex = 0;
    _quizScore = 0;
    _quizFinished = false;
    _showExplanation = false;
    notifyListeners();
  }

  void answerQuestion(int index) {
    if (_quizFinished || _showExplanation) return;

    _lastAnswerCorrect =
        (index == _quizQuestions[_currentQuizIndex].correctIndex);
    if (_lastAnswerCorrect) _quizScore++;

    _showExplanation = true;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuizIndex < _quizQuestions.length - 1) {
      _currentQuizIndex++;
      _showExplanation = false;
    } else {
      _quizFinished = true;
    }
    notifyListeners();
  }

  void addProcess(OSProcess process) {
    //... (existing methods remain the same)
    _processes.add(process);
    _resetSimulation();
    notifyListeners();
  }

  void removeProcess(String id) {
    _processes.removeWhere((p) => p.id == id);
    _resetSimulation();
    notifyListeners();
  }

  void setAlgorithm(SchedulingAlgorithm algo) {
    _algorithm = algo;
    _resetSimulation();
    notifyListeners();
  }

  void _resetSimulation() {
    _stop();
    _steps = [];
    _currentStepIndex = -1;
    _isPlaying = false;
  }

  void runSimulation() {
    _stop();
    _steps = [];
    if (_processes.isEmpty) return;

    switch (_algorithm) {
      case SchedulingAlgorithm.fcfs:
        _simulateFCFS();
        break;
      case SchedulingAlgorithm.sjf:
        _simulateSJF();
        break;
      default:
        _simulateFCFS();
    }

    if (_steps.isNotEmpty) {
      _currentStepIndex = 0;
    }
    notifyListeners();
  }

  void _simulateFCFS() {
    List<OSProcess> sortedProcesses = List.from(_processes)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));

    int currentTime = 0;
    List<OSProcess> currentStates = sortedProcesses
        .map((p) => p.copyWith(state: ProcessState.andReady))
        .toList();

    for (var i = 0; i < currentStates.length; i++) {
      var p = currentStates[i];

      while (currentTime < p.arrivalTime) {
        _steps.add(
          SimulationStep(
            time: currentTime,
            processes: currentStates.map((pro) => pro.copyWith()).toList(),
            description: "Le processeur est inactif (Attente de processus)",
          ),
        );
        currentTime++;
      }

      p.state = ProcessState.running;
      for (int t = 0; t < p.burstTime; t++) {
        _steps.add(
          SimulationStep(
            time: currentTime,
            processes: currentStates.map((pro) => pro.copyWith()).toList(),
            runningProcessId: p.id,
            description:
                "Exécution de ${p.name} (Étape ${t + 1}/${p.burstTime})",
          ),
        );
        currentTime++;
        p.remainingTime--;
      }

      p.state = ProcessState.terminated;
      p.completionTime = currentTime;
      p.turnAroundTime = p.completionTime - p.arrivalTime;
      p.waitingTime = p.turnAroundTime - p.burstTime;
    }

    // Final state
    _steps.add(
      SimulationStep(
        time: currentTime,
        processes: currentStates.map((pro) => pro.copyWith()).toList(),
        description: "Simulation terminée",
      ),
    );
  }

  void _simulateSJF() {
    // Non-preemptive Shortest Job First
    List<OSProcess> remaining = _processes
        .map((p) => p.copyWith(state: ProcessState.andReady))
        .toList();
    List<OSProcess> finished = [];
    int currentTime = 0;

    while (remaining.isNotEmpty) {
      // Find available processes
      var available = remaining
          .where((p) => p.arrivalTime <= currentTime)
          .toList();

      if (available.isEmpty) {
        // Find next arrival
        int nextArrival = remaining
            .map((p) => p.arrivalTime)
            .reduce((a, b) => a < b ? a : b);
        while (currentTime < nextArrival) {
          _steps.add(
            SimulationStep(
              time: currentTime,
              processes: [
                ...finished,
                ...remaining,
              ].map((pro) => pro.copyWith()).toList(),
              description: "Processeur inactif",
            ),
          );
          currentTime++;
        }
        available = remaining
            .where((p) => p.arrivalTime <= currentTime)
            .toList();
      }

      // Choose SHORTEST burst time
      available.sort((a, b) => a.burstTime.compareTo(b.burstTime));
      var p = available.first;
      remaining.remove(p);

      p.state = ProcessState.running;
      for (int t = 0; t < p.burstTime; t++) {
        _steps.add(
          SimulationStep(
            time: currentTime,
            processes: [
              ...finished,
              p,
              ...remaining,
            ].map((pro) => pro.copyWith()).toList(),
            runningProcessId: p.id,
            description: "Exécution de ${p.name} (SJF - Plus court d'abord)",
          ),
        );
        currentTime++;
        p.remainingTime--;
      }

      p.state = ProcessState.terminated;
      p.completionTime = currentTime;
      p.turnAroundTime = p.completionTime - p.arrivalTime;
      p.waitingTime = p.turnAroundTime - p.burstTime;
      finished.add(p);
    }

    _steps.add(
      SimulationStep(
        time: currentTime,
        processes: finished.map((pro) => pro.copyWith()).toList(),
        description: "Simulation terminée",
      ),
    );
  }

  void nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      notifyListeners();
    } else {
      _stop();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      _stop();
    } else {
      _start();
    }
  }

  void _start() {
    if (_steps.isEmpty) runSimulation();
    if (_steps.isEmpty) return;

    _isPlaying = true;
    _playTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      nextStep();
    });
    notifyListeners();
  }

  void _stop() {
    _playTimer?.cancel();
    _playTimer = null;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }
}
