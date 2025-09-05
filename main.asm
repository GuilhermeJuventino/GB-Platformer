INCLUDE "utils.asm"
INCLUDE "game.asm"
INCLUDE "player.asm"
INCLUDE "hardware.inc"


SECTION "header", ROM0[$100]
    ; Making room for cartridge header
    jp EntryPoint

    ds $150 - @, 0


EntryPoint:
    ; Initializing global variables
    xor a
    ld [wFrameCounter], a

    call InitGameStateMachine
    call GameStateManager


TitleScreenTiles: INCBIN "assets/tilemaps/GBTitleScreenTileset.2bpp"
TitleScreenTilesEnd:

TitleScreenMap: INCBIN "assets/tilemaps/GBTitleScreenTilemap.tilemap"
TitleScreenMapEnd:

LevelTiles: INCBIN "assets/tilemaps/GBPlatformerTileset.2bpp"
LevelTilesEnd:

LevelMap: INCBIN "assets/tilemaps/GBPlatformerTilemap.tilemap"
LevelMapEnd:


SECTION "Counter", WRAM0
wFrameCounter: db

