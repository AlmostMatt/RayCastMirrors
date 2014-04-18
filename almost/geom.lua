--point is {x,y}
--polygon is {point,point,...}
--edge is {point,point}
--ray is {point, delta} where delta is a point ?
--segment is same as edge
--http://en.wikipedia.org/wiki/Polygon_triangulation in order to draw a concave polygon

--reflection as composition of translate, rotate, scale/shear, inverse rotate, inverse translate?
--stencil polygon as a mask
-- and vmath to transform positions that are possibly in mask region

require("almost/listf")

--[[ this is actually two different incomplete attempts at the function, priority changed
--make this a vmath extension of intersection?
function overlap(A,B) --assuming simple shapes like triangles, this isn't terribly efficient
	--each shape is a list of points
    --there will only be one resulting shape
	local C = {}
    local alongA = false
	local eA = edges(A)
	local eB = edges(B)
	local onA,onB = true,false
	local i,j = 1,1
	local lastpoint = A[1]
	local nextindex = 2
	local start = nil
	if not inpolygon(lastpoint,B) then
		while not start do
			local e1 = eA[i]
			local x = nil
			for j,e2 in ipairs(eB) do
				x = intersection(e1,e2)
				if x then
					e1 = S(e1[1],x)
				end
			end
			if x then
				start = x
				lastpoint = x
				nextindex = i + 1
			else
				i = i + 1
			end
		end
	else
		start = lastpoint
		nextindex = i + 1
	end
	--i > #A case?
	--no intersections and not in B case?
	table.insert(C,copy(a))
	while true do
		local x = nil
		if onA then
			for _,e2 in ipairs(eB) do
				local x = intersection(e1,e2)
		elseif onB then
			for _,e1 in ipairs(eA) do
				local x = intersection(e1,e2)
		end
		--set onb, lastpoint, nextindex, check for closed ( is start /startindex )
	end
        alongA = true
		table.insert(C,copy(a))
		local i,j = 1,1
        while i <= #eA do --go around A until reach last edge of A
            if alongA then
                local e1 = eA[i]
                local x = false
                local xi = false
                for bi,e2 in ipairs(eB) do
                    x = intersection(e1,e2)
                    if x then
                        e1 = S(e1[1],x)
                        xi = bi
                    end
                end
				if x then
                    table.insert(C,x)
                    j = bi
                    alongA = false
                else
                    i = i + 1
                end
            end
        for i,e in ipairs(eA) do
				if x then
					table.insert(C,x)
					--change flow (move around B now)
					--and stop if passing first inpoint
				end
			end
		end
	end
	if #C > 0 then
		return C
	else
		return nil
	end
end]]

function inpolygon(p,points)
    local count = 0
    for i,e in ipairs(edges(points)) do
        if intersection(R(p,Vadd(p,P(1,0.001))),e) then -- the ray is slightly offset from horizontal to make it unlikely that the ray will pass exactly through a point
            count=count+1
        end
    end
    return count%2 == 1
end

--list of segments
function edges(points) --do this with as_pairs, map, concat and foldr
    e = {S(points[#points],points[1])}
    for i = 1, #points-1 do
        table.insert(e,S(points[i],points[i+1]))
    end
    return e
end

function normalof(edge)
    return unitV(Vnorm(Vsub(edge[2],edge[1])))
end

function midpoint(edge)
    return Vavg(edge[1],edge[2])
end

function flatten(points) --do this with map, concat, and folder. or look for built in flatten function
    if #points == 0 or type(points[1]) == "number" then
        return points
    else
        local new = {}
        for i,pair in ipairs(points) do
            table.insert(new,pair[1])
            table.insert(new,pair[2])
        end
        return new
    end
end

function expand(flatpoints) --{a,b,c,d} to {{a,b},{c,d}}
    if #points == 0 or type(points[1]) == "table" then
        return points
    else
        local new = {}
        for i = 1,#points,2 do
            table.insert(new,{points[i],points[i+1]})
        end
        return new
    end
end

function polyfill(points)
--    love.graphics.polygon("fill",flatten(points))
    for i,t in ipairs(triangles(points)) do
        --love.graphics.setColor(0,0,0,64)
        love.graphics.polygon("fill",flatten(t))
        --love.graphics.polygon("line",flatten(t))
    end
end

function triangles(polygon)
    if #polygon < 3 then
        return {}
    elseif #polygon == 3 then
        return {polygon}
    else
        --an "ear" is a set of verts ABC such that AB and BC are edges and AC is completely inside the polygon
        local ear
        for i = 1,#polygon do
            if i == #polygon then
                ear = {i,1,2}
            elseif i+1 == #polygon then
                ear = {i,i+1,1}
            else
                ear = {i,i+1,i+2}
            end
            if isear(polygon,ear) then
                -- every poly with >3 edges and no "holes" has an ear
                break
            end
        end
        --if the ear is removed (v1 v2 A B C v3 v4 to v1 v2 A C v3 v4) then triangulize this shape with same algorith recursively, and ABC is a triangle
        local newtri = {polygon[ear[1]],polygon[ear[2]],polygon[ear[3]]}
        local newpoly = copy(polygon)
        table.remove(newpoly,ear[2])
        local tris = triangles(newpoly)
        table.insert(tris,newtri)
        return tris
    end
end

function isear(polygon, ear)
    -- checking points ABC
    local A = polygon[ear[1]]
    local B = polygon[ear[2]]
    local C = polygon[ear[3]]
    --if average(A,C) is in polygon and AC does not intersect any edges that do not contain A or C then ABC is an ear. 
    if not inpolygon(Vavg(A,C),polygon) then
        return false
    end
    local edge = S(A,C)
    for i,e in ipairs(edges(polygon)) do
        if not commonpoint(edge,e) then
            --check for intersection
            if intersection(edge,e) then
                return false
            end
        end
    end
    local lw = love.graphics.getLineWidth()
    local r,g,b,a = love.graphics.getColor()
    if (DEBUG) then
        love.graphics.setLineWidth(1)
        love.graphics.setColor(255,0,0)
        love.graphics.line(A[1],A[2],C[1],C[2])
        love.graphics.setColor(r,g,b,a)
        love.graphics.setLineWidth(3)
    end
    return true
end

function polyline(points, closed)
    if closed then
        table.insert(points, points[1])
    end
    for i = 1,#points-1 do
        local e = {{points[i][1],points[i][2]},{points[i+1][1],points[i+1][2]}}
        love.graphics.setColor(0,0,0)
        love.graphics.line(flatten(e))
        if DEBUG then
            love.graphics.setColor(0,255,0)
            love.graphics.line(flatten({ midpoint(e), Vadd(midpoint(e),Vmult(20,normalof(e))) }))
        end
    end
    if closed then
        table.remove(points)
    end
end

function samepoint(a,b) --check if two poitns are the same
    return a[1] == b[1] and a[2] == b[2]
end

function commonpoint(e1,e2) --check if two edges have one or more points in common
    return samepoint(e1[1],e2[1]) or samepoint(e1[1],e2[2]) or samepoint(e1[2],e2[1]) or samepoint(e1[2],e2[2])
end


function trimmedShape(points,area)
    --clockwise, so that normals can be generated with cross product
    local result = points
    for i=1,#area.e do
        --trim the shape based on this edge
        local e = area.e[i]
        result = trimShape(result,L(e[1],e[2]),area.n[i])
    end
    return shape(result)
end

function trimmedLine(segment,area)
    local result = segment
    for i=1,#area.e do
        --trim the shape based on this edge
        local e = area.e[i]
        result = trimLine(result,L(e[1],e[2]),area.n[i])
    end
    if #result < 2 then
        return nil
    else
        return S(result[1],result[2])
    end
end

function trimLine(points,edge,normal)
    --should be 0 or 2 points
    -- a lone point would be on the edge and can be ignored
    if #points < 2 then return points end
    local p1,p2 = points[1],points[2]
    local new = {}
    local wasin = not Vsamedir( Vsub(p1,edge[1]) , normal )
    --find out if first point is in shape
    if wasin then
        table.insert(new,p1)
    end
    local isin = not Vsamedir( Vsub(p2,edge[1]) , normal )
    if isin ~= wasin then
        --an intersection!
        local i = intersection(L(p1,p2),edge)
        if i then
            table.insert(new,i)
        else
            print("trimLINE")
            --table.insert(new,p2)
            --isin = wasin
            --I think this means it is just on the edge, so I will increase the length of p1 p2
            --[[
            local d = Vsub(p2,p1)
            Vscale(d,1)
            local i2 = intersection(S(Vsub(p1,d),Vadd(p2,d)),edge)
            if i2 then
                table.insert(new,i2)
            end
            ]]
        end
    end
    if isin then
        table.insert(new,p2)
    end
    return new
end
function trimShape(points,edge,normal)
    if #points == 0 then return points end
    --maybe make normal optional
    local new = {}
    local wasin = not Vsamedir( Vsub(points[#points],edge[1]) , normal )
    local st = points[1]
    for j,e in ipairs(edges(points)) do
--        local wasin = not Vsamedir( Vsub(e[1],edge[1]) , normal )
        local isin = not Vsamedir( Vsub(e[2],edge[1]) , normal )
        if isin ~= wasin then
            --an intersection!
            local i = intersection(L(e[1],e[2]),edge)
            if i then
                table.insert(new,i)
            else
                print("trimSHAPE " .. e.t .. ", ".. edge.t)
                --table.insert(new,e[2])
                --isin = wasin
                --[[
                --I think this means it is just on the edge, so I will triple the length of p1 p2
                local d = Vsub(e[2],e[1])
                local i2 = intersection(S(Vsub(e[1],d),Vadd(e[2],d)),edge)
                if i2 then
                    table.insert(new,i2)
                    --if it still does not exist this is a weird case like camera is inside line so area is 0 width
                end
                ]]
            end
        end
        if isin then
            table.insert(new,e[2])
        end
        wasin = isin
    end
    return new
end

--takes a shhape returns minpoint maxpoint for bounding rectangle
function bounds(s)
    local x1,y1,x2,y2 = s.p[1][1],s.p[1][2],s.p[1][1],s.p[1][2]
    for i,p in ipairs(s.p) do
        x1 = math.min(x1,p[1])
        x2 = math.max(x2,p[1])
        y1 = math.min(y1,p[2])
        y2 = math.max(y2,p[2])
    end
    return P(x1,y1),P(x2,y2)
end

function shape(points)
    if #points <= 2 then return nil end --need 3 points for a shape to have area
    --precalculate normals
    --and change order of points to clockwise if necessary
    --assume convex, check angle between two edges two determine which side is the normal
    --cut off the stuff on the normal side of each edge
    local p = points
    local edge1 = S(points[1],points[2])
    local edge2 = S(points[2],points[3])
    --clockwise test
    if Vsamedir(
        Vnorm(Vsub(edge1[2],edge1[1])),
        Vsub(edge2[2],edge2[1])
    ) then
        --invert order of points
        p = {}
        while #points > 0 do
            table.insert(p,table.remove(points))
        end
    end
    local e = edges(p)
    local normals = {}
    for i,edge in ipairs(e) do
        table.insert(normals,Vnorm(Vsub(edge[2],edge[1])))
    end
    return {p=p,e=e,n=normals,t=TYPES.SHAPE}
end

--area behind a wall with respect to a view point and within an area
function areaBehind(p,m,drawarea)
    --point and segment
    local d1,d2 = Vsub(m[1],p),Vsub(m[2],p)
    local bignumber = 20000000
    --to see if this is large enough, stand very close to a very wide wall
    --bignumber = 300
     --need these points to be "offscreen" and this isn't called too often so this seems to work
    --I can't use width or height since the diff might be nearly vertical aka diffx might be < 1
    local p1 = Vadd(m[1],Vscale(d1,bignumber))
    local p2 = Vadd(m[2],Vscale(d2,bignumber))
    --make it huge enough to be roughly infinite
    
    --crop it to the screen (or other draw area if drawing in a mirror area)
--DEBUG
--    love.graphics.setColor(0,0,0)
--    love.graphics.polygon("line",flatten({m[1],m[2],p2,p1}))
    return trimmedShape({m[1],m[2],p2,p1},drawarea)
end


--need line edges even if they were previously segments