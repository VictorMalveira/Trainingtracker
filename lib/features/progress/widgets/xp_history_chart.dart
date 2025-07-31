import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class XpHistoryChart extends StatelessWidget {
  final Map<String, dynamic> xpHistory;

  const XpHistoryChart({super.key, required this.xpHistory});

  @override
  Widget build(BuildContext context) {
    // Se não houver dados, exibe uma mensagem
    if (xpHistory.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados de XP suficientes para gerar o gráfico.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Extrai os dados para o gráfico
    final List<FlSpot> spots = [];
    final List<String> dates = [];
    
    // Ordena as entradas por data
    final sortedEntries = xpHistory.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));
    
    // Cria os pontos para o gráfico
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      spots.add(FlSpot(i.toDouble(), entry.value.toDouble()));
      dates.add(_formatDate(DateTime.parse(entry.key)));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 100,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Text(
                    dates[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: spots.length - 1.0,
        minY: 0,
        maxY: _calculateMaxY(spots),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(51), // 0.2 * 255 = 51
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Arredonda para o próximo múltiplo de 100 para melhor visualização
    return ((maxY ~/ 100) + 1) * 100.0;
  }
}