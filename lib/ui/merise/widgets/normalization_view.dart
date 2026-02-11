import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/merise_provider.dart';
import '../../../theme.dart';
import '../../../merise/mcd_analyzer.dart';

class NormalizationView extends StatefulWidget {
  final AppTheme theme;
  final bool isMobile;
  const NormalizationView({
    super.key,
    required this.theme,
    this.isMobile = false,
  });

  @override
  State<NormalizationView> createState() => _NormalizationViewState();
}

class _NormalizationViewState extends State<NormalizationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeriseProvider>();
    final mcd = provider.mcd;
    final scale = provider.textScaleFactor;
    final theme = widget.theme;

    // Analyser le MCD
    final allIssues = McdAnalyzer.analyze(mcd);
    final score = McdAnalyzer.calculateScore(allIssues);

    final errors = allIssues
        .where((i) => i.severity == IssueSeverity.error)
        .toList();
    final warnings = allIssues
        .where((i) => i.severity == IssueSeverity.warning)
        .toList();
    final infos = allIssues
        .where((i) => i.severity == IssueSeverity.info)
        .toList();

    return Container(
      color: ThemeColors.editorBg(theme),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(widget.isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(scale, score, allIssues.length, theme),
                  const SizedBox(height: 24),
                  _buildStats(
                    score,
                    errors.length,
                    warnings.length,
                    infos.length,
                    scale,
                    theme,
                  ),
                  const SizedBox(height: 24),
                  if (!widget.isMobile)
                    _buildTabs(theme, scale)
                  else
                    const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIssuesList(allIssues, provider, scale, theme),
                        _buildIssuesList(errors, provider, scale, theme),
                        _buildIssuesList(warnings, provider, scale, theme),
                        _buildIssuesList(infos, provider, scale, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.isMobile) _buildPedagogicalSidebar(scale, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(double scale, int score, int issueCount, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Analyse de Normalisation",
          style: TextStyle(
            fontSize: (widget.isMobile ? 20 : 28) * scale,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textMain(theme),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          issueCount == 0
              ? "Modèle parfait ! Aucune erreur détectée."
              : "Nous avons trouvé $issueCount point${issueCount > 1 ? 's' : ''} d'attention dans votre modèle.",
          style: TextStyle(
            fontSize: (widget.isMobile ? 12 : 15) * scale,
            color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(AppTheme theme, double scale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF1E88E5),
        unselectedLabelColor: ThemeColors.textMain(
          theme,
        ).withValues(alpha: 0.5),
        indicatorColor: const Color(0xFF1E88E5),
        labelStyle: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: "Tout"),
          Tab(text: "Erreurs"),
          Tab(text: "Avertissements"),
          Tab(text: "Informations"),
        ],
      ),
    );
  }

  Widget _buildStats(
    int score,
    int errors,
    int warnings,
    int infos,
    double scale,
    AppTheme theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _tabController.animateTo(0),
            child: _buildScoreStatCard(score, scale, theme),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _tabController.animateTo(1),
            child: _buildStatCard(
              widget.isMobile ? "Err." : "Erreurs",
              errors,
              Colors.red,
              Icons.error,
              scale,
              theme,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _tabController.animateTo(2),
            child: _buildStatCard(
              widget.isMobile ? "Warn." : "Alertes",
              warnings,
              Colors.orange,
              Icons.warning,
              scale,
              theme,
            ),
          ),
        ),
        if (!widget.isMobile) ...[
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(3),
              child: _buildStatCard(
                "Informations",
                infos,
                Colors.blue,
                Icons.info,
                scale,
                theme,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreStatCard(int score, double scale, AppTheme theme) {
    Color scoreColor = score >= 80
        ? Colors.green
        : (score >= 60 ? Colors.orange : Colors.red);
    return _buildStatCard(
      widget.isMobile ? "Qualité" : "Score Global",
      score,
      scoreColor,
      Icons.speed,
      scale,
      theme,
      suffix: "/100",
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    IconData icon,
    double scale,
    AppTheme theme, {
    String suffix = "",
  }) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isMobile
          ? Column(
              children: [
                Icon(icon, color: color, size: 20 * scale),
                const SizedBox(height: 4),
                Text(
                  "$count$suffix",
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.textMain(theme),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: color, size: 28 * scale),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$count$suffix",
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textMain(theme),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: ThemeColors.textMain(
                          theme,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildIssuesList(
    List<NormalizationIssue> issues,
    MeriseProvider provider,
    double scale,
    AppTheme theme,
  ) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64 * scale, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              "Tout est en ordre !",
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textMain(theme),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemCount: issues.length,
      itemBuilder: (context, index) => _IssueCard(
        issue: issues[index],
        scale: scale,
        theme: theme,
        provider: provider,
      ),
    );
  }

  Widget _buildPedagogicalSidebar(double scale, AppTheme theme) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          left: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Text(
                "Guide Théorique",
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textMain(theme),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNormRule(
            "1ère Forme Normale (1NF)",
            "Chaque attribut doit être atomique (une seule valeur) et l'entité doit avoir une clé primaire.",
            scale,
            theme,
          ),
          _buildNormRule(
            "2ème Forme Normale (2NF)",
            "Doit être en 1NF, et chaque attribut non-clé doit dépendre de TOUTE la clé primaire.",
            scale,
            theme,
          ),
          _buildNormRule(
            "3ème Forme Normale (3NF)",
            "Doit être en 2NF, et aucun attribut ne doit dépendre d'un autre attribut non-clé.",
            scale,
            theme,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pourquoi normaliser ?",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "La normalisation évite la redondance des données et les anomalies lors des mises à jour.",
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormRule(
    String title,
    String desc,
    double scale,
    AppTheme theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12 * scale,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final NormalizationIssue issue;
  final double scale;
  final AppTheme theme;
  final MeriseProvider provider;

  const _IssueCard({
    required this.issue,
    required this.scale,
    required this.theme,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor = issue.severity == IssueSeverity.error
        ? Colors.red
        : (issue.severity == IssueSeverity.warning
              ? Colors.orange
              : Colors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                issue.severity == IssueSeverity.error
                    ? Icons.error
                    : (issue.severity == IssueSeverity.warning
                          ? Icons.warning
                          : Icons.info),
                size: 20 * scale,
                color: severityColor,
              ),
              const SizedBox(width: 8),
              Text(
                issue.title,
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textMain(theme),
                ),
              ),
              const Spacer(),
              if (issue.affectedEntityId != null)
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  onPressed: () {
                    provider.setActiveView('mcd');
                    final entity = provider.entities.firstWhere(
                      (e) => e.id == issue.affectedEntityId,
                    );
                    provider.selectItem(entity);
                    provider.jumpTo(
                      entity.position + const Offset(75, 50),
                      MediaQuery.of(context).size,
                    );
                  },
                  tooltip: "Localiser dans le MCD",
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            issue.description,
            style: TextStyle(
              fontSize: 14 * scale,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          if (issue.suggestion != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      issue.suggestion!,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontStyle: FontStyle.italic,
                        color: ThemeColors.textMain(
                          theme,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (issue.title == 'Clé primaire manquante' &&
                      issue.affectedEntityId != null)
                    ElevatedButton(
                      onPressed: () =>
                          provider.autoFixMissingPK(issue.affectedEntityId!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: const Text("Auto-Fix"),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
