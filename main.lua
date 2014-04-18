function love.load()
    DEBUG = false
    width = love.graphics.getWidth( )
    height = love.graphics.getHeight()
    
--    require("almost/files")
    require("almost/ui")
    require("almost/state")
	
--    require("game")
    require("demo")
    
    fontname = "Gothic.TTF"
    font12 = love.graphics.newFont(fontname,12)
    font14 = love.graphics.newFont(fontname,14)
    font18 = love.graphics.newFont(fontname,18)
    font24 = love.graphics.newFont(fontname,24)
    font32 = love.graphics.newFont(fontname,32)
    love.graphics.setFont(font12)
    
    love.graphics.setBackgroundColor(255,255,255)
    

    timediff = 0
    timestep = 1/30

--    loadstate(Menu)
    loadstate(Demo)
end

function love.draw()
    activestate:draw()
    love.graphics.setColor(128,128,128)
    local fps = "FPS: " .. love.timer.getFPS()
    love.graphics.print(fps,20,20)
end

function love.update(dt)
    timediff = timediff + dt
    while timediff > timestep do
        timediff = timediff - timestep
        frame = frame + 1
        activestate:update(timestep)
    end
end

function love.mousepressed(x,y, button)
    activestate:mousepress(x,y,button)
    for i,layer in ipairs(activestate.layers) do
        if isui(layer) then
            clickbox(layer.ui)
        end
    end
end

function love.mousereleased(x,y, button)
    activestate:mouserelease(x,y,button)
end

function love.keypressed(key)
    if key == "r" then
        love.load()
    elseif key == "q" then
        love.event.quit()
    elseif key == "lctrl" or key == "lshift" then
        DEBUG = not DEBUG
    else
        activestate:keypress(key)
    end
end

function love.keyreleased(key)
    activestate:keyrelease(key)
end

function loadstate(s)
    activestate = s
    frame = 0
    s:load()
    s:update(timestep)
end

function resumestate(s)
    activestate = s
    if not s.loaded then
        frame = 0
        s:load()
        s:update(timestep)
        s.loaded = true
    end
end