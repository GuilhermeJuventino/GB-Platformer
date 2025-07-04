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
    ld a, 0
    ld [wPlayerJumpSpeed], a
    ld a, 8
    ld [wPlayerMaxJumpSpeed], a
    ld a, 4
    ld [wPlayerGravity], a
    ld a, 1
    ld [wPlayerDirection], a
    ld a, 0
    ld [wCurrentAnimationFrame], a

    ld a, 0
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
    
    cp a, PLAYER_IDLE
    jp z, .updateIdleState

    cp a, PLAYER_WALKING
    jp z, .updateWalkingState

    cp a, PLAYER_JUMPING
    jp z, .updateJumpingState

    jp UpdateEnd

.updateIdleState:
    call UpdatePlayerAnimations

    jp UpdateEnd

.updateWalkingState:
    call UpdatePlayerPosition
    call UpdatePlayerAnimations

    jp UpdateEnd


.updateJumpingState:
    call UpdatePlayerPosition
    call UpdatePlayerAnimations

    jp UpdateEnd


.updateFallingState:
    call UpdatePlayerPosition
    call UpdatePlayerAnimations

    jp UpdateEnd


UpdateEnd: 
    call PlayerJump
    call UpdatePlayerGravity
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
    ld a, 0
    ld [wCurrentPlayerState], a

    jp EndMovePlayer


EndMovePlayer:
    ret


UpdatePlayerPosition:
    ld a, [wPlayerSpeed]
    ;cp a, 0
    ;jp z, .updateIdle ; Skip to updateIdle if speed == 0
    
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

    ; Preventing player from moving outside the left boundary of the screen
    cp a, 7
    jp z, EndUpdatePlayerPosition

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
    
    ; Preventing player from moving outside the right boundary of the screen
    ld a, [_OAMRAM + 5]
    dec a
    cp a, 160
    jp nc, EndUpdatePlayerPosition

    ld a, [_OAMRAM + 1]
    add a, b
    ld [_OAMRAM + 1], a

    ld a, [_OAMRAM + 5]
    add a, b
    ld [_OAMRAM + 5], a


EndUpdatePlayerPosition:


    ret


PlayerJump:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, PlayerNotJumping

    ld a, [wPlayerMaxJumpSpeed]
    ld [wPlayerJumpSpeed], a

    ld a, 2
    ld [wCurrentPlayerState], a
    
    jp EndPlayerJump


PlayerNotJumping:
    ld a, 0
    ld [wPlayerJumpSpeed], a


EndPlayerJump:


    ret


UpdatePlayerGravity:
    ; Apply jump velocity
    ld a, [wPlayerJumpSpeed]
    ld b, a
    ld a, [_OAMRAM]

    sub a, b
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    sub a, b
    ld [_OAMRAM + 4], a

    ; Apply gravity
    ld a, [wPlayerGravity]
    ld b, a
    ld a, [_OAMRAM]

    add a, b
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    add a, b
    ld [_OAMRAM + 4], a


EndUpdatePlayerGravity:


    ret


UpdatePlayerAnimations:
    call FlipPlayerSprite

    ld a, [wCurrentPlayerState]
    cp PLAYER_IDLE
    call z, IdleAnimation

    cp PLAYER_WALKING
    call z, WalkingAnimation

    cp PLAYER_JUMPING
    call z, JumpingAnimation


EndUpdatePlayerAnimations:


    ret



FlipPlayerSprite: 
    ld a, [wPlayerDirection]
    cp a, 0
    call z, FacingLeft

    cp a, 1
    call z, FacingRight


EndFlipPlayerSprite:


    ret


IdleAnimation:
    ld a, $00
    ld [wCurrentAnimationFrame], a


IdleAnimationEnd:


    ret


JumpingAnimation:
    ld a, $0C
    ld [wCurrentAnimationFrame], a

    ld a, [_OAMRAM + 3]
    ld b, %00100000
    and a, b
    call nz, FacingLeft
    call z, FacingRight


JumpingAnimationEnd:


    ret


WalkingAnimation:
    ; Safety check to prevent animation frame from going over animation tile indexes
    ld a, [wCurrentAnimationFrame]
    call CheckWalkingFrames

    ld a, [wCurrentAnimationFrame]
    cp a, $0C
    call c, IncreasAnimationFrameCounter
    
    ; Checking if the player is currently flipped horizontally
    ; and branching code accordingly
    ld a, [_OAMRAM + 3]
    ld b, %00100000
    and a, b
    call nz, FacingLeft
    call z, FacingRight


WalkingAnimationEnd:


    ret


CheckWalkingFrames:
    cp a, $04
    jp c, EndCheckWalkingFrames

    cp a, $09
    jp nc, EndCheckWalkingFrames

    ld a, $04
    ld [wCurrentAnimationFrame], a


EndCheckWalkingFrames:


    ret


IncreasAnimationFrameCounter:
    ; Multiplying animation counter by 4
    ld a, [wCurrentAnimationFrame]
    inc a
    inc a
    inc a
    inc a

    ; If A falls goes over the tile indexes for animation frames
    ; reset the animation frame counter
    cp a, $0C
    jp nc, IncreasAnimationFrameCounterEnd
    
    ld [wCurrentAnimationFrame], a


IncreasAnimationFrameCounterEnd:
    ld a, [wCurrentAnimationFrame]
    cp $0C
    call nz, ResetWalkingAnimation
    

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

    ; Swapping metasprite tile indexes
    ld a, [wCurrentAnimationFrame]
    inc a
    inc a
    ld [_OAMRAM + 2], a
    
    dec a
    dec a
    ld [_OAMRAM + 6], a 

    ;call IncreasAnimationFrameCounter

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

    ; Swapping metasprite tile indexes
    ld a, [wCurrentAnimationFrame]
    ld [_OAMRAM + 2], a

    inc a
    inc a
    ld [_OAMRAM + 6], a

    ;call IncreasAnimationFrameCounter

    ret


ResetWalkingAnimation:
    ld a, 4
    ld [wCurrentAnimationFrame], a


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

    jp CheckFloorCollisionEnd


CollideWithFloor:
    ld a, [_OAMRAM]
    sub a, 4
    ld [_OAMRAM], a

    ld a, [_OAMRAM + 4]
    sub a, 4
    ld [_OAMRAM + 4], a

    jp CheckFloorCollisionEnd


CheckFloorCollisionEnd:


    ret


CollideWithScreenBoundary:
    ld a, [_OAMRAM + 1]
    sub a, 1


CollideWithScreenBoundaryEnd:


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


SECTION "Player Variables", WRAM0

wCurrentPlayerState: db
wPlayerSpeed: db
wPlayerAcceleration: db
wPlayerMaxSpeed: db
wPlayerJumpSpeed: db
wPlayerMaxJumpSpeed: db
wPlayerGravity: db
wPlayerDirection: db
wCurrentAnimationFrame: db


SECTION "Player Constants", WRAM0

DEF PLAYER_IDLE EQU $00
DEF PLAYER_WALKING EQU $01
DEF PLAYER_JUMPING EQU $02
DEF PLAYER_FALLING EQU $03
