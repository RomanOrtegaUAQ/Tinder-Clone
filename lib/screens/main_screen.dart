import 'dart:math' as math; // For rotation calculation
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/character_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  // Add SingleTickerProviderStateMixin
  final ApiService _apiService = ApiService();
  List<Character> _characters = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;

  // Swipe animation variables
  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;
  late AnimationController _swipeAnimationController;
  late Animation<Offset> _swipeAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadCharacters();

    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swipeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextCharacterAfterSwipe();
      }
    });
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final newCharacters = await _apiService.getCharacters(page: _currentPage);
      setState(() {
        _characters.addAll(newCharacters);
        _isLoading = false;
        if (_characters.isEmpty && _currentPage == 1) {
          // Check if it's the first load and no characters
          _errorMessage = "No characters found.";
        }
        // Reset card position for new character if not dragging
        if (!_isDragging) {
          _cardOffset = Offset.zero;
          _cardRotation = 0.0;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _nextCharacterAfterSwipe() {
    setState(() {
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
      _isDragging = false; // Reset dragging state
      _swipeAnimationController.reset();

      if (_characters.isNotEmpty) {
        // Ensure there are characters before trying to increment
        if (_currentIndex < _characters.length - 1) {
          _currentIndex++;
          if (_characters.length - _currentIndex < 5) {
            _currentPage++;
            _loadCharacters();
          }
        } else {
          // Reached the end of the current list, try to load more
          _currentPage++;
          // Temporarily set loading to true to prevent showing "No characters" briefly
          // if the list becomes empty before new ones are loaded.
          // _isLoading = true; // This might cause a flicker, handle carefully
          _loadCharacters().then((_) {
            // If after loading, we still don't have more characters at the new _currentIndex,
            // it means we've truly run out or there was an issue.
            // The _buildBody method will handle displaying "No characters to show."
            // or an error message based on _characters.isEmpty and _errorMessage.
            if (_currentIndex >= _characters.length && _characters.isNotEmpty) {
              // This case should ideally not be hit if pagination and loading work correctly
              // but as a fallback, reset to the beginning of what we have.
              _currentIndex = _characters.length - 1;
            }
          });
        }
      } else {
        // If characters list is empty (e.g. after an error or no results from API)
        // try loading first page again.
        _currentPage = 1;
        _loadCharacters();
      }
    });
  }

  // This function is kept for potential direct calls (e.g. from a button not triggering swipe animation)
  void _advanceToNextCharacterCard() {
    setState(() {
      if (_characters.isNotEmpty) {
        if (_currentIndex < _characters.length - 1) {
          _currentIndex++;
          if (_characters.length - _currentIndex < 5) {
            _currentPage++;
            _loadCharacters();
          }
        } else {
          _currentPage++;
          _loadCharacters();
        }
      }
      // Reset card position for next character
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
    });
  }

  void _previousCharacter() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      }
      // Reset card position
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_characters.isEmpty || _currentIndex >= _characters.length)
      return; // No card to drag
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging ||
        _characters.isEmpty ||
        _currentIndex >= _characters.length)
      return;
    setState(() {
      _cardOffset += details.delta;
      final screenWidth = MediaQuery.of(context).size.width;
      _cardRotation =
          (_cardOffset.dx / (screenWidth / 2)) *
          (math.pi / 12); // Max 15 degrees (pi/12)
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging ||
        _characters.isEmpty ||
        _currentIndex >= _characters.length)
      return;

    final screenWidth = MediaQuery.of(context).size.width;
    final swipeThreshold = screenWidth * 0.35; // Must swipe 35% of screen width
    final velocityThreshold = 400; // Velocity threshold for a flick

    bool didSwipe =
        _cardOffset.dx.abs() > swipeThreshold ||
        details.velocity.pixelsPerSecond.dx.abs() > velocityThreshold;

    if (didSwipe) {
      final endOffset =
          _cardOffset.dx > 0
              ? Offset(
                screenWidth * 1.5,
                _cardOffset.dy + details.velocity.pixelsPerSecond.dy * 0.15,
              ) // Swipe right
              : Offset(
                -screenWidth * 1.5,
                _cardOffset.dy + details.velocity.pixelsPerSecond.dy * 0.15,
              ); // Swipe left

      _swipeAnimation = Tween<Offset>(
        begin: _cardOffset,
        end: endOffset,
      ).animate(
        CurvedAnimation(
          parent: _swipeAnimationController,
          curve: Curves.easeOut,
        ),
      );
      _swipeAnimationController.forward();
      // _nextCharacterAfterSwipe is called by the animation listener
    } else {
      // Animate back to center
      _swipeAnimation = Tween<Offset>(
        begin: _cardOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _swipeAnimationController,
          curve: Curves.elasticOut,
        ),
      );
      _swipeAnimationController.forward().then((_) {
        setState(() {
          _cardOffset = Offset.zero;
          _cardRotation = 0.0;
          _isDragging = false;
          _swipeAnimationController.reset();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'tinder',
          style: TextStyle(
            color: Color(0xFFFE5048), // Tinder red-pink
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.grey),
            onPressed: () {
              // TODO: Implement filter/settings
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _characters.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE5048)),
      );
    }

    if (_errorMessage != null && _characters.isEmpty) {
      // Show error only if no characters are loaded
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_characters.isEmpty || _currentIndex >= _characters.length) {
      // This can happen if we run out of characters or an error occurs after some were loaded
      return const Center(
        child: Text(
          'No more characters to show.', // Changed message slightly
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    final character = _characters[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: LayoutBuilder(
                // Use LayoutBuilder to get constraints for rotation anchor
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: AnimatedBuilder(
                      animation: _swipeAnimationController,
                      builder: (context, child) {
                        final currentOffset =
                            _isDragging || _swipeAnimationController.isAnimating
                                ? (_swipeAnimationController.isAnimating
                                    ? _swipeAnimation.value
                                    : _cardOffset)
                                : Offset.zero;
                        final currentRotation =
                            _isDragging || _swipeAnimationController.isAnimating
                                ? (_swipeAnimationController.isAnimating
                                    ? (_swipeAnimation.value.dx /
                                            (constraints.maxWidth / 2)) *
                                        (math.pi / 12) // Max 15 degrees
                                    : _cardRotation)
                                : 0.0;

                        return Transform.translate(
                          offset: currentOffset,
                          child: Transform.rotate(
                            angle: currentRotation,
                            origin: Offset(
                              0,
                              -constraints.maxHeight * 0.3,
                            ), // Rotate from a bit above center
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        color: const Color.fromARGB(
                          255,
                          22,
                          22,
                          22,
                        ), // Dark card
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              character.image,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: const Color(0xFFFE5048),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            ).animate().fadeIn(duration: 500.ms),
                            _buildGradientOverlay(),
                            _buildCharacterInfo(character),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildCharacterInfo(Character character) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                // Added Flexible to prevent overflow if name is too long
                child: Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black54,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis, // Handle long names
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      character.status == 'Alive'
                          ? Colors.green.withOpacity(0.7)
                          : character.status == 'Dead'
                          ? Colors.red.withOpacity(0.7)
                          : Colors.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  character.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"I am a ${character.species} from ${character.origin.name}. Time isn\'t real, is it?"',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              shadows: const [
                Shadow(
                  blurRadius: 1.0,
                  color: Colors.black45,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ).animate().slideY(
        begin: 0.2,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.replay, Colors.amber, 30, () {
          _previousCharacter();
        }),
        _actionButton(Icons.close, Colors.red, 40, () {
          // Dislike action
          _animateSwipe(isLike: false);
        }, isLarge: true),
        _actionButton(Icons.star, Colors.blue, 30, () {
          // TODO: Implement Super Like
          _animateSwipe(
            isLike: true,
            isSuperLike: true,
          ); // Example for super like
        }),
        _actionButton(Icons.favorite, Colors.green, 40, () {
          // Like action
          _animateSwipe(isLike: true);
        }, isLarge: true),
        _actionButton(Icons.flash_on, Colors.purple, 30, () {
          // TODO: Implement Boost
          // For now, let's just advance to next character as a placeholder
          _advanceToNextCharacterCard();
        }),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  void _animateSwipe({required bool isLike, bool isSuperLike = false}) {
    if (_characters.isEmpty ||
        _currentIndex >= _characters.length ||
        _swipeAnimationController.isAnimating)
      return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Offset endOffset;
    double angle = 0;

    if (isSuperLike) {
      endOffset = Offset(
        _cardOffset.dx,
        -screenHeight,
      ); // Swipe up for super like
      // No rotation for super like, or a very slight one if desired
    } else {
      endOffset =
          isLike
              ? Offset(
                screenWidth * 1.5,
                _cardOffset.dy + (_cardOffset.dy * 0.3),
              ) // Swipe right with some vertical movement based on current dy
              : Offset(
                -screenWidth * 1.5,
                _cardOffset.dy + (_cardOffset.dy * 0.3),
              ); // Swipe left with some vertical movement
      angle = (isLike ? 1 : -1) * (math.pi / 12); // 15 degrees rotation
    }

    // Animate rotation along with position
    final rotationTween = Tween<double>(begin: _cardRotation, end: angle);

    _swipeAnimation = Tween<Offset>(begin: _cardOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeOut),
    )..addListener(() {
      // Update rotation during the swipe animation from buttons
      if (!_isDragging) {
        // Only apply if not manually dragging
        setState(() {
          _cardRotation = rotationTween.evaluate(
            CurvedAnimation(
              parent: _swipeAnimationController,
              curve: Curves.easeOut,
            ),
          );
        });
      }
    });

    _swipeAnimationController.forward();
    // _nextCharacterAfterSwipe is called by the animation listener on completion
  }

  Widget _actionButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(
          0.15,
        ), // Slightly transparent background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: isLarge ? size : size * 0.8),
        iconSize: isLarge ? size : size * 0.8,
        padding: EdgeInsets.all(isLarge ? 18 : 12),
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: color,
          padding: EdgeInsets.all(isLarge ? 20 : 15),
          shape: const CircleBorder(),
        ),

        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFE5048), // Tinder red-pink
        unselectedItemColor: Colors.grey[600],
        currentIndex: 0, // Assuming this is the main "discovery" tab
        type: BottomNavigationBarType.fixed, // To show all items with labels
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot), // Tinder flame icon
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), // Or a diamond for "Top Picks"
            label: 'Top Picks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation to other screens
        },
      ),
    );
  }
}
