import 'package:flutter/material.dart';

class SetEditorResult {
  final double weight;
  final int reps;
  final bool isWarmup;

  const SetEditorResult({
    required this.weight,
    required this.reps,
    required this.isWarmup,
  });
}

class SetEditorSheet extends StatefulWidget {
  final bool isEditing;
  final String exerciseName;
  final Color panelColor;
  final String initialWeightText;
  final String initialRepsText;
  final double? previousSetWeight;
  final int? previousSetReps;
  final bool previousSetIsWarmup;
  final bool initialIsWarmup;
  final double? lastWeight;
  final int? lastReps;
  final double? prWeight;
  final int? prReps;
  final String restLabel;
  final String Function(double value) formatWeight;

  const SetEditorSheet({
    super.key,
    required this.isEditing,
    required this.exerciseName,
    required this.panelColor,
    required this.initialWeightText,
    required this.initialRepsText,
    required this.previousSetWeight,
    required this.previousSetReps,
    required this.previousSetIsWarmup,
    required this.initialIsWarmup,
    required this.lastWeight,
    required this.lastReps,
    required this.prWeight,
    required this.prReps,
    required this.restLabel,
    required this.formatWeight,
  });

  @override
  State<SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<SetEditorSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late bool _isWarmup;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.initialWeightText);
    _repsController = TextEditingController(text: widget.initialRepsText);
    _isWarmup = widget.initialIsWarmup;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  double _parseWeight() {
    return double.tryParse(
          _weightController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  int _parseReps() {
    return int.tryParse(_repsController.text.trim()) ?? 0;
  }

  void _setWeight(double value) {
    final safeValue = value < 0 ? 0.0 : value;

    setState(() {
      _weightController.text = widget.formatWeight(safeValue);
      _weightController.selection = TextSelection.fromPosition(
        TextPosition(offset: _weightController.text.length),
      );
    });
  }

  void _setReps(int value) {
    final safeValue = value < 1 ? 1 : value;

    setState(() {
      _repsController.text = '$safeValue';
      _repsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _repsController.text.length),
      );
    });
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    final reps = int.tryParse(_repsController.text.trim());

    if (weight == null || reps == null || weight < 0 || reps <= 0) {
      setState(() {
        _errorText = 'Introduce un peso y reps válidos';
      });
      return;
    }

    Navigator.of(context).pop(
      SetEditorResult(weight: weight, reps: reps, isWarmup: _isWarmup),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomInset + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing ? 'Editar serie' : 'Añadir serie',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.exerciseName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bottomInset > 0)
                      IconButton(
                        onPressed: () => FocusScope.of(context).unfocus(),
                        icon: const Icon(Icons.keyboard_hide_rounded),
                        tooltip: 'Ocultar teclado',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.panelColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referencia rápida',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.previousSetWeight != null &&
                              widget.previousSetReps != null)
                            _SetEditorQuickFillChip(
                              label:
                                  '${widget.previousSetIsWarmup ? 'Últ. calent.' : 'Última serie'} ${widget.formatWeight(widget.previousSetWeight!)} × ${widget.previousSetReps}',
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _setWeight(widget.previousSetWeight!);
                                _setReps(widget.previousSetReps!);
                              },
                            ),
                          if (widget.lastWeight != null && widget.lastReps != null)
                            _SetEditorQuickFillChip(
                              label:
                                  'Última vez ${widget.formatWeight(widget.lastWeight!)} × ${widget.lastReps}',
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _setWeight(widget.lastWeight!);
                                _setReps(widget.lastReps!);
                              },
                            ),
                          if (widget.prWeight != null && widget.prReps != null)
                            _SetEditorQuickFillChip(
                              label:
                                  'PR ${widget.formatWeight(widget.prWeight!)} × ${widget.prReps}',
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _setWeight(widget.prWeight!);
                                _setReps(widget.prReps!);
                              },
                            ),
                          if (widget.previousSetWeight == null &&
                              widget.lastWeight == null &&
                              widget.prWeight == null)
                            const _SetEditorMiniTagChip(
                              icon: Icons.info_outline_rounded,
                              label: 'Sin referencias todavía',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
                          errorText: _errorText,
                        ),
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() {
                              _errorText = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        onSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          labelText: 'Repeticiones',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tipo de serie',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Serie efectiva'),
                      selected: !_isWarmup,
                      onSelected: (_) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _isWarmup = false;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Calentamiento'),
                      selected: _isWarmup,
                      onSelected: (_) {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _isWarmup = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ajustes rápidos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SetEditorQuickAdjustChip(
                      label: '+2.5 kg',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setWeight(_parseWeight() + 2.5);
                      },
                    ),
                    _SetEditorQuickAdjustChip(
                      label: '+5 kg',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setWeight(_parseWeight() + 5);
                      },
                    ),
                    _SetEditorQuickAdjustChip(
                      label: '-2.5 kg',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setWeight(_parseWeight() - 2.5);
                      },
                    ),
                    _SetEditorQuickAdjustChip(
                      label: '+1 rep',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setReps(_parseReps() + 1);
                      },
                    ),
                    _SetEditorQuickAdjustChip(
                      label: '+2 reps',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setReps(_parseReps() + 2);
                      },
                    ),
                    _SetEditorQuickAdjustChip(
                      label: '-1 rep',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _setReps(_parseReps() - 1);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descanso que se guardará',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.restLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isWarmup
                            ? 'Se guardará como serie de calentamiento'
                            : 'Se guardará como serie efectiva',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(
                          widget.isEditing ? 'Guardar cambios' : 'Guardar serie',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetEditorMiniTagChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SetEditorMiniTagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.78)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.82))),
        ],
      ),
    );
  }
}

class _SetEditorQuickFillChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SetEditorQuickFillChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.07),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

class _SetEditorQuickAdjustChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SetEditorQuickAdjustChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.88),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
