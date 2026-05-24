import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/hive_service.dart';
import '../models/task.dart';
import '../widgets/dashboard_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];
  final Map<String, double> _categoryData = {};
  int _completedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final allTasks = await HiveService().getTasks(DateTime.now()); // Fetching current day for simplicity, but we could fetch all
    // In a real app, we'd fetch all tasks or stats directly from Supabase
    
    // For demo, let's fetch a wider range if possible, or just use what we have
    _tasks = allTasks;
    _completedCount = _tasks.where((t) => t.isCompleted).length;
    _pendingCount = _tasks.length - _completedCount;
    
    for (var t in _tasks) {
      if (t.category != null) {
        _categoryData[t.category!] = (_categoryData[t.category!] ?? 0) + 1;
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Corporate Banner Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E1E2E), // Obsidian Dark Color
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "TASKIFY",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.Text(
                      "Executive Schedule Analysis & Performance Report",
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          // Executive Summary Section
          pw.Text(
            "EXECUTIVE SUMMARY",
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1E1E2E),
            ),
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 1.5),
          pw.SizedBox(height: 12),

          // KPI Cards Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfKpiCard("Total Tasks Scheduled", "${_tasks.length}", PdfColors.indigo600),
              _buildPdfKpiCard("Completed Tasks", "$_completedCount", PdfColors.green600),
              _buildPdfKpiCard("Pending Checklist Items", "$_pendingCount", PdfColors.orange600),
            ],
          ),
          pw.SizedBox(height: 30),

          // Detailed Schedule Analysis Table
          pw.Text(
            "DETAILED SCHEDULE ANALYSIS",
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1E1E2E),
            ),
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 1.5),
          pw.SizedBox(height: 12),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.symmetric(
              inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.8),
            ),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF27272A),
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
            ),
            rowDecoration: const pw.BoxDecoration(
              color: PdfColors.grey50,
            ),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 28,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: <String>['Task Description', 'Scheduled Time', 'Priority Index', 'Current Status'],
            data: <List<String>>[
              ..._tasks.map((t) => [
                t.title,
                "${t.startTime} - ${t.endTime}",
                t.priority.toUpperCase(),
                t.isCompleted ? 'COMPLETED' : 'PENDING'
              ]),
            ],
          ),
          pw.SizedBox(height: 40),

          // Signoff footer
          pw.Divider(color: PdfColors.grey200, thickness: 1.0),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Generated via Taskify Premium Analytics Engine.",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                "Page 1 of 1",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildPdfKpiCard(String label, String value, PdfColor highlightColor) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey200, width: 1.0),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: highlightColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircularIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.pop(context),
        ),
        title: Text("Performance Stats", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _exportToPdf,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEfficiencyScore(theme),
                const SizedBox(height: 30),
                _buildSummaryCards(theme),
                const SizedBox(height: 30),
                _buildSectionTitle(theme, "Task Distribution"),
                const SizedBox(height: 20),
                _buildCompletionChart(theme),
                const SizedBox(height: 40),
                _buildSectionTitle(theme, "Category Analysis"),
                const SizedBox(height: 20),
                _buildCategoryChart(theme),
                const SizedBox(height: 40),
                _buildProductivityTip(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildEfficiencyScore(ThemeData theme) {
    final total = _tasks.length;
    final progress = total == 0 ? 0.0 : _completedCount / total;
    final percentage = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  color: theme.primaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$percentage%",
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Efficiency Score",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  percentage > 70 ? "You're doing great! Highly productive day." : "Keep going! Small steps lead to big wins.",
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityTip(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: theme.primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                "Pro Tip",
                style: TextStyle(color: theme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Tasks are 40% more likely to be completed if you schedule them in the first 2 hours of your day.",
            style: TextStyle(color: theme.hintColor, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    return Row(
      children: [
        _summaryCard(theme, "Completed", _completedCount.toString(), theme.primaryColor),
        const SizedBox(width: 15),
        _summaryCard(theme, "Pending", _pendingCount.toString(), theme.hintColor),
      ],
    );
  }

  Widget _summaryCard(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.hintColor, fontSize: 14)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildCompletionChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: _completedCount.toDouble(),
              title: 'Done',
              color: theme.primaryColor,
              radius: 50,
              titleStyle: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              value: _pendingCount.toDouble(),
              title: 'Todo',
              color: theme.dividerColor,
              radius: 50,
              titleStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildCategoryChart(ThemeData theme) {
    if (_categoryData.isEmpty) {
      return Center(child: Text("No category data available", style: TextStyle(color: theme.hintColor)));
    }
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: _categoryData.entries.toList().asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: theme.primaryColor,
                  width: 15,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() < _categoryData.length) {
                    return Text(_categoryData.keys.elementAt(val.toInt()).substring(0, 3), 
                      style: TextStyle(color: theme.hintColor, fontSize: 10));
                  }
                  return const Text("");
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}
