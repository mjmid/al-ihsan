import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class PtFontSizeSelectorWidget extends StatefulWidget {
  final quill.QuillController controller;

  const PtFontSizeSelectorWidget({
    super.key,
    required this.controller,
  });

  @override
  State<PtFontSizeSelectorWidget> createState() => _PtFontSizeSelectorWidgetState();
}

class _PtFontSizeSelectorWidgetState extends State<PtFontSizeSelectorWidget> {
  static const double defaultBasePt = 16.0;

  static const List<double> standardPresets = [
    8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 40, 48, 56, 64, 72, 96
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  double _getCurrentFontSize() {
    final attr = widget.controller.getSelectionStyle().attributes[quill.Attribute.size.key];
    if (attr == null || attr.value == null) {
      return defaultBasePt;
    }
    final val = attr.value;
    if (val is num) return val.toDouble();
    if (val is String) {
      if (val == 'small') return 11.0;
      if (val == 'normal') return 14.0;
      if (val == 'large') return 22.0;
      if (val == 'huge') return 28.0;
      final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(clean);
      if (parsed != null && parsed > 0) return parsed;
    }
    return defaultBasePt;
  }

  String _formatPt(double pt) {
    if (pt == pt.roundToDouble()) {
      return '${pt.toInt()} pt';
    }
    return '${pt.toStringAsFixed(1)} pt';
  }

  void _applyFontSize(double? pt, {bool applyToWholeDocument = false}) {
    final attrVal = (pt == null || pt <= 0)
        ? null
        : (pt == pt.roundToDouble() ? pt.toInt() : pt);

    final attr = quill.Attribute.fromKeyValue(quill.Attribute.size.key, attrVal);

    if (applyToWholeDocument) {
      final docLength = widget.controller.document.length;
      if (docLength > 0) {
        widget.controller.formatText(0, docLength, attr);
      }
    } else {
      widget.controller.formatSelection(attr);
    }
    if (mounted) setState(() {});
  }

  void _stepFontSize(int delta) {
    final current = _getCurrentFontSize();
    final next = (current + delta).clamp(6.0, 150.0);
    _applyFontSize(next);
  }

  void _openCustomPicker(BuildContext context) {
    final currentPt = _getCurrentFontSize();
    final textController = TextEditingController(
      text: (currentPt == currentPt.roundToDouble())
          ? currentPt.toInt().toString()
          : currentPt.toStringAsFixed(1),
    );
    double sliderVal = currentPt.clamp(8.0, 72.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final theme = Theme.of(modalContext);
            final colorScheme = theme.colorScheme;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title and Current Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ফন্ট সাইজ (pt) নির্ধারণ করুন',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatPt(currentPt),
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'ইচ্ছামত সাইজ লিখুন',
                              hintText: 'যেমন: 18 বা 22.5',
                              suffixText: 'pt',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val.trim());
                              if (parsed != null && parsed >= 6 && parsed <= 150) {
                                setModalState(() {
                                  sliderVal = parsed.clamp(8.0, 72.0);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            final parsed = double.tryParse(textController.text.trim());
                            if (parsed != null && parsed > 0) {
                              _applyFontSize(parsed.clamp(6.0, 150.0));
                              Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('প্রয়োগ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Interactive Slider
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          tooltip: '-1 pt',
                          onPressed: () {
                            final next = (sliderVal - 1).clamp(8.0, 72.0);
                            setModalState(() {
                              sliderVal = next;
                              textController.text = (next == next.roundToDouble())
                                  ? next.toInt().toString()
                                  : next.toStringAsFixed(1);
                            });
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: sliderVal,
                            min: 8.0,
                            max: 72.0,
                            divisions: 64,
                            label: '${sliderVal.round()} pt',
                            onChanged: (val) {
                              setModalState(() {
                                sliderVal = val;
                                textController.text = val.round().toString();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          tooltip: '+1 pt',
                          onPressed: () {
                            final next = (sliderVal + 1).clamp(8.0, 72.0);
                            setModalState(() {
                              sliderVal = next;
                              textController.text = (next == next.roundToDouble())
                                  ? next.toInt().toString()
                                  : next.toStringAsFixed(1);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Preset Chips Header
                    Text(
                      'সাধারণ সাইজ নির্বাচন:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Preset Chips Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: standardPresets.map((pt) {
                        final isSelected = (currentPt == pt);
                        return ChoiceChip(
                          label: Text('${pt.toInt()} pt'),
                          selected: isSelected,
                          onSelected: (_) {
                            _applyFontSize(pt);
                            Navigator.pop(ctx);
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                          selectedColor: colorScheme.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Action buttons: Apply to Whole Document & Reset
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text(
                              'পুরো নোটে দিন',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              final parsed = double.tryParse(textController.text.trim()) ?? sliderVal;
                              _applyFontSize(parsed.clamp(6.0, 150.0), applyToWholeDocument: true);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('সম্পূর্ণ নোটে ${_formatPt(parsed)} প্রয়োগ করা হয়েছে'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'ডিফল্ট রিসেট',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              _applyFontSize(null);
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPt = _getCurrentFontSize();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Down (- 1 pt)
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            onTap: () => _stepFontSize(-1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Icon(
                Icons.remove,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Central Pt Pill (Opens dialog)
          InkWell(
            onTap: () => _openCustomPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPt(currentPt),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Step Up (+ 1 pt)
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            onTap: () => _stepFontSize(1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Icon(
                Icons.add,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
