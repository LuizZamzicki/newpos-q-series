import 'dart:async';

import 'package:flutter/material.dart';
import 'package:newpos_q_series/newpos_q_series.dart';

import 'printer_labels.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    required this.platformVersion,
    required this.bound,
    required this.status,
    required this.message,
    required this.diagnostics,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
    required this.onDiagnostics,
    super.key,
  });

  final String platformVersion;
  final bool bound;
  final NewposQPrinterStatus? status;
  final String message;
  final String diagnostics;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;
  final VoidCallback onDiagnostics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Device', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Android: $platformVersion'),
            Text('Service: ${bound ? 'connected' : 'disconnected'}'),
            Text('Printer: ${status?.label ?? 'unknown'}'),
            if (status == NewposQPrinterStatus.paperless) ...<Widget>[
              const SizedBox(height: 8),
              const WarningBanner(message: 'Printer is out of paper'),
            ],
            Text('Last: $message'),

            if (busy) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: busy ? null : onConnect,
                  child: const Text('Connect'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : onRefresh,
                  child: const Text('Refresh'),
                ),

                OutlinedButton(
                  onPressed: busy ? null : onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colors.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(displayValue, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((item) {
            return ChoiceChip(
              label: Text(labelBuilder(item)),
              selected: item == value,
              onSelected: (_) => onChanged(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class DropdownRow<T> extends StatelessWidget {
  const DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: Text(label)),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: values.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) onChanged(item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({required this.buttons, super.key});

  final List<ActionButton> buttons;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 3 ? 3.1 : 2.4,
          children: buttons.map((button) {
            return FilledButton.tonal(
              onPressed: () => unawaited(button.onPressed()),
              child: Text(button.label, textAlign: TextAlign.center),
            );
          }).toList(),
        );
      },
    );
  }
}

class ActionButton {
  const ActionButton(this.label, this.onPressed);

  final String label;
  final Future<void> Function() onPressed;
}
