
OBJECT = 1
UNIT = 2
PLAYER = 3

--skin color {180,161,147}
Object = {t=OBJECT,p=P(0,0),v=P(0,0),r=8,col={115,70,60}, line={80,80,80}}
 
function Object:new(o)
    o = o or {}
    o.p = o.p or P(0,0)
    o.v = o.v or P(0,0)
    setmetatable(o,self)
    self.__index = self
    return o
end

Unit = Object:new{r=7,t=UNIT,hp=5,maxhp=5,vision=110}
Player = Unit:new{r=8,col={56,56,64},xp=0,maxxp=60,level=1,hp=20,maxhp=20}
--Hero = Unit:new{facing = P(1,0),col={71,123,201}}


function Unit:draw(a)
    local linecol = colormult(0.5,self.col)
    if a then
        self.col[4] = a
        linecol[4] = a
    else
        self.col[4] = 255
        linecol[4] = 255
    end
    love.graphics.setColor(self.col)
    love.graphics.circle("fill",self.p[1],self.p[2],self.r)

    love.graphics.setColor(linecol)
    love.graphics.circle("line",self.p[1],self.p[2],self.r)    
end

function newPlayer(p,z)
    return Player:new{p=p,z=z}
end

function Unit:ondeath()
    player:getxp(10)
    for i=1,8 do --15
--        blood(self.p,self.z)
    end
    self.dead = true
--    killed = killed + 1
end

function Player:ondeath()
    --GAME OVER (do nothing)
    --remove all nearby enemies
    --white explosion the size of the screen
    --and then respawn in 3s
    player.xp = 0
--        player.level = player.level - 1
    player.hp = player.maxhp
    --game.restart or .load
    --or GG popup
end

function Player:getxp(x)
    self.xp = self.xp + x
    while self.xp >= self.maxxp do
        self.xp = self.xp - self.maxxp
        self.level = self.level + 1
        self.maxxp = self.maxxp * 1.2
--        weapon.r = weapon.r + 4
--        weapon.range = weapon.range + 11
    end
end

function Unit:damage(x)
    self.hp = self.hp - x
--    blood(self.p,self.z)
    if self.hp <= 0 and not self.dead then
        self:ondeath()
    end
end

function Other(p,z)
    return Unit:new({p=p,z=z})
end
--[[
function newHero(p,z)
    return Hero:new({p=p,z=z})
end
]]

function Unit:move(dt)
    self.collided = false
    --friction
    local d = Vmagn(self.v)
    self.v = Vscale(self.v,math.max(0,d-FRICTION*dt))
    local p2 = Vadd(self.p,Vmult(dt,self.v))
    --need a list of wall tiles that are hit
    local walls = getWalls(p2,self.r)
    if #walls > 0 then
        --collision
        local vx = P(self.v[1],0)
        local vy = P(0,self.v[2])
        local pvx = Vadd(self.p,Vmult(dt,vx))
        --ideally use some math to handle walls of arbitrary normal and thus improve the collision response
        local hits = getWalls(pvx,self.r)
        if #hits > 0 then
            self.v = Vsub(self.v,vx)
            self.collided = true
        end
        local pvy = Vadd(self.p,Vmult(dt,vy))
        hits = getWalls(pvy,self.r)
        if #hits > 0 then
            self.v = Vsub(self.v,vy)
            self.collided = true
        end
        p2 = Vadd(self.p,Vmult(dt,self.v))
        hits = getWalls(p2,self.r)
        if #hits > 0 then
            self.v = P(0,0)
            self.collided = true
        end
    --else
    end    
    self.p = p2
end


--[[
sorted = false

function drawbefore(a,b)
    --0 is =, -1 is <, 1 is >
    --aka <=>
    local ax1,ax2
    local ay1,ay2
    local bx1,bx2
    local by1,by2
    local result = 0
    local a1,a2 = bounds(a)
    local b1,b2 = bounds(b)
            
    --these are either in front of each other, or on top of each other
    local dx,dy = 0,0
    if a1[1] >= b2[1] then
        dx = 1
    elseif a2[1] <= b1[1] then
        dx = -1
    end
    if a1[2] >= b2[2] then
        dy = -1
    elseif a2[2] <= b1[2] then
        dy = 1
    end
    if not sorted then
        --print ("a min max b min max result")
        --print ("x", ax1,ax2,bx1,bx2,dx)
        --print ("y", ay1,ay2,by1,by2,dy)
    end
    if dx == dy and dx ~= 0 then
        --a is either above or below on both axis
        result = dx
    elseif dx ~= 0 and dy ~= 0 then
        --above on one axis, below on the other
        result = 0--dx
    elseif (dx == 0 or dy == 0) and dx ~= dy then
        --only above or below on one axis
        result = dx+dy
    --else dx and dy both 0
    elseif a.z < b.z then
        result  = -1
    elseif a.z > b.z then
        result  = 1
    else
        --overlapping and same z
        result = 0
    end
    if not sorted then
        --print(dx,dy,result)
    end
    
    return result
    --return result == -1
end

function tableswap(t,i,j)
    local x = t[i]
    t[i] = t[j]
    t[j] = x
end

function verticalsort(objects)
    --built in sort assumes a definite a < b, b = c, c < d implies a < d, but it is complicated.
    --I want a "doesn't matter" but not a "is the same"
    --so I will write my own sort
    --table.sort(objects,drawbefore)

    --only need to check all but last i items after i iterations?
    local done = false
    local firstnode = 1
    local count = 0
    while not done do
        count = count + 1
        local a = objects[firstnode]
        local changed = false
        for i = firstnode + 1,#objects do
            if not changed then
                local b = objects[i]
                local diff = drawbefore(a,b)
                --print(diff)
                if diff == 1 then
                    changed = true
                    tableswap(objects,firstnode,i)
                end
            end
        end
        if (not changed) or (count > #objects-firstnode) then --infinite loop fix - just skip it
            firstnode = firstnode + 1
            count = 0
        end
        
        --[
        local changed = false
        for i = 1,#objects-1 do
            local a,b = objects[i],objects[i+1]
            local diff = drawbefore(a,b)
            if diff == -1 then
                --oK!
            elseif diff == 1 then
                --swap
                changed = true
                tableswap(objects,i,i+1)
            else
                -- order doesn't matter, dunno what to do with these
                --afraid of infinite loop If I use this
            end
        end
        done = not changed
        ]
        done = firstnode == #objects
    end
    --local result = mergesort(makepairs(objects))
    sorted = true
    --return result
end

function center(o)
    if o.t == PRISM then
        return Vadd(Vadd(o.p,Vmult(0.5,o.v1)) , Vmult(0.5,o.v2))  ,o.z+o.h/2
    elseif o.t == UNIT then
        return o.p,o.z+o.h/2
    end
end

--return p1,p2 with p1 being minx miny and p2 maxx maxy
function bounds(o)
    local x1,x2,y1,y2
    if o.t == PRISM then
        x1,x2 = math.min(o.p[1],o.p[1]+o.v1[1],o.p[1]+o.v2[1]),math.max(o.p[1],o.p[1]+o.v1[1],o.p[1]+o.v2[1])
        y1,y2 = math.min(o.p[2],o.p[2]+o.v1[2],o.p[2]+o.v2[2]),math.max(o.p[2],o.p[2]+o.v1[2],o.p[2]+o.v2[2])
    elseif o.t == UNIT or o.t == TREE or o.t == PARTICLE then
        x1,x2 = o.p[1] - o.r, o.p[1] + o.r
        y1,y2 = o.p[2] - o.r, o.p[2] + o.r
    elseif o.t == SHADOWTILE then
        x1,x2 = o.tile.p[1], o.tile.p[1] -- -TILESIZE/2 ?
        y1,y2 = o.tile.p[2], o.tile.p[2]
    end
    return P(x1,y1),P(x2,y2)
end
]]