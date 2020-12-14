pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- …∧░➡️⧗▤⬆️☉🅾️◆
-- q w e r t y u i o p
-- █★⬇️✽●♥웃⌂⬅️
-- a s d f g h j k l
-- ▥❎🐱ˇ▒♪😐
-- z x c v b n m


-- math

function to(◆, n, ∧)
 if n > ◆ then
  n = n - ∧
  if n < ◆ then n = ◆ end
 elseif n < ◆ then
  n = n + ∧
  if n > ◆ then n = ◆ end
 end
 
 return n
end

function to_zero(n, ∧)
 return to(0, n, ∧)
end


-- data

gpio = 0x5f80
myplr = gpio + 127

-- crap to generate addrs
addr_ptr = gpio
local function alloc(bytes)
 local result = addr_ptr
 addr_ptr = addr_ptr + bytes
 -- sanity check
 if addr_ptr - gpio >= 127 then
  die("too much gpio :(")
 end
 return result
end

local function alloc_plr()
 return {
  x  = alloc(4),
	 y  = alloc(4),
	 go = alloc(1),
	 state = alloc(1)
 }
end
-- end crap

-- use this for peek/poke
addr = {}
addr.p1 = alloc_plr()
addr.p2 = alloc_plr()

function plr_addr(n)
 return n == 0
        and addr.p1
        or addr.p2
end
function my_plr_addr()
 return @myplr == 0
        and addr.p1
        or addr.p2
end
function net_plr_addr()
 return @myplr == 0
        and addr.p2
        or addr.p1
end

guys = {
 elimon = {
  start_spr = 0,
  box = {x=5,y=3,w=5,h=12}
 },
 cenn   = {
  start_spr = 32,
  box = {x=5,y=1,w=5,h=15}
 },
 kuzu = {
  start_spr = 64,
  box = {x=6,y=3,w=4,h=13}
 },
 hector = {
  start_spr = 96,
  box = {x=4,y=2,w=4,h=15}
 }
}

sm = { -- "sm" for state machine
 idle = 0,
 walk = 1
}

term_vel_x = 1.0
term_vel_y = 4.0


-- factories..

function make_guy(who, plr)
 -- initialize shared mem
 local a = plr_addr(plr)
 poke(a.go, 1) -- dangerous maybe

 -- construct table
 return {
		who=who,
		plr=plr,
		
		go=1,
		left=false,
		
  x=20, y=20,
  dx=0, dy=0,
  
  net_x=0, net_y=0,
  
  p_state=sm.idle,
  state=sm.idle,
  timer=0,
  
  isme = function(★)
   return @myplr == ★.plr
  end
 }
end


-- logic

function simple_⬅️➡️(g)
 g.go = 1

 if btn(0) then
  g.go = g.go - 1
 end
 if btn(1) then
  g.go = g.go + 1
 end
 
 -- temporary up/down
 if btnp(2) then
  -- bad
  g.dy = g.dy - 1
 elseif btnp(3) then
  g.dy = g.dy + 1
 end
end

-- update position if it strays
-- too far from net position
function net_adjust(g)
 local x∧ = abs(g.net_x - g.x)
           / 30.0
           + 0.1
 local y∧ = abs(g.net_y - g.y)
           / 30.0
           + 0.1
 g.x = to(g.net_x, g.x, x∧)
 g.y = to(g.net_y, g.y, y∧)
end

-- main guy update function for
-- main loop
function update_guy(g)
 -- gpio read
 if not g:isme() then
	 local a = net_plr_addr()
	 g.net_x = $a.x
	 g.net_y = $a.y
	 g.go = @a.go
	 -- todo state redundant
	 g.state = @a.state
 end

 -- handle speed
 if g.go == 1 then
  g.dx = to_zero(g.dx, 0.3)
 else
  local go = g.go - 1
	 g.dx = g.dx + (go * 0.6)
	end
 
 if g.dy > term_vel_y then
  g.dy = term_vel_y
 end
 if g.dx > term_vel_x then
  g.dx = term_vel_x
 elseif g.dx < -term_vel_x then
  g.dx = -term_vel_x
 end
 
 g.x = g.x + g.dx
 g.y = g.y + g.dy
 
 if g:isme() then
  collide_guy(g)
 else
  net_adjust(g)
 end
 
 -- animation
 if g.go == 1 then
  g.state = sm.idle
 else
  g.state = sm.walk
  g.left = g.go < 1
 end
 
 -- state machine
 g.timer = g.timer + 1

 if g.state ~= g.p_state then
  -- state changed
  g.timer = 0
  g.p_state = g.state
 end
 
 -- gpio write
 if g:isme() then
	 local a = my_plr_addr()
	 poke4(a.x, g.x)
	 poke4(a.y, g.y)
	 poke(a.go, g.go)
	 poke(a.state, g.state)
 end
end


-- game state

p1 = make_guy(guys.elimon, 0)
p2 = make_guy(guys.cenn, 1)


-- drawing

function draw_guy(g)
	local s = g.who.start_spr
	
	if g.state == sm.walk then
	 s = s + 2
	 if g.timer % 15 > 7 then
	  s = s + 2
	 end
	end
	
	spr(s, g.x, g.y, 2, 2, g.left)

 --local █ = g.who.box
	--rect(
 -- g.x+█.x, g.y+█.y,
 -- g.x+█.x+█.w, g.y+█.y+█.h
	--)
end


-- game loop

p2.x = 40

function _draw()
 cls(1)
	--map(0, 0, 0, 0, 16, 8)
	
 draw_world()
 draw_guy(p1)
 draw_guy(p2)
end

function _update60()
 if p1:isme() then
	 simple_⬅️➡️(p1)
	else
	 simple_⬅️➡️(p2)
	end

 update_guy(p1)
 update_guy(p2)
end
-->8
-- physics file

function copy(x)
	local c = {}
 for k,v in pairs(x) do
  c[k] = v
 end
	return c
end

function contains(█, ◆)
 return ◆.x > █.x      and
        ◆.x < █.x+█.w and
        ◆.y > █.y      and
        ◆.y < █.y+█.h
end

function collider(g, █)
 return {
  compute = function(★, r)
   -- debug crap
   ★.msg = ""
   
		 ★.⬆️⬅️ = {
		  x=█.x,
		  y=█.y
		 }
		 ★.⬆️➡️ = {
		  x=█.x+█.w,
		  y=█.y
		 }
		 ★.⬇️⬅️ = {
		  x=█.x,
		  y=█.y+█.h
		 }
		 ★.⬇️➡️ = {
		  x=█.x+█.w,
		  y=█.y+█.h
		 }
		 ★.⬆️⬅️_in = contains(r, ★.⬆️⬅️)
		 ★.⬆️➡️_in = contains(r, ★.⬆️➡️)
		 ★.⬇️⬅️_in = contains(r, ★.⬇️⬅️)
		 ★.⬇️➡️_in = contains(r, ★.⬇️➡️)
		 ★.p_⬇️ = █.y+█.h - g.dy
		 ★.p_⬆️ = █.y - g.dy
		 ★.⬇️bump = 2
		 ★.⬆️bump = 1
  end,
  
  log = function(★, m)
   if m ~= ★.msg then
    printh(m, "debug.out")
    ★.msg = m
   end
  end,
  
  collide_⬇️ = function(★, r)
		 if
	   -- bottom corner inside r
	   (★.⬇️⬅️_in or ★.⬇️➡️_in)
	   and (
	    -- previous frame was above
	    ★.p_⬇️ <= r.y
		   or
		   -- within bump threshold
		   abs(r.y-(█.y+█.h)) <= ★.⬇️bump
	   )
	  then -- bump up
	   █.y = r.y - █.h
	   ★:log("bump up")
	   return true
	  end
	  return false
	 end,
	 
  collide_⬆️ = function(★, r)
	  if
		  -- top corner inside r
		  (★.⬆️⬅️_in or ★.⬆️➡️_in)
		  and (
		   -- previous frame was below
		   ★.p_⬆️ >= r.y+r.h
		   or
		   -- within bump threshold
		   abs((r.y+r.h)-█.y) <= ★.⬆️bump
		  )
	  then -- bump down
	   █.y = r.y + r.h
	   ★:log("bump down")
	   return true
	  end
	  return false
	 end,
	 
  collide_⬅️ = function(★, r)
	  if ★.⬆️⬅️_in or ★.⬇️⬅️_in then
	   █.x = r.x + r.w
	   ★:log("bump left")
	   return true
	  end
	  return false
	 end,
	 
	 collide_➡️ = function(★, r)
	  if ★.⬆️➡️_in or ★.⬇️➡️_in then
	   █.x = r.x - █.w
	   ★:log("bump right")
	   return true
	  end
	  return false
	 end
 }
end

function collide_guy(g)
 local █ = copy(g.who.box)
 █.x = █.x + g.x
 █.y = █.y + g.y
 local ˇ = collider(g, █)
 
 for _i,r in ipairs(collision_rects) do
  ˇ:compute(r)
  
  -- ˇ should adjust █ until
  -- there is no more overlap
  local cnt = 0
  while
	  ˇ:collide_⬇️(r) or
			ˇ:collide_⬆️(r) or
			ˇ:collide_⬅️(r) or
			ˇ:collide_➡️(r)
		do
		 -- sanity check / assertion
		 cnt = cnt + 1
		 if cnt > 100 then die("✽⬆️🐱⌂") end
		 
		 ˇ:compute(r)
		end
 end
 
 g.x = █.x - g.who.box.x
 g.y = █.y - g.who.box.y
end

-->8
-- the world

local floor = {
 x=0,  y=100,
 w=128,h=28
}

local testbox = {
 x=16.0, y=64.0,
 w=16.0, h=16.0
}

collision_rects = {
 { -- left boundary
  x=-100,y=0,
  w=100, h=1000
 },
 { -- right boundary
  x=128,y=0,
  w=100,h=1000
 },

 floor,
 testbox
}

local function draw_rect(r)
 rect(
  r.x,r.y,
  r.x+r.w,r.y+r.h
 )
end

function draw_world()
 draw_rect(floor)
 draw_rect(testbox)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000555500000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005555000000000005555550000000000055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005555550000000000451f10000000000045fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000451f1000000000000ffff000000000000f1f10000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ffff0000000000444440000000000000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000444440007700000006666000000000004444400077000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006664550077700000067676770000000066645500777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067666554777000000066666700000000676665547770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066676554470000000006766000000000666765544700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067665450400000000000660000000000676654504000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006650050000000000000550000000000066500550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000540045000000000000450000000000045400454000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000440044000000000000440000000000004000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000555550000000000055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000005d222000000000005d222000000000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dd1d1d0000000000dd1d1d00000000005d22200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000005dddd000000000005dddd00000000000dd1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000dd22000000000000dd22000000000005dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005dd00000000000005dd0000000000000dd2200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000022255500000000000025500000000000005dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002222555000000000002255000000000002225500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022022555550000000052522000000000022225500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022022550550000000052522000000000220225555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055500000000000005550000000000220555055000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055500000000000000550000000000000555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000550500000000000000550000000000055550555000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000005505500000000000055500000000000d550005dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000dd505dd000000000005dd000000000000d000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000022200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000222000000000000222220000000000002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000222220000000000022f8f8000000000022222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000022f8f8000000000022fff2000000000022f8f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000022fff2000000000022fff2000000000022fff200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000222ff20000000000222f20000000000222fff200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000262f2000000000022067220000000022222f2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006267220000000002207720000000002026672200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007277260000000002207600000000000027772600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000276702000000000007600000000000072767020000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000060600000000000002600000000000020206000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000020200000000000002220000000000000202200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000020200000000000000220000000000002200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000220220000000000000220000000000002000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000099900000000000009990000000000000999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999900000000000999990000000000099999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ff7f700000000000fff7f00000000000fff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000fffff00000000000fffff00000000000fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000fffff00000000000fffff00000000000fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ff00000000000000ff00000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009fff4000000000000fff0000000000009fff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099999440000000000099900000000000999994400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099999440000000000099900000000000999994400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ff9944f00000000000ff900000000000ff994ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000994400000000000099400000000000009944000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000990400000000000099400000000000099944000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000990400000000000099400000000000999004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990440000000000099900000000000990004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990444000000000099940000000000090004440000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33b333b3666666660000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24244244444444440000006446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55444442465444440000064444600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55544442455444440000644444460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42244444444444650006446565446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44425554444444550064445555444600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44255554446544440646544444465460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44422244445544446445544444455446000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444654444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22445544444444444444554446544444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55445242465444446544444445544654000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55542442455444445544444444444554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42244444444444654444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44425554444444554446544444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44255554446544444445544446544465000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44422244445544444444444445544455000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111555551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111115d2221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111dd1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111115dddd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111dd221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111115dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11112225551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11112222555111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11122122555551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11122122551551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111155511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111155511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111551511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111551551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111dd515dd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111115555111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111155555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111451f1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111ffff111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111444441117711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111116664551177711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111167666554777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111166676554471111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111167665451411111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111116651151111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111541145111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116666666446644666611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116111111111111111611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111116666666666666666611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8300000000000000000000000000008200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9283000000000000000000000000829200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9391818181818181818181818181939100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9291919192919393929193929192939300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
