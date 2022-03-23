pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

draw_pixels = nil
function _init()
  draw_pixels = getpixels()
  progressive_coroutine=false
  moved=true
  screen_width = .03
  camx = 2.734
  camy = 0.937

  calc_distance=4
  calc_distance_sq=calc_distance*calc_distance

  mandels = {
    {2.5,2,.1},
    {0,0,1},
    {4,1,1},
    --{8,3},
    --{12,7},
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
    if btn(4) then
      screen_width = max(screen_width * 0.98, 0x0.0001)
      moved=true
    end
    if btn(5) then
      screen_width = max(screen_width/0.98, screen_width+0x0.0001)
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
    if btn(4) then
      mandels[1][3]*=0.98
      --moved=true
    end
    if btn(5) then
      mandels[1][3]/=0.98
      --moved=true
    end    
  end


end

function _draw()
  progressive_draw()

  -- if tracing and not moved then
  --   line(64,62,64,66,9) -- orange
  --   line(62,64,66,64,9) -- orange
  --   tracing_points={}
  --   mandel(64,64)
  --   if #tracing_points > 0 then
  --     line(64,64,tracing_points[1][1],tracing_points[1][2],tracing_points[1][3]) -- yellow

  --     for i=2, #tracing_points do
  --       line(tracing_points[i][1],tracing_points[i][2],tracing_points[i][3])
  --     end
  --   end
  --   tracing_points=false
  -- end
end

max_i = 30
max_orbits = 1
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

function mandel(screenx,screeny)
  local raw = mandel_raw(screenx,screeny)
  if raw == max_i then
    return 0
  end

  return (raw % 15)+1
end

function mandel_raw(screenx,screeny)
  local x = ((screenx/128) - 0.5) * screen_width + camx
  local y = ((screeny/128) - 0.5) * screen_width + camy

  local ox = x
  local oy = y

  -- max_i * max_orbits * mandels
  local next_orbits = {
  }

  local man
  local orbit_distance_sq
  for i=1,#mandels do
    man = mandels[i]
    orbit_distance_sq = (man[1] - x)*(man[1] - x) + (man[2] - y)*(man[2] - y)
    if orbit_distance_sq <= calc_distance_sq then
      add(next_orbits, {x,y,i,orbit_distance_sq})
    end
  end

  local orbit
  local zx,zy,cx,cy,zxf,zyf
  local o
  for i=1,max_i do
    -- clear the candidate orbits for the next round and iterate through the ones from the last (or 1 orbit from i=0)
    this_orbits = next_orbits
    next_orbits = {}
    for j=1,#this_orbits do
      orbit = this_orbits[j]

      -- get the mandel that was paired as being close to the orbit
      man = mandels[orbit[3]]

      -- offset the orbit with that mandel
      zx = (orbit[1] - man[1])/man[3]
      zy = (orbit[2] - man[2])/man[3]
      cx = (x - man[1])/man[3]
      cy = (y - man[2])/man[3]

      -- (r) component
      zxf = zx*zx - zy*zy + cx
      -- (i) component
      zyf = (zx + zx) * zy + cy

      zxf = zxf*man[3] + man[1]
      zyf = zyf*man[3] + man[2]

      -- for each mandel which is within range of the offset orbit
      for k=1,#mandels do
        man = mandels[k]
        --orbit_distance_sq = (man[1] - zxf)*(man[1] - zxf)/man[3]/man[3] + (man[2] - zyf)*(man[2] - zyf)/man[3]/man[3]
        orbit_distance_sq = ((man[1] - zxf)*(man[1] - zxf) + (man[2] - zyf)*(man[2] - zyf))/man[3]/man[3]
        if orbit_distance_sq <= calc_distance_sq then
          -- add a candidate to next round's pool pairing the mandel with the offset orbit
          o = 1
          while o < #next_orbits and orbit_distance_sq > next_orbits[o][4] do
            o = o + 1
          end

          -- evict as necessary, ordered by how close the mandel is to the offset orbit
          if o <= max_orbits then
            add(next_orbits, {zxf,zyf,k,orbit_distance_sq}, o)
          end
        end
      end
    end -- this_orbits

    if #next_orbits == 0 then
      return i
    end
  end

  return max_i
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
55555555555555555555555555555555555555555555555555555555555555555566666666666666666666677777788be0bbaa988888899999999aaaaabbd000
55555555555555555555555555555555555555555555555555555555555555555556666666666666666666777777889ac000db998888999999999aaaabbccde0
6666655555555555555555555555555555555555555555555555555555555555555556666666666666666777777788cbaed00a99889999999999aaaaabbefde0
6666666555566666666555555555555555555555555555555555555555555555555555566666666666667777777788999accdb999999999999f0aaaaabbfedde
7bc7876666666667666665555555555566555555555555555555555555555555555555666666666666667777777788889adaa999999999999bddeaaabbbcdcdf
9098eb666667879a876666655555666666666655555555555555555555555555555566666666666666677777778888888999999999aaaaa9b000cbbbbbbcccf0
8a0987666679b7a087787666656666666666666655555555555555555555555555566666666666666677777778888888899999999abbbbaa0e00cb0ebbbbccdf
8d0d8876667808a0a88f8766666667778877666666555555555555555555555555666666666666666777777888999b0999999999ab000caacefcceecdcbbcddd
7a90d876667780e0098ca766666679878098766666655555555555555555555566666666666666666777778889fa90f99aaaaaaaad00dbaaa00ccf00ecccce00
799d0a7777799a00e988776666678908e09a777666665555555555555555556666666666666666667777778899bb9a0ba0cccbaaabefecbaaabc0df00dccde00
7808a87778989a00b087dc866666778900f88b0766665555555555555555666666666666666666677777788eccbaaaccbb00cbcaab0f0bbaaabbdcd0dcccd0e0
778877778dc990d0bb8800066666778a00e8a0b776666555557677805566666666666666666666677777788c000cbcbb0c0f0c0bbbbbcbaaabbbbbcccccccdde
6777777789e9bbf0bb89a807666777ba00989cf776666655977890d000666666666666666666667777778899b000fd0fee000d0cbbbbbbbbbbbbbbbccccdddde
677777788899bc00de90c0777667898a0ca8777766666666777909c0098666666666666666666777777788bdac00000000000edd0dcbbbccbbbbbbcccddeef0e
777778898b9cf0000ea99877777780ab0bd8777666666667790aaadea08866666666666666666777777788aa9bbc00000000000000eccdd0ecbf0cccdee0f000
77788a9d9fbcf0000eaa98877777898c0c9a8776666668c790dbd00ee87776666666666666667777777788999ead00000000000000ddcd00dce0eccde000ff00
7788c00baabc00000ebd9ad87777788adbac87766666670d9b000000988c86666666666666677777778888899bdbd0000000000000e0dd00dc0000ddf0000000
778aa000cc0e000000cb0ba98777779acb8877666666e789bd0000fb9dd0966666666666667777778888888890dbcdf00000000000feedddccdf00eee0000000
888eac0000000000000d000b87777788987777666666889cf000000f898906666666666666777778890999999abac0000000000000000fddddddefef00000000
98899cfe0000000000000f098877777777777766666699ac0000f00b98776666666666666777777889caaca999aa0ce000000000000000ef0eddeee000000000
a989aacd00000000000cc0ab987777777777766666660f00dcedcbec9777777777766666777777889a0b000a99abcee0000000000000000f0e0ff00000000000
da9900bdf000000000ddaaa098777777777766666666000caaa9a9bd8777777777777777777777880000000a99abc0000000000000000000fff0000000000000
da99bbb000000000000baa9988777777776666666666b0ea999988887777777777777777777777880bfcbbb999abe00000000000000000000000000000000000
b999aacd000000000ebb0a08888777777776666666666a9a08f987788877888887777777777778889aaaebb9999accddddef0000000000000000000000000000
999a000df0000000eccbbab88888877777776666666668809899888a99888cc98777777777777788a0c99999999ac0bc0ddfe000000000000000000000000000
99abccd000000000e0caa9988889888777777666666667777777899ebbab890a98777777777777889f0999989999abbbcdcdf000000000000000000000000000
99a000f0000000000d00a99888a0998877777776666777777888899edab99cdab877777777777788899988888999aaaabbbd000ff00000000000000000000000
9accf00000000000000ca998999aac98877777776677777788c988ab00aa9ab98887777777777788888888888999aaabbbbcfeddedefe0ff0000000000000000
9abbd00000000000f000a999ab0cfd08877777777777777880aa990b000c99988887777777777788888888888999acbd0bbbccccdddde00ee000000000000000
baab0d000000000f0fdba999bfc00b9888777777777777789c0fb9ae000eaa9888887777777777788888888889a9acd0ddbbbbccffdcd00deeef000000000000
d0bbdd00000000fdcbfba999ab00baa988777777777777788aacb9b0000fcf999888877777777778888888888cbbac0f0cbabbb00fdccfedeeef000000000000
edbbc0f000000ed0e0baa999b0caaaca88777777777777788ea999abd00dbe99c99888777777777888888888b00ebcccbbaaab0c00dcccde00eef00000000000
bcbcef0000000edcc0aa9999aca099a988777777777777788888899bbd0fc0aace9888777777777888888888cf000bb00baaab00ecccccdf0ffeeff000000000
aabc0000000000ecbaaa9999999a98888877777777777777888880bcadd00eba0b9888877777778888888888ad00dcabbaaaaae00fbbccd00eedef0000000000
abbcdf000000000bbaaba99999998888887777777777777788888a0ca0c000ca999888877777788888888888abd0eeaaaaaaaacdd0bbbccdeedd000000000000
aecdde00000fe0cbbcbeba99888888888877777777777777788888999abe00c099988888777788888888888890cc0fbaaaaaaaabbbbbbcccdddd00ff00000000
c0ffd000000e0cbbbed00a9998888888a89a7777777777777888899aaab0f0f0bb988888777888888888889999ab09999aaaaaabbbbcccccccddeeef00000000
b0ccd000000eccbbcfedba99988888a90aa99977777777777888890b0faa00f0ba9888887788888888889999999999999aaaaabbbbccccccccdd00f000000000
bbcce00000ed00cbbccdba99988880fbcf0ef0a777777777788889a0da9a0acd0a9888887888888888999999999999999aaaaabc0cde0eccccddf0f000000000
cccdde000ffd0dcbaaaaa99999888000000fcc0777777777788889a0fb9990baa99888888888888889999aa9999999999aaaabbd0df000dccccdee0000000000
cc00e0000edcccbbaaaaa99999999ab000000f087777777778888899a9999aa999888888888888889999a0baa99999999aaaabbcdf0000dccccdef0000000000
ccdeef000fdd0bbbaac09999999999acce00fbb88877777777888889999999999888888888888899999af0caaaaa99999aaaabbe0000eedccccde00000000000
deee00000ff0fbbbb00fb999999999acac0b0a9888888777778888888888888888888888888888999aaaa0eaaaaaaaa99aaaabbe0ff0d0dccccdd0f000000000
f0f000000fedcbbc0e000999999ad0aa9abaa0988888888877888888888888888888888888888999abc0bbbaabdbaaaaaaaaabbccdcccccccccdde0ff00f0000
0000000000eeccccdfcde99999abdcae0a999c88888888888888888888888888888888888888999ab00df0dcbcfbaaaaaaaaaabb00dccccbccccde0fe00f0000
000000000000dcde00b0aa9999aabbcfdb999888888888888888888888888888888888888888999a0e000fdcdccbbbaaaaaaaabbcedcbbbbccccddefeef00000
000000000000dcc0debaaa9999aaacf0eea99988888888888888888888888888888888888889999abbd0000000e0fbbaaaaaaabbbccbbbbbcccccdddeef00000
00000000000fdccccbbaaaa99aaa0f00fbca998888888888888888888888888888888888888999aaabce0000000000baaaaaaaabbbbbbbbbcccccddddee0000f
000000000000ddccbbbaaaa9aabcb00dccda999888888888888888888888888888888888889999adeebdddee0000dcbaaaaaaaaabbbbbbbbccccdddddeef00ff
0000000000fedfdcbcbbaaaaaacfcf0fbaaa99988888888888888888888888888888888888999abe00bbcecdcd0e0bbaaaaaaaaabbbbbbbbedcdeeeeeeeeffff
00000000000fe0ecc0fbbaaaaabbc00ccaa999988888888888888888888888888888888888999ab0cbaa00bcdcbbbbaaaaaaaaaabbbbbbb000dd0f0ffeeeefff
000000000000eed0dfdbbaaaaaabd0dc0aa999999988888888888888888888888888888889999aab0baaabbc0cbbaaaaaaaaaaaabbbbbbdf00ff00000eeeeff0
00000000000000e00ee0cbaaaaaac0fbaa99999999999999999888888888888888888888899999aaaaaaaabd00cbaaaaaaaaaaabbbbbbbd000e00000feeeef00
0000000000000f000000cbbaaaaabbbaaa999999999999999999999999988888888888888999999aaaaaaabbcbbaaaaaaaaaaaabbbbbccc0000eff00feeeff00
0000000000000000000ecbbaaaaaaaaaa99999999999999999999999999999999999999999999999999aaaaabbaaaaaaaaaaaabbbbccccce00de0eefeeeeff00
0000000000000000000dccbbaaaaaaaa99999999aaaaaa99999999999999999999999999999999999999aaaaaaaaaaaaaaaaabbbbccddcccc0ddeeeeeeeef000
0000000000000000feddfebbaaaaaaaa999999aaab0bbaa9aaaaa99999999999999999999999999999999aaaaaaaaaaaaaaabbbbcdd0edccccdddddddeeef000
00000000000000fe00d00dbbaaaaaaaaaa999aabcc0eeaaaababaaa9999999999999999999999999999999aaaaaaaaaaaaabbbbbc000eedcccddddddeeeff000
0000000000000000edccccbbbaaaaaaaaaaaaaabfcf0cbaae0c00baaa9999aaa999999999999999999999999aaaaaaaaaaabbbbcd0000edccdddddddeeef0000
0000000000000f00ddccccbbbbbbbbbaaaaaaaaabbc00babbce0dc0baaaaaaaaaaa999999999999999999999aaaaaaaaaabbbbbcde0000dcdddddd00eeef0000
00000000000000eeddd0fdbbbbcccccbbaaaaaaaab0ccbbbf000eecbaaaabbbebaaa9999999999999999999aaaaaaaaaabbbbbbcccdedddddddddf00fffff000
00000000000000eeeefe0fbbbbc0e0ebbbaaaaaaabbbbbc0cd000cbcaaabd0d0cbaaa99999999999999999aaaaaaaaaabbbbbccccccdddddeffee000f00ff000
00000000000000ee000efebbbbcce00ddbbaaaaaabbbbccdd0000cd0aaabbc00cccbaa99999999999999aaaaaaaaaaaabbbccded0dddddde000ee0000000f000
0000000000000fee00fecccbbbcf00ee0bbace0bbbbcc0ed00000d0cbaabb000c0fbaaa99999999999aaaaaaaaaaaaabbbbcdd0dffe0ffeef00feef000000000
0000000000000feeefedccccbcde000ccbb000ebbbcd0eef0000fdccbbbbed0ecbcbaaaa9cbbdd0aaaaaaaaaaaaaaabbbbcd00feeff00f0ef00feeff00000000
000000000000fffeedddccccccdee0e0cbbe00dcccde0000000000ddbbbbde0dcbbaaaaaabccd00eaaaaaaaaaaaaabbbbbcd00000000000ffffffffff0000000
000000000000ff0feddddccccccde0eccbb0f0ffdcd0f00000000f0ecbbbcdfd0baaaaafb00f00edcaaaaaaaaaaaabbbbcd0e0000000000000f00ffff0000000
0000000000000000eeefeddcccccddccbbbbcd000dd0f00000000000cbbbbcdcbbaaaacb000000dc0baaaaaaaaaabbbbbccdd000000000000000000000000000
0000000000000000fee0fddcccccccccbbbbccd0edde00000000000fdcbbbbbbbbaaaacee00000d00daaaaaaaaabbbbcccccdff0000000000000000000000000
000000000000000f00fff0eddccccccccccccccddde0000000000feddcbbbbbbbaaaaa0000000fcccaaaaaaaaabbbbcceddcd0e0000000000000000000000000
00000000000000000000000dddcccccccccccccdde0000000000f0f0ccbbbbbaaaaaaa000f0ff0cbbbbbbaaaabbbbccdfeeddde0000000000000000000000000
00000000000000000000000eeddccccdddcccefdd00000000000feddccccbbbbaaaaaa0eecdcecbbbbbbbbbbbbbbbcd0000fdd00000000000000000000000000
0000000000000000000000ff0eddcdde0eedd00eef0000000000fedccd0ccbbbbaaaaacc0d0cccccbcccbbbbbbbbbcde0f0eddf0000000000000000000000000
0000000000000000000000f00edddd0f0ffdf0f00f00000000000eddddf0ccbbbbaaaabbbbccd0fdcf0ccbbbbbbbbcd0ededdde0000000000000000000000000
0000000000000000000000ffeeddddef00edd0ff0f0000000000fedd0f00dcbbbbbabbbbbcccd0f0d000cbbbbbbbbcd0fdddddeff00000000000000000000000
0000000000000000000000fee0fdddef00feddeef0000000000ffddd000edcbbbbbbbbbbc0edef00eeeccbbbbbbbbccddcccdddeeef000000000000000000000
0000000000000000000000ff0000ddeef0eeeeeef000000000feeddd0fee0ccbbbbbbbbcc00ee000fdcccbbbbbbbbccccccccddef0ff00000000000000000000
0000000000000000000000ff00feeeeeeeeeeff00000000000feeddddedddccbbbbbbbbcc0dde000ffddccbbbbbbbbccccccced0000fff000000000000000000
0000000000000000000000f0000feeeeeeeef00f000000000ff00eddddccccbbbbbbbbbbccccd00000d0eccbbbbbbbcccccc000f00feff000000000000000000
000000000000000000000000000fffffffef0000000000000f000eddccccccbbbbbbbbbbcccc0e0000e00cccbbbbbccccccc000ff0feef000000000000000000
000000000000000000000000000f000000fff000000000000fff0eddccccdedebbbbbbbbbcccdde0000ddcccbbbbccccccccf00fefeee0000f00000000000000
000000000000000000000000000000000000000000000000feeeedddccc0000fdbbbbbbbbccd00e0000fdcccbbbcccccccccd000feeeeef0fff0000000000000
000000000000000000000000000000000000000000000000feefdddddde000000bbbbbbbbccde0ee000fdccccbccccccccdddefdddeeeeffff00000000000000
000000000000000000000000000000000000000000000000f000fddddddef00000bbbbbbbccdefedd0eedcccccccccccddddddddddeeeef00000000000000000
00000000000000000000000000000000000000000000000000000ddddeede000d0ccbbbbbcccddddddddccccccccccdddeedddddddeeef000000000000000000
0000000000000000000000000000000000000000000000000000eddde00e0ddd0cccccbbbccccccccdcccccccccccddde00eedddddeeef000000000000000000
0000000000000000000000000000000000000000000000000ffeedddeef00eddccccccccccccccccccccccccccccdddeef0eeeeeddeeef000000000000000000
0000000000000000000000000000000000000000000000000ffeeedee0000eedcccccccccccccccccccccccccccdddf000fff0feeeeeeff00000000000000000
000000000000000000000000000000000000000000000000000feeee000000fddccccccccccccccccccccccccccdde00000000feeeeeeff00000f00000000000
000000000000000000000000000000000000000000000000000feeeef000feeddcccccccccccccccccccccccccdddee00000000feeeeeeff0ffff00000000000
0000000000000000000000000000000000000000000000000000feeee000fedddcccccccccccccccccccccccccdde00f00000000feeeeeeffffff00000000000
0000000000000000000000000000000000000000000000000000feeeeffeeddddddddcccccccccccccccccccccdde00ff000000feeeeeeeffffff00000000000
0000000000000000000000000000000000000000000000000000ffeeeeeeeddddddddddddddccccccccccccccdddef0ee0f00fffeeeeeeefffff000000000000
00000000000000000000000000000000000000000000000000000feeeeeddddddeeedddddddddddccccccccccddddeeeeef00feeeeeeeeeffff0000000000000
00000000000000000000000000000000000000000000000000000feeeeeeddddee0feddddddddddddddddddddddddeeeeeffffeeeeeeeeffffff000000000000
0000000000000000000000000000000000000000000000000000ffffffeeeeeee000feeeeeedddddddddddddddddddddeeeeeeeeeeeeefff0000000000000000
0000000000000000000000000000000000000000000000000000fff000feeeeeef000ef000eedddddddddddddddddddddeeeeeeeeeeefff00000000000000000
0000000000000000000000000000000000000000000000000000fff0000feeeeee00fff00000eeeeeeedddddddddddddddeeeeeeeeeefff00000000000000000
00000000000000000000000000000000000000000000000000000f000000feeeeefff000000feeeff0feedddddddddddddddeeeeeeefff000000000000000000
00000000000000000000000000000000000000000000000000000f000000ff00fff0000000000ee000ffeeddddddddddddeeeeeeeeffff000000000000000000
00000000000000000000000000000000000000000000000000000000000ff0000f0000000000feff0000feeddddddddddeeeeeeeeffff0000000000000000000
00000000000000000000000000000000000000000000000000000000000fff00000000000000fff00000feeddfffdddeeeeeeeeefff000000000000000000000
00000000000000000000000000000000000000000000000000000000000ff0000000000000000ff0000feeeeff000eeeeeeeeeeefff000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ff000feeee000000feeeeeeeeefff0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000ffffffeee00000000feeeeeeeffff0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000fffffeeee000000000eeeeeefff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000fffeeeee000000ffffeeeefff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000fffeeee00000ffffffffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000fffeeffff0000000fffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff0000000000ffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff0000000000ffffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff00000000000fffff0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff00000000000fffff0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff00000000000ffff0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000fffff000000000000fff00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff000000000000ff000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff00000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

