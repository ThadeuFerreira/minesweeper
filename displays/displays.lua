local NewGameButton = require("displays.newgamebutton")
local Timer = require("displays.timer")
local CellsHiddenCounter = require("displays.cellhiddencounter")
local BombCounter = require("displays.bombcounter")
local NextLevelButton = require("displays.nextlevelbutton")
local ReturnToMainMenuButton = require("displays.returntomainmenubutton")


return {
    NewGameButton = NewGameButton,
    ReturnToMainMenuButton = ReturnToMainMenuButton,
    Timer = Timer,
    CellsHiddenCounter = CellsHiddenCounter,
    BombCounter = BombCounter,
    NextLevelButton = NextLevelButton
}