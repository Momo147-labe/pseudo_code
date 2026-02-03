import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/barre_haut.dart';
import 'ui/editeur_widget.dart';
import 'ui/console_widget.dart';
import 'ui/barre_laterale.dart';
import 'ui/activity_bar.dart';
import 'ui/status_bar.dart';
import 'ui/merise/merise_studio.dart';
import 'package:pseudo_code/ui/educational_panel.dart';
import 'theme.dart';
import 'providers/merise_provider.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/file_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/debug_provider.dart';
import 'providers/example_provider.dart';
import 'providers/ai_provider.dart';
import 'repositories/example_repository.dart';
import 'outils/file_open_service.dart';
import 'package:pseudo_code/l10n/app_localizations.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du thème avant de lancer l'app pour éviter le scintillement
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  // Récupération des fichiers passés en argument (Windows %1)
  final List<String> initialFiles = FileOpenService.getFilesFromArgs(args);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()), // UI Provider
        ChangeNotifierProvider(
          create: (_) => FileProvider(initialFiles: initialFiles),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(
          create: (_) => ExampleProvider(ExampleRepository()),
        ),
        ChangeNotifierProvider(create: (_) => MeriseProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Optimisation : On ne reconstruit MaterialApp que si le thème change
    final theme = context.select<ThemeProvider, AppTheme>(
      (p) => p.currentTheme,
    );
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return MaterialApp(
      title: 'Interpréteur Pseudo-Code',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: ThemeColors.editorBg(theme),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: ThemeColors.textMain(theme)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final consoleKey = GlobalKey<ConsoleWidgetState>();

  @override
  Widget build(BuildContext context) {
    // On n'écoute que les propriétés nécessaires pour éviter les rebuilds globaux
    final fileProvider = context.read<FileProvider>();
    final debugProvider = context.read<DebugProvider>();
    final theme = context.select<ThemeProvider, AppTheme>(
      (p) => p.currentTheme,
    );
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            const RunIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewFileIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
            const ClearConsoleIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          RunIntent: CallbackAction<RunIntent>(
            onInvoke: (_) {
              final activeFile = fileProvider.activeFile;
              if (activeFile != null) {
                debugProvider.setPaused(false);
                context.read<AppProvider>().setConsoleVisible(true);
                _runAlgorithm(activeFile, context);
              }
              return null;
            },
          ),
          NewFileIntent: CallbackAction<NewFileIntent>(
            onInvoke: (_) {
              fileProvider.createFile(
                fileProvider.currentDirectory,
                "nouveau.alg",
              );
              return null;
            },
          ),
          ClearConsoleIntent: CallbackAction<ClearConsoleIntent>(
            onInvoke: (_) {
              consoleKey.currentState?.clear();
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: ThemeColors.editorBg(theme),
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: Scaffold(
                backgroundColor: ThemeColors.editorBg(theme),
                endDrawer: EducationalPanel(isMobile: isMobile),
                drawer: isMobile ? const BarreLaterale() : null,
                body: SafeArea(
                  child: Column(
                    children: [
                      BarreHaut(
                        isMobile: isMobile,
                        onExecuter: () {
                          final activeFile = fileProvider.activeFile;
                          if (activeFile != null) {
                            debugProvider.setPaused(false);
                            context.read<AppProvider>().setConsoleVisible(true);
                            _runAlgorithm(activeFile, context);
                          }
                        },
                        onDebug: () {
                          final activeFile = fileProvider.activeFile;
                          if (activeFile != null) {
                            debugProvider.setPaused(true);
                            context.read<AppProvider>().setActiveSidebarTab(
                              'debug',
                            );
                            context.read<AppProvider>().setConsoleVisible(true);
                            _runAlgorithm(activeFile, context);
                          }
                        },
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (!isMobile) ...[
                              const ActivityBar(),
                              const BarreLaterale(),
                            ],
                            Expanded(
                              child: Consumer<AppProvider>(
                                builder: (context, p, _) {
                                  final isBottomOrTop =
                                      p.consolePosition ==
                                          ConsolePosition.bottom ||
                                      p.consolePosition == ConsolePosition.top;

                                  if (isBottomOrTop) {
                                    return Column(
                                      children: [
                                        if (p.isConsoleVisible &&
                                            p.consolePosition ==
                                                ConsolePosition.top) ...[
                                          SizedBox(
                                            height: p.consoleHeight,
                                            child: ConsoleWidget(
                                              key: consoleKey,
                                            ),
                                          ),
                                          _buildResizer(
                                            p,
                                            true,
                                            isDark,
                                            isMobile,
                                          ),
                                        ],
                                        const Expanded(
                                          child: _MainEditorArea(),
                                        ),
                                        if (p.isConsoleVisible &&
                                            p.consolePosition ==
                                                ConsolePosition.bottom) ...[
                                          _buildResizer(
                                            p,
                                            true,
                                            isDark,
                                            isMobile,
                                          ),
                                          SizedBox(
                                            height: p.consoleHeight,
                                            child: ConsoleWidget(
                                              key: consoleKey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Expanded(
                                          child: _MainEditorArea(),
                                        ),
                                        if (p.isConsoleVisible) ...[
                                          _buildResizer(
                                            p,
                                            false,
                                            isDark,
                                            isMobile,
                                          ),
                                          SizedBox(
                                            width: p.consoleWidth,
                                            child: ConsoleWidget(
                                              key: consoleKey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StatusBar(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResizer(
    AppProvider p,
    bool isVertical,
    bool isDark,
    bool isMobile,
  ) {
    final size = isMobile ? 12.0 : 4.0;
    return GestureDetector(
      onPanUpdate: (details) {
        if (isVertical) {
          if (p.consolePosition == ConsolePosition.top) {
            p.setConsoleHeight(p.consoleHeight + details.delta.dy);
          } else {
            p.setConsoleHeight(p.consoleHeight - details.delta.dy);
          }
        } else {
          p.setConsoleWidth(p.consoleWidth - details.delta.dx);
        }
      },
      child: Container(
        height: isVertical ? size : double.infinity,
        width: isVertical ? double.infinity : size,
        color: Colors.transparent,
        child: MouseRegion(
          cursor: isVertical
              ? SystemMouseCursors.resizeUpDown
              : SystemMouseCursors.resizeLeftRight,
          child: Center(
            child: Container(
              width: isVertical ? 30 : 2,
              height: isVertical ? 2 : 30,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
        ),
      ),
    );
  }

  void _runAlgorithm(AppFile activeFile, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeFile.extension.toLowerCase() != 'alg') {
        final l10n = AppLocalizations.of(context)!;
        consoleKey.currentState?.printDirect(
          "ERREUR: ${l10n.errorFileExtension}",
        );
        return;
      }
      consoleKey.currentState?.runCode(activeFile.content);
    });
  }
}

class NewFileIntent extends Intent {
  const NewFileIntent();
}

class RunIntent extends Intent {
  const RunIntent();
}

class ClearConsoleIntent extends Intent {
  const ClearConsoleIntent();
}

class _MainEditorArea extends StatelessWidget {
  const _MainEditorArea();

  @override
  Widget build(BuildContext context) {
    // On n'écoute que le changement de la vue principale
    final activeMainView = context.select<AppProvider, ActiveMainView>(
      (p) => p.activeMainView,
    );

    if (activeMainView == ActiveMainView.merise) {
      return const MeriseStudio();
    }

    return const EditeurWidget();
  }
}
