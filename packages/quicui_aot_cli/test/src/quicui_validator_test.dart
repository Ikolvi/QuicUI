import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/auth/auth.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group(QuicuiValidator, () {
    late Auth auth;
    late QuicuiLogger logger;
    late Platform platform;
    late Validator validator;
    late QuicuiEnv quicuiEnv;
    late QuicuiValidator quicuiValidator;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {
          authRef.overrideWith(() => auth),
          loggerRef.overrideWith(() => logger),
          platformRef.overrideWith(() => platform),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
        },
      );
    }

    setUp(() {
      auth = MockAuth();
      logger = MockQuicuiLogger();
      platform = MockPlatform();
      quicuiEnv = MockQuicuiEnv();
      validator = MockValidator();
      quicuiValidator = runWithOverrides(QuicuiValidator.new);
    });

    group('PreconditionFailedException', () {
      test('have correct exit codes', () {
        expect(QuicuiNotInitializedException().exitCode, ExitCode.config);
        expect(UserNotAuthorizedException().exitCode, ExitCode.noUser);
        expect(ValidationFailedException().exitCode, ExitCode.config);
        expect(
          UnsupportedOperatingSystemException().exitCode,
          ExitCode.unavailable,
        );
      });
    });

    group('validatePreconditions', () {
      test('throws UnsupportedOperatingSystemException '
          'when the operating system is not supported', () async {
        when(() => platform.operatingSystem).thenReturn(Platform.linux);
        const supportedOperatingSystems = {Platform.macOS, Platform.windows};
        await expectLater(
          runWithOverrides(
            () => quicuiValidator.validatePreconditions(
              supportedOperatingSystems: supportedOperatingSystems,
            ),
          ),
          throwsA(isA<UnsupportedOperatingSystemException>()),
        );
        verify(
          () => logger.err(
            '''This command is only supported on ${supportedOperatingSystems.join(' ,')}.''',
          ),
        ).called(1);
      });

      test('throws UserNotAuthorizedException '
          'when user is not authenticated', () async {
        when(() => auth.isAuthenticated).thenReturn(false);
        await expectLater(
          runWithOverrides(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: true,
            ),
          ),
          throwsA(isA<UserNotAuthorizedException>()),
        );
        verifyInOrder([
          () => logger.err('You must be logged in to run this command.'),
          () => logger.info(
            '''If you already have an account, run ${lightCyan.wrap('quicui login')} to sign in.''',
          ),
          () => logger.info(
            '''If you don't have a Quicui account, go to ${link(uri: Uri.parse('https://console.quicui.dev'))} to create one.''',
          ),
        ]);
      });

      group(
        '''when quicui has not been properly initialized for the current app''',
        () {
          group("when quicui.yaml doesn't exist", () {
            setUp(() {
              when(() => quicuiEnv.hasQuicuiYaml).thenReturn(false);
            });

            test(
              '''prints error message and throws QuicuiNotInitializedException''',
              () async {
                await expectLater(
                  runWithOverrides(
                    () => quicuiValidator.validatePreconditions(
                      checkQuicuiInitialized: true,
                    ),
                  ),
                  throwsA(isA<QuicuiNotInitializedException>()),
                );
                verifyInOrder([
                  () => logger.err(
                    '''Unable to find quicui.yaml. Are you in a quicui app directory?''',
                  ),
                  () => logger.info(
                    '''If you have not yet initialized your app, run ${lightCyan.wrap('quicui init')} to get started.''',
                  ),
                ]);
              },
            );
          });

          group("when pubspec.yaml doesn't contain "
              'quicui.yaml as an asset', () {
            setUp(() {
              when(() => quicuiEnv.hasQuicuiYaml).thenReturn(true);
              when(
                () => quicuiEnv.pubspecContainsQuicuiYaml,
              ).thenReturn(false);
            });

            test(
              '''prints error message and throws QuicuiNotInitializedException''',
              () async {
                await expectLater(
                  runWithOverrides(
                    () => quicuiValidator.validatePreconditions(
                      checkQuicuiInitialized: true,
                    ),
                  ),
                  throwsA(isA<QuicuiNotInitializedException>()),
                );
                verifyInOrder([
                  () => logger.err(
                    '''Your pubspec.yaml does not have quicui.yaml as a flutter asset.''',
                  ),
                  () => logger.info('''
To fix, update your pubspec.yaml to include the following:

  flutter:
    assets:
      - quicui.yaml # Add this line
'''),
                ]);
              },
            );
          });
        },
      );

      test('throws ValidationFailedException if validator fails', () async {
        final issue = ValidationIssue(
          message: 'test issue',
          severity: ValidationIssueSeverity.error,
          fix: () async {},
        );
        when(() => validator.canRunInCurrentContext()).thenReturn(true);
        when(() => validator.validate()).thenAnswer((_) async => [issue]);
        await expectLater(
          runWithOverrides(
            () => quicuiValidator.validatePreconditions(
              validators: [validator],
            ),
          ),
          throwsA(isA<ValidationFailedException>()),
        );
        verify(() => validator.validate()).called(1);
        verify(
          () => logger.err('Aborting due to validation errors.'),
        ).called(1);
        verify(
          () => logger.info('${red.wrap('[✗]')} ${issue.message}'),
        ).called(1);
        verify(
          () => logger.info(
            '''1 issue can be fixed automatically with ${lightCyan.wrap('quicui doctor --fix')}.''',
          ),
        ).called(1);
      });

      test(
        '''throws UnsupportedContextException if validator cannot be run in current context''',
        () async {
          const errorMessage = 'Cannot run in this context';
          when(() => validator.canRunInCurrentContext()).thenReturn(false);
          when(
            () => validator.incorrectContextMessage,
          ).thenReturn(errorMessage);
          await expectLater(
            runWithOverrides(
              () => quicuiValidator.validatePreconditions(
                validators: [validator],
              ),
            ),
            throwsA(isA<UnsupportedContextException>()),
          );
          verify(() => logger.err(errorMessage)).called(1);
        },
      );
    });

    group('validateFlavors', () {
      late QuicuiYaml quicuiYaml;

      setUp(() {
        when(
          () => quicuiEnv.getQuicuiYaml(),
        ).thenAnswer((_) => quicuiYaml);

        when(() => platform.isWindows).thenReturn(false);
        when(() => platform.isLinux).thenReturn(false);
      });

      group('when quicui.yaml has flavors', () {
        setUp(() {
          quicuiYaml = const QuicuiYaml(
            appId: 'test',
            flavors: {'flavorA': 'flavorA'},
          );
        });

        setUp(() {
          when(() => quicuiEnv.getQuicuiYaml()).thenReturn(quicuiYaml);
        });

        group('when platform does not support flavors', () {
          group('when a flavor arg is provided', () {
            test('validation fails', () async {
              await expectLater(
                runWithOverrides(
                  () => quicuiValidator.validateFlavors(
                    flavorArg: 'flavorA',
                    releasePlatform: ReleasePlatform.windows,
                  ),
                ),
                throwsA(isA<ValidationFailedException>()),
              );

              verify(
                () => logger.err('Flavors are not supported on this platform.'),
              ).called(1);
              verify(
                () => logger.info(
                  '''Please re-run this command without the --flavor argument. The app id ${lightCyan.wrap('test')} will be used.''',
                ),
              ).called(1);
            });
          });

          group('when no flavor arg is provided', () {
            test('passes validation', () async {
              await expectLater(
                runWithOverrides(
                  () => quicuiValidator.validateFlavors(
                    flavorArg: null,
                    releasePlatform: ReleasePlatform.windows,
                  ),
                ),
                completes,
              );
            });
          });
        });

        group('when platform supports flavors', () {
          group('when no flavor is specified', () {
            test('logs warning and fails validation', () async {
              await expectLater(
                runWithOverrides(
                  () => quicuiValidator.validateFlavors(
                    flavorArg: null,
                    releasePlatform: ReleasePlatform.android,
                  ),
                ),
                completes,
              );
              verify(
                () => logger.warn(
                  '''
The project has flavors (flavorA), but no --flavor argument was provided.
The default app id test will be used.''',
                ),
              ).called(1);
            });
          });

          group('when a flavor arg is provided that exists in the project', () {
            test('passes validation', () async {
              await expectLater(
                runWithOverrides(
                  () => quicuiValidator.validateFlavors(
                    flavorArg: 'flavorA',
                    releasePlatform: ReleasePlatform.android,
                  ),
                ),
                completes,
              );
            });
          });
        });
      });

      group('when quicui.yaml does not have flavors', () {
        setUp(() {
          quicuiYaml = const QuicuiYaml(appId: 'test');
        });

        group('when no flavor arg is provided', () {
          test('passes validation', () async {
            await expectLater(
              runWithOverrides(
                () => quicuiValidator.validateFlavors(
                  flavorArg: null,
                  releasePlatform: ReleasePlatform.android,
                ),
              ),
              completes,
            );
          });

          group('when a flavor arg is provided', () {
            test('fails validation', () async {
              await expectLater(
                runWithOverrides(
                  () => quicuiValidator.validateFlavors(
                    flavorArg: 'flavorA',
                    releasePlatform: ReleasePlatform.android,
                  ),
                ),
                throwsA(isA<ValidationFailedException>()),
              );
            });
          });
        });
      });
    });
  });
}
