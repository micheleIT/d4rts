# Basic requirements for the App

## Environment

* Flutter with Dart
* Web application and Android apk
* Create web application on commit @ main
* Create Release with apk on new tag

## What the app should deliver

The user wants to play darts and this app should make the exeperience smoother

- Game starts for every player at 501 points (default, configurable in settings)
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
