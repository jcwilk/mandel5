pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

draw_pixels = nil
function _init()
  draw_pixels = getpixels()
  progressive_coroutine=false
  moved=true
  screen_width = 16
  camx = 6
  camy = 5

  calc_distance=2
  calc_distance_sq=calc_distance*calc_distance

  mandels = {
    {6,9,1,1},
    {0,0,1,1},
    {4,1,1,1},
    {8,3,1,1},
    {12,7,1,1},
  }

  pan_cb = function()
    panning=true
    menuitem(1, "switch to move", move_cb)
  end

  move_cb = function()
    panning=false
    menuitem(1, "switch to pan", pan_cb)
  end

  move_cb()

  enable_trace = function()
    tracing=true
    menuitem(2, "disable tracing", disable_trace)
  end

  disable_trace = function()
    tracing=false
    menuitem(2, "enable tracing", enable_trace)
  end

  disable_trace()
end

pan=.02
function _update60()
  moved=false

  if panning then
    if btn(0) then
      camx-=pan*screen_width
      moved=true
    end
    if btn(1) then
      camx+=pan*screen_width
      moved=true
    end
    if btn(2) then
      camy-=pan*screen_width
      moved=true
    end
    if btn(3) then
      camy+=pan*screen_width
      moved=true
    end
  else
    if btn(0) then
      mandels[1][1]-=pan
      -- moved=true
    end
    if btn(1) then
      mandels[1][1]+=pan
      -- moved=true
    end
    if btn(2) then
      mandels[1][2]-=pan
      -- moved=true
    end
    if btn(3) then
      mandels[1][2]+=pan
      -- moved=true
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

  if tracing and not moved then
    line(64,62,64,66,9) -- orange
    line(62,64,66,64,9) -- orange
    tracing_points={}
    mandel(64,64)
    if #tracing_points > 0 then
      line(64,64,tracing_points[1][1],tracing_points[1][2],tracing_points[1][3]) -- yellow
      
      for i=2, #tracing_points do
        line(tracing_points[i][1],tracing_points[i][2],tracing_points[i][3])
      end
    end
    tracing_points=false
  end
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
      pset(x, y, ceil(mandel(x, y)))
    else
      rectfill(x-1, y-1, x+1, y+1, ceil(mandel(x, y)))
    end

    if stat(1) > 0.85 then
      return
    end
  end
end

function mandel(x,y)
  x = ((x/128) - 0.5) * screen_width + camx
  y = ((y/128) - 0.5) * screen_width + camy

  local ox = x
  local oy = y

  local zx,zy,zxf,zyf

  local xs,ys,orbiting,tempx,tempy,min_candidate,candidates,net_invmagsq

  local originx,originy

  local diffx,diffy

  for i=1,max_i do
    xs = 0
    ys = 0
    orbiting=false
    min_candidate = 10000

    candidates = {}
    net_invmagsq = 0

    for j=1,#mandels do

      originx = mandels[j][1]
      originy = mandels[j][2]

      zx = ox - originx
      zy = oy - originy

      zx/= mandels[j][3]
      zy/= mandels[j][4]

      cx = x - originx
      cy = y - originy

      cx/= mandels[j][3]
      cy/= mandels[j][4]

      zxsq = zx*zx - zy*zy
      zysq = (zx+zx)*zy

      zxf = zxsq + cx
      zyf = zysq + cy

      tempx = zxf - zx
      tempy = zyf - zy
      tempx*= mandels[j][3]
      tempy*= mandels[j][4]

      -- zxsq, zysq is the Z^2 part of Zf = Z^2 + C, so 1/Z^2 is kind of like 1/r^2 which seems like a reasonable way to rate how "strong" a fractal affects a point
      invmagsq = 1/(abs(zxsq) + abs(zysq))
      add(candidates, {tempx, tempy, invmagsq, originx, originy})
      net_invmagsq+= invmagsq
    end -- looping through mandels

    if tracing_points then
      local trace_color
      if seen_this_iteration[1] then
        trace_color = 12
      elseif seen_this_iteration[2] then
        trace_color = 14
      else
        trace_color = 7
      end
      add(tracing_points, {((ox-camx)/screen_width + 0.5)*128, ((oy-camy)/screen_width + 0.5)*128, trace_color})
    end

    foreach(candidates, function(candidate)
      ox+= candidate[1] * candidate[3] / net_invmagsq
      oy+= candidate[2] * candidate[3] / net_invmagsq
    end)

    diffx = 0
    diffy = 0
    foreach(candidates, function(candidate)
      diffx=abs(candidate[4]-ox)
      diffy=abs(candidate[5]-oy)
      if (diffx <= calc_distance and diffy <= calc_distance) then
        if diffx*diffx + diffy*diffy <= calc_distance_sq then
          orbiting = true
        end
      end
    end)

    if not orbiting then
      return ceil(15*i/max_i)
    end
    
    -- this refers to a lot of no-longer-existing stuff but keeping it for color reference in case I want to revisit that
    -- if seen_this_fn_call[1] then
    --   if seen_this_fn_call[2] then
    --     return 5 --dk gray
    --   else
    --     return 3 --dk green
    --   end
    -- else
    --   if seen_this_fn_call[2] then
    --     return 2 --dk purple
    --   else
    --     return 0 --black
    --   end
    -- end

  end -- iterations loop

  return 0

  -- if seen_this_fn_call[1] and seen_this_fn_call[2] then
  --   return 6 -- light gray
  -- elseif seen_this_fn_call[1] then
  --   return 11 -- green
  -- elseif seen_this_fn_call[2] then
  --   return 8 -- red
  -- else
  --   error_invalid_state()
  -- end
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
__label__
66666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666565555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555533333
66666666666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555555555533333333333
66666666666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555533333333333333333
66666666666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555533333555555555555555555
bb666666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666666555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666566555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666665655555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666565655555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666666555555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666666666565555555555555555555555555555555555555555555555555555555555555
b6666666666666666666666666666666666666666666666666666666666656666555555555555555555555555555555555555555555555555555555555555555
bbbbbbbbb66666666666666666666666666666666666666666666666666666666665555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbb6666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbb666666666666666666666666666666666666666666666666666666565555555555555555555555555555555555555333333333333333333333333
bbbbbbbbb66666666666666666666666666666666666666666666666666666666555555555555555555555555555555555555555555555555555555555555333
bbbbbbbb666666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbb6666666666666666666666666666666666666666666666666555555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbb66666666666666666666666666666666666666666666666666555556555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbb66666666666666666666666666666666666666666666666666656655655555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbb6666666666666666666666666666666666666666656665565555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbb6666666666666666666666666666666666666666666665666655655555555555555555555555555555555555555533333333333333333
bbbbbbbbbbbbbbbbbbb6666666666666666666666666666666666666666666666666565555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbbb666666666666666666666666666666666666666665656665555555555555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666556565656666656656555556555555555555555555555555555555553333333333333333333333
bbbbbbbbbbbbbbbbbb66666666666666666666666666666666665555666666666665555555555555555555333333555555555555555555555555555555555555
bbbbbbbbbbbb6b666666666666666666666666666666666566666666666555555555565555555555555555533333333333333333555555555555555555555555
bbbbbbbbbbb6bb66b666666656356663555566555555666333555555666333333355555555333333333333333333555553333333333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666bbb6666666566536555655556666665655333333555555555555555555555555533333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666566666666666666655655555533333555555555555555566555555555555555555555333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666666665666656666655555566665555555555555555555555333333333333333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666665566655666555556555555555555555555555555555555555555556655555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666665655565555555555555656555555666665565555555555555553333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666666665555666655555555555555555555555555533333333333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666665665566666666666666655555555555555555555555555555555555555555555555553
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666666666666655555556555555555666666666666666666666655555555555555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666666666666666666655555555555555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666656566555565565565565555655655665555666555656565555555565665555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666666665655555555555555555555655555555555555555555555555555555555555553333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666656556655666666666665555555555555555555555333333333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666666566666565556666666666665555555555555553333333333333333333333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666655555555555566666666666655555555555555555555555555553333333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666666666666666666666666555565555555566666666666665555555555555555555555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666666666666666666666666555555555555555666666666666655555555555555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666655666666666666666666666666666666666655555555555555555666666666666655555555555555555
bbbbbbbbbbbbbbbbbbbbbbbbbb666666666666666666666665556555666666666666666666666666666666665555555555555555555556666666666666555555
bbbbbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666666565555555556666666666666666666666666666666665555555555555555555555555566666
bbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666556666655655555555666666666666666666666666666666666555555555555555555555
bbbbbbbbbbbbbbbbbbbbbb6666666666666666666666666666665666655555666666666655555655566555666666666666666666666666666666666655555555
bbbbbbbbbbbbbbbbbbbbb66666666666666666666666666666666666666555566666666665555556555555566666555555556666666666666666666666666666
bbbbbbbbbbbbbbbbbbb6566666666666666666666666666666666656566565556666666666555555555555555555555555566655555555555555566666666666
bbbbbbbbbbbbbbbbb666666666666666666666666666666666666666565665555566666666665555555555555555555555555555555555555555555555555555
bbbbbbbbbbbbbbb66666666666666666666666666666666666666665566656555556666666666655555555553333355555555555555555555555555555555555
bbbbbbbbbbbb66666666666666666666666666666666666666666666555556655655566666666665555555555555333333333333333333333333333333333333
bbbbbbbb666666666666666666666666666666666666666666666666655556565565555666666666655555555555555533333333333333333333333333333333
bbbbbbb6666666666666666655666666666666666666666666666666665555565655555566666666666555555555555555553333333333333333333333333333
bbbbbbb6666666666666666666656666666666666666666666666666666555555556565555666666666665555555555555555555333333333333333333333333
bbbbbbbb666666666666666666665666666666666666666666666666666665555556555555556666666666655555555555555555555553333333333333333333
bbbbbbbbb66666666666666666666556666666666666666666666666666666555555566555555566666666665555555555555555555555555333333333333333
bbbbbbbbbb6666666666666666666665566666666666666666666666666666655555555565555555666666666655555555555555555555555555553333333333
bbbbbbbbbbb666666666666666666666555666666666666666666666666666665555555555665555556666666666555555555555555555555555555555333333
bbbbb333333366666666666666666666665556666666666666666666666666666655555555556555555566666666665555555555555555555555555555555553
33333333333336666666666666666666666555566666666666666666666666666665555555555556555555666666666655555555555555555555555555555555
33333333333333666666666666666666666665555666666666666666666666666666655555555555565555556666666666555555555555555555555555555555
33333333333366666666666666666666666666655556666666666666666666666666666555555555555665555556666666665555555555555555555555555555
33333333333666666666666666666666666666666555566666666666666666666666666655555555555555655555566666666665555555555555555555555555
33333333366666666666666666666666666666666666555666666666666666666666666666555555555555555655555666666666655555555555555555555555
33333336666666666666666665555666666666666556665556666666666665556666666666665555555555555555655555666666666555555555555555555555
33333666666666666666666555555666666666655556665555566666666666555556666666666655555555555555555555555666666666555555555555555555
33365666666666666666665555555666666666555556665656655566666666665555566666666666555555555555555556555566666666665555555555555555
66565666666666666666655555555666666665555556655556565665666666666555555666666666665555555555555555555555556666666665555555555555
66555666666666666665555555555666666655555556656555566655556666666665555555666666666655555555555555555555555556666666665555555555
55556566666666666655555555555666666555555556655656555555556666566666555555556666666666555555555555555555555555555566666655555555
65555666666666666555555555556666665555555556655665566565556666566666555555555556666666665555555555555555555555555555556666655555
65556666666666666555555555556666655555555566655555565555556666556666555555555555566666666655555555555555555555555555555556666655
65555666666666665555555555556666655555555566556556565555556666556666555555555555555666666666555555555555555555555555555555555666
55565666666666655555555555566666555555555566555565566555555666556666655555556555555555666556666555555555555555555555555555555555
55566666666666555555555555566665555555555566555556655555555666556666655555556665555555556665556665555555555555555555555555555555
55566666666666555555555555666655555555555665555556555655555666656666655555555666665555555556655556665555555555555555555555555555
55656666666665555555555555666555555555555665555556565555555666656666655555555556666655555555566655566655555555555555555555555555
55656666666665555555555556665555555555555655555565555555555666656666655555555555556666655555555566555566655555555555555555555555
55556666666655555555555566655555555555556655555555556555555566666666655555555555555556666655555555565555566555555555555555555555
55566666666655555555555566555555555555556655555556655555555566666666665555555555555555566666555555555665555566555555555555555555
55566666666555555555555665555555555555556555555555555655555566666666665555555555555555555566666555555555665555566555555555555555
56566666666555555555556665555555555555556555555555565555555566666666665555555555555555555555566666555555555655555665555555555555
55566666666555555555566655555555555555566555555555566655555566666666665555555555555555555555555566666555555556655555665555555555
55566666666555555555666555555555555555565555555555555655555556666666665555555555555555555555555555566666555555556655555665555555
55566666666555555556665555555555555555565555555556655565555556666665665555555555555555565555555555555556666655555556555555665555
55666666666555555566555555555555555555665555555555556655555556666655666555555555555555556555555555555555556666655555556555555665
55666666666555556665555555555555555555655555555555555556555556666655566555555555555555555555555555555555555556666665555556555555
55666666666666666655555555555555555555655555555555555555555556666655566555555555555555553335555565555555555555556666665555556555
55666666666666666555555555555555555555655555555555555565555555666555566555555555555555555333333355555555555555555556666666555566
55666666666666655555555555555555555556555555555555556565555555666555566555555555555555555533333333335565555555555555555666666655
56666666666666555555555555555555555556555555555555555555555555666555556655555555555555555553333333333333355655555555555555666666
56666666666655555555555555555555555556555555555555555555555555666555556655555555555555555555333333333333333333555555555555555566
56666666665555555555555555555555555555555555555555555555555555566555556655555555555555555555333333333333333333333355555555555555
56666666655555555555555555555555555565555555555555555555556555566655556655555555555555555555533333333333333333333333333555555555
56666665555555555555555555555555555565555555555555555556556555566655555655555555555555555555553333333333333333333333333333335555
66666655555555555555555555555555555555555555555555555555555555566655555655555555555555555555555333333333333333333333333333333333
66666555555555555555555555555555555655555555555555555555555555566655555665555555555555555555555533333333333333333333333333333333
66665555555555555555555555555555555655555555555555555555555555555655555665555555555555555555555553333333333333333333333333333333
66665555555555555555555555555555555555555555555555555555565555555655555565555555555555555555555555333333333333333333333333333333
66655555555555555555555555555555555555555555555555555565655555555565555565555555555555555555555555533333333333333333333333333333
66555555555555555555555555555555556555555555555555555555555655555565555565555555555555555555555555553333333333333333333333333333
66555555555555555555555555555555556555555555555555555555555555555555555566555555555555555555555555553333333333333333333333333333
65555555555555555555555555555555555555555555555555555555555555655555555566555555555555555555555555555333333333333333333333333333
65555555555555555555555555555555555555555555555555555555565556555556555556565555555555555555555555555533333333333333333333333333
55555555555555555555555555555555565555555555555555555555565556555555555556565555555555555555555555555553333333333333333333333333
55555555555555555555555555555555555555555555555555555555565556555555555556665555555555555555555555555555333333333333333333333333
55555555555555555555555555555555555555555555555555555555655656555555655556665555555555555555555555555555533333333333333333333333
55555555555555555555555555555555555555555555555555555555655655555555555555665555555555555555555555555555553333333333333333333333
55555555555555555555555555555555555555555555555555555555565555655555555555665555555555555555555555555555555333333333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555665555555555555555555555555555555533333333333333333333
55555555555555555555555555555555555555555555555555555555556555655555555555666555555555555555555555555555555553333333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555666555555555555555555555555555555553333333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555566555555555555555555555555555555555333333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555566555555555555555555555555555555555533333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555566555555555555555555555555555555555553333333333333333
55555555555555555555555555555555555555555555555555555555555555555555555555566555555555555555555555555555555555555333333333333333

