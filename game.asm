SECTION "Game States", ROM0


InitGameStateMachine::
    ld a, 0
    ld [wCurrentGameState], a
    ret


GameStateManager::
    call WaitVBlank

    ; Turning off LCD
    xor a
    ld [rLCDC], a

    ; Clearing OAM
    xor a
    ld b, 160
    ld hl, _OAMRAM
    Call ClearOAM

    ld a, [wCurrentGameState]
    cp a, 0
    jp z, TitleScreenState

    cp 1
    jp z, InGameState

    ret


TitleScreenState:
    ; Copying Title Screen data into VRAM
    ld de, TitleScreenTiles
    ld hl, $9000
    ld bc, TitleScreenTilesEnd - TitleScreenTiles
    call Memcpy

    ld de, TitleScreenMap
    ld hl, $9800
    ld bc, TitleScreenMapEnd - TitleScreenMap
    call Memcpy
 
    ; Turning LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; Initializing display registers during first BLANK frame
    ld a, %11100100
    ld [rBGP], a


TitleScreenLoop: 
    ld a, [rLY]
    cp 144
    jp nc, TitleScreenLoop

    call WaitVBlank

    call UpdateKeys

    ld a, [wCurKeys]
    and a, PADF_START
    
    jp z, .leaveTitleScreenEnd

    .leaveTitleScreen:
        ld a, 1
        ld [wCurrentGameState], a
        jp GameStateManager
    .leaveTitleScreenEnd:

    jp TitleScreenLoop


InGameState:
    ; Copying level data into VRAM
    ld de, LevelTiles
    ld hl, $9000
    ld bc, LevelTilesEnd - LevelTiles
    call Memcpy

    ld de, LevelMap
    ld hl, $9800
    ld bc, LevelMapEnd - LevelMap
    call Memcpy

    call LoadPlayerSprite

    ld hl, _OAMRAM

    call InitPlayer

    ; Turning LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; Initializing display registers during first BLANK frame

    ; Background and object palletes are rotated left 6 times each because for some reason,
    ; The colors get flipped from their intended look if I don't do that... even tho this is the first time
    ; I ever needed to do that and I don't know why, since before it would work just fine by just using the commented pallete
    ld a, $1b
    ld [rBGP], a

    ld a, [rBGP]
    rlc a
    rlc a
    rlc a
    rlc a
    rlc a
    rlc a
    ld [rBGP], a
    
    ; I'm not sure if I NEED to do the same for the object layer as well, since I haven't added any sprite yet
    ; But I'm doing it just in case
    ld a, %10010011
    ld [rOBP0], a

    ; Enabling "tall sprites" (8x16)
    ldh a, [rLCDC]
    or a, LCDCF_OBJ16
    ldh [rLCDC], a

GameLoop:
    ld a, [rLY]
    cp 144
    jp nc, GameLoop

    call WaitVBlank

    call UpdateKeys
    call UpdatePlayer
    
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    cp a, 1
    jp nz, GameLoop

    jp GameLoop


; Since I don't really have any "lose" condition in the game, just pretend there's a Game over State Function beneath this.


SECTION "Game State Variables", WRAM0
wCurrentGameState: db
