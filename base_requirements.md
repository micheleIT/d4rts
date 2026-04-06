# Basic requirements for the App

## General

The user wants to play darts and this app should make the exeperience smoother.
All best practices for playing steel darts (what is probably the "standard") should apply.

## Environment

* Flutter with Dart
* Web application and Android apk
* Create web application on commit @ main
* Create Release with apk on new tag

## What the app should deliver

- Start a new game and enter the player who attend
- Game starts for every player at 501 (choose from 301,501,701) points (default, configurable in settings)
- For every player there should be an option to give them a handicap (e.g. 100Points, 200Points)
- Input are the three throws, the app should count the score
  - use codes to make it easier to input the single throw scores
  - d stands for double
  - t stands for thripple
  - that means as a example
    - D17 == 34
    - T20 == 60
    - D25 == 50
  - the inputs are all valid darts inputs
    - 1 to 20 for the numbers with additional d and t
    - 25 for bullseye
    - 25d for double bullseye   
- To exchange results between different instances, I want a import/export feature to replace oder ammend the results an a different instance of the app.

## Additional features

- Vs mode
  - Add players
  - Play
- Tournament mode
  - Add players
  - Define how many groups (default: 2)
  - In every group every player plays against every other from the group
  - When done tied players play a 1vs1 to gain a who wins
  - After that, generate a sudden death plan with all players. You can orientate yourself like this systems are ommited during world champoinships, but enhanced with all players.
    - Plus: Every player should have the same amount of games. So every place on the final ladder should be played out
    - E.g. 4 Players: A, B, C, D
      - 2 Groups A,C : B, D
      - A wins C , D wins B
      - G1: 1. A, 2. C
      - G2: 1. D, 2. B
      - Half Finals
        - A vs B : A wins
        - C vs D : C wins
        - Finals:
          - A vs C : C wins
          - B vs D : D wins
      - Results:
        - 1: C
        - 2: A
        - 3: D
        - 4: B
