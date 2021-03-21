pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

draw_pixels = nil
function _init()
  draw_pixels = getpixels()
  progressive_coroutine=false
  x2 = 0
  y2 = 0
  moved=true
  screen_width = 4
  screenx = 0
  screeny = 0

  pan_cb = function()
    panning=true
    menuitem(1, "switch to move", move_cb)
  end

  move_cb = function()
    panning=false
    menuitem(1, "switch to pan", pan_cb)
  end

  move_cb()
end

pan=.02
function _update60()
  moved=false

  if panning then
    if btn(0) then
      screenx-=pan*screen_width
      moved=true
    end
    if btn(1) then
      screenx+=pan*screen_width
      moved=true
    end
    if btn(2) then
      screeny-=pan*screen_width
      moved=true
    end
    if btn(3) then
      screeny+=pan*screen_width
      moved=true
    end
  else
    if btn(0) then
      x2-=pan
      moved=true
    end
    if btn(1) then
      x2+=pan
      moved=true
    end
    if btn(2) then
      y2-=pan
      moved=true
    end
    if btn(3) then
      y2+=pan
      moved=true
    end
  end

  if btn(4) then
    screen_width = max(screen_width * 0.98, 0x0.0001)
    moved=true
  end
  if btn(5) then
    screen_width = max(screen_width/0.98, screen_width+0x0.0001)
    moved=true
  end
end

function _draw()
  progressive_draw()
end

max_i = 50
pixels_i = 1
redraw_at = pixels_i
redraw = false
function progressive_draw()
  local x,y
  while true do
    pixels_i+= 1
    if pixels_i > #draw_pixels then
      pixels_i = 1
    end

    x, y = draw_pixels[pixels_i][1], draw_pixels[pixels_i][2]
    if not moved then
      pset(x, y, ceil(mandel(x, y)/max_i*15))
    else
      rectfill(x-1, y-1, x+1, y+1, ceil(mandel(x, y)/max_i*15))
    end

    if stat(1) > 0.85 then
      return
    end
  end
end

function mandel(x,y)
  x = ((x>>>7) - 0.5) * screen_width + screenx
  y = ((y>>>7) - 0.5) * screen_width + screeny

  local ox = 0
  local oy = 0
  if x*x + y*y > (x-x2)^2 + (y-y2)^2 then
    ox=x2
    oy=y2
  end
  local zx,zy,zswap
  local cx,cy -- center of the orbit

  for i=1,max_i do
    if ox*ox + oy*oy < (ox-x2)*(ox-x2) + (oy-y2)*(oy-y2) then
    --if abs(ox-0) + abs(oy-0) < abs(ox-x2) + abs(oy-y2) then
      cx=0
      cy=0
    else
      cx=x2
      cy=y2
    end
    zx = ox-cx
    zy = oy-cy

    zx, zy = zx*zx - zy*zy + (x-cx), (zx+zx)*zy + (y-cy)
    
    if abs(zx) + abs(zy) > 2 then
      if zx*zx + zy*zy > 4 then
        return i
      end
    end

    ox = zx+cx
    oy = zy+cy
  end

  if cx != 0 then
    return 0--15
  else
    return 0
  end
end

shuffled_pixels=true
function getpixels()
  pixels = {}
  local i, temp
  local add_from = function(startx, starty, every, size)
    for x=startx,127,every do
      for y=starty,127,every do
        temp = {x, y}
        add(pixels, temp)
        i = ceil(rnd(#pixels))
        pixels[i][1], pixels[i][2], temp[1], temp[2] = temp[1], temp[2], pixels[i][1], pixels[i][2]
      end
    end
  end

  add_from(0, 0, 1, 2)

  return pixels
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
