import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';

import 'config.dart';
import 'models.dart';

/// Scans Dart source files for string literals that look like user-facing
/// text but are not wrapped in Nylo's `.tr()` / `trans()` translation calls.
class StringScanner {
  StringScanner(this.config);

  final AuditConfig config;

  List<Finding> scan(Iterable<File> files) {
    final findings = <Finding>[];
    for (final file in files) {
      findings.addAll(scanFile(file));
    }
    findings.sort((a, b) {
      final byPath = a.relativePath.compareTo(b.relativePath);
      if (byPath != 0) return byPath;
      return a.line.compareTo(b.line);
    });
    return findings;
  }

  List<Finding> scanFile(File file) {
    final source = file.readAsStringSync();
    final ParseStringResult parsed;
    try {
      parsed = parseString(content: source, throwIfDiagnostics: false);
    } catch (_) {
      return const [];
    }

    final lineInfo = parsed.lineInfo;
    final ignoredLines = _collectIgnoredLines(parsed.unit, lineInfo);

    final visitor = _StringVisitor(config);
    parsed.unit.accept(visitor);

    final findings = <Finding>[];
    for (final hit in visitor.hits) {
      final loc = lineInfo.getLocation(hit.node.offset);
      if (ignoredLines.contains(loc.lineNumber)) continue;
      findings.add(
        Finding(
          relativePath: config.relativeTo(file.path),
          line: loc.lineNumber,
          column: loc.columnNumber,
          value: hit.value,
          context: hit.context,
        ),
      );
    }
    return findings;
  }

  Set<int> _collectIgnoredLines(CompilationUnit unit, LineInfo lineInfo) {
    final ignored = <int>{};
    Token? token = unit.beginToken;
    while (token != null) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        if (_isIgnoreMarkerComment(comment.lexeme)) {
          final commentLine = lineInfo.getLocation(comment.offset).lineNumber;
          ignored.add(commentLine);
          ignored.add(commentLine + 1);
        }
        comment = comment.next;
      }
      if (token.type == TokenType.EOF) break;
      token = token.next;
    }
    return ignored;
  }

  /// Whether [lexeme] is a dedicated ignore-marker comment (e.g. `// i18n-ignore`
  /// or `// i18n-ignore: not yet translated`), rather than prose that merely
  /// mentions the marker (`// see the i18n-ignore docs`). The marker must lead
  /// the comment body and be followed by end-of-comment, whitespace, or `:`.
  bool _isIgnoreMarkerComment(String lexeme) {
    final body = lexeme
        .replaceFirst(RegExp(r'^/[/*]+'), '') // strip `//`, `///`, `/*`
        .replaceFirst(RegExp(r'\*+/\s*$'), '') // strip a trailing `*/`
        .trim();
    for (final marker in config.ignoreMarkers) {
      if (body == marker) return true;
      if (body.startsWith(marker)) {
        final next = body[marker.length];
        if (next == ' ' || next == '\t' || next == ':') return true;
      }
    }
    return false;
  }
}

class _Hit {
  _Hit(this.node, this.value, this.context);
  final AstNode node;
  final String value;
  final String context;
}

class _StringVisitor extends RecursiveAstVisitor<void> {
  _StringVisitor(this.config);

  final AuditConfig config;
  final List<_Hit> hits = [];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _consider(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final buffer = StringBuffer();
    for (final element in node.elements) {
      if (element is InterpolationString) {
        buffer.write(element.value);
      } else {
        buffer.write(r'${..}');
      }
    }
    _consider(node, buffer.toString());
    super.visitStringInterpolation(node);
  }

  void _consider(Expression node, String rawValue) {
    final value = rawValue.trim();
    if (!_looksLikeUserFacingText(value)) return;
    if (_isLookupKey(node)) return;
    if (!_isInsideTextWidget(node)) return;
    hits.add(_Hit(node, value, _describeContext(node)));
  }

  /// A string used purely as a lookup key — `map["key"]` or the key half of a
  /// `{"key": value}` entry — is never displayed copy, even inside a `Text`
  /// (e.g. `Text(currentWord["translation"])` shows the value, not the key).
  bool _isLookupKey(Expression node) {
    final parent = node.parent;
    if (parent is IndexExpression && identical(parent.index, node)) return true;
    if (parent is MapLiteralEntry && identical(parent.key, node)) return true;
    return false;
  }

  bool _looksLikeUserFacingText(String value) {
    if (value.isEmpty) return false;
    if (value.length < config.minLength) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) return false;

    if (config.treatKeysAsTranslated &&
        RegExp(r'^[a-z0-9]+([._][a-z0-9]+)+$').hasMatch(value)) {
      return false;
    }

    for (final pattern in config.skipPatterns) {
      if (pattern.hasMatch(value)) return false;
    }
    return true;
  }

  /// Whether [node]'s nearest enclosing call is a text-bearing widget — the
  /// only place a raw string is user-facing copy. Walking up to the first
  /// call/constructor naturally skips keys, routes, data-model constructors,
  /// and translation calls: `Text("welcome".tr())` resolves to `tr` (not a
  /// text widget), so it is excluded without any special-casing.
  bool _isInsideTextWidget(Expression node) {
    AstNode? current = node.parent;
    while (current != null) {
      // Unresolved parsing represents a bare `Text(...)` (no `const`/`new`) as
      // a MethodInvocation and `const Text(...)` as an InstanceCreation, so a
      // widget name can appear as either — check both against [textWidgets].
      if (current is InstanceCreationExpression) {
        final ctor = current.constructorName;
        final typeName = ctor.type.name.lexeme;
        final named = ctor.name?.name;
        final full = named == null ? typeName : '$typeName.$named';
        return _isTextCall(typeName) || _isTextCall(full);
      }
      if (current is MethodInvocation) {
        return _isTextCall(current.methodName.name);
      }
      // Reached a declaration/body without first sitting inside a call, so the
      // string isn't widget content (e.g. `var path = "/home"`).
      if (current is VariableDeclaration || current is FunctionBody) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }

  /// A call whose string content is user-facing: a text widget like `Text`, or
  /// a configured string-bearing helper.
  bool _isTextCall(String name) =>
      config.textWidgets.contains(name) || config.textFunctions.contains(name);

  String _describeContext(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is MethodInvocation) {
        return '${current.methodName.name}(...)';
      }
      if (current is InstanceCreationExpression) {
        return current.constructorName.type.name.lexeme;
      }
      if (current is VariableDeclaration) {
        return 'var ${current.name.lexeme}';
      }
      current = current.parent;
    }
    return 'string literal';
  }
}
