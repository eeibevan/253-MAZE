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
  W = WALL_CODE                 ; Alias For Code

  ;; Water
  WATER_CODE = 2
  WATER_CHARACTER = 219         ; Block
  WATER_COLOR = 0x3h            ; Cyan
  Wa = WATER_CODE               ; Alias For Code




maze:
  db W,  W,  W,  W,  W,  W,  W,  W,  W
  db W,  B,  B,  B,  W,  B,  B,  Wa, W
  db W,  B,  B,  B,  B,  B,  B,  B,  W
  db W,  B,  B,  B,  W,  B,  B,  B,  W
  db W,  W,  W,  W,  W,  W,  W,  W,  W
  MAZE_COLUMNS = 9
  MAZE_ROWS = 5

  ;; Character
  CHARACTER_CHARACTER = 1
  CHARACTER_COLOR = 0xFh        ; White
  char_x db 2
  char_y db 2

.code

_main:
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

  ;; Hack The Character In For Now
  GOTOXY [char_x], [char_y]
  mov al, CHARACTER_CHARACTER
  mov bl, CHARACTER_COLOR
  mov ah, 9
  xor bh, bh
  mov cx, 1
  int 10h
  ret

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

_load_blank:
  PUTC BLANK_CHARACTER          ; Print Blank
  jmp _after_cursor_adv         ; Jump After Advance Cursor Since No Color Is Associated
_load_wall:
  mov al, WALL_CHARACTER        ; Load Wall Ascii Character
  mov bl, WALL_COLOR            ; Load Wall Color
  jmp _print_advance_cursor     ; Jump To Print
_load_water:
  mov al, WATER_CHARACTER       ; Load Water Ascii Character
  mov bl, WATER_COLOR           ; Load Water Color
  jmp _print_advance_cursor     ; Jump To Print

_print_advance_cursor:
  mov ah, 9                     ; Interrupt Code
  xor bh, bh                    ; Print On Page 0
  mov cx, 1                     ; Print Only One Character
  int 10h                       ; Print Character With Attribute

  advance_cursor                ; Move To The Next Position

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

