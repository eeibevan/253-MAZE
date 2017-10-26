include emu8086.inc
org 100h

.data


  ;; Blank
  BLANK_CODE = 0                ; Code In Data Structure
  BLANK_CHARACTER = 32          ; Space
  BLANK_COLOR = 0               ; Black
  B = BLANK_CODE                ; Alias For Code

  ;; Wall
  WALL_CODE = 1                 ; Code In Data Structure
  WALL_CHARACTER = 219          ; Block
  WALL_COLOR = 8                ; Dark Gray
  W = WALL_CODE                 ; Alias For Code


  ;; Water
  WATER_CODE = 2
  WATER_CHARACTER = 219         ; Block
  WATER_COLOR = 3               ; Cyan
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
  call parse_and_print
  add sp, 2                     ; Clean Up Parameter
  inc si                        ; Move To Next Maze Byte
  dec cl                        ; Column Now Complete (For This Row)
  jnz _read_column              ; Loop For Every Column In One Row
  PRINTN                        ; Print A New Line At The End of The Row
  dec ch                        ; Row Now Complete
  jnz _read_row                 ; Loop For Each Row

  ;; Hack The Character In For Now
  GOTOXY 2, 2
  mov al, CHARACTER_CHARACTER
  mov bl, CHARACTER_COLOR
  mov ah, 9
  xor bh, bh
  mov cx, 1
  int 10h
  ret

parse_and_print proc
  mov bp, sp
  push ax
  push cx
  mov ax, [bp+2]

  cmp ax, BLANK_CODE
  je _load_blank

  cmp ax, WALL_CODE
  je _load_wall

  cmp ax, WATER_CODE
  je _load_water
  jne _load_blank               ; Fall Through Protection

_load_blank:
  mov al, BLANK_CHARACTER       ; Load Blank Character
  mov bl, BLANK_COLOR           ; Load Blank Color (Move To Overwrite Previous Color)
  jmp _end_parse_and_print      ; Jump To Print
_load_wall:
  mov al, WALL_CHARACTER        ; Load Wall Ascii Character
  mov bl, WALL_COLOR            ; Load Wall Color
  jmp _end_parse_and_print      ; Jump To Print
_load_water:
  mov al, WATER_CHARACTER       ; Load Water Ascii Character
  mov bl, WATER_COLOR           ; Load Water Color
  jmp _end_parse_and_print      ; Jump To Print

_end_parse_and_print:
  mov ah, 9                     ; Interrupt Code
  xor bh, bh                    ; Print On Page 0
  mov cx, 1                     ; Print Only One Character
  int 10h                       ; Print Character With Attribute

  call advance_cursor           ; Move To The Next Position

  pop cx
  pop ax
  mov sp, bp
  ret
endp

advance_cursor proc
  ;; These Interrupts Use A Nightmarish Amount of Registers
  ;; TODO: Optimize Saved Regsters
  push ax
  push bx
  push cx
  push dx

  ;; Get Cursor Position
  mov ah, 3h
  xor bh, bh
  int 10h

  inc dl                        ; Advance By 1 Column

  ;; Set New Cursor Position
  mov ah, 2h
  int 10h

  pop bx
  pop cx
  pop dx
  pop ax
  ret
endp

