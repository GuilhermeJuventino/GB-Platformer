SECTION "Player", ROM0


InitPlayer::
    ; Write player's properties to VRAM
    ld a, 80 ; Writing Y coordinates for metasprite 0
    ld [hli], a
    ld a, 16 ; Writing X coordinates for metasprite 0
    ld [hli], a
    ld a, 0 ; Object ID and attributes for metasprite 0 
    ld [hli], a
    ld [hli], a

    ld a, 80
    ld [hli], a ; Writing Y coordinates for metasprite 1
    ld a, 24
    ld [hli], a ; Writing X coordinates for metasprite 1
    ld a, 2 ; Object ID and attributes for metasprite 1
    ld [hli], a
    ld a, 0
    ld [hli], a
    
    ld a, 0
    ld [wPlayerSpeed], a
    ld a, 3
    ld [wPlayerMaxSpeed], a
    ld a, 1
    ld [wPlayerAcceleration], a
    ld a, 1
    ld [wPlayerJumpSpeed], a
    ld a, 6
    ld [wPlayerMaxJumpSpeed], a
    ld a, 4
    ld [wPlayerGravity], a

    ld a, [PLAYER_IDLE]
    ld [wCurrentPlayerState], a

    ret

LoadPlayerSprite:: 
    ld de, playerWalking
    ld hl, $8000
    ld bc, playerWalkingEnd - playerWalking
    Call Memcpy

    ret


UpdatePlayer::
    ld a, [wCurrentPlayerState]
    ;cp a, PLAYER_IDLE
    ;ret z

    call MovePlayer

    cp a, PLAYER_WALKING
    jp z, UpdateWalkingState

    cp a, PLAYER_JUMPING
    jp z, UpdateJumpingState

    cp a, PLAYER_FALLING
    jp z, UpdateFallingState


    jp UpdateEnd


UpdateWalkingState:
    call UpdatePlayerPosition

    jp UpdateEnd

UpdateJumpingState:
    call UpdatePlayerPosition

    jp UpdateEnd

UpdateFallingState:
    call UpdatePlayerPosition

    jp UpdateEnd

UpdateEnd:
    

    ret


MovePlayer:
    ; Moving the player based on controller input
CheckKeyLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT

    jp z, CheckKeyRight
AccelerateLeft:
    ld a, [wPlayerSpeed]
    ld hl, wPlayerAcceleration
    
    sub a, [hl]
    ld [wPlayerSpeed], a

    ld a, [PLAYER_WALKING]
    ld [wCurrentPlayerState], a

    ;ld a, [wPlayerSpeed]
    ;ld [_OAMRAM + 1], a

    jp EndMovePlayer

CheckKeyRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT

    jp z, PlayerIdle
AccelerateRight:
    ld a, [wPlayerSpeed]
    ld hl, wPlayerAcceleration

    add a, [hl]
    ld [wPlayerSpeed], a

    ld a, [PLAYER_WALKING]
    ld [wCurrentPlayerState], a

    ;ld a, [wPlayerSpeed]
    ;ld [_OAMRAM + 1], a


    ;jp EndMovePlayer

PlayerIdle:
    ld a, [PLAYER_IDLE]
    ld [wCurrentPlayerState], a

    jp EndMovePlayer

EndMovePlayer:
    ret


UpdatePlayerPosition:
    ld a, [wPlayerSpeed]
    cp a, 0
    jp c, .updateLeft ; Speed less than zero

    cp a, 0
    jp nc, .updateRight ; Speed greater than zero

    cp a, 0
    jp z, .updateIdle

.updateLeft:
    ; (TODO) Flip sprite left

    ld a, [wPlayerSpeed]
    ld [_OAMRAM + 1], a

    jp EndUpdatePlayerPosition

.updateRight:
    ; (TODO) Flip sprite right
    
    ld a, [wPlayerSpeed]
    ld [_OAMRAM + 1], a

    jp EndUpdatePlayerPosition

.updateIdle:
    ; (TODO) Set sprite to Idle and animate it

    jp EndUpdatePlayerPosition


EndUpdatePlayerPosition:


    ret


SECTION "Player Graphics", ROM0

playerWalking:
    Walking00: INCBIN "assets/player/Player0-0.2bpp"
    Walking01: INCBIN "assets/player/Player0-1.2bpp"
playerWalkingEnd:


SECTION "Player Variables", WRAM0

wCurrentPlayerState: db
wPlayerSpeed: db
wPlayerAcceleration: db
wPlayerMaxSpeed: db
wPlayerJumpSpeed: db
wPlayerMaxJumpSpeed: db
wPlayerGravity: db


SECTION "Player Constants", WRAM0

DEF PLAYER_IDLE EQU $00
DEF PLAYER_WALKING EQU $01
DEF PLAYER_JUMPING EQU $03
DEF PLAYER_FALLING EQU $04
