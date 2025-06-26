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
    ld a, 1
    ld [wPlayerDirection], a

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
    call MovePlayer
    ld a, [wCurrentPlayerState]
    ;cp a, PLAYER_IDLE
    ;ret z

    cp a, $01
    jp z, UpdateWalkingState

    cp a, $02
    jp z, UpdateJumpingState

    cp a, $03
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
    
    add a, [hl]
    ld [wPlayerSpeed], a

    ld a, $01
    ld [wCurrentPlayerState], a
    
    ld a, 0
    ld [wPlayerDirection], a
    call UpdatePlayerAnimations

    jp CheckMaxVelocity


CheckKeyRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT

    jp z, PlayerIdle


AccelerateRight:
    ld a, [wPlayerSpeed]
    ld hl, wPlayerAcceleration

    add a, [hl]
    ld [wPlayerSpeed], a

    ld a, $01
    ld [wCurrentPlayerState], a

    ld a, 1
    ld [wPlayerDirection], a
    call UpdatePlayerAnimations


CheckMaxVelocity:
    ld a, [wPlayerSpeed]
    ld hl, wPlayerMaxSpeed
    cp a, [hl]

    jp z, LimitVelocity
    jp c, EndMovePlayer
    jp LimitVelocity


LimitVelocity:
    ld hl, wPlayerMaxSpeed
    ld a, [hl]
    ld [wPlayerSpeed], a

    jp EndMovePlayer


PlayerIdle:
    ld a, $00
    ld [wCurrentPlayerState], a

    jp EndMovePlayer


EndMovePlayer:
    ret


UpdatePlayerPosition:
    ld a, [wPlayerSpeed]
    cp a, 0
    jp z, .updateIdle ; Skip to updateIdle if speed == 0
    
    ld a, [wPlayerDirection]
    cp a, 0 ; Player is moving left
    jp z, .updateLeft 
    
    cp a, 1 ; Player is moving right
    jp z, .updateRight

.updateLeft:
    ; Decrease sprite X coordinate based on current speed
    ld a, [wPlayerSpeed]
    ld b, a
    ld a, [_OAMRAM + 1]
    sub a, b
    ld [_OAMRAM + 1], a

    ld a, [_OAMRAM + 5]
    sub a, b
    ld [_OAMRAM + 5], a

    jp EndUpdatePlayerPosition

.updateRight:
    ; Increase sprite X coordinate based on current speed
    ld a, [wPlayerSpeed]
    ld b, a
    ld a, [_OAMRAM + 1]
    add a, b
    ld [_OAMRAM + 1], a

    ld a, [_OAMRAM + 5]
    add a, b
    ld [_OAMRAM + 5], a

    jp EndUpdatePlayerPosition

.updateIdle:
    ; (TODO) Set sprite to Idle and animate it

    jp EndUpdatePlayerPosition


EndUpdatePlayerPosition:


    ret


UpdatePlayerAnimations:
    call FlipPlayerSprite


EndUpddatePlayerAnimations:


    ret

FlipPlayerSprite: 
    ld a, [wPlayerDirection]
    cp a, 0
    jp z, .flipLeft

    cp a, 1
    jp z, .flipRight


.flipLeft:
    ld a, [_OAMRAM + 3]
    ld b, %00100000
    
    ; Checking if player sprite is already flpped left
    ; if so, skip the rest of the code
    and a, b
    jp nz, EndFlipPlayerSprite


    ; Flipping both metasprite tiles horizontally
    ld a, [_OAMRAM + 3]
    xor a, b
    ld [_OAMRAM + 3], a

    ld a, [_OAMRAM + 7]
    xor a, b
    ld [_OAMRAM + 7], a

    ; Swapping metasprite tile indexes
    ld a, 2
    ld [_OAMRAM + 2], a

    ld a, 0
    ld [_OAMRAM + 6], a 

    jp EndFlipPlayerSprite


.flipRight:
    ld a, [_OAMRAM + 3]
    ld b, %00100000

    ; Checking if player sprite is already flpped right
    ; if so, skip the rest of the code
    and a, b
    jp z, EndFlipPlayerSprite

    ; Swapping metasprite tile indexes
    ld a, 0
    ld [_OAMRAM + 2], a

    ld a, 2
    ld [_OAMRAM + 6], a
    
    ; Flipping both metasprite tiles horizontally
    ld a, [_OAMRAM + 3]
    ld b, %00100000
    xor a, b
    ld [_OAMRAM + 3], a

    ld a, [_OAMRAM + 7]
    xor a, b
    ld [_OAMRAM + 7], a

    jp EndFlipPlayerSprite


EndFlipPlayerSprite:


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
wPlayerDirection: db


SECTION "Player Constants", WRAM0

DEF PLAYER_IDLE EQU $00
DEF PLAYER_WALKING EQU $01
DEF PLAYER_JUMPING EQU $02
DEF PLAYER_FALLING EQU $03
