unit = 30
mapw = math.floor(width/unit)
maph = math.floor(height/unit)
tiles = {}
sqrt2 = math.sqrt(2)

--visibility states
VISIBLE = 0
FOG = 1
NONE = 2

function init()
    tiles = {}
    --stuff for future map generation
    exits = {}
    makeRoom(P(-5,-4),P(5,4))
--    exits = newpaths
--    table.insert(exits,newpaths)
    --[[
        w = math.min(w,mapw-1-x1)
        h = math.min(h,maph-1-y1)
        for x=x1,x1+w do
            for y = y1,y1+h do
                print(x,y)
                for c = 1,3 do
                    tiles[x][y][c] = tiles[x][y][c] * 0.25
                end
            end
        end
    end
    ]]
end

function gridtile(p)
    return P(math.floor(p[1]/unit),math.floor(p[2]/unit))
end
function gridPoint(p)
    return Vmult(unit,gridtile(Vadd(p,P(unit/2,unit/2))))
end
function getTile(p)
    --gridpoint
    local g = gridtile(p)
    return tileXY(g[1],g[2])
end

function tileXY(x,y)
    if not tiles[x] or not tiles[x][y] then
        return newTile(x,y)
    else
        return tiles[x][y]
    end
end

rooms = {}
rooms2 = {}
function makeRoom(g1,g2,entrance)
    local p1,p2 = Vmult(unit,g1),Vmult(unit,g2)
    table.insert(rooms,{p1,p2})
    print(g1[1],g1[2],g2[1],g2[2])
-- do not allow one wide areas
--and do something about rooms with no possible exits

--    local g1,g2 = gridtile(p1),gridtile(p2)
    local w = g2[1] - g1[1]
    local h = g2[2] - g1[2]
    local ts = {}
    for x = g1[1],g2[1] do
        local t = tileXY(x,g1[2])
        t.iswall = true
        local t2 = tileXY(x,g2[2])
        t2.iswall = true
        if x ~= g1[1] and x~= g2[1] then
            table.insert(ts,t)
            table.insert(ts,t2)
        end
    end
    for y = g1[2],g2[2] do
        local t = tileXY(g1[1],y)
        t.iswall = true
        local t2 = tileXY(g2[1],y)
        t2.iswall = true
        if y ~= g1[2] and y~= g2[2] then
            table.insert(ts,t)
            table.insert(ts,t2)
        end
    end
    if entrance then
        local x,y = entrance[1],entrance[2]
        --exits[x][y] = nil
        local t = tileXY(x,y)
    end
    
    --local exits = {}
    --local result = {}
    local n = math.random(2,4)
    for i=1,n do
        local e,x,y,p,dx,dy--,x2,y2
        local tries = 100
        local try = 0
        repeat
            try = try + 1
            e = math.random(1,#ts)
            p = Vmult(1/unit,ts[e].p)
            x = p[1]
            y = p[2]
            dx,dy = 0,0
            if x == g1[1] then dx = - 1
            elseif x == g2[1] then dx = 1 end
--            else x2 = x end
            if y == g1[2] then dy = - 1
            elseif y == g2[2] then dy = 1 end
--            else y2 = 2 end
            x,y = x+dx,y+dy
        until (not tiles[x]) or (not tiles[x][y]) or (try > tries) or tiles[x][y].visible == NONE
        if try <= tries then
            ts[e].iswall = false
            if not exits[x] then
                exits[x] = {}
            end
            exits[x][y] = P(dx,dy)
        end
        --exits[e] = ts[e]        
    end
--    for i,e in pairs(exits) do
--        e.iswall = false
--    end
    --[[
    for x = g1[1]+1,g2[1]-1 do
        for y = g1[2]+1,g2[2]-1 do
            local t = tileXY(x,y)
            t.iswall = false
        end
    end
    ]]
    --[[
    if w > 10 and h > 10  then
        for i = 1,4 do
            local x1,x2 = math.random(p1[1],p2[1]),math.random(p1[1],p2[1])
            local y1,y2 = math.random(p1[2],p2[2]),math.random(p1[2],p2[2])
            makeRoom(
                P(math.min(x1,x2),math.min(y1,y2)),
                P(math.max(x1,x2),math.max(y1,y2)))
        end
    end
    ]]
end

function newTile(x,y)
    if not tiles[x] then
        tiles[x] = {}
    end
    tiles[x][y] = {
        lastview=0, --frame?
        visible=NONE,
        p={x*unit,y*unit},
        iswall=false,
        color = {
            math.random(192,255),
            math.random(192,255),
            math.random(192,255)
        }
    }
    if exits[x] and exits[x][y] then
        dx,dy = exits[x][y][1],exits[x][y][2] --it is a point indicating the direction of the exit
        --and the exit should be two or three tiles wide I think
        local w1,h1,w2,h2
        --find available space
        --if too little space, fill in the exit or make this a dead end room the size of the available spaces
        if dx ~= 0 then
            h1 = math.random(2,4)
            h2 = math.random(2,4)
            if dx == 1 then
                w1 = 0
                w2 = math.random(4,8)
            elseif dx == -1 then
                w1 = math.random(4,8)
                w2 = 0
            end
        elseif dy ~= 0 then
            w1 = math.random(2,4)
            w2 = math.random(2,4)
            if dy == -1 then
                h1 = math.random(4,8)
                h2 = 0
            elseif dy == 1 then
                h1 = 0
                h2 = math.random(4,8)
            end
        end


        --iterate over each (line of tiles inside of the) wall and if it already exists shrink the room by 1 from that side
        local hitwall
        repeat
            hitwall = false
            --top wall
            if h1 > 0 then
                local ry = y-h1
                for rx = x-w1,x+w2 do
                    if tiles[rx] and tiles[rx][ry] and tiles[rx][ry].iswall then
                        hitwall = true
                        h1 = h1 - 1
                        break
                    end
                end
            end
            --bottom wall
            if h2 > 0 then
                local ry = y+h2
                for rx = x-w1,x+w2 do
                    if tiles[rx] and tiles[rx][ry] and tiles[rx][ry].iswall then
                        hitwall = true
                        h2 = h2 - 1
                        break
                    end
                end
            end
            --left wall
            if w1 > 0 then
                local rx = x-w1
                for ry = y-h1,y+h2 do
                    if tiles[rx] and tiles[rx][ry] and tiles[rx][ry].iswall then
                        hitwall = true
                        w1 = w1 - 1
                        break
                    end
                end
            end
            --right wall
            if w2 > 0 then
                local rx = x+w2
                for ry = y-h1,y+h2 do
                    if tiles[rx] and tiles[rx][ry] and tiles[rx][ry].iswall then
                        hitwall = true
                        w2 = w2 - 1
                        break
                    end
                end
            end
            if not hitwall then
                --this seems like a good area, check the "inside" of it
                for rx = x-w1+1,x+w2-1 do
                    for ry = y-h1+1,y+h2-1 do
                        if tiles[rx] and tiles[rx][ry] and tiles[rx][ry].iswall then
                            if rx < x then
                                w1 = w1 - 1
                            elseif rx > x then
                                w2 = w2 - 1
                            end
                            if ry < y then
                                h1 = h1 - 1
                            elseif ry > y then
                                h2 = h2 - 1
                            end
                            hitwall = true
                            break
                        end
                        if hitwall then break end
                    end
                end
            end
        until (not hitwall)

        local minw,minh = 3,3
        if (w1+w2) >= minw and (h1+h2) >= minh and ((w1 > 0 and w2 > 0) or (h1 > 0 and h2 > 0)) then
            --room bust be at least 2 x 2 and must have thhe entrance not on a corner
            makeRoom(P(x-w1,y-h1),P(x+w2,y+h2),P(x,y))
            tiles[x][y].iswall = false
        else
            local g1,g2 = P(x-w1,y-h1),P(x+w2,y+h2)
            local p1,p2 = Vmult(unit,g1),Vmult(unit,g2)
            table.insert(rooms2,{p1,p2})
            --fill in the previous exit
            tiles[x-dx][y-dy].iswall = true
            tiles[x][y].iswall = true
        end
    end
    return tiles[x][y]
end

function getWalls(p,r)
    local new = {}
    for i,t in ipairs(getTiles(p,r)) do
        if t.iswall then
            table.insert(new,t)
        end
    end
    return new
end

function getTiles(p,r)
    local new = {}
    local p1,p2 = gridtile(Vsub(p,P(r,r))),gridtile(Vadd(p,P(r,r)))
    for x = p1[1],p2[1] do
        for y = p1[2],p2[2] do
            -- add "if in circle" for tile centred at x,y with width TILESIZE
            if Vdist(Vmult(unit,P(x+0.5,y+0.5)),p) < r+unit*sqrt2/2 then
                table.insert(new, tileXY(x,y))
            end
        end
    end
    return new
end

function drawTiles(minp,maxp)
    local tmp = false
    local f = frame
    for x = minp[1],maxp[1]+unit,unit do
        for y = minp[2],maxp[2]+unit,unit do
            local t = getTile(P(x,y))
            local notviewed = false
            if t.lastview < frame then
                notviewed = true
                local d = Vdist(Vadd(t.p,P(unit/2,unit/2)),player.p)
                if d < 300 + unit*sqrt2/2 then
                    viewTiles(tileLine(player.p,t.p))
                    if not tmp then
                        if t.lastview < frame then
                        --    print(t.lastview , frame)
                        end
                        tmp = true
                    end
                elseif t.visible == VISIBLE then
                    t.visible = FOG
                    t.lastview = frame
                end
            end
            local color = t.color
            if not t.iswall then
--                color = coloradd({128,0,0},colormult(0.5,color))
--                color = t.color
                if ((t.p[1]+t.p[2])/unit)%2 == 1 then
--                    color = {215,248,234}
                    color = {190,219,198}
                else
--                    color = {192,205,233}
                    color = {140,173,163}
                end
            else
--                color = {115,115,120}
                color = {57,130,57}
            end
            if t.visible == FOG then
                color = colormult(0.5,color)
            elseif t.visible == NONE then
--                color = colormult(0.1,color)
                color = {0,0,0} --mult 0.1
            end
            --debug to see which tiles are not covered by the circle of raycasts
            --if notviewed then
            --    color = {color[1], color[2] * 0.5,color[3] * 0.5}
            --end
            if t.iswall then
                --love.graphics.setColor(255-t.color[1],255-t.color[2],255-t.color[3])
                love.graphics.setColor(color)
                love.graphics.rectangle("fill",t.p[1],t.p[2],unit,unit)
                love.graphics.setColor(0,0,0)
                love.graphics.rectangle("line",t.p[1],t.p[2],unit,unit)
            else
                love.graphics.setColor(color)
                love.graphics.rectangle("fill",t.p[1],t.p[2],unit,unit)
            end
        end
    end
    if DEBUG then
        for i,r in ipairs(rooms) do
            love.graphics.setColor(0,0,255)
            local p1,p2 = r[1],r[2]
            local w,h = p2[1]-p1[1],p2[2]-p1[2]
            love.graphics.circle("fill",p1[1]+unit/2,p1[2]+unit/2,unit/4)
            love.graphics.rectangle("line",p1[1]+unit/2,p1[2]+unit/2,w,h)
        end
        for i,r in ipairs(rooms2) do
            love.graphics.setColor(0,128,128)
            local p1,p2 = r[1],r[2]
            local w,h = p2[1]-p1[1],p2[2]-p1[2]
            love.graphics.circle("fill",p1[1]+unit/2,p1[2]+unit/2,unit/4)
            love.graphics.rectangle("line",p1[1]+unit/2,p1[2]+unit/2,w,h)
        end
        love.graphics.setColor(0,255,0)
        love.graphics.setLineWidth(3)
        for x,row in pairs(exits) do
            for y,diff in pairs(row) do
                local dx,dy = diff[1],diff[2]
                local p2 = Vmult(unit,P(x+0.5,y+0.5))
                local p1 = Vsub(p2,Vmult(unit,P(dx,dy)))
                love.graphics.line(p1[1],p1[2],p2[1],p2[2])
            end
        end
        love.graphics.setLineWidth(1)
    end
end

function colormult(s,col)
    new = {}
    for i=1,3 do
        new[i] = s * col[i] 
    end
    new[4] = col[4]
    return new
end

function coloradd(col1,col2)
    new = {}
    for i=1,3 do
        new[i] = col1[i] + col2[i]
    end
--    new[4] = col[4]
    return new
end

--Bresenham's algorithm
--consider making a second function that creates a more inclusive set of tiles  
function tileLine(p1,p2)
    local ts = {}
    local g1 = gridtile(p1) --rounded
    --Vmult(1/unit,p1)
    local g2 = gridtile(p2)
    --Vmult(1/unit,p2)
    local dx,dy = math.abs(g2[1] - g1[1]),math.abs(g2[2] -g1[2])
    local sx,sy
    if g2[1] > g1[1] then sx = 1 else sx = -1 end
    if g2[2] > g1[2] then sy = 1 else sy = -1 end
    local err = dx-dy
    
    local x,y = g1[1],g1[2]
    local x2,y2 = g2[1],g2[2]

    while x ~= x2 or y ~= y2 do
        table.insert(ts,tileXY(x,y))
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end
    table.insert(ts,tileXY(x2,y2))
    --[[
    local slope = dy / dx
    local x1 = math.floor(g1[1]) -- +0.5)
    local y = g1[2] + (x1-g1[1]) * slope 
    for x = x1,g2[1] do
        y = y + slope
        local t = tileXY(x,math.floor(y)) -- +0.5
        table.insert(ts,t)
    end
    ]]
    return ts
end

--http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
function tileCircle(p,r)
    local ts = {}
    
    local r = math.floor(0.5 + r/unit)
    local g = gridtile(p)
    local f = 1 - r
    local ddFx = 1
    local ddFy = -2 * r
    local x,y = 0,r
    
    table.insert(ts,tileXY(g[1],g[2]+r))
    table.insert(ts,tileXY(g[1],g[2]-r))
    table.insert(ts,tileXY(g[1]+r,g[2]))
    table.insert(ts,tileXY(g[1]-r,g[2]))
    while x < y do
        -- ddFx == 2 * x + 1;
        -- ddFy == -2 * y;
        -- f == x*x + y*y - radius*radius + 2*x - y + 1;
        if f >= 0 then
          y = y - 1;
          ddFy = ddFy + 2;
          f = f + ddFy;
        end
        x = x + 1;
        ddFx = ddFx + 2;
        f = f + ddFx;    
        table.insert(ts,tileXY(g[1] + x,g[2] + y))
        table.insert(ts,tileXY(g[1] - x,g[2] + y))
        table.insert(ts,tileXY(g[1] + x,g[2] - y))
        table.insert(ts,tileXY(g[1] - x,g[2] - y))
        table.insert(ts,tileXY(g[1] + y,g[2] + x))
        table.insert(ts,tileXY(g[1] - y,g[2] + x))
        table.insert(ts,tileXY(g[1] + y,g[2] - x))
        table.insert(ts,tileXY(g[1] - y,g[2] - x))
    end
    return ts
end

function fillTiles(ts)
    for i,t in ipairs(ts) do
        love.graphics.rectangle("fill",t.p[1],t.p[2],unit,unit)
    end
end

function viewTiles(ts) --in order
    local count = 0
    local maxcount = 1 -- 2
    local visible = true
    for i,t in ipairs(ts) do
        if t.lastview < frame then
            if t.visible == VISIBLE then
                t.visible = FOG
            end
            t.lastview = frame
--            local pp = Vadd(t.p,P(unit/2,unit/2))
--            love.graphics.setColor(0,0,0)
--            love.graphics.circle("line",pp[1],pp[2],unit/2)

        end
        if count < maxcount then -- if count < maxcount
            t.visible = VISIBLE
        end
        if visible and t.iswall then
            visible = false
        end
        if count < maxcount and not visible then
            count = count + 1
        end
    end
end

function updatefog()
    --[[
        local points = 128
    local x,y = r,0
    local a = 2 * math.pi / points
    local cosA,sinA = math.cos(a),math.sin(a)
    --rotation matrix
    -- cosA  -sinA
    -- sinA   cosA
    for i = 1,points do
        x,y = (x * cosA - y * sinA),(y * cosA + x * sinA)
        local p = Vadd(player.p,P(x,y))
        love.graphics.setColor(128,64,64,255)
    end
    ]]
    local r = 300
    local circle = tileCircle(player.p,r)
    for i,t in ipairs(circle) do
        viewTiles(tileLine(player.p,t.p))
        love.graphics.line(t.p[1],t.p[2],player.p[1],player.p[2])
    end
--    fillTiles(tileLine(player.p,mouse))
--    love.graphics.setColor(255,128,128,192)
--    love.graphics.setColor(128,128,255)
--    fillTiles(circle)
end

function drawMiniMap(p)
    local size = 3
    local cx,cy = p[1],p[2]
    for x,row in pairs(tiles) do
        for y,t in pairs(row) do
            --these xy xoordinates are integer so draw 1 point per tile
            --if t.visible == VISIBLE then
            if t.iswall then
                love.graphics.setColor(128,128,128)
            else
                love.graphics.setColor(128,0,0)
            end
        --[[
            elseif t.visible == FOG then
                if t.iswall then
                    love.graphics.setColor(64,64,64)
                else
                    love.graphics.setColor(64,0,0)
                end
            end
            ]]
            if t.visible ~= NONE then
                if size == 1 then
                    love.graphics.point(cx + x,cy+y)
                else
                    love.graphics.rectangle("fill",cx+x*size,cy+y*size,size,size)
                end
            end
        end
    end
end