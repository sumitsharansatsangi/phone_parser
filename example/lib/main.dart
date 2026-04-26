import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phone_parser/phone_parser.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PhoneNumber? phoneNumber;
  String? downloadStatus;
  String? parseError;

  bool get _hasMetadata => MetadataFinder.info.isNotEmpty;

  PhoneNumber? _parsePhoneNumberInput(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (!_hasMetadata) {
      throw const PhoneNumberException(
        code: Code.notFound,
        description: 'Download metadata before parsing phone numbers',
      );
    }
    if (normalized.startsWith('+')) {
      return PhoneNumber.parse(normalized);
    }
    return PhoneNumber.parse(normalized, destinationCountry: 'US');
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoneNumber = phoneNumber;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text(
                'Try a phone number to see the parsing result below',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  setState(() => downloadStatus = 'Downloading...');
                  try {
                    // Use current directory for CLI, or path_provider for Flutter mobile/desktop
                    String dirPath;
                    try {
                      // Try path_provider for mobile/desktop
                      // ignore: import_of_legacy_library_into_null_safe

                      final dir = await getApplicationSupportDirectory();
                      dirPath = dir.path;
                    } catch (_) {
                      dirPath = Directory.current.path;
                    }
                    await MetadataFinder.readMetadataJson(dirPath);
                    setState(() {
                      downloadStatus = '✅ Download and save succeeded!';
                      parseError = null;
                      phoneNumber = _parsePhoneNumberInput('+16505551234');
                    });
                  } catch (e) {
                    setState(() => downloadStatus = '❌ Download failed: $e');
                  }
                },
                child: const Text('Test Metadata Download'),
              ),
              if (downloadStatus != null) ...[
                const SizedBox(height: 8),
                Text(downloadStatus!),
              ],
              const SizedBox(height: 12),
              TextFormField(
                initialValue: currentPhoneNumber?.international,
                decoration: InputDecoration(
                  label: const Text('Phone number'),
                  hintText: '+16505551234 or 6505551234',
                  errorText: parseError,
                ),
                onChanged: (value) {
                  try {
                    final parsed = _parsePhoneNumberInput(value);
                    setState(() {
                      phoneNumber = parsed;
                      parseError = null;
                    });
                  } on PhoneNumberException catch (e) {
                    setState(() {
                      phoneNumber = null;
                      parseError = e.description ?? e.code.toString();
                    });
                  } catch (_) {
                    setState(() {
                      phoneNumber = null;
                      parseError = 'Unable to parse phone number';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        ListTile(
                          title: const Text('international'),
                          trailing: currentPhoneNumber != null
                              ? Text(currentPhoneNumber.international)
                              : Text(
                                  _hasMetadata
                                      ? '-'
                                      : 'Download metadata to begin',
                                ),
                        ),
                        ListTile(
                          title: const Text('Formatted national'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber.formatNsn(
                                    format: NsnFormat.national,
                                  ),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Formatted international'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber.formatNsn(
                                    format: NsnFormat.international,
                                  ),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Iso code'),
                          trailing: currentPhoneNumber != null
                              ? Text(currentPhoneNumber.isoCode)
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Country Dial Code'),
                          trailing: currentPhoneNumber != null
                              ? Text(currentPhoneNumber.countryCode)
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid'),
                          trailing: currentPhoneNumber != null
                              ? Text(currentPhoneNumber.isValid().toString())
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Mobile'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.mobile)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Fixed Line'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.fixedLine)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Voip'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.voip)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Toll-Free'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.tollFree)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Premium Rate'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(
                                        type: PhoneNumberType.premiumRate,
                                      )
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Shared Cost'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.sharedCost)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Personal Number'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(
                                        type: PhoneNumberType.personalNumber,
                                      )
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid UAN'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.uan)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Pager'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.pager)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                        ListTile(
                          title: const Text('Is Valid Voice Mail'),
                          trailing: currentPhoneNumber != null
                              ? Text(
                                  currentPhoneNumber
                                      .isValid(type: PhoneNumberType.voiceMail)
                                      .toString(),
                                )
                              : const Text('-'),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
