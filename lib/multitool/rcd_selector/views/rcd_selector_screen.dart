import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/rcd_selector/logic/rcd_selector_provider.dart';
import 'package:gridly/multitool/rcd_selector/models/rcd_models.dart';
import 'package:gridly/theme/grid_theme.dart';

class RcdSelectorScreen extends StatelessWidget {
  const RcdSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dobór Typu RCD'),
        elevation: 0,
      ),
      body: Consumer<RcdSelectorProvider>(
        builder: (context, provider, _) {
          if (provider.result == null) {
            return _buildQuestionnaire(context, provider);
          } else {
            return _buildResult(context, provider.result!);
          }
        },
      ),
    );
  }

  Widget _buildQuestionnaire(BuildContext context, RcdSelectorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quiz: Dobór RCD',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${provider.questionProgress}/${provider.questions.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: provider.questions.isEmpty
                        ? 0
                        : provider.questionProgress / provider.questions.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        GridTheme.electricYellow),
                  ),
                ),
              ],
            ),
          ),
          // Questions
          ...provider.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final isAnswered = provider.answers.containsKey(question.id);
            final answer = provider.answers[question.id];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildQuestionCard(
                context,
                index + 1,
                question,
                isAnswered,
                answer,
                (value) {
                  provider.setAnswer(question.id, value);
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          // Submit button
          if (provider.allAnswered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  provider.calculateRecommendation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridTheme.electricYellow,
                  foregroundColor: GridTheme.deepNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Oblicz zalecenie',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int number,
    RcdQuestion question,
    bool isAnswered,
    bool? answer,
    Function(bool) onAnswer,
  ) {
    return Card(
      elevation: 1,
      color: isAnswered
          ? (answer! ? Colors.green[50] : Colors.blue[50])
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GridTheme.electricYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GridTheme.deepNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isAnswered)
                  Icon(
                    answer! ? Icons.check_circle : Icons.cancel,
                    color: answer ? Colors.green : Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAnswer(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answer == true
                          ? Colors.green
                          : Colors.grey[300],
                      foregroundColor:
                          answer == true ? Colors.white : Colors.black,
                    ),
                    child: const Text('Tak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAnswer(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answer == false
                          ? Colors.blue[600]
                          : Colors.grey[300],
                      foregroundColor:
                          answer == false ? Colors.white : Colors.black,
                    ),
                    child: const Text('Nie'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, RcdSelectionResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendation header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GridTheme.electricYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zalecany Typ RCD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GridTheme.deepNavy,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.recommendedType.code,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: GridTheme.deepNavy,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.recommendedType.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GridTheme.deepNavy,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details
          Text(
            'Szczegóły',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            result.reasoning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            result.details,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 24),

          // Alternative types
          if (result.alternativeTypes.isNotEmpty) ...[
            Text(
              'Typy alternatywne',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...result.alternativeTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.code,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: GridTheme.electricYellow,
                                ),
                          ),
                          Text(
                            type.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Type specifications table
          Text(
            'Specyfikacja wybranych typów',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildSpecificationTable(context, result),
          const SizedBox(height: 24),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<RcdSelectorProvider>().resetAnswers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
              ),
              child: const Text('Zacznij od nowa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationTable(
      BuildContext context, RcdSelectionResult result) {
    final types = [result.recommendedType, ...result.alternativeTypes];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1.5),
          },
          border: TableBorder.all(color: Colors.grey[300]!, width: 1),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: GridTheme.electricYellow.withOpacity(0.2),
              ),
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Typ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Cechy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            ...types.map((type) => TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          type.code,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          type.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
