
--find and replace Demo and DemoCanvas
require("almost/vmath")
require("almost/geom")
require("almost/tiles")
require("objects")

Demo = State:new()
DemoCanvas = Layer:new()
Demo:addlayer(DemoCanvas)

function Demo:load()
    init()
--    KEYS = {JUMP="z",DASH="x",LEFT="left",RIGHT="right",UP="up",DOWN="down",ATTACK="c"}
    KEYS = {JUMP=" ",DASH="x",LEFT="a",RIGHT="d",UP="w",DOWN="s",ATTACK="c"}
--    DIRS = {UP=P(-sqrt2/2,sqrt2/2), LEFT=P(-sqrt2/2,-sqrt2/2), RIGHT=P(sqrt2/2,sqrt2/2), DOWN=P(sqrt2/2,-sqrt2/2)}
    DIRS = {UP=P(0,-1), LEFT=P(-1,0), RIGHT=P(1,0), DOWN=P(0,1)}

    --check if the player knows his controls
    --Game:update(1/30) --force an update before any draw function is possible.
    MAXDEPTH = 4
    WALL=1
    MIRROR = 2
    
    walls = {}
    player = newPlayer(P(unit/2,unit/2),P(0,0))
    getTile(player.p).iswall = false
--    MAXSPEED = 180 --speed after which unable to accelerate by running. could be ignored and use the breakeven point of friction instead
--    ACCEL = 1100
    MAXSPEED = 330 --speed after which unable to accelerate by running. could be ignored and use the breakeven point of friction instead
    ACCEL = 1200
    FRICTION = 500

    objects = {}
    
    local s = S(P(240,100),P(300,400))
    --table.insert(walls,{s=s,t=MIRROR})
    s = S(P(500,120),P(440,460))
    --table.insert(walls,{s=s,t=WALL})
    
    
    notvisible = {140,140,140}
    maxdepthcolor = {64,64,128}
    wallcolor = {0,128,0}
    wallcolor = {0,0,0}
    mirrorcolor= {0,0,128}
    playercolor = {180,180,180}
    --CANNOT HAVE ALPHA IN A MIRROR
    --DUE TO BUG WITH LOVE CANVASES AND ALPHA BLENDING
end

function DemoCanvas:draw()
    love.graphics.push()
    love.graphics.translate(-camera[1],-camera[2])
    drawmap(
        player.p, --mouse
        screen,
        0,
        nil,
        camera[1],
        camera[2])
    
    local g = gridPoint(mouse)
    if placing then
        love.graphics.setColor(mirrorcolor)
        love.graphics.line(placing[1],placing[2],g[1],g[2])
    end
    if placing2 then
        love.graphics.setColor(wallcolor)
        love.graphics.line(placing2[1],placing2[2],g[1],g[2])
    end
    love.graphics.pop()
    
    drawMiniMap(P(100,100))
end

function drawmap(viewpoint,area,depth,currentmirror,offsetx,offsety)
    p1,p2 = bounds(area)
    updatefog()
    drawTiles(p1,p2)
    

--    love.graphics.setColor(255,64,64)
--    fillTiles(tileLine(player.p,mouse),true)
--    love.graphics.line(player.p[1],player.p[2],mouse[1],mouse[2])
    
--    love.graphics.setColor(playercolor)
--    love.graphics.circle("fill",player.p[1],player.p[2],player.r)
    player:draw()
    
    love.graphics.setLineWidth(2)
    --assuming no walls overlap
    --a wall is strictly closer if any point on it is closer
    --there may be a complicated case where a spiral of walls are all behind each other but this is unlikely in practice
    for i,w in ipairs(walls) do
        w.d = nil
    end
    local furtherwall = function(w1,w2)
        if not w1.d then
            w1.d = pointdistance(viewpoint,w1.s)
        end
        if not w2.d then
            w2.d = pointdistance(viewpoint,w2.s)
        end
        return w1.d > w2.d
        --draw further away walls first by painters algorithm
    end
    local drawable = {}
    for i,w in ipairs(walls) do
        table.insert(drawable,w)
    end
    table.sort(drawable,furtherwall) --can't sort walls because this function is recursive and it would be resorted mid draw
    
    --if depth > 0 then
        for i,o in ipairs(objects) do
            if o.p[1] + o.r > p1[1] and o.p[1] - o.r < p2[1]
            and o.p[2] + o.r > p1[2] and o.p[2] - o.r < p2[2] then 
                love.graphics.setColor(190,0,0)
                love.graphics.circle("fill",o.p[1],o.p[2],o.r)
                love.graphics.setColor(120,0,0)
                love.graphics.circle("line",o.p[1],o.p[2],o.r)
            end
        end
    --end
    
    for i,wall in ipairs(drawable) do
        if wall.t == WALL or depth > MAXDEPTH then
            local w = trimmedLine(wall.s,area)
            if w then
                if wall.t == WALL then
                    love.graphics.setColor(notvisible)
                else
                    love.graphics.setColor(maxdepthcolor)
                end
                local wallarea = areaBehind(viewpoint,w,area)
                if wallarea then
                    love.graphics.polygon("fill",flatten(wallarea.p))
                    local w1,w2 = w[1],w[2]
                    love.graphics.setColor(wallcolor)
                    love.graphics.line(w1[1],w1[2],w2[1],w2[2])
                end
            end
        elseif wall.t == MIRROR then
            local mirror = wall
            if depth <= MAXDEPTH then 
        
    --        print(depth)
                local m = trimmedLine(mirror.s,area)
                local currentedge = nil
                if currentmirror then
                    currentedge = currentmirror.s
                end
                if m and (mirror.s ~= currentedge) then
                    local m1,m2 = m[1],m[2]
                    local d = Vsub(m2,m1)
                    local a = Vangleof(d)

                    local area1 = areaBehind(viewpoint,m,area)
                    if area1 then
                        local refl = Mreflect(m) --this is used to transform shapes
                        local area2 = shape(map(function(a) return Mmult(refl,a) end, area1.p))

    --                    mask1 = function() love.graphics.polygon("fill",flatten(area1.p)) end
                        mask2 = function() love.graphics.polygon("fill",flatten(area2.p)) end

                        local b1,b2 = bounds(area2)
                        local wh = Vsub(b2,b1) --find width and height of area
                        if not offsetx then
    --                        b1[1] = b1[1] - offsetx
    --                        b1[2] = b1[2] - offsety
                            offsetx = 0
                            offsety = 0
                        end
                        local w,h = wh[1],wh[2]
                        --DEBUG
                        --print(w,h)
                        if math.abs(w) > 1 and math.abs(h) > 1 and w < 2000 and h < 2000 then
                            
                            local c = love.graphics.newCanvas(w,h)
                            local oldcanvas = love.graphics.getCanvas()
                            
                            --draw to new canvas
                            love.graphics.setCanvas(c)
                            love.graphics.push()
                            love.graphics.translate(offsetx-b1[1],offsety-b1[2]) --shift as if canvas was at b1[1], b1[2]
                            pushMask(mask2)
                            
                            --DEBUG
                            --mask2()
                            love.graphics.setColor(255,255,255)
                            drawmap(Mmult(refl,viewpoint),area2,depth+1,mirror,b1[1],b1[2])
                            
                            popMask()
                            
                            love.graphics.pop()
                            --DEBUG
                            --love.graphics.setColor(0,128,0)
                            --love.graphics.rectangle("line",1,1,w-2,h-2)

                            love.graphics.setCanvas(oldcanvas)
                            
                            --describe reflection as shear translate and scale based on contents of reflection matrix
                            love.graphics.push()
                            love.graphics.translate(m1[1],m1[2])
                            love.graphics.rotate(a)
                            love.graphics.scale(1,-1)
                            love.graphics.rotate(-a)
                            love.graphics.translate(-m1[1],-m1[2])
                            --[[
                            love.graphics.translate(refl[3][1],refl[3][2])
                            local shx = 0
                            local shy = 0
                            local scx = 1
                            local scy = 1 --scale is only used to compensate for shear?
                            if refl[1][1] ~= 0 then
                                shy = refl[1][2]/refl[1][1]
                                scx = refl[1][1]
                            else
                                shy = refl[1][2]
                                scx = 0
                            end
                            if refl[2][2] ~= 0 then
                                shx = refl[2][1]/refl[2][2]
                                scy = refl[2][2]
                            else
                                shx = refl[2][1]
                                scy = 0
                            end
                            love.graphics.shear(shx,shy)
                            love.graphics.scale(scx,scy)
                            ]]
    --                        love.graphics.translate(b1[1],b1[2])
                            
--                            local col = 90
                            local col = 255 --how much or if I should tint the color of the reflection. 255 
                            love.graphics.setColor(col,col,col,255)
--                            love.graphics.setColorMode("combine")
                            --reflected draw the canvas
                            love.graphics.draw(c,b1[1],b1[2])
                            
                            love.graphics.pop()
                            
                            --outline the mirror
                            love.graphics.setColor(mirrorcolor)
                            love.graphics.line(m1[1],m1[2],m2[1],m2[2])
                        end
                    end
                end
            end
        end
    end
end

function Demo:update(dt)
	dt = math.min(dt,1/30)
    mx,my = love.mouse.getPosition()
    
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            player.v = Vadd(player.v, Vmult(ACCEL*dt,dir))
        --elseif not Vsamedir(player.v,dir) then
        --    player.v = Vadd(player.v, Vmult(FRICTION*dt,dir))
        end
    end
    if Vdd(player.v) > MAXSPEED*MAXSPEED then
        player.v = Vscale(player.v,MAXSPEED)
    end
    
    --if player.collided and player.onground then --maybe stuck on a wall
    --    player.vz = JUMP
    --end
    player:move(dt)
    --[[
    local d = Vmagn(player.v)
    player.v = Vscale(player.v,math.max(0,d-FRICTION*dt))
    player.p = Vadd(player.p,Vmult(dt,player.v))
    ]]
    
    camera = Vsub(player.p,P(width/2,height/2))
    screen = shape(
        {camera,Vadd(camera,P(width,0)),Vadd(camera,P(width,height)),Vadd(camera,P(0,height))}
    )

    mouse = Vadd(P(mx,my),camera)
    if love.mouse.isDown("l") then  
        t = getTile(mouse)
        t.iswall = true
    end
    if love.mouse.isDown("r") then  
        t = getTile(mouse)
        --t.iswall = false
    end
end


function Demo:mousepress(x,y, button)
    --[[
    if button == "l" then
        placing = gridPoint(mouse)
    else]]if button == "r" then
        placing2 = gridPoint(mouse)
    end
end

function Demo:mouserelease(x,y, button)
    local g = gridPoint(mouse)
    if button == "l" and placing then
        if not samepoint(placing,g) then
            table.insert(walls,{s=S(placing,g),t=WALL})
        end
        placing = nil
    elseif button == "r" and placing2 then
        if not samepoint(placing2,g) then
            table.insert(walls,{s=S(placing2,g),t=MIRROR})
        end
        placing2 = nil
    end
end

function Demo:keypress(key)
    if key == KEYS.JUMP then
        table.insert(objects,{p=mouse,r=math.random(5,15)})
    end
end

function Demo:keyrelease(key)
    
end

--a list of masks for recursive functions that set stencil and want to return to a previous stencil
masks = {
    nil
}

function pushMask(f) --ends up creating union instead of intersection
    table.insert(masks,f)
    love.graphics.setStencil(f)
end

function popMask()
    table.remove(masks)
    love.graphics.setStencil(masks[#masks])
end
