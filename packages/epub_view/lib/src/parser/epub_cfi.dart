import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

class CfiFragment {
  CfiFragment({@required this.type, @required this.cfiString});

  final String type;
  final String cfiString;
}

class CfiRange {
  CfiRange({
    @required this.type,
    @required this.path,
    @required this.localPath,
    @required this.range1,
    @required this.range2,
  });

  final String type;
  final String path;
  final String localPath;
  final String range1;
  final String range2;
}

class CfiPath {
  CfiPath({@required this.type, @required this.path, @required this.localPath});

  final String type;
  final String path;
  final CfiLocalPath localPath;
}

class CfiLocalPath {
  CfiLocalPath({@required this.steps, @required this.termStep});

  final String steps;
  final String termStep;
}

class CfiStep {
  CfiStep({
    @required this.type,
    @required this.stepLength,
    @required this.idAssertion,
  });

  final String type;
  final int stepLength;
  final int idAssertion;
}

class CfiTerminus {
  CfiTerminus({
    @required this.type,
    @required this.offsetValue,
    @required this.textAssertion,
  });

  final String type;
  final int offsetValue;
  final String textAssertion;
}

class CfiTextLocationAssertion {
  CfiTextLocationAssertion({
    @required this.type,
    @required this.csv,
    @required this.parameter,
  });

  final String type;
  final CfiCsv csv;
  final CfiParameter parameter;
}

class CfiParameter {
  CfiParameter({
    @required this.type,
    @required this.lHSValue,
    @required this.rHSValue,
  });

  final String type;
  final String lHSValue;
  final String rHSValue;
}

class CfiCsv {
  CfiCsv({
    @required this.type,
    @required this.preAssertion,
    @required this.postAssertion,
  });

  final String type;
  final String preAssertion;
  final String postAssertion;
}

class ErrorPosition {
  ErrorPosition({@required this.line, @required this.column});

  final int line;
  final int column;
}

class EpubCfiParser {
  int pos = 0;
  final int reportFailures = 0;
  int rightmostFailuresPos = 0;
  List<String> rightmostFailuresExpected = [];
  String input;
  String startRule;

  /*
   * ECMA-262, 5th ed., 7.8.4: All characters may appear literally in a
   * string literal except for the closing quote character, backslash,
   * carriage return, line separator, paragraph separator, and line feed.
   * Any character may appear in the form of an escape sequence.
   *
   * For portability, we also escape escape all control and non-ASCII
   * characters. Note that "\0" and "\v" escape sequences are not used
   * because JSHint does not like the first and IE the second.
   */
  String quote(String s) =>
      '"' +
      s
          .replaceAll(RegExp(r'\\'), '\\\\') // backslash
          .replaceAll(RegExp(r'"'), '\\"') // closing quote character
          .replaceAll(RegExp(r'\x08'), '\\b') // backspace
          .replaceAll(RegExp(r'\t'), '\\t') // horizontal tab
          .replaceAll(RegExp(r'\n'), '\\n') // line feed
          .replaceAll(RegExp(r'\f'), '\\f') // form feed
          .replaceAll(RegExp(r'\r'), '\\r') // carriage return
          .replaceAllMapped(RegExp(r'[\x00-\x07\x0B\x0E-\x1F\x80-\uFFFF]'),
              (Match m) => Uri.encodeFull(m[0])) +
      '"';

  dynamic parse(String _input, String _startRule) {
    input = _input;
    startRule = _startRule;

    final parseFunctions = {
      'fragment': _parseFragment,
      'range': _parseRange,
      'path': _parsePath,
      'local_path': _parseLocalPath,
      'indexStep': _parseIndexStep,
      'indirectionStep': _parseIndirectionStep,
      'terminus': _parseTerminus,
      'idAssertion': _parseIdAssertion,
      'textLocationAssertion': _parseTextLocationAssertion,
      'parameter': _parseParameter,
      'csv': _parseCsv,
      'valueNoSpace': _parseValueNoSpace,
      'value': _parseValue,
      'escapedSpecialChars': _parseEscapedSpecialChars,
      'number': _parseNumber,
      'integer': _parseInteger,
      'space': _parseSpace,
      'circumflex': _parseCircumflex,
      'doubleQuote': _parseDoubleQuote,
      'squareBracket': _parseSquareBracket,
      'parentheses': _parseParentheses,
      'comma': _parseComma,
      'semicolon': _parseSemicolon,
      'equal': _parseEqual,
      'character': _parseCharacter
    };

    if (startRule != null) {
      if (parseFunctions[startRule] == null) {
        throw FlutterError('Invalid rule name: ' + quote(startRule) + '.');
      }
    } else {
      startRule = 'fragment';
    }

    final result = parseFunctions[startRule]();

    /*
       * The parser is now in one of the following three states:
       *
       * 1. The parser successfully parsed the whole input.
       *
       *    - |result != null|
       *    - |pos == input.length|
       *    - |rightmostFailuresExpected| may or may not contain something
       *
       * 2. The parser successfully parsed only a part of the input.
       *
       *    - |result != null|
       *    - |pos < input.length|
       *    - |rightmostFailuresExpected| may or may not contain something
       *
       * 3. The parser did not successfully parse any part of the input.
       *
       *   - |result == null|
       *   - |pos == 0|
       *   - |rightmostFailuresExpected| contains at least one failure
       *
       * All code following this comment (including called functions) must
       * handle these states.
       */
    if (result == null || pos != input.length) {
      var offset = max(pos, rightmostFailuresPos);
      var found = offset < input.length ? input[offset] : null;
      var errorPosition = _computeErrorPosition();

      // throw this.SyntaxError(
      //   _cleanupExpected(rightmostFailuresExpected),
      //   found,
      //   offset,
      //   errorPosition.line,
      //   errorPosition.column,
      // );
    }

    return result;
  }

  CfiFragment _parseFragment() {
    dynamic result0, result1, result2;
    int pos0, pos1;

    pos0 = pos;
    pos1 = pos;
    if (input.substring(pos, 8) == 'epubcfi(') {
      result0 = 'epubcfi(';
      pos += 8;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"epubcfi(\"');
      }
    }
    if (result0 != null) {
      result1 = _parseRange();
      if (result1 == null) {
        result1 = _parsePath();
      }
      if (result1 != null) {
        if (input.codeUnitAt(pos) == 41) {
          result2 = ')';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\")\"');
          }
        }
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((offset, fragmentVal) =>
              CfiFragment(type: 'CFIAST', cfiString: fragmentVal))(
          pos0, result0[1]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiRange _parseRange() {
    dynamic result0, result1, result2, result3, result5;
    String result4;
    int pos0, pos1;

    pos0 = pos;
    pos1 = pos;
    result0 = _parseIndexStep();
    if (result0 != null) {
      result1 = _parseLocalPath();
      if (result1 != null) {
        if (input.codeUnitAt(pos) == 44) {
          result2 = ',';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\",\"');
          }
        }
        if (result2 != null) {
          result3 = _parseLocalPath();
          if (result3 != null) {
            if (input.codeUnitAt(pos) == 44) {
              result4 = ',';
              pos++;
            } else {
              result4 = null;
              if (reportFailures == 0) {
                _matchFailed('\",\"');
              }
            }
            if (result4 != null) {
              result5 = _parseLocalPath();
              if (result5 != null) {
                result0 = [
                  result0,
                  result1,
                  result2,
                  result3,
                  result4,
                  result5
                ];
              } else {
                result0 = null;
                pos = pos1;
              }
            } else {
              result0 = null;
              pos = pos1;
            }
          } else {
            result0 = null;
            pos = pos1;
          }
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((int offset, String stepVal, String localPathVal,
              String rangeLocalPath1Val, String rangeLocalPath2Val) =>
          CfiRange(
            type: 'range',
            path: stepVal,
            localPath: localPathVal,
            range1: rangeLocalPath1Val,
            range2: rangeLocalPath2Val,
          ))(pos0, result0[0], result0[1], result0[3], result0[5]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiPath _parsePath() {
    dynamic result0, result1;
    final int pos0 = pos, pos1 = pos;

    result0 = _parseIndexStep();
    if (result0 != null) {
      result1 = _parseLocalPath();
      if (result1 != null) {
        result0 = [result0, result1];
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 =
          ((int offset, String stepVal, CfiLocalPath localPathVal) => CfiPath(
                type: 'path',
                path: stepVal,
                localPath: localPathVal,
              ))(pos0, result0[0], result0[1]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiLocalPath _parseLocalPath() {
    dynamic result0, result1;
    final int pos0 = pos, pos1 = pos;

    result1 = _parseIndexStep();
    if (result1 == null) {
      result1 = _parseIndirectionStep();
    }
    if (result1 != null) {
      result0 = [];
      while (result1 != null) {
        result0.add(result1);
        result1 = _parseIndexStep();
        if (result1 == null) {
          result1 = _parseIndirectionStep();
        }
      }
    } else {
      result0 = null;
    }
    if (result0 != null) {
      result1 = _parseTerminus();
      result1 = result1 != null ? result1 : '';
      if (result1 != null) {
        result0 = [result0, result1];
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((int offset, String localPathStepVal, String termStepVal) =>
              CfiLocalPath(steps: localPathStepVal, termStep: termStepVal))(
          pos0, result0[0], result0[1]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiStep _parseIndexStep() {
    dynamic result0, result1, result2;
    String result3, result4;
    final int pos0 = pos, pos1 = pos;
    int pos2;

    if (input.codeUnitAt(pos) == 47) {
      result0 = '/';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"/\"');
      }
    }
    if (result0 != null) {
      result1 = _parseInteger();
      if (result1 != null) {
        pos2 = pos;
        if (input.codeUnitAt(pos) == 91) {
          result2 = '[';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\"[\"');
          }
        }
        if (result2 != null) {
          result3 = _parseIdAssertion();
          if (result3 != null) {
            if (input.codeUnitAt(pos) == 93) {
              result4 = ']';
              pos++;
            } else {
              result4 = null;
              if (reportFailures == 0) {
                _matchFailed('\"]\"');
              }
            }
            if (result4 != null) {
              result2 = [result2, result3, result4];
            } else {
              result2 = null;
              pos = pos2;
            }
          } else {
            result2 = null;
            pos = pos2;
          }
        } else {
          result2 = null;
          pos = pos2;
        }
        result2 = result2 != null ? result2 : '';
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 =
          ((int offset, String stepLengthVal, List<int> assertVal) => CfiStep(
                type: 'indexStep',
                stepLength: int.parse(stepLengthVal),
                idAssertion: assertVal[1],
              ))(pos0, result0[1], result0[2]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiStep _parseIndirectionStep() {
    dynamic result0, result1, result2;
    String result3, result4;
    final int pos0 = pos, pos1 = pos;
    int pos2;

    if (input.substring(pos, 2) == '!/') {
      result0 = '!/';
      pos += 2;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"!/\"');
      }
    }
    if (result0 != null) {
      result1 = _parseInteger();
      if (result1 != null) {
        pos2 = pos;
        if (input.codeUnitAt(pos) == 91) {
          result2 = '[';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\"[\"');
          }
        }
        if (result2 != null) {
          result3 = _parseIdAssertion();
          if (result3 != null) {
            if (input.codeUnitAt(pos) == 93) {
              result4 = ']';
              pos++;
            } else {
              result4 = null;
              if (reportFailures == 0) {
                _matchFailed('\"]\"');
              }
            }
            if (result4 != null) {
              result2 = [result2, result3, result4];
            } else {
              result2 = null;
              pos = pos2;
            }
          } else {
            result2 = null;
            pos = pos2;
          }
        } else {
          result2 = null;
          pos = pos2;
        }
        result2 = result2 != null ? result2 : '';
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 =
          ((int offset, String stepLengthVal, List<int> assertVal) => CfiStep(
                type: 'indirectionStep',
                stepLength: int.parse(stepLengthVal),
                idAssertion: assertVal[1],
              ))(pos0, result0[1], result0[2]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiTerminus _parseTerminus() {
    dynamic result0, result1, result2, result3;
    String result4;
    final int pos0 = pos, pos1 = pos;
    int pos2;

    if (input.codeUnitAt(pos) == 58) {
      result0 = ':';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\":\"');
      }
    }
    if (result0 != null) {
      result1 = _parseInteger();
      if (result1 != null) {
        pos2 = pos;
        if (input.codeUnitAt(pos) == 91) {
          result2 = '[';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\"[\"');
          }
        }
        if (result2 != null) {
          result3 = _parseTextLocationAssertion();
          if (result3 != null) {
            if (input.codeUnitAt(pos) == 93) {
              result4 = ']';
              pos++;
            } else {
              result4 = null;
              if (reportFailures == 0) {
                _matchFailed('\"]\"');
              }
            }
            if (result4 != null) {
              result2 = [result2, result3, result4];
            } else {
              result2 = null;
              pos = pos2;
            }
          } else {
            result2 = null;
            pos = pos2;
          }
        } else {
          result2 = null;
          pos = pos2;
        }
        result2 = result2 != null ? result2 : '';
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((int offset, int textOffsetValue, String textLocAssertVal) =>
          CfiTerminus(
            type: 'textTerminus',
            offsetValue: textOffsetValue,
            textAssertion: textLocAssertVal[1],
          ))(pos0, result0[1], result0[2]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseIdAssertion() {
    String result0;
    final int pos0 = pos;

    result0 = _parseValue();
    if (result0 != null) {
      result0 = ((offset, idVal) => idVal)(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiTextLocationAssertion _parseTextLocationAssertion() {
    dynamic result0, result1;
    final int pos0 = pos, pos1 = pos;

    result0 = _parseCsv();
    result0 = result0 != null ? result0 : '';
    if (result0 != null) {
      result1 = _parseParameter();
      result1 = result1 != null ? result1 : '';
      if (result1 != null) {
        result0 = [result0, result1];
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((int offset, CfiCsv csvVal, CfiParameter paramVal) =>
          CfiTextLocationAssertion(
            type: 'textLocationAssertion',
            csv: csvVal,
            parameter: paramVal,
          ))(pos0, result0[0], result0[1]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiParameter _parseParameter() {
    dynamic result0;
    String result1, result2, result3;
    final int pos0 = pos, pos1 = pos;

    if (input.codeUnitAt(pos) == 59) {
      result0 = ';';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\";\"');
      }
    }
    if (result0 != null) {
      result1 = _parseValueNoSpace();
      if (result1 != null) {
        if (input.codeUnitAt(pos) == 61) {
          result2 = '=';
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('\"=\"');
          }
        }
        if (result2 != null) {
          result3 = _parseValueNoSpace();
          if (result3 != null) {
            result0 = [result0, result1, result2, result3];
          } else {
            result0 = null;
            pos = pos1;
          }
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((offset, paramLHSVal, paramRHSVal) => CfiParameter(
            type: 'parameter',
            lHSValue: paramLHSVal,
            rHSValue: paramRHSVal,
          ))(pos0, result0[1], result0[3]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  CfiCsv _parseCsv() {
    dynamic result0;
    String result1, result2;
    final int pos0 = pos, pos1 = pos;

    result0 = _parseValue();
    result0 = result0 != null ? result0 : '';

    if (result0 != null) {
      if (input.codeUnitAt(pos) == 44) {
        result1 = ',';
        pos++;
      } else {
        result1 = null;
        if (reportFailures == 0) {
          _matchFailed('\",\"');
        }
      }
      if (result1 != null) {
        result2 = _parseValue();
        result2 = result2 != null ? result2 : '';
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((offset, preAssertionVal, postAssertionVal) => CfiCsv(
            type: 'csv',
            preAssertion: preAssertionVal,
            postAssertion: postAssertionVal,
          ))(pos0, result0[0], result0[2]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseValueNoSpace() {
    dynamic result0;
    String result1;
    final int pos0 = pos;

    result1 = _parseEscapedSpecialChars();
    if (result1 == null) {
      result1 = _parseCharacter();
    }
    if (result1 != null) {
      result0 = List<String>();
      while (result1 != null) {
        result0.add(result1);
        result1 = _parseEscapedSpecialChars();
        if (result1 == null) {
          result1 = _parseCharacter();
        }
      }
    } else {
      result0 = null;
    }
    if (result0 != null) {
      result0 = ((offset, stringVal) => stringVal.join(''))(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseValue() {
    dynamic result0;
    String result1;
    final int pos0 = pos;

    result1 = _parseEscapedSpecialChars();
    if (result1 == null) {
      result1 = _parseCharacter();
      if (result1 == null) {
        result1 = _parseSpace();
      }
    }
    if (result1 != null) {
      result0 = List<String>();
      while (result1 != null) {
        result0.add(result1);
        result1 = _parseEscapedSpecialChars();
        if (result1 == null) {
          result1 = _parseCharacter();
          if (result1 == null) {
            result1 = _parseSpace();
          }
        }
      }
    } else {
      result0 = null;
    }
    if (result0 != null) {
      result0 = ((offset, stringVal) => stringVal.join(''))(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseEscapedSpecialChars() {
    dynamic result0;
    String result1;
    int pos0, pos1;

    pos0 = pos;
    pos1 = pos;
    result0 = _parseCircumflex();
    if (result0 != null) {
      result1 = _parseCircumflex();
      if (result1 != null) {
        result0 = [result0, result1];
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 == null) {
      pos1 = pos;
      result0 = _parseCircumflex();
      if (result0 != null) {
        result1 = _parseSquareBracket();
        if (result1 != null) {
          result0 = [result0, result1];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
      if (result0 == null) {
        pos1 = pos;
        result0 = _parseCircumflex();
        if (result0 != null) {
          result1 = _parseParentheses();
          if (result1 != null) {
            result0 = [result0, result1];
          } else {
            result0 = null;
            pos = pos1;
          }
        } else {
          result0 = null;
          pos = pos1;
        }
        if (result0 == null) {
          pos1 = pos;
          result0 = _parseCircumflex();
          if (result0 != null) {
            result1 = _parseComma();
            if (result1 != null) {
              result0 = [result0, result1];
            } else {
              result0 = null;
              pos = pos1;
            }
          } else {
            result0 = null;
            pos = pos1;
          }
          if (result0 == null) {
            pos1 = pos;
            result0 = _parseCircumflex();
            if (result0 != null) {
              result1 = _parseSemicolon();
              if (result1 != null) {
                result0 = [result0, result1];
              } else {
                result0 = null;
                pos = pos1;
              }
            } else {
              result0 = null;
              pos = pos1;
            }
            if (result0 == null) {
              pos1 = pos;
              result0 = _parseCircumflex();
              if (result0 != null) {
                result1 = _parseEqual();
                if (result1 != null) {
                  result0 = [result0, result1];
                } else {
                  result0 = null;
                  pos = pos1;
                }
              } else {
                result0 = null;
                pos = pos1;
              }
            }
          }
        }
      }
    }
    if (result0 != null) {
      result0 = ((offset, escSpecCharVal) => escSpecCharVal[1])(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  Map<String, dynamic> _parseNumber() {
    dynamic result0, result1, result2;
    String result3;
    int pos0, pos1, pos2;

    pos0 = pos;
    pos1 = pos;
    pos2 = pos;

    if (RegExp(r'^[1-9]').hasMatch(input[pos])) {
      result0 = input[pos];
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('[1-9]');
      }
    }
    if (result0 != null) {
      if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
        result2 = input[pos];
        pos++;
      } else {
        result2 = null;
        if (reportFailures == 0) {
          _matchFailed('[0-9]');
        }
      }
      if (result2 != null) {
        result1 = [];
        while (result2 != null) {
          result1.add(result2);
          if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
            result2 = input[pos];
            pos++;
          } else {
            result2 = null;
            if (reportFailures == 0) {
              _matchFailed('[0-9]');
            }
          }
        }
      } else {
        result1 = null;
      }
      if (result1 != null) {
        result0 = [result0, result1];
      } else {
        result0 = null;
        pos = pos2;
      }
    } else {
      result0 = null;
      pos = pos2;
    }
    if (result0 != null) {
      if (input.codeUnitAt(pos) == 46) {
        result1 = '.';
        pos++;
      } else {
        result1 = null;
        if (reportFailures == 0) {
          _matchFailed('\".\"');
        }
      }
      if (result1 != null) {
        pos2 = pos;
        result2 = [];
        if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
          result3 = input[pos];
          pos++;
        } else {
          result3 = null;
          if (reportFailures == 0) {
            _matchFailed('[0-9]');
          }
        }
        while (result3 != null) {
          result2.add(result3);
          if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
            result3 = input[pos];
            pos++;
          } else {
            result3 = null;
            if (reportFailures == 0) {
              _matchFailed('[0-9]');
            }
          }
        }
        if (result2 != null) {
          if (RegExp(r'^[1-9]').hasMatch(input[pos])) {
            result3 = input[pos];
            pos++;
          } else {
            result3 = null;
            if (reportFailures == 0) {
              _matchFailed('[1-9]');
            }
          }
          if (result3 != null) {
            result2 = [result2, result3];
          } else {
            result2 = null;
            pos = pos2;
          }
        } else {
          result2 = null;
          pos = pos2;
        }
        if (result2 != null) {
          result0 = [result0, result1, result2];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    } else {
      result0 = null;
      pos = pos1;
    }
    if (result0 != null) {
      result0 = ((offset, intPartVal, fracPartVal) =>
              intPartVal.join('') + '.' + fracPartVal.join(''))(
          pos0, result0[0], result0[2]);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseInteger() {
    dynamic result0;
    List<String> result1;
    String result2;
    int pos1;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 48) {
      result0 = '0';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"0\"');
      }
    }
    if (result0 == null) {
      pos1 = pos;
      if (RegExp(r'^[1-9]').hasMatch(input[pos])) {
        result0 = input[pos];
        pos++;
      } else {
        result0 = null;
        if (reportFailures == 0) {
          _matchFailed('[1-9]');
        }
      }
      if (result0 != null) {
        result1 = [];
        if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
          result2 = input[pos];
          pos++;
        } else {
          result2 = null;
          if (reportFailures == 0) {
            _matchFailed('[0-9]');
          }
        }
        while (result2 != null) {
          result1.add(result2);
          if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
            result2 = input[pos];
            pos++;
          } else {
            result2 = null;
            if (reportFailures == 0) {
              _matchFailed('[0-9]');
            }
          }
        }
        if (result1 != null) {
          result0 = [result0, result1];
        } else {
          result0 = null;
          pos = pos1;
        }
      } else {
        result0 = null;
        pos = pos1;
      }
    }
    if (result0 != null) {
      result0 = ((offset, integerVal) {
        if (integerVal == '0') {
          return '0';
        } else {
          return integerVal[0].concat(integerVal[1].join(''));
        }
      })(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseSpace() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 32) {
      result0 = ' ';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\" \"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => ' ')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseCircumflex() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 94) {
      result0 = '^';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"^\"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => '^')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseDoubleQuote() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 34) {
      result0 = '\"';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"\\\"\"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => '"')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseSquareBracket() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 91) {
      result0 = '[';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"[\"');
      }
    }
    if (result0 == null) {
      if (input.codeUnitAt(pos) == 93) {
        result0 = ']';
        pos++;
      } else {
        result0 = null;
        if (reportFailures == 0) {
          _matchFailed('\"]\"');
        }
      }
    }
    if (result0 != null) {
      result0 = ((offset, bracketVal) => bracketVal)(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseParentheses() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 40) {
      result0 = '(';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"(\"');
      }
    }
    if (result0 == null) {
      if (input.codeUnitAt(pos) == 41) {
        result0 = ')';
        pos++;
      } else {
        result0 = null;
        if (reportFailures == 0) {
          _matchFailed('\")\"');
        }
      }
    }
    if (result0 != null) {
      result0 = ((offset, paraVal) => paraVal)(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseComma() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 44) {
      result0 = ',';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\",\"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => ',')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseSemicolon() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 59) {
      result0 = ';';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\";\"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => ';')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseEqual() {
    String result0;
    final int pos0 = pos;

    if (input.codeUnitAt(pos) == 61) {
      result0 = '=';
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('\"=\"');
      }
    }
    if (result0 != null) {
      result0 = ((offset) => '=')(pos0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  String _parseCharacter() {
    String result0;
    final int pos0 = pos;

    if (RegExp(r'^[a-z]').hasMatch(input[pos])) {
      result0 = input[pos];
      pos++;
    } else {
      result0 = null;
      if (reportFailures == 0) {
        _matchFailed('[a-z]');
      }
    }
    if (result0 == null) {
      if (RegExp(r'^[A-Z]').hasMatch(input[pos])) {
        result0 = input[pos];
        pos++;
      } else {
        result0 = null;
        if (reportFailures == 0) {
          _matchFailed('[A-Z]');
        }
      }
      if (result0 == null) {
        if (RegExp(r'^[0-9]').hasMatch(input[pos])) {
          result0 = input[pos];
          pos++;
        } else {
          result0 = null;
          if (reportFailures == 0) {
            _matchFailed('[0-9]');
          }
        }
        if (result0 == null) {
          if (input.codeUnitAt(pos) == 45) {
            result0 = '-';
            pos++;
          } else {
            result0 = null;
            if (reportFailures == 0) {
              _matchFailed('\"-\"');
            }
          }
          if (result0 == null) {
            if (input.codeUnitAt(pos) == 95) {
              result0 = '_';
              pos++;
            } else {
              result0 = null;
              if (reportFailures == 0) {
                _matchFailed('\"_\"');
              }
            }
            if (result0 == null) {
              if (input.codeUnitAt(pos) == 46) {
                result0 = '.';
                pos++;
              } else {
                result0 = null;
                if (reportFailures == 0) {
                  _matchFailed('\".\"');
                }
              }
            }
          }
        }
      }
    }
    if (result0 != null) {
      result0 = ((offset, charVal) => charVal)(pos0, result0);
    }
    if (result0 == null) {
      pos = pos0;
    }
    return result0;
  }

  void _matchFailed(String failure) {
    if (pos < rightmostFailuresPos) {
      return;
    }

    if (pos > rightmostFailuresPos) {
      rightmostFailuresPos = pos;
      rightmostFailuresExpected = [];
    }

    rightmostFailuresExpected.add(failure);
  }

  List<String> _cleanupExpected(List<String> expected) {
    expected.sort();

    String lastExpected;
    final List<String> cleanExpected = [];
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] != lastExpected) {
        cleanExpected.add(expected[i]);
        lastExpected = expected[i];
      }
    }
    return cleanExpected;
  }

  String _padLeft(String input, String padding, int length) {
    String result = input;

    final padLength = length - input.length;
    for (int i = 0; i < padLength; i++) {
      result = padding + result;
    }

    return result;
  }

  String _escape(String ch) {
    final charCode = ch.codeUnitAt(0);
    String escapeChar = 'u';
    int length = 4;

    if (charCode <= 0xFF) {
      escapeChar = 'x';
      length = 2;
    }

    return '\\' +
        escapeChar +
        _padLeft(charCode.toRadixString(16).toUpperCase(), '0', length);
  }

  ErrorPosition _computeErrorPosition() {
    /*
         * The first idea was to use |String.split| to break the input up to the
         * error position along newlines and derive the line and column from
         * there. However IE's |split| implementation is so broken that it was
         * enough to prevent it.
         */

    int line = 1;
    int column = 1;
    bool seenCR = false;

    for (int i = 0; i < max(pos, rightmostFailuresPos); i++) {
      final ch = input[i];
      if (ch == '\n') {
        if (!seenCR) {
          line++;
        }
        column = 1;
        seenCR = false;
      } else if (ch == '\r' || ch == '\u2028' || ch == '\u2029') {
        line++;
        column = 1;
        seenCR = true;
      } else {
        column++;
        seenCR = false;
      }
    }

    return ErrorPosition(line: line, column: column);
  }
}