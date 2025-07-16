INCLUDE "utils.asm"
INCLUDE "player.asm"
INCLUDE "hardware.inc"


SECTION "header", ROM0[$100]
    ; Making room for cartridge header
    jp EntryPoint

    ds $150 - @, 0


EntryPoint:
    ; Waiting for VBlank
    call WaitVBlank

    ; Turning off LCD
    xor a
    ld [rLCDC], a
    
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

    ; Clearing OAM
    xor a
    ld b, 160
    ld hl, _OAMRAM
    Call ClearOAM

    ld hl, _OAMRAM

    call InitPlayer

    ; Initializing global variables
    xor a
    ld [wFrameCounter], a

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


Main:
    ld a, [rLY]
    cp 144
    jp nc, Main

    call WaitVBlank

    call UpdateKeys
    call UpdatePlayer
    
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    cp a, 1
    jp nz, Main

    jp Main


LevelTiles: INCBIN "assets/tilemaps/GBPlatformerTileset.2bpp"
LevelTilesEnd:

LevelMap: INCBIN "assets/tilemaps/GBPlatformerTilemap.tilemap"
LevelMapEnd:


SECTION "Counter", WRAM0
wFrameCounter: db

