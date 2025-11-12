
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdvancedCodeInput extends StatefulWidget {
  final int codeLength;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool hasError;
  final String? errorMessage;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? errorColor;
  final Color? cursorColor;
  final TextStyle? textStyle;
  final double? boxWidth;
  final double? boxHeight;
  final double? borderRadius;
  final EdgeInsets? margin;
  final bool enableContextMenu;
  final bool autofocus;

  const AdvancedCodeInput({
    super.key,
    this.codeLength = 4,
    this.onCompleted,
    this.onChanged,
    this.focusNode,
    this.hasError = false,
    this.errorMessage,
    this.backgroundColor,
    this.activeColor,
    this.errorColor,
    this.cursorColor,
    this.textStyle,
    this.boxWidth,
    this.boxHeight,
    this.borderRadius,
    this.margin,
    this.enableContextMenu = true,
    this.autofocus = false,
  });

  @override
  State<AdvancedCodeInput> createState() => _AdvancedCodeInputState();
}

class _AdvancedCodeInputState extends State<AdvancedCodeInput>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showCursor = false;
  late Timer _cursorTimer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // 样式默认值
  Color get _backgroundColor => widget.backgroundColor ?? Colors.white;
  Color get _activeColor => widget.activeColor ?? const Color(0xFF00B2C0);
  Color get _errorColor => widget.errorColor ?? Colors.red;
  Color get _cursorColor => widget.cursorColor ?? _activeColor;
  TextStyle get _textStyle => widget.textStyle ?? const TextStyle(
    fontSize: 68,
    fontWeight: FontWeight.bold,
  );
  double get _boxWidth => widget.boxWidth ?? 61.8;
  double get _boxHeight => widget.boxHeight ?? 100;
  double get _borderRadius => widget.borderRadius ?? 8;
  EdgeInsets get _margin => widget.margin ?? const EdgeInsets.symmetric(horizontal: 8);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupInputCallbacks();
    _startCursorAnimation();
    _setupShakeAnimation();
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _setupInputCallbacks() {
    _controller.addListener(() {
      widget.onChanged?.call(_controller.text);
      if (_controller.text.length == widget.codeLength) {
        widget.onCompleted?.call(_controller.text);
      }
    });
  }

  void _startCursorAnimation() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_focusNode.hasFocus) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void didUpdateWidget(AdvancedCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _triggerShakeAnimation();
    }
  }

  void _triggerShakeAnimation() {
    _shakeController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _cursorTimer.cancel();
    _shakeController.dispose();
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _handlePaste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      if (text.isNotEmpty) {
        final pastedText = text.substring(0, text.length > widget.codeLength ? widget.codeLength : text.length);
        _controller.text = pastedText;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        // 如果粘贴的内容长度等于要求的长度，直接触发完成回调
        if (pastedText.length == widget.codeLength) {
          widget.onCompleted?.call(pastedText);
        }
      }
    } catch (e) {
      // 粘贴失败时显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('粘贴失败，请重试'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleClear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _showCustomContextMenu() {
    if (!widget.enableContextMenu) return;
    
    // 添加延迟以确保 renderBox 准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + size.height,
          position.dx + size.width,
          position.dy + size.height * 2,
        ),
        items: [
          PopupMenuItem(
            value: 'paste',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.paste, size: 16),
                SizedBox(width: 8),
                Text('粘贴'),
              ],
            ),
          ),
          if (_controller.text.isNotEmpty)
            PopupMenuItem(
              value: 'clear',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear, size: 16),
                  SizedBox(width: 8),
                  Text('清空'),
                ],
              ),
            ),
        ],
      ).then((value) {
        if (value == 'paste') {
          _handlePaste();
        } else if (value == 'clear') {
          _handleClear();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _focusNode.requestFocus(),
          onLongPress: _showCustomContextMenu,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value * 10 * (widget.hasError ? 1 : 0), 0),
                child: Stack(
                  children: [
                    // 隐藏的文本输入系统
                    _buildHiddenTextInput(),
                    // 自定义显示UI
                    _buildVisualCodeDisplay(),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.hasError && widget.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.errorMessage!,
            style: TextStyle(
              color: _errorColor,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHiddenTextInput() {
    return Opacity(
      opacity: 0.0,
      child: EditableText(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.codeLength),
        ],
        style: const TextStyle(color: Colors.transparent),
        cursorColor: Colors.transparent,
        backgroundCursorColor: Colors.transparent,
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildVisualCodeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.codeLength, (index) {
        final hasFocus = _focusNode.hasFocus;
        final currentIndex = _controller.selection.extentOffset;
        final showCursor = hasFocus &&
            index == currentIndex &&
            _showCursor;
        final hasValue = index < _controller.text.length;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _focusNode.requestFocus();
            final newPosition = index.clamp(0, _controller.text.length);
            _controller.selection = TextSelection.collapsed(offset: newPosition);
          },
          onLongPress: _showCustomContextMenu,
          child: Container(
            width: _boxWidth,
            height: _boxHeight,
            margin: _margin,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(
                color: widget.hasError 
                    ? _errorColor 
                    : (hasFocus && index == currentIndex) 
                        ? _activeColor 
                        : Colors.grey.withOpacity(0.3),
                width: widget.hasError ? 2 : 1,
              ),
              boxShadow: [
                if (hasFocus && index == currentIndex)
                  BoxShadow(
                    color: _activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: AnimatedOpacity(
                    opacity: hasValue ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      hasValue ? _controller.text[index] : '',
                      style: _textStyle.copyWith(
                        color: widget.hasError ? _errorColor : _textStyle.color,
                      ),
                    ),
                  ),
                ),
                if (showCursor) _buildAnimatedCursor(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedCursor() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 2,
          width: 24,
          decoration: BoxDecoration(
            color: _cursorColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}