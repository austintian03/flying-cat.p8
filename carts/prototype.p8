pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	game_over=false
	win=false
	k_count=0
	seeds={}
	make_player()
	make_stars()
	make_enemies()
end

function _update()
	if (not game_over) then
		--add and move stars
		add_stars()
		foreach(stars,update_star)
		
		--player update
		move_player()
		player_shoot()
		if(#p.bullets>0) then
			foreach(p.bullets,update_bullet)
		end
		
		--enemy update
		while #enemies<30 do
			add_enemy(168)
		end
		foreach(enemies,update_enemy)
		
		--seed update
		foreach(seeds,update_seed)
	else
		if (btnp(5)) _init()
	end
	
end

function _draw()
 cls(1)
 --background
 foreach(stars,draw_star)

 --seeds
 foreach(seeds,draw_seed)

 --player
 draw_player()
 if(#p.bullets>0) then
	 foreach(p.bullets,draw_bullet)
 end

 --enemies
 foreach(enemies,draw_enemy)
 
 print("🐱:"..k_count,2,2,7)
 if (game_over) then
  if (win) then
   print("you win!",48,48,11)
  elseif (not win) then
   print("uh oh, gameover!",31,52,8)
  end
  print("press ❎ to play again",20,62,7)  
 end
end
-->8
function make_player()
	dr=0.5		--drag
	p={}
	p.x=8
	p.y=60
	p.dx=0
	p.dy=0
	p.max_spd=3
	p.sprite=33
	p.bullets={}
	p.s_count=0
end

function move_player()
	--add drag to player movement
	if (p.dx>0) p.dx-=dr
	if (p.dx<0)	p.dx+=dr
	if (p.dy>0)	p.dy-=dr
	if (p.dy<0)	p.dy+=dr
	
	--add speed
	if (btn(0)) p.dx-=1
	if (btn(1)) p.dx+=1
	if (btn(2)) p.dy-=1
	if (btn(3)) p.dy+=1
	cap_speed()
	
	--adjust position
	p.x+=p.dx
	p.y+=p.dy
	stay_on_screen()
end

function stay_on_screen()
	if (p.x<0) then --left side
		p.x=0
		p.dx=0
	end
	if (p.x>111) then --right side
		p.x=111
		p.dx=0
	end
	if (p.y<0) then --top side
		p.y=0
		p.dy=0
	end
	if (p.y>=112) then --bot side
		p.y=112
		p.dy=0
	end
end

function cap_speed()
	--cap horizontal speed
	local cap_dx=mid(0,abs(p.dx),p.max_spd)
	p.dx=(p.dx/abs(p.dx)) * cap_dx
	
	--cap vertical speed
	local cap_dy=mid(0,abs(p.dy),p.max_spd)
	p.dy=(p.dy/abs(p.dy)) * cap_dy
end

function player_shoot()
	if(#p.bullets<3 and btnp(5)) then
		sfx(0)
		local dir=(p.dy==0 and {0} or {p.dy/abs(p.dy)})[1]
		local b={}
		b.x=p.x+15
		b.y=p.y+11
		b.dx=2
		b.dy=max(0.5,abs(p.dy/3))*dir
		add(p.bullets,b)
	end
end

function update_bullet(b)
	b.x+=b.dx
	b.y+=b.dy
	if(b.x>127) then
		del(p.bullets,b)
	end
end

function check_hit(b,t)
	local ycol=b.y>=t.y and b.y<=t.y+5
	local xcol=b.x>=t.x and b.x<=t.x+7
	return ycol and xcol
end

function resolve_s_pickup()
 --sfx(1)
 p.s_count+=1
 if(p.s_count%2==0) p.sprite+=2
 if(p.s_count==6) then
  game_over=true
  win=true
 end
end
function draw_bullet(b)
	pset(b.x,b.y,8)
end

function draw_player()
	spr(p.sprite,p.x,p.y,2,2)
end
-->8
function rndb(low,high)
	return flr(rnd(high-low+1)+low)
end

function rndbf(low,high)
	return rnd(high-low+1)+low
end

function make_stars()
 stars={}
 for i=1,25 do
 	local s={}
 	s.x=rndb(0,127)
 	s.y=rndb(0,127)
 	s.col=rndb(5,7)
		add(stars,s)
	end
end

function update_star(s)
	s.x-=1
	if (s.x<0) del(stars,s)
end

function add_stars()
	while (#stars<50) do
		local s={}
		s.x=rndb(128,255)
		s.y=rndb(0,127)
		s.col=rndb(5,7)
		add(stars,s)
	end
end

function draw_star(s)
	pset(s.x,s.y,s.col)
end
-->8
function make_enemies()
	enemies={}
	for i=1,10 do
		add_enemy(0)
	end
end

function add_enemy(x)
	local e={}
	e.x=rndb(x+176,x+512)	--spawn at random pos
	e.y=rndb(0,119)
	e.dx=0
	e.dy=0
	e.sprite={4,5}
	e.nf=rndb(1,2)			--next spriteframe
	e.ft=rndb(15,20)	--random initial frametime
	e.aggro=false				--aggro state
	add(enemies,e)
end

function update_enemy(e)
	collide_with_b(e)	--check for bullet
	collide_with_p(e) --check for player collision
	
	--local vars to aide movement calcs
	local dist={e.x-p.x,p.y-e.y}					--line between player and enemy
	local dir=dist[2]/abs(dist[2]) 		--direction
	
	--set directional force, checking aggro distance
	if ((e.x<p.x+75 and e.x>=p.x+36)) then
		e.aggro=true
		e.dy=max(dir*1.8,dist[2]/32)
		e.dx=max(2.25,dist[1]/24)
	elseif (not e.aggro) then
		e.dx=0.8
		e.dy=rndb(-1,1)
	end
	
	--move the player, staying within bounds
	e.x-=e.dx
	e.y+=e.dy
	bind_vertical(e)
	
	--causes for deletion
	if (e.x<-7) del(enemies,e)
end

function bind_vertical(e)
	--fuzzy method to prevent bat stacking
	if (pget(e.x,e.y-1)==3 or
	pget(e.x,e.y+8)==3) then
		e.dy=0
	end
	
	--screen boundary
	if (e.y<0) then --top side
		e.y=0
	end
	if (e.y>119) then --bot side
		e.y=119
	end
end

function collide_with_p(e)
	if (check_x_col(e) and check_y_col(e)) then
		game_over=true
	end
end

function check_x_col(e)
	--horizontal hitbox of 8 pixels
	for i=e.x,e.x+7 do
		if (i>=p.x+5 and i<=p.x+10) return true
	end
	return false
end

function check_y_col(e)
	--vertical hitbox of 5 pixels
	for i=e.y,e.y+4 do
		if (i>=p.y+2 and i<=p.y+13) return true
	end
	return false
end

function collide_with_b(e)
	--if not on screen don't bother
	if (e.x>127) then
		return false
	else
		for i=1,#p.bullets do
			if(check_hit(p.bullets[i],e)) then
				k_count+=1
				drop_seed(e.x,e.y)
				del(p.bullets,p.bullets[i])
				del(enemies,e)
				break
			end
		end 
	end
end

function draw_enemy(e)
	--frametime calc
	e.ft-=1
	if (e.ft==0) then
		if (e.nf==1) then
			e.nf=2
		elseif (e.nf==2) then
			e.nf=1
		end
		if (not e.aggro) then
			e.ft=15
		else
			e.ft=5
		end
	end
	
	--draw sprite
	spr(e.sprite[e.nf],e.x,e.y)
end
-->8
function roll(dc)
 return rndb(0,100)<=dc
end

function drop_seed(x,y)
 local dc=10+flr(k_count/5)*5
 if(roll(dc)) then
  local s={}
  s.x=x
  s.y=y
  s.sprite=7
  s.life=60
  add(seeds,s)
 end
end

function update_seed(s)
 s.life-=1
 if (s.life<=0) then
  del(seeds,s)
 else
  check_bullet(s)
  check_pickup(s)
 end
end

function check_bullet(s)
 for i=1,#p.bullets do
  if(check_hit(p.bullets[i],s)) then
   del(p.bullets,p.bullets[i])
   del(seeds,s)
   break
  end
 end
end

function check_pickup(s)
 local col=check_s_p_x(s) and check_s_p_y(s)
	if (col) then
	 resolve_s_pickup()
		del(seeds,s)
	end
end

function check_s_p_x(s)
	for i=s.x,s.x+4 do
		if (i>=p.x+4 and i<=p.x+11) return true
	end
	return false
end

function check_s_p_y(s)
	for i=s.y,s.y+5 do
		if (i>=p.y+2 and i<=p.y+14) return true
	end
	return false
end

function draw_seed(s)
	spr(s.sprite,s.x,s.y)
end
__gfx__
0000000000000000000000000055550000200d0060200d0600000000009000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000055555500002d0002202d0220050050009a300000000000000000000000000000000000000000000000000000000000000000000
00700700000000005000000005d55d500082820022828222000550003aa730000000000000000000000000000000000000000000000000000000000000000000
00077000000000050000000055dddd5502222d2022222d2200d5d5003ac730000000000000000000000000000000000000000000000000000000000000000000
0007700000000004400000000daddad02d02d0222002d00205555550337330000000000000000000000000000000000000000000000000000000000000000000
007007000000002222000000d0dddd00200000020000000055055055033300000000000000000000000000000000000000000000000000000000000000000000
0000000000000222222000000d0dd000000000000000000000500500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000002822820000000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000022888822000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000008a88a80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900080888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099008088006665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000900900888005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099094444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009900000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000003000000000000000330000000000000033000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000030800000000000003003800000000000300380000000000000000000000000000000000000000000000000000000000000
000000000000000030000000000000300000000000000030088000000000003008f8000000000000000000000000000000000000000000000000000000000000
00000000000000030000000000000003000000000000080300000000000008030080000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000004400000000000000440000000000000044000800000000000000000000000000000000000000000000000000000000000
00000000000000555500000000000055550000000000005555000000000000555500000000000000000000000000000000000000000000000000000000000000
00000000000005555550000000000555555000000000055555500000000005555550000000000000000000000000000000000000000000000000000000000000
00000000000005d55d500000000005d55d500000000005d55d500000000005d55d50000000000000000000000000000000000000000000000000000000000000
00000000000055dddd550000000055dddd550000000055dddd550000000055dddd55000000000000000000000000000000000000000000000000000000000000
0000000000000daddad0000000000daddad0000000000daddad0000000000daddad0000000000000000000000000000000000000000000000000000000000000
000000009000d0dddd0000009000d0dddd0000009000d0dddd0000009000d0dddd00000000000000000000000000000000000000000000000000000000000000
0000000009900d0dd006665009900d0dd006665009900d0dd006665009900d0dd006665000000000000000000000000000000000000000000000000000000000
00000000900900ddd0050000900900ddd0050000900900ddd0050000900900ddd005000000000000000000000000000000000000000000000000000000000000
00000000099094444444444009909444444444400990944444444440099094444444444000000000000000000000000000000000000000000000000000000000
00000000009900000000000400990000000000040099000000000004009900000000000400000000000000000000000000000000000000000000000000000000
00000000990000000000000099000000000000009900000000000000990000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000000000500001600016000160001600026000070000000066000660007600057000670007700087000b700096000000000000000000000000000000000000000000114000e400134101e4101d41022410
