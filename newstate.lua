--find and replace newstate and newcanvas

NewState = State:new()
NewCanvas = Layer:new()
NewState:addlayer(NewCanvas)

function NewState:load()

    --KEYS = {JUMP="z",DASH="x",LEFT="left",RIGHT="right",UP="up",DOWN="down",ATTACK="c"}
    KEYS = {JUMP=" ",DASH="x",LEFT="a",RIGHT="d",UP="w",DOWN="s",ATTACK="c"}
    DIRS = {UP=P(-sqrt2/2,sqrt2/2), LEFT=P(-sqrt2/2,-sqrt2/2), RIGHT=P(sqrt2/2,sqrt2/2), DOWN=P(sqrt2/2,-sqrt2/2)}

    --check if the player knows his controls
    --Game:update(1/30) --force an update before any draw function is possible.
end

function NewCanvas:draw()
    
end

function NewState:update(dt)
	dt = math.min(dt,1/30)
    mx,my = love.mouse.getPosition()
    mouse = P(mx,my)
end


function NewState:mousepress(x,y, button)
    if button == "l" then

    elseif button == "r" then
    
    end
end

function NewState:mouserelease(x,y, button)

end

function NewState:keypress(key)
    if key == KEYS.JUMP then

    end
end

function NewState:keyrelease(key)

end