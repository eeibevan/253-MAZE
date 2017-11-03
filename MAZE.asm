  ;; Author: Evan Black
  ;; Purpose: Give A Small Demo of A Maze
  ;;
  ;; Algorithm:
  ;;  Read Through Row/Column
  ;;  Compare Found Byte To Known Shapes
  ;;  Draw Shape On The Screen
  ;;  Draw Player Character
include emu8086.inc
org 100h

.data
  ;; Blank
  BLANK_CODE = 0                ; Code In Data Structure
  BLANK_CHARACTER = ' '
  B = BLANK_CODE                ; Alias For Code

  ;; Wall
  WALL_CODE = 1                 ; Code In Data Structure
  WALL_CHARACTER = 219          ; Block
  WALL_COLOR = 0x8h             ; Dark Gray
  W = WALL_CODE

  ;; Water
  WATER_CODE = 2
  WATER_CHARACTER = 219         ; Block
  WATER_COLOR = 0x3h            ; Cyan
  Wa = WATER_CODE               ; Alias For Code

  ;; Electric
  ELECTRIC_CODE = 3
  ELECTRIC_COLOR = 0xEh         ; Yellow
  ELECTRIC_CHARACTER = 219      ; Block
  E = ELECTRIC_CODE

  ;; Goal
  GOAL_CODE = 4
  GOAL_COLOR = 0xFh             ; White
  GOAL_CHARACTER = 197          ; Cross?
  G = GOAL_CODE

maze:
  db W,  W,  W,  W,  W,  W,  W,  W,  W
  db W,  B,  B,  B,  W,  B,  B,  Wa, W
  db W,  B,  B,  B,  B,  B,  B,  B,  W
  db W,  B,  B,  B,  W,  B,  G,  E,  W
  db W,  B,  B,  B,  W,  B,  B,  Wa, W
  db W,  B,  B,  B,  W,  B,  B,  Wa, W
  db W,  W,  W,  W,  W,  W,  W,  W,  W
  MAZE_COLUMNS = 9
  MAZE_ROWS = 7

  ;; Character
  CHARACTER_CHARACTER = 1
  CHARACTER_COLOR = 0xFh        ; White
  char_x db 1
  char_y db 2

.code

_main:

  call render_maze

  ;; Character Inital Position
  mov al, [char_x]
  push ax
  mov al, [char_y]
  push ax
  call draw_character
  add sp, 4                     ; Clean 2 Params

_get_keyboard_input:
  mov ch, [char_x]
  mov cl, [char_y]
  xor ax, ax
  int 16h
  cmp al, 'w'
  je _move_up
  cmp al, 'a'
  je _move_left
  cmp al, 's'
  je _move_down
  cmp al, 'd'
  je _move_right
  jne _get_keyboard_input       ; Ignore Other Inputs

_move_up:
  dec cl
  jmp _check_target
_move_left:
  dec ch
  jmp _check_target
_move_down:
  inc cl
  jmp _check_target
_move_right:
  inc ch
  jmp _check_target

_check_target:
  GET_ADDRESS ch, cl
  lea si, maze
  add si, ax
  xor ax, ax
  mov al, [si]

  cmp al, BLANK_CODE
  je _move_redraw

  cmp al, WATER_CODE
	je _move_redraw

  cmp al, WALL_CODE
  je _no_move_target

  cmp al, ELECTRIC_CODE
  je _death_target

  cmp al, GOAL_CODE
  je _goal_target

_no_move_target:
  PUTC 7                        ; Beep
  jmp _get_keyboard_input
_move_redraw:
  mov al, [char_x]              ; src x
  push ax
  mov al, [char_y]              ; src y
  push ax
  mov al, ch                    ; dest x
  push ax
  mov al, cl                    ; dest y
  push ax
  call move_character
  add sp, 8                     ; Clean 4 Params
  mov [char_x], ch              ; Commit New x & y
  mov [char_y], cl
  jmp _get_keyboard_input
_goal_target:
  call clear_screen
  GOTOXY 30, 12
  PRINT "A WINNER IS YOU"
  ret
_death_target:
  call clear_screen
  GOTOXY 35, 12
  PRINT "YOU DIED"
  ret

render_maze proc
  lea si, maze
  mov ch, MAZE_ROWS
_read_row:
	mov cl, MAZE_COLUMNS
_read_column:
	mov al, byte ptr [si]
  push ax                       ; Partial Register Stall On A Real 8086 Chip!
  call parse_print
  add sp, 2                     ; Clean Up Parameter
  inc si                        ; Move To Next Maze Byte
  dec cl                        ; Column Now Complete (For This Row)
  jnz _read_column              ; Loop For Every Column In One Row
  PRINTN                        ; Print A New Line At The End of The Row
  dec ch                        ; Row Now Complete
  jnz _read_row                 ; Loop For Each Row
  ret
endp

move_character proc
  mov bp, sp
  push ax
  push bx
  push cx
  push dx
  push si

	mov cl, [bp+8]                ; 1st Param, Source  X
  mov ch, [bp+6]                ; 2nd Param, Source  Y
  mov bl, [bp+4]                ; 3rd Param, Destination X
  mov bh, [bp+2]                ; 4th Param, Destination Y

  push bp                       ; Save bp Since New proc Will Clobber
  GOTOXY cl, ch
  GET_ADDRESS cl, ch
  lea si, maze
  add si, ax
  xor dx, dx                    ; Clear dx For Partial Register Move
  mov dl, byte ptr [si]         ; Get Character In Maze
  push dx                       ; Pass Character To Print
  call parse_print              ; Print Maze Character Over Old Character Position
  add sp, 2                     ; Clean Param
  pop bp                        ; Restore Base Pointer

  push bp                       ; Save bp Since New proc Will Clobber
  mov bl, [bp+4]
  push bx
  mov bl, [bp+2]
  push bx
	call draw_character
	add sp, 4                     ; Clean 2 Params
  pop bp                        ; Restore Base Pointer


  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  mov sp, bp
  ret
endp

draw_character proc
  mov bp, sp
  push ax
  push bx
  push cx

  mov cl, [bp+4]
  mov ch, [bp+2]
  GOTOXY cl, ch
	mov al, CHARACTER_CHARACTER
	mov bl, CHARACTER_COLOR
	mov ah, 9
	xor bh, bh
	mov cx, 1
	int 10h

  pop cx
  pop bx
  pop ax
  mov sp, bp
  ret
endp

; Print The Character Defined By character-code
; Param:
;    [Stack] Word character-code: The Code
;    of a Predefined Character To Print
parse_print proc
  mov bp, sp                    ; Start Our Stack Frame
  push ax                       ; Save All Used Registers
  push bx
  push cx
  mov ax, [bp+2]                ; Get character-code Param

  cmp ax, BLANK_CODE
  je _load_blank

  cmp ax, WALL_CODE
  je _load_wall

  cmp ax, WATER_CODE
  je _load_water

  cmp ax, ELECTRIC_CODE
  je _load_electric

  cmp ax, GOAL_CODE
  je _load_goal

_load_blank:
  PUTC BLANK_CHARACTER          ; Print Blank
  jmp _after_cursor_adv         ; Jump After Advance Cursor Since No Color Is Associated
_load_wall:
  mov al, WALL_CHARACTER        ; Load Wall Ascii Character
  mov bl, WALL_COLOR            ; Load Wall Color
  jmp _print_advance_cursor     ; Jump To Print
_load_water:
  mov al, WATER_CHARACTER
  mov bl, WATER_COLOR
  jmp _print_advance_cursor
_load_electric:
  mov al,ELECTRIC_CHARACTER
  mov bl, ELECTRIC_COLOR
  jmp _print_advance_cursor
_load_goal:
  mov al, GOAL_CHARACTER
  mov bl, GOAL_COLOR
  jmp _print_advance_cursor

_print_advance_cursor:
  mov ah, 9                     ; Interrupt Code
  xor bh, bh                    ; Print On Page 0
  mov cx, 1                     ; Print Only One Character
  int 10h                       ; Print Character With Attribute

  ADVANCE_CURSOR                ; Move To The Next Position

_after_cursor_adv:              ; Label For Characters With No Color
  pop cx                        ; Restore All Used Registers
  pop bx
  pop ax
  mov sp, bp                    ; Close Our Stack Frame
  ret
endp

; Advance The Cursor One Column To The Right
; Registers Used: ah, bh, dx, cx
ADVANCE_CURSOR macro
  ;; Get Cursor Position
  mov ah, 3h
  xor bh, bh
  int 10h

  inc dl                        ; Advance By 1 Column

  ;; Set New Cursor Position
  mov ah, 2h
  int 10h
endm

; Convert x,y Coordinates To The Offest of The Character In The Maze In Memory
; Pass With Anything But bx, al
; Return With ax
; x, y bytes! Not Words!
GET_ADDRESS macro x, y
  push bx
  xor bx, bx                    ; Clear Relevant Registers
  xor ax, ax
  mov bh, x                     ; Move x To bh In Case It's An Immediate
  mov bl, y                     ; Same As x

  ;; WIDTH * Y + X
  mov al, MAZE_COLUMNS
  mul bl                        ; Use bl Since X/Y Should Be Bytes & To Do Byte mul
  add al, bh

  pop bx
endm

DEFINE_CLEAR_SCREEN
DEFINE_PRINT_NUM
DEFINE_PRINT_NUM_UNS

