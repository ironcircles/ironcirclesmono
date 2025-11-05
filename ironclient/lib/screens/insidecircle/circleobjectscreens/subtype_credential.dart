import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ironcirclesapp/blocs/circleobject_bloc.dart';
import 'package:ironcirclesapp/blocs/globalevent_bloc.dart';
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/blocs/usercircle_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/dialogselectnetwork.dart';
import 'package:ironcirclesapp/screens/widgets/icappbar.dart';
import 'package:ironcirclesapp/screens/widgets/selectnetworkstextbutton.dart';
import 'package:ironcirclesapp/screens/widgets/widget_export.dart';

class SubtypeCredential extends StatefulWidget {
  final UserCircleCache userCircleCache;
  final UserCircleBloc userCircleBloc;
  final CircleObjectBloc circleObjectBloc;
  final CircleObject? circleObject;
  final UserFurnace userFurnace;
  final List<UserFurnace> userFurnaces;
  final int screenMode;
  final GlobalEventBloc globalEventBloc;
  final Function? setNetworks;
  final int timer;
  final CircleObject? replyObject;
  final Function? update;
  final DateTime? scheduledFor;
  final bool wall;

  const SubtypeCredential({
    Key? key,
    this.circleObject,
    required this.userCircleCache,
    required this.globalEventBloc,
    required this.userCircleBloc,
    required this.circleObjectBloc,
    this.setNetworks,
    required this.userFurnaces,
    required this.userFurnace,
    required this.screenMode,
    required this.timer,
    required this.replyObject,
    this.scheduledFor,
    this.wall = false,
    this.update,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CredentialState();
  }
}

class _CredentialField {
  final String id;
  final String? label;
  final TextEditingController valueController;
  final bool isPassword;
  final DateTime? lastUpdated;

  _CredentialField({
    required this.id,
    this.label,
    required this.valueController,
    this.isPassword = false,
    this.lastUpdated,
  });

  void dispose() {
    valueController.dispose();
  }
}

class _CredentialState extends State<SubtypeCredential> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _application = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final List<_CredentialField> _customFields = [];
  final Map<String, bool> _customFieldsObscured =
      {}; // Track obscured state for custom password fields
  final List<Map<String, dynamic>> _passwordHistory =
      []; // Store password history with timestamps
  String _previousPassword = ''; // Track previous password value
  late DateTime _applicationLastUpdated;
  late DateTime _urlLastUpdated;
  late DateTime _usernameLastUpdated;
  late DateTime _passwordLastUpdated;
  bool _usernameObscured = false;
  bool _passwordObscured = true;
  User? _lastEdited;
  List<UserFurnace> _selectedNetworks = [];
  bool _showSubmit = true;
  bool _popped = false;

  bool _showSpinner = false;
  final spinkit = SpinKitDualRing(color: globalState.theme.spinner, size: 60);

  @override
  void initState() {
    super.initState();

    void setFields() {
      // Initialize timestamps with current time as default
      _applicationLastUpdated = DateTime.now();
      _urlLastUpdated = DateTime.now();
      _usernameLastUpdated = DateTime.now();
      _passwordLastUpdated = DateTime.now();

      // Try to parse JSON from body field first (new format with custom fields)
      if (widget.circleObject!.body != null &&
          widget.circleObject!.body!.isNotEmpty) {
        try {
          final data = json.decode(widget.circleObject!.body!);
          if (data is Map<String, dynamic>) {
            // Load standard fields
            _application.text = data['application'] ?? '';
            _url.text = data['url'] ?? '';
            _username.text = data['username'] ?? '';
            _password.text = data['password'] ?? '';
            _previousPassword = _password.text; // Track initial password

            // Load timestamps for standard fields
            if (data['applicationLastUpdated'] != null) {
              try {
                _applicationLastUpdated = DateTime.parse(
                  data['applicationLastUpdated'],
                );
              } catch (e) {
                _applicationLastUpdated = DateTime.now();
              }
            }
            if (data['urlLastUpdated'] != null) {
              try {
                _urlLastUpdated = DateTime.parse(data['urlLastUpdated']);
              } catch (e) {
                _urlLastUpdated = DateTime.now();
              }
            }
            if (data['usernameLastUpdated'] != null) {
              try {
                _usernameLastUpdated = DateTime.parse(
                  data['usernameLastUpdated'],
                );
              } catch (e) {
                _usernameLastUpdated = DateTime.now();
              }
            }
            if (data['passwordLastUpdated'] != null) {
              try {
                _passwordLastUpdated = DateTime.parse(
                  data['passwordLastUpdated'],
                );
              } catch (e) {
                _passwordLastUpdated = DateTime.now();
              }
            }

            // Load password history
            if (data['passwordHistory'] is List) {
              _passwordHistory.clear();
              for (var entry in data['passwordHistory']) {
                if (entry is Map<String, dynamic>) {
                  _passwordHistory.add({
                    'password': entry['password'] ?? '',
                    'timestamp':
                        entry['timestamp'] ?? DateTime.now().toIso8601String(),
                  });
                }
              }
            }

            // Load custom fields
            if (data['customFields'] is List) {
              for (var field in data['customFields']) {
                if (field is Map<String, dynamic>) {
                  DateTime? fieldLastUpdated;
                  if (field['lastUpdated'] != null) {
                    try {
                      fieldLastUpdated = DateTime.parse(field['lastUpdated']);
                    } catch (e) {
                      debugPrint('Error parsing field lastUpdated: $e');
                    }
                  }

                  final fieldId =
                      DateTime.now().millisecondsSinceEpoch.toString() +
                      _customFields.length.toString();
                  final isPassword = field['isPassword'] ?? false;

                  _customFields.add(
                    _CredentialField(
                      id: fieldId,
                      label: field['label'] ?? '',
                      valueController: TextEditingController(
                        text: field['value'] ?? '',
                      ),
                      isPassword: isPassword,
                      lastUpdated: fieldLastUpdated,
                    ),
                  );

                  // Initialize obscured state for password fields (default to obscured)
                  if (isPassword) {
                    _customFieldsObscured[fieldId] = true;
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing credential JSON: $e');
          // Fall back to old format if JSON parsing fails
          _loadFromOldFormat();
        }
      }
      // Fallback to old format using subString fields (backward compatibility)
      else {
        _loadFromOldFormat();
      }

      if (widget.circleObject!.lastEdited != null) {
        _lastEdited = widget.circleObject!.lastEdited;
      }
    }

    if (widget.screenMode == ScreenMode.EDIT ||
        widget.screenMode == ScreenMode.READONLY) {
      _showSubmit = false;
      setFields();
    } else if (widget.circleObject != null) {
      setFields();
    } else {
      // Initialize timestamps for new credentials
      _applicationLastUpdated = DateTime.now();
      _urlLastUpdated = DateTime.now();
      _usernameLastUpdated = DateTime.now();
      _passwordLastUpdated = DateTime.now();
    }

    widget.globalEventBloc.circleObjectBroadcast.listen(
      (circleObject) {
        if (mounted && widget.screenMode == ScreenMode.ADD) {
          if (!_popped) {
            _popped = true;
            _exit(circleObject: circleObject);
          }
        }
      },
      onError: (err) {
        setState(() {
          _showSpinner = false;
        });
        debugPrint("error $err");
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          2,
          true,
        );
      },
      cancelOnError: false,
    );

    widget.circleObjectBloc.saveResults.listen(
      (circleObject) {
        if (mounted && widget.screenMode != ScreenMode.ADD) {
          if (!_popped) {
            _popped = true;
            Navigator.of(context).pop(circleObject);
          }
        }
      },
      onError: (err) {
        setState(() {
          _showSpinner = false;
        });
        debugPrint("error $err");
        FormattedSnackBar.showSnackbarWithContext(
          context,
          err.toString(),
          "",
          2,
          true,
        );
      },
      cancelOnError: false,
    );
  }

  void _loadFromOldFormat() {
    if (widget.circleObject!.subString1 != null) {
      _application.text = widget.circleObject!.subString1!;
    }
    if (widget.circleObject!.subString2 != null) {
      _url.text = widget.circleObject!.subString2!;
    }
    if (widget.circleObject!.subString3 != null) {
      _username.text = widget.circleObject!.subString3!;
    }
    if (widget.circleObject!.subString4 != null) {
      _password.text = widget.circleObject!.subString4!;
      _previousPassword = _password.text; // Track initial password
    }
  }

  @override
  void dispose() {
    _application.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    for (var field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _addCustomField() {
    // Show dialog to get field name and whether it should be obscured
    final TextEditingController fieldNameController = TextEditingController();
    bool isPasswordField = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: globalState.theme.background,
                  title: Text(
                    'Add Custom Field',
                    style: TextStyle(color: globalState.theme.listTitle),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: fieldNameController,
                        autofocus: true,
                        maxLength: 25,
                        style: TextStyle(color: globalState.theme.listTitle),
                        decoration: InputDecoration(
                          labelText: 'Field Name (max 25 chars)',
                          labelStyle: TextStyle(
                            color: globalState.theme.cardSubTitle,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: globalState.theme.cardSubTitle,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: globalState.theme.button,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isPasswordField,
                            onChanged: (value) {
                              setDialogState(() {
                                isPasswordField = value ?? false;
                              });
                            },
                            activeColor: globalState.theme.button,
                          ),
                          Expanded(
                            child: Text(
                              'Obscure text (for sensitive data)',
                              style: TextStyle(
                                color: globalState.theme.listTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: globalState.theme.button),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (fieldNameController.text.trim().isNotEmpty) {
                          setState(() {
                            final fieldId =
                                DateTime.now().millisecondsSinceEpoch
                                    .toString();
                            _customFields.add(
                              _CredentialField(
                                id: fieldId,
                                label: fieldNameController.text.trim(),
                                valueController: TextEditingController(),
                                isPassword: isPasswordField,
                                lastUpdated: DateTime.now(),
                              ),
                            );
                            // Initialize obscured state for password fields (default to obscured)
                            if (isPasswordField) {
                              _customFieldsObscured[fieldId] = true;
                            }
                            _setDirty();
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Add',
                        style: TextStyle(color: globalState.theme.button),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _removeCustomField(String id) {
    setState(() {
      final index = _customFields.indexWhere((field) => field.id == id);
      if (index != -1) {
        _customFields[index].dispose();
        _customFields.removeAt(index);
        _customFieldsObscured.remove(id);
        _setDirty();
      }
    });
  }

  void _toggleCustomFieldVisibility(String id) {
    setState(() {
      _customFieldsObscured[id] = !(_customFieldsObscured[id] ?? false);
    });
  }

  void _addPasswordToHistory(String oldPassword) {
    if (oldPassword.isNotEmpty && oldPassword != _password.text) {
      // Check if this password already exists in history
      bool alreadyExists = _passwordHistory.any(
        (entry) => entry['password'] == oldPassword,
      );
      if (!alreadyExists) {
        _passwordHistory.insert(0, {
          'password': oldPassword,
          'timestamp': DateTime.now().toIso8601String(),
        });
        // Keep only last 10 passwords
        if (_passwordHistory.length > 10) {
          _passwordHistory.removeRange(10, _passwordHistory.length);
        }
      }
    }
  }

  void _showPasswordHistory() {
    // Track which passwords are visible in the dialog
    final Map<int, bool> visiblePasswords = {};

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: globalState.theme.background,
                  title: Text(
                    'Password History',
                    style: TextStyle(color: globalState.theme.listTitle),
                  ),
                  content:
                      _passwordHistory.isEmpty
                          ? Text(
                            'No password history available',
                            style: TextStyle(
                              color: globalState.theme.listTitle,
                            ),
                          )
                          : SizedBox(
                            width: double.maxFinite,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _passwordHistory.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    color: globalState.theme.cardSubTitle
                                        .withOpacity(0.3),
                                  ),
                              itemBuilder: (context, index) {
                                final entry = _passwordHistory[index];
                                final password = entry['password'] ?? '';
                                final timestamp = entry['timestamp'] ?? '';
                                final isVisible =
                                    visiblePasswords[index] ?? false;
                                DateTime? dateTime;
                                try {
                                  dateTime = DateTime.parse(timestamp);
                                } catch (e) {
                                  dateTime = null;
                                }

                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isVisible ? password : '••••••••',
                                          style: TextStyle(
                                            color: globalState.theme.listTitle,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: globalState.theme.button,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            visiblePasswords[index] =
                                                !isVisible;
                                          });
                                        },
                                        tooltip: isVisible ? 'Hide' : 'Show',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: globalState.theme.button,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _copyToClipBoard(password);
                                        },
                                        tooltip: 'Copy to clipboard',
                                      ),
                                    ],
                                  ),
                                  subtitle:
                                      dateTime != null
                                          ? Text(
                                            _formatDate(dateTime),
                                            style: TextStyle(
                                              color:
                                                  globalState
                                                      .theme
                                                      .labelTextSubtle,
                                            ),
                                          )
                                          : null,
                                );
                              },
                            ),
                          ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: globalState.theme.button),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _updateFieldTimestamp(String id) {
    final index = _customFields.indexWhere((field) => field.id == id);
    if (index != -1) {
      final field = _customFields[index];
      _customFields[index] = _CredentialField(
        id: field.id,
        label: field.label,
        valueController: field.valueController,
        isPassword: field.isPassword,
        lastUpdated: DateTime.now(),
      );
    }
  }

  void _editFieldLabel(String id) {
    final index = _customFields.indexWhere((field) => field.id == id);
    if (index == -1) return;

    final field = _customFields[index];
    final TextEditingController labelController = TextEditingController(
      text: field.label ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: globalState.theme.background,
            title: Text(
              'Edit Field Label',
              style: TextStyle(color: globalState.theme.listTitle),
            ),
            content: TextField(
              controller: labelController,
              autofocus: true,
              maxLength: 25,
              style: TextStyle(color: globalState.theme.listTitle),
              decoration: InputDecoration(
                labelText: 'Field Name (max 25 chars)',
                labelStyle: TextStyle(color: globalState.theme.cardSubTitle),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: globalState.theme.cardSubTitle),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: globalState.theme.button),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: globalState.theme.button),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (labelController.text.trim().isNotEmpty) {
                    setState(() {
                      _customFields[index] = _CredentialField(
                        id: field.id,
                        label: labelController.text.trim(),
                        valueController: field.valueController,
                        isPassword: field.isPassword,
                        lastUpdated: field.lastUpdated,
                      );
                      _setDirty();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: globalState.theme.button),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final makeBody = Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Application field (required)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row with timestamp and character count
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.application,
                              style: TextStyle(
                                fontSize: 14,
                                color: globalState.theme.cardSubTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Text(
                              _formatDate(_applicationLastUpdated),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          SizedBox(
                            width: 16,
                          ), // Empty space to align with eye icon
                          SizedBox(width: 4),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '${_application.text.length}/${TextLength.Smallest}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Field with copy button
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ExpandingLineText(
                            maxLength: TextLength.Smallest,
                            labelText: '',
                            maxLines: 4,
                            counterText: '',
                            controller: _application,
                            onChanged: (value) {
                              setState(() {
                                _applicationLastUpdated = DateTime.now();
                              });
                              _setDirty();
                            },
                            validator: (value) {
                              if (value.toString().isEmpty) {
                                return 'required';
                              }
                              return null;
                            },
                          ),
                        ),
                        widget.screenMode == ScreenMode.EDIT &&
                                _application.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: globalState.theme.button,
                                size: 20,
                              ),
                              onPressed: () {
                                _copyToClipBoard(_application.text);
                              },
                              tooltip: 'Copy to clipboard',
                            )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),

              // URL field
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row with timestamp and character count
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.linkWord,
                              style: TextStyle(
                                fontSize: 14,
                                color: globalState.theme.cardSubTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Text(
                              _formatDate(_urlLastUpdated),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          SizedBox(
                            width: 16,
                          ), // Empty space to align with eye icon
                          SizedBox(width: 4),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '${_url.text.length}/${TextLength.Small}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Field with copy button
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ExpandingLineText(
                            maxLength: TextLength.Small,
                            labelText: '',
                            counterText: '',
                            controller: _url,
                            onChanged: (value) {
                              setState(() {
                                _urlLastUpdated = DateTime.now();
                              });
                              _setDirty();
                            },
                          ),
                        ),
                        widget.screenMode == ScreenMode.EDIT &&
                                _url.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: globalState.theme.button,
                                size: 20,
                              ),
                              onPressed: () {
                                _copyToClipBoard(_url.text);
                              },
                              tooltip: 'Copy to clipboard',
                            )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),

              // Username field
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row with timestamp and character count
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.username,
                              style: TextStyle(
                                fontSize: 14,
                                color: globalState.theme.cardSubTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Text(
                              _formatDate(_usernameLastUpdated),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _usernameObscured = !_usernameObscured;
                              });
                            },
                            child: Icon(
                              _usernameObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: globalState.theme.button,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 4),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '${_username.text.length}/${TextLength.Smallest}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Field with copy button
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ExpandingLineText(
                            maxLength: TextLength.Smallest,
                            labelText: '',
                            maxLines: 1,
                            counterText: '',
                            obscureText: _usernameObscured,
                            controller: _username,
                            onChanged: (value) {
                              setState(() {
                                _usernameLastUpdated = DateTime.now();
                              });
                              _setDirty();
                            },
                          ),
                        ),
                        widget.screenMode == ScreenMode.EDIT &&
                                _username.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: globalState.theme.button,
                                size: 20,
                              ),
                              onPressed: () {
                                _copyToClipBoard(_username.text);
                              },
                              tooltip: 'Copy to clipboard',
                            )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),

              // Password field
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row with timestamp and character count
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.password,
                              style: TextStyle(
                                fontSize: 14,
                                color: globalState.theme.cardSubTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 65,
                            child: Text(
                              _formatDate(_passwordLastUpdated),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _passwordObscured = !_passwordObscured;
                              });
                            },
                            child: Icon(
                              _passwordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: globalState.theme.button,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: _showPasswordHistory,
                            child: Icon(
                              Icons.history,
                              color: globalState.theme.button,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 4),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '${_password.text.length}/${TextLength.Smallest}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11,
                                color: globalState.theme.labelTextSubtle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Field with copy button
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ExpandingLineText(
                            maxLength: TextLength.Smallest,
                            labelText: '',
                            maxLines: 1,
                            counterText: '',
                            obscureText: _passwordObscured,
                            controller: _password,
                            onChanged: (value) {
                              setState(() {
                                _passwordLastUpdated = DateTime.now();
                              });
                              _setDirty();
                            },
                          ),
                        ),
                        widget.screenMode == ScreenMode.EDIT &&
                                _password.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: globalState.theme.button,
                                size: 20,
                              ),
                              onPressed: () {
                                _copyToClipBoard(_password.text);
                              },
                              tooltip: 'Copy to clipboard',
                            )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),

              // Custom fields
              ..._customFields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field label row with timestamp and character count (clickable to edit)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        (widget.screenMode == ScreenMode.EDIT ||
                                                widget.screenMode ==
                                                    ScreenMode.ADD)
                                            ? () => _editFieldLabel(field.id)
                                            : null,
                                    child: Text(
                                      field.label ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: globalState.theme.cardSubTitle,
                                        fontWeight: FontWeight.w500,
                                        decoration:
                                            (widget.screenMode ==
                                                        ScreenMode.EDIT ||
                                                    widget.screenMode ==
                                                        ScreenMode.ADD)
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  // Remove field button (inline with label)
                                  (widget.screenMode == ScreenMode.EDIT ||
                                          widget.screenMode == ScreenMode.ADD)
                                      ? GestureDetector(
                                        onTap: () {
                                          _removeCustomField(field.id);
                                        },
                                        child: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      )
                                      : Container(),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 65,
                              child: Text(
                                _formatDate(
                                  field.lastUpdated ?? DateTime.now(),
                                ),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: globalState.theme.labelTextSubtle,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            // Eye icon toggle for password fields, or empty space for alignment
                            field.isPassword
                                ? GestureDetector(
                                  onTap: () {
                                    _toggleCustomFieldVisibility(field.id);
                                  },
                                  child: Icon(
                                    (_customFieldsObscured[field.id] ?? true)
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: globalState.theme.button,
                                    size: 16,
                                  ),
                                )
                                : SizedBox(
                                  width: 16,
                                ), // Empty space to align with eye icon
                            SizedBox(width: 4),
                            SizedBox(
                              width: 55,
                              child: Text(
                                '${field.valueController.text.length}/${TextLength.Small}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: globalState.theme.labelTextSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Value field with all buttons
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ExpandingLineText(
                              maxLength: TextLength.Small,
                              labelText: '',
                              maxLines: field.isPassword ? 1 : 4,
                              counterText: '',
                              obscureText:
                                  field.isPassword &&
                                  (_customFieldsObscured[field.id] ?? true),
                              controller: field.valueController,
                              onChanged: (value) {
                                setState(() {
                                  _updateFieldTimestamp(field.id);
                                });
                                _setDirty();
                              },
                            ),
                          ),
                          // Copy button (only in edit mode)
                          widget.screenMode == ScreenMode.EDIT &&
                                  field.valueController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: globalState.theme.button,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _copyToClipBoard(field.valueController.text);
                                },
                                tooltip: 'Copy to clipboard',
                              )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Add field button
              (widget.screenMode == ScreenMode.EDIT ||
                      widget.screenMode == ScreenMode.ADD)
                  ? Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: TextButton.icon(
                      icon: Icon(Icons.add, color: globalState.theme.button),
                      label: Text(
                        'Add Field',
                        style: TextStyle(color: globalState.theme.button),
                      ),
                      onPressed: _addCustomField,
                    ),
                  )
                  : Container(),

              // Last edited by
              _lastEdited != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.lastEditedBy.toLowerCase()} ',
                          textScaler: TextScaler.linear(
                            globalState.messageHeaderScaleFactor,
                          ),
                          style: TextStyle(color: globalState.theme.listTitle),
                        ),
                        Expanded(
                          child: ICText(
                            _lastEdited!.getUsernameAndAlias(globalState),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            textScaleFactor:
                                globalState.messageHeaderScaleFactor,
                            color:
                                _lastEdited!.id == widget.userFurnace.userid
                                    ? globalState.theme.userObjectText
                                    : Member.getMemberColor(
                                      widget.userFurnace,
                                      _lastEdited,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : Container(),
            ],
          ),
        ),
      ),
    );

    final makeBottom = SizedBox(
      height: 55.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(
          children: <Widget>[
            _showSubmit
                ? Expanded(
                  child: GradientButton(
                    text:
                        widget.screenMode == ScreenMode.ADD
                            ? AppLocalizations.of(context)!.create.toUpperCase()
                            : AppLocalizations.of(
                              context,
                            )!.update.toUpperCase(),
                    onPressed: () {
                      _save();
                    },
                  ),
                )
                : Container(),
          ],
        ),
      ),
    );

    _pop() {
      if (widget.wall == false && _isDirty()) {
        DialogYesNo.askYesNo(
          context,
          widget.screenMode == ScreenMode.ADD
              ? widget.circleObject == null || widget.circleObject!.id != null
                  ? AppLocalizations.of(context)!.saveDraftTitle
                  : AppLocalizations.of(context)!.updateDraftTitle
              : AppLocalizations.of(context)!.saveChangesTitle,
          widget.screenMode == ScreenMode.ADD
              ? widget.circleObject == null || widget.circleObject!.id != null
                  ? AppLocalizations.of(context)!.saveDraftMessage
                  : AppLocalizations.of(context)!.updateDraftMessage
              : AppLocalizations.of(context)!.saveChangesMessage,
          widget.screenMode == ScreenMode.ADD ? _saveDraft : _upsert,
          _exitCheckToSave,
          false,
        );
      } else {
        _exitCheckToSave();
      }
    }

    final _formWidget = Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: globalState.theme.background,
        key: _scaffoldKey,
        appBar: ICAppBar(
          title:
              widget.screenMode == ScreenMode.ADD
                  ? AppLocalizations.of(context)!.newCredential
                  : AppLocalizations.of(context)!.credential,
          pop: _pop,
        ),
        body: SafeArea(
          left: false,
          top: false,
          right: false,
          bottom: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    makeBody,
                    _showSpinner ? Center(child: spinkit) : Container(),
                  ],
                ),
              ),

              ///select a furnace to post to
              (widget.screenMode == ScreenMode.EDIT ||
                          widget.screenMode == ScreenMode.ADD) &&
                      widget.userFurnaces.length > 1 &&
                      widget.wall &&
                      widget.setNetworks != null
                  ? Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            left: 2,
                            right: 2,
                          ),
                          child: SelectNetworkTextButton(
                            userFurnaces: widget.userFurnaces,
                            selectedNetworks: _selectedNetworks,
                            callback: _setNetworks,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Container(),
              widget.screenMode == ScreenMode.EDIT ||
                      widget.screenMode == ScreenMode.ADD
                  ? makeBottom
                  : Container(),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        _pop();
      },
      child:
          Platform.isIOS
              ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 200) {
                    _pop();
                  }
                },
                child: _formWidget,
              )
              : _formWidget,
    );
  }

  bool _isDirty() {
    if (widget.screenMode == ScreenMode.ADD) {
      if (_application.text.isNotEmpty ||
          _url.text.isNotEmpty ||
          _username.text.isNotEmpty ||
          _password.text.isNotEmpty) {
        return true;
      }
      for (var field in _customFields) {
        if (field.valueController.text.isNotEmpty) {
          return true;
        }
      }
    } else if (widget.circleObject != null) {
      // Compare current state with saved state
      final currentJson = _buildCredentialJson();
      final savedJson = widget.circleObject!.body ?? '';

      if (currentJson != savedJson) {
        return true;
      }

      // Also check if standard fields changed (for backward compatibility)
      if (widget.circleObject!.subString1 != _application.text ||
          widget.circleObject!.subString2 != _url.text ||
          widget.circleObject!.subString3 != _username.text ||
          widget.circleObject!.subString4 != _password.text) {
        return true;
      }
    }

    return false;
  }

  _setDirty() {
    _showSubmit = false;

    if (widget.screenMode == ScreenMode.EDIT) {
      if (_isDirty()) _showSubmit = true;
    } else if (widget.screenMode == ScreenMode.ADD) {
      _showSubmit = true;
    }

    setState(() {});
  }

  String _buildCredentialJson() {
    final data = {
      'application': _application.text,
      'url': _url.text,
      'username': _username.text,
      'password': _password.text,
      'applicationLastUpdated': _applicationLastUpdated.toIso8601String(),
      'urlLastUpdated': _urlLastUpdated.toIso8601String(),
      'usernameLastUpdated': _usernameLastUpdated.toIso8601String(),
      'passwordLastUpdated': _passwordLastUpdated.toIso8601String(),
      'passwordHistory': _passwordHistory,
      'customFields':
          _customFields
              .map(
                (field) => {
                  'label': field.label ?? '',
                  'value': field.valueController.text,
                  'isPassword': field.isPassword,
                  'lastUpdated':
                      (field.lastUpdated ?? DateTime.now()).toIso8601String(),
                },
              )
              .toList(),
    };
    return json.encode(data);
  }

  CircleObject _prepObject() {
    CircleObject newCircleObject = CircleObject.prepNewCircleObject(
      widget.userCircleCache,
      widget.userFurnace,
      '',
      0,
      widget.replyObject,
      type: CircleObjectType.CIRCLEMESSAGE,
    );

    newCircleObject.subType = SubType.LOGIN_INFO;

    // Store all data as JSON in the body field
    newCircleObject.body = _buildCredentialJson();

    // Also store the standard fields for backward compatibility
    newCircleObject.subString1 = _application.text;
    newCircleObject.subString2 = _url.text;
    newCircleObject.subString3 = _username.text;
    newCircleObject.subString4 = _password.text;

    newCircleObject.emojiOnly = false;

    return newCircleObject;
  }

  _upsert() {
    try {
      if (_formKey.currentState!.validate()) {
        if (widget.screenMode == ScreenMode.ADD) {
          CircleObject newCircleObject = _prepObject();

          if (widget.timer != UserDisappearingTimer.OFF)
            newCircleObject.timer = widget.timer;

          if (widget.scheduledFor != null) {
            newCircleObject.scheduledFor = widget.scheduledFor;
          }

          newCircleObject.lastEdited = widget.userFurnace.user;

          if (widget.wall) {
            ///Don't save the object if it's a wall post. The User might have selected multiple networks
            //_pop(newObject);
            _exit(circleObject: newCircleObject);
          } else {
            widget.circleObjectBloc.saveCircleObject(
              widget.globalEventBloc,
              widget.userFurnace,
              widget.userCircleCache,
              newCircleObject,
            );
          }
        } else if (widget.screenMode == ScreenMode.EDIT) {
          // Add old password to history if it changed
          if (_previousPassword.isNotEmpty &&
              _previousPassword != _password.text) {
            _addPasswordToHistory(_previousPassword);
            _previousPassword = _password.text; // Update to track new password
          }

          // Store all data as JSON
          widget.circleObject!.body = _buildCredentialJson();

          // Also update standard fields for backward compatibility
          widget.circleObject!.subString1 = _application.text;
          widget.circleObject!.subString2 = _url.text;
          widget.circleObject!.subString3 = _username.text;
          widget.circleObject!.subString4 = _password.text;

          widget.circleObject!.lastEdited = widget.userFurnace.user;

          widget.circleObjectBloc.updateCircleObject(
            widget.circleObject!,
            widget.userFurnace,
          );
        }

        setState(() {
          _showSpinner = true;
        });
      }
    } catch (err, trace) {
      LogBloc.insertError(err, trace);
      debugPrint('Credentials._create: $err');
    }
  }

  _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSpinner = true;
      });

      if (widget.wall) {
        if (_selectedNetworks.isEmpty) {
          if (widget.userFurnaces.length == 1) {
            _setNetworksAndPost(widget.userFurnaces);
          } else {
            List<UserFurnace>? selectedNetworks =
                await DialogSelectNetworks.selectNetworks(
                  context: context,
                  networks: widget.userFurnaces,
                  callback: _setNetworksAndPost,
                  existingNetworksFilter: _selectedNetworks,
                );

            if (selectedNetworks == null) {
              setState(() {
                _showSpinner = false;
              });
            }
          }
        } else {
          _upsert();
        }
      } else {
        _upsert();
      }
    }
  }

  _saveDraft() async {
    CircleObject circleObject = _prepObject();

    await widget.circleObjectBloc.saveDraft(
      widget.userFurnace,
      widget.userCircleCache,
      '',
      null,
      null,
      preppedObject: circleObject,
    );

    _exit();
  }

  _exitCheckToSave() async {
    if (widget.circleObject != null && widget.circleObject!.draft) {
      await widget.circleObjectBloc.saveDraft(
        widget.userFurnace,
        widget.userCircleCache,
        '',
        null,
        null,
        preppedObject: widget.circleObject!,
      );
    }

    _exit();
  }

  _exit({CircleObject? circleObject}) {
    _popped = true;

    _closeKeyboard();
    if (circleObject != null) {
      Navigator.of(context).pop(circleObject);
    } else {
      Navigator.pop(context);
    }
  }

  _closeKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  ///callback for the automatic popup
  _setNetworksAndPost(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;

      _upsert();
    }
  }

  ///callback for the ui control tap
  _setNetworks(List<UserFurnace> newlySelectedNetworks) {
    if (widget.setNetworks != null) {
      widget.setNetworks!(newlySelectedNetworks);
      _selectedNetworks = newlySelectedNetworks;
      setState(() {});
    }
  }

  _copyToClipBoard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}';
  }
}
