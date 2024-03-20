import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MainGame extends StatefulWidget {
  const MainGame({Key? key}) : super(key: key);

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
  late Timer _timer;
  Random random = Random();
  List<_Object> _objects = [];
  double _speed = 1.0;
  double _gravity = 0.1;
  late Size _screenSize;
  int _numObjects = 1; // Number of objects to spawn
  double _spawnFrequency = 1.0; // Example frequency: 1 spawn per second
  int _destroyedCount = 0;
  int _missedCount = 0; // Count of missed animated containers that reached the top
  Duration _gameDuration = Duration(seconds: 20); // Total duration of the game
  late int _timeLeft; // Time left in the game

  @override
  void initState() {
    super.initState();
    _screenSize = Size(0, 0); // Initialize _screenSize with default values
    _timeLeft = _gameDuration.inSeconds; // Initialize time left to total game duration
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size; // Initialize _screenSize after the first frame is rendered
      _startSpawning(); // Start spawning immediately
      _startMovement(); // Start movement immediately
      _startGameTimer(); // Start the game timer
      _startTimerUpdate(); // Start the timer to update time left display
    });
  }

  void _startSpawning() {
    _timer = Timer.periodic(Duration(seconds: 1 ~/ _spawnFrequency), (timer) {
      _spawnObjects(); // Spawn objects at the specified frequency
    });
  }

  void _spawnObjects() {
    setState(() {
      for (int i = 0; i < _numObjects; i++) {
        double x = random.nextDouble() * (_screenSize.width - 24); // Random x coordinate within the screen width
        double y = _screenSize.height; // Start from the bottom of the screen
        double size = random.nextDouble() * 30 + 50; // Random text size between 10 and 30
        _objects.add(_Object(Offset(x, y), size));
      }
    });
  }

  void _startMovement() {
    _timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        for (int i = 0; i < _objects.length; i++) {
          double currentSpeed = _speed; // Store the current speed
          _objects[i].position = Offset(_objects[i].position.dx, _objects[i].position.dy - currentSpeed); // Move object upwards with constant speed
          if (_objects[i].position.dy < 0.0) {
            if (!_objects[i].destroyed) {
              _missedCount++; // Increment missed count if the object reached the top without being destroyed
            }
            _objects.removeAt(i); // Remove object when it goes out of screen
          }
        }
      });
    });
  }

  void _destroyObject(int index) {
    setState(() {
      _objects[index].destroyed = true; // Mark the object as destroyed
      _objects.removeAt(index); // Remove the object
      _destroyedCount++; // Increment destroyed count
    });
  }

  void _startGameTimer() {
    Timer(_gameDuration, () {
      // Redirect to game over screen when game duration is reached
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => GameOverScreen(score: _destroyedCount, missed: _missedCount),
      ));
    });
  }

  void _startTimerUpdate() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--; // Decrease the time left
      });
      if (_timeLeft <= 0) {
        timer.cancel(); // Stop the timer when time is up
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [

                Text('Destroyed: $_destroyedCount'),
                Text('/${_missedCount+_destroyedCount}'),
              ],
            ),

            Container(
              child: Row(
                children: [
                  Icon(Icons.timer),
                  Text('$_timeLeft s'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: _objects.asMap().entries.map((entry) {
          final index = entry.key;
          final object = entry.value;
          return Positioned(
            left: object.position.dx,
            top: object.position.dy,
            child: GestureDetector(
              onTap: () {
                _destroyObject(index);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 16),
                child: Text(
                  "O",
                  style: TextStyle(fontSize: object.size),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class _Object {
  Offset position;
  double size;
  bool destroyed = false; // Flag to track if the object is destroyed

  _Object(this.position, this.size);
}

class GameOverScreen extends StatelessWidget {
  final int score;
  final int missed;

  const GameOverScreen({Key? key, required this.score, required this.missed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Over'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: ${2*score-missed}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              'Destroyed: $score',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              'Missed: $missed',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to the game screen
              },
              child: Text('Replay'),
            ),
          ],
        ),
      ),
    );
  }
}
