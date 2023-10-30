import 'package:dash_run/audio/audio.dart';
import 'package:dash_run/game/game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leap/leap.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioController extends Mock implements AudioController {}

class _MockSimpleCombinedInput extends Mock implements SimpleCombinedInput {}

class _TestDashRunGame extends DashRunGame {
  _TestDashRunGame({
    required super.audioController,
  });

  @override
  Future<void> onLoad() async {
    // Noop
  }
}

class _TestPlayer extends Player {
  _TestPlayer({
    required _TestDashRunGame game,
    bool isAlive = true,
    bool isOnGround = true,
  })  : _game = game,
        _isAlive = isAlive,
        _isOnGround = isOnGround,
        super(
          cameraViewport: Vector2.all(200),
          levelSize: Vector2.all(200),
        );

  final bool _isAlive;
  final bool _isOnGround;
  final _TestDashRunGame _game;

  @override
  DashRunGame get gameRef => _game;

  @override
  bool get isAlive => _isAlive;

  @override
  bool get isOnGround => _isOnGround;

  @override
  Future<void> onLoad() async {
    // Noop
  }
}

void main() {
  group('PlayerControllerBehavior', () {
    setUpAll(() {
      registerFallbackValue(Sfx.jump);
    });
    _TestDashRunGame createGame([AudioController? audioController]) {
      final controller = audioController ?? _MockAudioController();
      when(() => controller.playSfx(any())).thenAnswer((_) async {});
      return _TestDashRunGame(
        audioController: controller,
      );
    }

    testWithGame(
      'can be attached to player',
      createGame,
      (game) async {
        final input = _MockSimpleCombinedInput();

        final player = _TestPlayer(game: game)..input = input;
        await game.ensureAdd(player);

        final playerControllerBehavior = PlayerControllerBehavior();
        await player.ensureAdd(playerControllerBehavior);

        expect(playerControllerBehavior.mounted, completes);
      },
    );

    testWithGame(
      'when the player is alive, jumping, on the groupd and input is '
      'pressed, continue to jump',
      createGame,
      (game) async {
        final input = _MockSimpleCombinedInput();

        final player = _TestPlayer(game: game)
          ..input = input
          ..jumping = true;

        when(() => input.isPressed).thenReturn(true);
        when(() => input.justPressed).thenReturn(false);

        await game.ensureAdd(player);

        final playerControllerBehavior = PlayerControllerBehavior();
        await player.ensureAdd(playerControllerBehavior);

        playerControllerBehavior.update(0);

        expect(player.jumping, isTrue);
      },
    );

    testWithGame(
      'when the player is alive, jumping, on the ground but input is not '
      'pressed, stop jumping',
      createGame,
      (game) async {
        final input = _MockSimpleCombinedInput();

        final player = _TestPlayer(game: game)
          ..input = input
          ..jumping = true;

        when(() => input.isPressed).thenReturn(false);
        when(() => input.justPressed).thenReturn(false);

        await game.ensureAdd(player);

        final playerControllerBehavior = PlayerControllerBehavior();
        await player.ensureAdd(playerControllerBehavior);

        playerControllerBehavior.update(0);

        expect(player.jumping, isFalse);
      },
    );

    testWithGame(
      'when the player is alive, not jumping, not on the ground and input is '
      "pressed, don't jump",
      createGame,
      (game) async {
        final input = _MockSimpleCombinedInput();

        final player = _TestPlayer(game: game, isOnGround: false)
          ..input = input
          ..jumping = false;

        when(() => input.isPressed).thenReturn(false);
        when(() => input.justPressed).thenReturn(false);

        await game.ensureAdd(player);

        final playerControllerBehavior = PlayerControllerBehavior();
        await player.ensureAdd(playerControllerBehavior);

        playerControllerBehavior.update(0);

        expect(player.jumping, isFalse);
      },
    );

    group('when a input was just pressed', () {
      testWithGame(
        'starts to walk when the input is right and the player is not walking',
        createGame,
        (game) async {
          final input = _MockSimpleCombinedInput();

          final player = _TestPlayer(game: game, isOnGround: false)
            ..input = input
            ..walking = false;

          when(() => input.isPressed).thenReturn(false);
          when(() => input.justPressed).thenReturn(true);
          when(() => input.isPressedRight).thenReturn(true);

          await game.ensureAdd(player);

          final playerControllerBehavior = PlayerControllerBehavior();
          await player.ensureAdd(playerControllerBehavior);

          playerControllerBehavior.update(0);

          expect(player.walking, isTrue);
        },
      );

      testWithGame(
        'jumps when is moving, not facing left and on the ground',
        createGame,
        (game) async {
          final input = _MockSimpleCombinedInput();

          final player = _TestPlayer(game: game)
            ..input = input
            ..jumping = false
            ..walking = true;

          when(() => input.isPressed).thenReturn(false);
          when(() => input.justPressed).thenReturn(true);
          when(() => input.isPressedRight).thenReturn(true);

          await game.ensureAdd(player);

          final playerControllerBehavior = PlayerControllerBehavior();
          await player.ensureAdd(playerControllerBehavior);

          playerControllerBehavior.update(0);

          expect(player.jumping, isTrue);
        },
      );

      testWithGame(
        'when not facing right, just stops and turns',
        createGame,
        (game) async {
          final input = _MockSimpleCombinedInput();

          final player = _TestPlayer(game: game)
            ..input = input
            ..jumping = false
            ..walking = true
            ..faceLeft = true;

          when(() => input.isPressed).thenReturn(false);
          when(() => input.justPressed).thenReturn(true);
          when(() => input.isPressedRight).thenReturn(true);

          await game.ensureAdd(player);

          final playerControllerBehavior = PlayerControllerBehavior();
          await player.ensureAdd(playerControllerBehavior);

          playerControllerBehavior.update(0);

          expect(player.faceLeft, isFalse);
        },
      );
    });
  });
}
