pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

function _init()
  draw_pixels = getpixels()
  progressive_coroutine=false
  x2 = 0
  y2 = 0
  moved=true
end

pan=.02
function _update60()
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

function _draw()
  if not progressive_coroutine then
    progressive_coroutine=cocreate(progressive_draw)
    moved=false
  end
  assert(coresume(progressive_coroutine)) -- if needed, args get passed in here and only read the first time
end

function progressive_draw()
  local i = 1
  local pixel
  local redraw=false
  while true do
    if i > #draw_pixels then
      i = 1
      redraw=true
    end

    pixel = draw_pixels[i]
    if redraw then
      pset(pixel.x, pixel.y, mandel(pixel.x,pixel.y))
    else
      rectfill(pixel.x, pixel.y, pixel.x+pixel.size-1, pixel.y+pixel.size-1, mandel(pixel.x,pixel.y))
    end

    i+=1

    if stat(1) > 0.85 then
      yield()
    end
  end
end

function mandel(x,y)
  x = x>>>5
  y = y>>>5
  -- we're dividing by 2^n here to scale down from resolution

  x-=2+1 -- -2,2
  y-=2+1-- -2,2

  local ox = 0
  local oy = 0
  if x*x + y*y > (x-x2)^2 + (y-y2)^2 then
    ox=x2
    oy=y2
  end
  local zx,zy,zswap
  local cx,cy -- center of the orbit

  for i=1,14 do
    if ox*ox + oy*oy < (ox-x2)^2 + (oy-y2)^2 then
    --if abs(ox-0) + abs(oy-0) < abs(ox-x2) + abs(oy-y2) then
      cx=0
      cy=0
    else
      cx=x2
      cy=y2
    end
    zx = ox-cx
    zy = oy-cy

    zswap = zx*zx - zy*zy + (x-cx)
    zy = (zx+zx)*zy + (y-cy)
    zx = zswap
    
    if zx*zx + zy*zy > 4 then
    --if abs(zx) + abs(zy) > 4 then
      return i
    end

    ox = zx+cx
    oy = zy+cy
  end

  if cx != 0 then
    return 15
  else
    return 0
  end
end

function getpixels()
  local pixels = {}

  local add_from = function(startx, starty, every, size)
    for x=startx,127,every do
      for y=starty,127,every do
        add(pixels,{
          x=x,
          y=y,
          size=size
        })
      end
    end
  end

  add_from(0, 0, 16, 16)

  add_from(8, 8, 16, 8)
  add_from(8, 0, 16, 8)
  add_from(0, 8, 16, 8)

  add_from(4, 4, 8, 4)
  add_from(4, 0, 8, 4)
  add_from(0, 4, 8, 4)

  add_from(2, 2, 4, 2)
  add_from(2, 0, 4, 2)
  add_from(0, 2, 4, 2)

  add_from(1, 1, 2, 1)
  add_from(1, 0, 2, 1)
  add_from(0, 1, 2, 1)

  return pixels
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
