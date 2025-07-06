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
    ld a, 5
    ld [wPlayerMaxSpeed], a
    ld a, 1
    ld [wPlayerAcceleration], a
    ld a, 0
    ld [wPlayerJumpSpeed], a
    ld a, 8
    ld [wPlayerMaxJumpSpeed], a
    ld a, 15
    ld [wPlayerMaxJumpDuration], a
    ld a, 4
    ld [wPlayerGravity], a
    ld a, 1
    ld [wPlayerDirection], a
    ld a, 0
    ld [wCurrentAnimationFrame], a 
    ld [wPlayerIsWalking], a
    ld [wPlayerIsJumping], a
    ld [wCurrentPlayerState], a
    ld [wMetaSpriteFlipped], a

    ld a, 8
    ld [wWalkingAnimationDelay], a

    ret


LoadPlayerSprite:: 
    ld de, playerWalking
    ld hl, $8000
    ld bc, playerWalkingEnd - playerWalking
    Call Memcpy

    ret


UpdatePlayer::
    call MovePlayer
    call UpdatePlayerPosition
    call PlayerJump
    call UpdatePlayerGravity
    call SetPlayerAnimationState
    call UpdatePlayerAnimations
    call CheckFloorCollision

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

    ld a, 1
    ld [wCurrentPlayerState], a
    
    ld a, 0
    ld [wPlayerDirection], a

    ld a, 1
    ld [wPlayerIsWalking], a

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

    ld a, 1
    ld [wCurrentPlayerState], a

    ld a, 1
    ld [wPlayerDirection], a
    ld [wPlayerIsWalking], a


CheckMaxVelocity:
    ld a, [wPlayerSpeed]
    ld hl, wPlayerMaxSpeed
    cp a, [hl]

    jp z, LimitVelocity
    ret c

    jp LimitVelocity


LimitVelocity:
    ld hl, wPlayerMaxSpeed
    ld a, [hl]
    ld [wPlayerSpeed], a

    ret


PlayerIdle:
    ld a, 0
    ld [wPlayerSpeed], a
    ld [wPlayerIsWalking], a
    ld [wPlayerIsJumping], a

    ld a, [wCurrentPlayerState]
    cp 2
    ret z

    ld [wCurrentPlayerState], a

    ret


UpdatePlayerPosition:
    ld a, [wPlayerDirection]
    cp a, 0 ; Player is moving left
    jp z, .updateLeft 
    
    cp a, 1 ; Player is moving right
    jp z, .updateRight

.updateLeft:
    ; Decrease sprite X coordinate based on current speed
    ld a, [wPlayerSpeed]

    ; dividing by power of 2 (sub pixel calculation)
    srl a

    ld b, a
    ld a, [_OAMRAM + 1]

    ; Preventing player from moving outside the left boundary of the screen
    cp a, 8
    ret z

    sub a, b
    ld [_OAMRAM + 1], a

    ld a, [_OAMRAM + 5]
    sub a, b
    ld [_OAMRAM + 5], a

    ret

.updateRight:
    ; Increase sprite X coordinate based on current speed
    ld a, [wPlayerSpeed]

    ; dividing by power of 2 (sub pixel calculation)
    srl a
    ld b, a
    
    ; Preventing player from moving outside the right boundary of the screen
    ld a, [_OAMRAM + 5]
    dec a
    cp a, 160
    ret nc

    ld a, [_OAMRAM + 1]
    add a, b
    ld [_OAMRAM + 1], a

    ld a, [_OAMRAM + 5]
    add a, b
    ld [_OAMRAM + 5], a

    ret


PlayerJump:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, PlayerNotJumping
    
    ld a, [wPlayerMaxJumpDuration]
    cp 0
    jp z, PlayerNotJumping

    ld a, [wPlayerMaxJumpSpeed]
    ld [wPlayerJumpSpeed], a

    ld a, 2
    ld [wCurrentPlayerState], a

    ld a, 1
    ld [wPlayerIsJumping], a

    ld a, [wPlayerMaxJumpDuration]
    dec a
    ld [wPlayerMaxJumpDuration], a
    
    ret


PlayerNotJumping:
    ld a, 0
    ld [wPlayerJumpSpeed], a

    ret


UpdatePlayerGravity:
    ; Apply jump velocity
    ld a, [wPlayerJumpSpeed]

    ; dividing by power of 2 (sub pixel calculation)
    srl a
    ld b, a
    ld a, [_OAMRAM]

    sub a, b
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    sub a, b
    ld [_OAMRAM + 4], a

    ; Apply gravity
    ld a, [wPlayerGravity]

    ; dividing by power of 2 (sub pixel calculation)
    srl a
    ld b, a
    ld a, [_OAMRAM]

    add a, b
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    add a, b
    ld [_OAMRAM + 4], a

    ret


SetPlayerAnimationState:
    ld a, [wPlayerIsJumping]
    cp 1
    jp z, .setToJumping

    ld a, [wPlayerIsWalking]
    cp 1
    jp z, .setToWalking

    jp .setToIdle

    ret

.setToIdle:
    ld a, [wCurrentPlayerState]
    cp 0
    ret z

    ld a, 0
    ld [wCurrentPlayerState], a

    ret

.setToWalking:
    ld a, [wCurrentPlayerState]
    cp 1
    ret z

    ld a, 1
    ld [wCurrentPlayerState], a

    ret

.setToJumping:
    ld a, [wCurrentPlayerState]
    cp 2
    ret z

    ld a, 2
    ld [wCurrentPlayerState], a

    ret


UpdatePlayerAnimations:
    ld a, [wCurrentPlayerState]
    cp 0
    call z, IdleAnimation

    cp 1
    call z, WalkingAnimation

    cp 2
    call z, JumpingAnimation
    
    call FlipPlayerSprite
    call SwapMetaSprite

    ret


IdleAnimation:
    ld a, [wPlayerSpeed]
    cp 0
    ret nz
    
    ld a, [wMetaSpriteFlipped]
    cp 0
    jp nz, EndSwapIdleRight

    SwapIdleRight:
        ld a, $00

        ld [_OAMRAM + 2], a

        inc a
        inc a

        ld [_OAMRAM + 6], a
    EndSwapIdleRight:

    ld a, [wMetaSpriteFlipped]
    cp 1
    ret nz

    SwapIdleLeft:
        ld a, $00

        ld [_OAMRAM + 6], a

        inc a
        inc a

        ld [_OAMRAM + 2], a
    EndSwapIdleLeft:

    ret


JumpingAnimation:
    ld a, [wPlayerJumpSpeed]
    cp 0
    ret z
    
    ld a, [wMetaSpriteFlipped]
    cp 0
    jp nz, EndSwapJumpingRight

    SwapJumpingRight:
        ld a, $0C

        ld [_OAMRAM + 2], a

        inc a
        inc a

        ld [_OAMRAM + 6], a
    EndSwapJumpingRight:

    ld a, [wMetaSpriteFlipped]
    cp 1
    ret nz

    SwapJumpingLeft:
        ld a, $0C

        ld [_OAMRAM + 6], a

        inc a
        inc a

        ld [_OAMRAM + 2], a
    EndSwapJumpingLeft:
    
    ret


WalkingAnimation:
    ; Safety check to prevent animation frame from going over animation tile indexes
    ld a, [wCurrentAnimationFrame]
    call CheckWalkingFrames 
    
    
    ld a, [wMetaSpriteFlipped]
    cp 0
    jp nz, EndSwapWalkingRight

    SwapWalkingRight:
        ld a, [wCurrentAnimationFrame]
        ld b, a

        ld hl, wWalkingFrames
        ld a, [hl]
        add a, b

        ld [_OAMRAM + 2], a

        inc a
        inc a

        ld [_OAMRAM + 6], a
    EndSwapWalkingRight:
    
    ld a, [wMetaSpriteFlipped]
    cp 1
    jp nz, EndSwapWalkingLeft

    SwapWalkingLeft:
        ld a, [wCurrentAnimationFrame]
        ld b, a

        ld hl, wWalkingFrames
        ld a, [hl]
        add a, b

        ld [_OAMRAM + 6], a

        inc a
        inc a
        
        ld [_OAMRAM + 2], a
    EndSwapWalkingLeft:
    
    ld a, [wWalkingAnimationDelay]
    cp 0
    jp nz, DelayWalkingAnimationEnd

    DelayWalkingAnimation:
        call IncreasAnimationFrameCounter
        ld a, 8
        ld [wWalkingAnimationDelay], a
    DelayWalkingAnimationEnd:
    
    dec a
    ld [wWalkingAnimationDelay], a

    ret


CheckWalkingFrames:
    cp a, 8
    call nc, ResetWalkingAnimation

    ret


IncreasAnimationFrameCounter:
    ; Increasing animation counter by 4
    ld a, [wCurrentAnimationFrame]
    inc a
    inc a
    inc a
    inc a
    
    ld [wCurrentAnimationFrame], a

    ret


ResetWalkingAnimation:
    ld a, 0
    ld [wCurrentAnimationFrame], a

    ret


SwapMetaSprite:
    ld a, [wPlayerDirection]
    cp 1
    jp z, .swapRight

    cp 0
    jp z, .swapLeft

    ret

.swapLeft:
    ld a, [wMetaSpriteFlipped]
    cp 1
    ret z

    ld a, 1
    ld [wMetaSpriteFlipped], a

    ret

.swapRight:
    ld a, [wMetaSpriteFlipped]
    cp 0
    ret z
    
    ld a, 0
    ld [wMetaSpriteFlipped], a

    ret


FlipPlayerSprite: 
    ld a, [wPlayerDirection]
    cp a, 0
    call z, FacingLeft

    cp a, 1
    call z, FacingRight

    ret


FacingLeft:
    ; Flipping both metasprite tiles horizontally
    ld a, [_OAMRAM + 3]
    ld b, %00100000
    
    ; Checking if player sprite is already flpped left
    ; if so, skip the rest of the code
    and a, b
    ret nz


    ; Flipping both metasprite tiles horizontally
    ld a, [_OAMRAM + 3]
    xor a, b
    ld [_OAMRAM + 3], a

    ld a, [_OAMRAM + 7]
    xor a, b
    ld [_OAMRAM + 7], a
    
    ret   


FacingRight:
    ld a, [_OAMRAM + 3]
    ld b, %00100000

    ; Checking if player sprite is already flpped right
    ; if so, skip the rest of the code
    and a, b
    ret z

    ; Flipping both metasprite tiles horizontally
    ld a, [_OAMRAM + 3]
    ld b, %00100000
    xor a, b
    ld [_OAMRAM + 3], a

    ld a, [_OAMRAM + 7]
    xor a, b
    ld [_OAMRAM + 7], a
    
    ret


CheckFloorCollision:
    ; Checking bottom-left corner of sprite
    ld a, [_OAMRAM]
    sub a, 6
    ld c, a
    ld a, [_OAMRAM + 1]
    ld b, a
    call GetTileByPixel

    ld a, [hl]
    call IsFloorTile

    jp z, CollideWithFloor

    ; Checking bottom-right corner of sprite
    ld a, [_OAMRAM + 4]
    sub a, 6
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8
    ld b, a
    call GetTileByPixel

    ld a, [hl]
    call IsFloorTile

    jp z, CollideWithFloor

    ret


CollideWithFloor:
    ld a, [_OAMRAM]
    sub a, 2
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    sub a, 2
    ld [_OAMRAM + 4], a

    ld a, 0
    ld [wPlayerIsJumping], a
    
    ld a, [wPlayerMaxJumpDuration]
    cp 0
    jp nz, EndResetJumpDuration

    ResetJumpDuration:
        ld a, 15
        ld [wPlayerMaxJumpDuration], a
    EndResetJumpDuration:

    ret


SECTION "Player Graphics", ROM0

playerWalking:
    Idle00: INCBIN "assets/player/Idle/PlayerIdle0-0.2bpp"
    Idle01: INCBIN "assets/player/Idle/PlayerIdle0-1.2bpp"

    Walking00: INCBIN "assets/player/Walk/PlayerWalking0-0.2bpp"
    Walking01: INCBIN "assets/player/Walk/PlayerWalking0-1.2bpp"

    Walking10: INCBIN "assets/player/Walk/PlayerWalking1-0.2bpp"
    Walking11: INCBIN "assets/player/Walk/PlayerWalking1-1.2bpp"

    Jumping00: INCBIN "assets/player/Jump/PlayerJump0-0.2bpp"
    Jumping01: INCBIN "assets/player/Jump/PlayerJump0-1.2bpp"
playerWalkingEnd:


SECTION "Walking Animation", ROM0

wWalkingFrames: db $04, $08
wWalkingFramesEnd:


SECTION "Player Variables", WRAM0

wCurrentPlayerState: db
wPlayerIsWalking: db
wPlayerIsJumping: db
wPlayerSpeed: db
wPlayerAcceleration: db
wPlayerMaxSpeed: db
wPlayerJumpSpeed: db
wPlayerMaxJumpSpeed: db
wPlayerMaxJumpDuration: db
wPlayerGravity: db
wPlayerDirection: db
wCurrentAnimationFrame: db
wMetaSpriteFlipped: db
wWalkingAnimationDelay: db


SECTION "Player Constants", WRAM0

DEF PLAYER_IDLE EQU $00
DEF PLAYER_WALKING EQU $01
DEF PLAYER_JUMPING EQU $02
DEF PLAYER_FALLING EQU $03
