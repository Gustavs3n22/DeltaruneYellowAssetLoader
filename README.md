
# Deltarune Yellow asset loader

<img width="800" height="450" alt="itspronouncedrules" src="https://github.com/user-attachments/assets/20e935d3-7760-45b6-94ef-8b3669429d57" />

This is a simple mod for DrY that allows you to easily edit sprites, text and audio of the game. Based on [godot universal mod manager](https://github.com/KoBeWi/Godot-Universal-Mod-Manager).

## Installation and first steps

Extract the archive and move contents of DeltaruneYellowAssetLoader folder into Deltarune Yellow's root folder (if you've done it correctly, override.cfg file would be in the same folder as Deltarune Yellow.exe).

Before you start editing assets you should visit mod.cfg file inside Resource_Pack folder. There you will find 4 variables: name of the project, description, language and version. All of them are currently cosmetic except language. If you are NOT going to edit text files, please leave language as "na", that way the mod won't create unnecessary language folder in appdata (more on that in "Changing text" paragraph)

## Changing sprites

Inside your game folder you can now find Resource_Pack folder. Open it and go directly into Sprites folder. There you will find every .png file that is currently used by DrY. You can put your spritesheet in place of any of the files, but make sure your new spritesheet file has the EXACT same name as one you're replacing!!

## Changing audio

If you want to replace audio, go to your Resource_Pack folder, And then to Audio folder. There you will find subfolders with every sound used in game. Same logic as sprites applies: replace the sound file with a file of exact same extention (.ogg, .mp3 or .wav depending on a file you're swapping) and exact same file name.

>NOTE: After you're done, delete every unchanged audio file to debloat your resource pack and make it easier to distribute

## Changing text

### Quick start

Text editing begins with mod.cfg, the language line to be exact. It has 3 options you can set it to:

"na" - Setting language to na prevents mod from creating a language folder in AppData/Roaming/Godot/app_userdata/Deltarune Yellow/Text (leave option at that if you're not touching the text files)

"remove" - Setting language option to remove deletes the Text folder in AppData/Roaming/Godot/app_userdata/Deltarune Yellow. You can swap it in and launch the game once in case you already generated a couple of unneeded language folders you want to remove.

"literraly anything else" - if you type in anything that is NOT "na" or "remove", the next game launch will copy every text file from mod's files to DrY's appdata folder, adding an option to choose this new redaction of dialogues right before DrY's title screen

Your next step would be going inside the Text folder itself. Open LangInfo.txt, this is where you can edit how your text redaction should appear in pre-title menu, for example:

Select language -> Seleccionar idioma
LANGUAGE NAME -> some new text name lmao

### Extras

from here, you can go to any text file and edit it as you wish. I'll leave dev's notes related to text editing for your convinience:

Obs: Do not remove or change the lines that start with @ > . or END those are system commands needed for the game to work
You can use the [font_size=X][/font_size] tags to change text size (with X being the value, default being 13)
For cyrillic: add [font=res://Fonts/dotumcheFixRus.tres] to make some text be uniform (like the store's item capacity) (or see how to replace fonts below)

----

The line limits for dialogue boxes should be:
-28 for text with portraits (29 max touching the edge)
-35 for text with no portraits (36 max touching the edge)
-32 for shop talk topics/exit dialogue
Try to keep each line to be within these limits

----

To replace fonts: Create a new folder inside your translation folder called "Fonts" and place the .ttf or .otf font you want there (name without spaces).
Then, in the LangInfo.txt file, add a line like so (after the language name):

font:FONTNAME:FONTFILE

Where FONTNAME can be either:
DTMono - font used for dialogues
DTSans - font used for menus/shop
SmallText - font used for the enemy battle blurbs and mini text in dialogue
PartyHUD - font used for the party's name in the DW HUD
PauseHUD - font used for the DW pause menu descriptor (ITEM, EQUIP, POWER, TALK, CONFIG)
OWText1 - font used for some overworld text element (shop signs, etc)
OWText2 - same as above but with a different style (like pennilton's shop)

And FONTFILE is the filename of the font you placed in the "Fonts" folder (including the extension). If compatible, it will then replace the font that the game uses by default.
Keep in mind you will likely need to use the font_size tags to adjust the font depending of how big it is.
All fonts besides DTMono font cannot be monospaced or the menus will display wrong, while DTMono must be monospaced.

----

For mini text, you can add 2 extra parameters for the X and Y coordinates of the box if you need to offset it, like:
>mini:KanakoNormal:Test!:195:57

----

Any of the following strings:
[INTERACT] [CANCEL] [MENU] [LEFT] [RIGHT] [UP] [DOWN]
will be converted into the keybind/controller button icon, so don't translate them.

----
