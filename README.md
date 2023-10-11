# Default Minus Minus for release 1.4.2

Dual Universe Custom Flight Script

>**Default--** is a highly modified version of Jeronimo's Default++ flight script which now **does NOT require locally installed files**.<br>
It continues to support advanced vector based flight, allowing cutting-edge features while offering low lag gameplay. 

### Advanced Features
- Fast, low latency, low Lag (not using vec3() built in functions )
- GEForce NOW compatible (Does not require local files for flight capability)
- Drone Mode (Drone style, tilt to move, vertical takeoff)
- Continuous Altitude Hold
- Alt + 1 easy access settings
- Auto Land G (Advanced Z Axis Braking distance calculation)
- "Parking" multi-directional hover capability
- Pitch / Roll snapping
- Customizable colors

Developed since 2017, and enhanced in 2023

DU flight parameters are brought to you on an other level with dozens of customizable settings and features.

![dualuniverse_2023-05-09_01h26m34s](https://user-images.githubusercontent.com/75027025/236959679-b8004eea-4f7e-4fad-b38a-ad1041fbd2f1.png)


## HOW TO INSTALL:

>Unpack the content of the .zip file into DU Dual Universe\Game\data\lua\autoconf\custom folder<br>
Keep WIDGETS-- folder and its files as they are in the custom folder


#### ATTENTION: manually link following elements to the control unit (command seat or remote control or ECU)
- Databank
- Fuel Tanks (atmo / space / rocket)
- Radars (atmo and space)
- Manual Switch (will be turned on upon script start, used in the multiple fuel tanks configuration)

>Install the DEFAULT-- script by right clicking on the control unit, choose Advanced, Run custom configuration


## USERS MANUAL:
- Menus and buttons are operated with the mouse.
- Windows and widgets can be draged by their title bar.
- Left Click over button = change the paramater increment (when there is one, increment is shown on the most right like so +-xyz)
- CTRL + Left Click over a button to save a button in the Quick Tool Bar (a little asterisk "*" confirms the shortcut is active)
- Wheel Scroll over button = change the parameter
- Wheel Scroll over a widget = scale size
- ALT + 1 = to open and close Main Settings menu
- Double ALT + hold = Quick Tool menu and Widgets adjustment menu
- To acces integrated manual user, find the Help Menu button at the bottom of the window Menu Settings

### Chat Commands:
- help = prints the help menu in lua chat tab
- reset all = formats databank to factory settings
- ::pos{} = translates map pos to world coordinate



## MULTIPLE FUEL TANKS CONFIGURATION:

>If total number of elements to be linked and high number of fuel tanks is greater than 10 links,<br>
It is possible to link high number of fuel tanks to 1 or multiple programing boards

### Installation steps are as follow:
- Within the WIDGETS-- folder find the "script for FuelTanks on Programming Boards.json" file to be copy pasted in the programing boards
- link 1 manual switch to command seat
- Databank needs to be cleared (enter the command **reset all** in lua chat to clear it)
- link the databank to each programming board
- link the manual switch to programing board (to a relay then to programing boards if multiple)
- link all the desired fuel tanks to programing boards
- install programing boards script
- turn on the manual switch to initiate the scripts (only once, the first time)
- start the command seat and enjoy (only works with custom widgets, not with default ones)


## CUSTOM WIDGETS:

>Default-- offers a high modularity and unlimited number of custom widgets designed by players.<br>
Widgets can be turned on and off at will from the Main Menu.<br>
To load succesfully a new custom widget, its name must match the incrementing list.<br>
Custom SVG, buttons, and flush override can be set by the widgets


## COPY RIGHTS:
>Free to use / change / customize.<br>
If you develop any changes that may improve the functionality please let me know on my Discord. I would love to see them! (thegreatsardini)

DISCORD: **thegreatsardini**


## CREDITS:
- [Jeronimo](https://github.com/JeronimoDU/Default-PLUS-PLUS) : Flight Script developed since 2017.
- [Arch-HUD](https://github.com/Archaegeo/Archaegeo-Orbital-Hud) : A few code snippits.
- [JayleBreak](https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom) : Flight Files