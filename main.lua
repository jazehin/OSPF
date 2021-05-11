--LÖVE2D 11.3

local routers = {};
local routerImage = love.graphics.newImage("res/router.png");
local deletedRouters = {};
local connections = {};
local buttons = {};
local buttonWidth;

Font = nil;

local placingRouter = false;
local relocatingRouter = 0;
local connecting = "";
local connectionsPage = 0;
local connectionsTabOpen = false;
local origin, destination = -1, -1;

local route = {};
local usedRouters = {};
local nextToDestination = {};

local mousex, mousey = 0, 0;

Object = require "classic";
require "router";
require "connection";

function love.load()
    love.window.setTitle("OSPF");
    Font = love.graphics.newFont();
    love.graphics.setFont(Font);

    --#region adding buttons
    buttons[1] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {0, 1, 100/255},
        txt = "Add router"
    };
    buttons[2] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {46/255, 139/255, 87/255},
        txt = "Add connection"
    };
    buttons[3] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {173/255, 216/255, 230/255},
        txt = "Connections"
    };
    buttons[4] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {1, 105/255, 180/255},
        txt = "Select the origin"
    };
    buttons[5] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {147/255, 112/255, 219/255},
        txt = "Select the destination"
    };
    buttons[6] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {240/255, 230/255, 140/255},
        txt = "Calculate"
    };
    buttons[7] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {1, 99/255, 71/255},
        txt = "Reset"
    };
    --#endregion

    --#region counting the width of buttons
    local windowWidth = love.graphics.getWidth();

    buttonWidth = math.floor(windowWidth / #buttons);

    for i = 1, #buttons, 1 do
        buttons[i].x = (i - 1) * buttonWidth;
        buttons[i].w = buttonWidth;
    end
    --#endregion
end

function love.update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0);

    if origin > -1 then
        love.graphics.setColor(1, 105/255, 180/255);

        if origin == 0 or not routers[origin].visible then
            love.graphics.circle("fill", mousex, mousey, routerImage:getWidth() / 2 + 5);
        else
            love.graphics.circle("fill", routers[origin].x, routers[origin].y, routerImage:getWidth() / 2 + 5);
        end
    end

    if destination > -1 then
        love.graphics.setColor(147/255, 112/255, 219/255);

        if destination == 0 or not routers[destination].visible then
            love.graphics.circle("fill", mousex, mousey, routerImage:getWidth() / 2 + 5);
        else
            love.graphics.circle("fill", routers[destination].x, routers[destination].y, routerImage:getWidth() / 2 + 5);
        end
    end

    love.graphics.setColor(46/255, 139/255, 87/255);

    --#region drawing circle around router that will be connected to an other originate
    if connecting ~= "" then
        if connecting ~= "choose" then
            local t = {};
            for str in string.gmatch(connecting, "([^|]+)") do
                table.insert(t, str);
            end
            love.graphics.circle("fill", routers[tonumber(t[1])].x, routers[tonumber(t[1])].y, routerImage:getWidth() / 2 + 5);
        end
        love.graphics.circle("fill", mousex, mousey, routerImage:getWidth() / 2 + 5);
    end
    --#endregion

    love.graphics.setColor(1, 1, 1);

    local textToPrint = "";
    for i, v in pairs(route) do
        textToPrint = textToPrint .. "R" .. route[i];
        if i ~= #route then
            textToPrint = textToPrint .. " -> ";
        end
    end

    love.graphics.print(textToPrint, 0, love.graphics.getHeight() - Font:getHeight());

    --#region drawing connections between routers
    for _, connection in pairs(connections) do
        --lines
        local x1, y1, x2, y2;

        if routers[connection.r1].visible then 
            x1, y1 = routers[connection.r1].x, routers[connection.r1].y;
        else
            x1, y1 = mousex, mousey;
        end
        if routers[connection.r2].visible then 
            x2, y2 = routers[connection.r2].x, routers[connection.r2].y;
        else
            x2, y2 = mousex, mousey;
        end
        love.graphics.line(x1, y1, x2, y2);

        --values
        local avgx, avgy = (x1 + x2) / 2, (y1 + y2) / 2;
        love.graphics.rectangle("fill", avgx - Font:getHeight()/2, avgy - Font:getHeight()/2, 30, Font:getHeight());
        love.graphics.setColor(0, 0, 0);
        love.graphics.printf(connection.cost, math.floor(avgx - Font:getHeight()/2), math.floor(avgy - Font:getHeight()/2), 30, "center"); --rendering text at non-integer intervals may make them blurry
        love.graphics.setColor(1, 1, 1);
    end
    --#endregion

    --#region drawing routers
    for _, router in pairs(routers) do
        if router.visible then
            love.graphics.draw(routerImage, router.x - routerImage:getWidth()/2, router.y - routerImage:getHeight()/2);
            love.graphics.printf(router.name, math.floor(router.x - routerImage:getWidth()/2), math.floor(router.y + routerImage:getHeight()/2), routerImage:getWidth(), "center");
        end
    end
    --#endregion

    --#region drawing the router that is being placed
    if placingRouter then
        love.graphics.draw(routerImage, mousex - routerImage:getWidth()/2, mousey - routerImage:getHeight()/2);
    end
    --#endregion

    --#region drawing the router that is being relocated
    if relocatingRouter ~= 0 then
        love.graphics.draw(routerImage, mousex - routerImage:getWidth()/2, mousey - routerImage:getHeight()/2);
        love.graphics.printf(routers[relocatingRouter].name, mousex - routerImage:getWidth()/2, mousey + routerImage:getHeight()/2, routerImage:getWidth(), "center");
    end
    --#endregion

    DrawButtons();
end

function love.keypressed(key)
    if key == "escape" then
        placingRouter = false;
        connecting = "";
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    --#region deleting a router when RIGHT mouse button is pressed
    if button == 2 then
        if placingRouter then
            placingRouter = false;
        elseif connecting ~= "" then
            connecting = "";
        elseif origin == 0 then
            origin = -1;
        elseif destination == 0 then
            destination = -1;
        else
            local routerIndex = PressedRouter(x, y);

            for i, connection in pairs(connections) do
                if connection.r1 == routerIndex or connection.r2 == routerIndex then
                    connections[i] = nil;
                end
            end

            if routerIndex ~= 0 and routers[routerIndex] then
                routers[routerIndex] = nil;
                table.insert(deletedRouters, routerIndex);
            end
        end
    end
    --#endregion

    --#region placing the router which is being relocated
    if relocatingRouter ~= 0 then
        routers[relocatingRouter].x, routers[relocatingRouter].y = mousex, mousey;
        routers[relocatingRouter].visible = true;

        --[[for _, connection in pairs(connections) do
            if connection.r1name == routers[relocatingRouter].name then
                connection.r1x, connection.r1y = routers[relocatingRouter].x, routers[relocatingRouter].y;
            elseif connection.r2name == routers[relocatingRouter].name then
                connection.r2x, connection.r2y = routers[relocatingRouter].x, routers[relocatingRouter].y;
            end
        end]]

        relocatingRouter = 0;
    end
    --#endregion

    --#region start relocating
    if presses == 2 and button == 1 then
        local routerIndex = PressedRouter(x, y);
        if routerIndex ~= 0 then
            relocatingRouter = routerIndex;
            routers[routerIndex].visible = false;
        end
    end
    --#endregion

    --#region placing a new router
    if placingRouter then
        local i;
        if deletedRouters[1] then
            i = deletedRouters[1];
            deletedRouters[1] = nil;
            deletedRouters = Pack(deletedRouters);
        else
            i = #routers+1;
        end
        routers[i] = Router(x, y, i);
        placingRouter = false;
    end
    --#endregion

    --#region new connection
    if connecting ~= "" then
        local routerIndex = PressedRouter(x, y);
        if connecting == "choose" then
            if routerIndex ~= 0 then
                connecting = routerIndex .. "|";
            end
        else
            if routerIndex ~= 0 then
                connecting = connecting .. routerIndex;
                CreateConnection();
            end
        end
    end
    --#endregion

    --#region selecting origin
    if origin == 0 then
        local routerIndex = PressedRouter(x, y);
        if routerIndex ~= 0 then
            origin = routerIndex;
        end
    end
    --#endregion

    --#region selecting destination
    if destination == 0 then
        local routerIndex = PressedRouter(x, y);
        if routerIndex ~= 0 then
            destination = routerIndex;
        end
    end
    --#endregion

    --#region button press
    local buttonIndex = PressedButton(x, y);

    if buttonIndex == 1 then
        placingRouter = not placingRouter;
        ConnectionsTab(false);
        connecting = "";
    elseif buttonIndex == 2 then
        if connecting == "choose" then
            connecting = "";
        else
            connecting = "choose";
        end
        ConnectionsTab(false);
    elseif buttonIndex == 3 then
        ConnectionsTab(not connectionsTabOpen);
    elseif buttonIndex == 4 then
        if origin == 0 then
            origin = -1;
        else
            origin = 0;
        end
    elseif buttonIndex == 5 then
        if destination == 0 then
            destination = -1;
        else
            destination = 0;
        end
    elseif buttonIndex == 6 then
        Calculate();
    elseif buttonIndex == 7 then
        origin, destination = -1, -1;
        for i, _ in pairs(routers) do
            routers[i] = nil;
        end
        for i, _ in pairs(connections) do
            connections[i] = nil;
        end
        ConnectionsTab(false);
    elseif buttons[buttonIndex] and buttons[buttonIndex].txt == "+" then
        local i = math.ceil((buttonIndex - 7) / 4);
        connections[connectionsPage * 5 + i].cost = connections[connectionsPage * 5 + i].cost + 1;
    elseif buttons[buttonIndex] and buttons[buttonIndex].txt == "-" then
        local i = math.ceil((buttonIndex - 7) / 4);
        if connections[connectionsPage * 5 + i].cost > 1 then
            connections[connectionsPage * 5 + i].cost = connections[connectionsPage * 5 + i].cost - 1;
        end
    elseif buttons[buttonIndex] and buttons[buttonIndex].txt == "X" then
        local i = (buttonIndex - 7) / 4;
        --connections[connectionsPage * 5 + i] = nil;

        for j = connectionsPage * 5 + i + 1, #connections, 1 do
            connections[j - 1] = connections[j];
        end

        connections[#connections] = nil;

        ConnectionsTab(true);
    elseif buttonIndex == #buttons - 2 then
        if connectionsPage > 0 then
            connectionsPage = connectionsPage - 1;
            ConnectionsTab(true);
        end
    elseif buttonIndex == #buttons then
        if connections[(connectionsPage + 1) * 5 + 1] then
            connectionsPage = connectionsPage + 1;
        end
        ConnectionsTab(true);
    end
    --#endregion

end

function love.mousemoved(x, y)
    mousex, mousey = x, y;
end

function DrawButtons()
    for i, button in pairs(buttons) do
        love.graphics.setColor(button.bg);
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h);
        love.graphics.reset();
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h);
        love.graphics.setColor(0, 0, 0);
        local _, wrappedtext = Font:getWrap(button.txt, button.w);
        love.graphics.printf(button.txt, button.x, ((button.y*2 + button.h) / 2) - (Font:getHeight() * #wrappedtext / 2), button.w, "center");
        love.graphics.reset();
    end
end

function PressedButton(x, y)
    for i, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
            return i;
        end
    end
    return 0;
end

function PressedRouter(x, y)
    for _, router in pairs(routers) do
        if x >= router.x - routerImage:getWidth()/2 and x <= router.x + routerImage:getWidth()/2 and y >= router.y - routerImage:getHeight()/2 and y <= router.y + routerImage:getHeight()/2 then
            return _;
        end
    end
    return 0;
end

function CreateConnection()
    local routersConnected = {};
    for str in string.gmatch(connecting, "([^|]+)") do
        table.insert(routersConnected, "R"..str);
    end

    -- deal with existing connections and connections which originate from and head towards the same router

    if routersConnected[1] == routersConnected[2] then
        connecting = "";
        return;
    end

    for i, connection in ipairs(connections) do
        if (connection.r1name == routersConnected[1] and connection.r2name == routersConnected[2]) or (connection.r1name == routersConnected[2] and connection.r2name == routersConnected[1]) then
            connecting = "";
            return;
        end
    end

    local i = 1;
    while i < #routers and routers[i].name ~= routersConnected[1] do
        i = i + 1;
    end

    local j = 1;
    while j < #routers and routers[j].name ~= routersConnected[2] do
        j = j + 1;
    end

    --connections[i] = Connection(routersConnected[1], routers[j].x, routers[j].y, routersConnected[2], routers[k].x, routers[k].y)

    table.insert(connections, Connection(routers[i].name, routers[j].name));

    connecting = "";

    ConnectionsTab(false);
end

function ConnectionsTab(open)
    if open then
        for i = 8, #buttons, 1 do
            buttons[i] = nil;
        end
        local colour = {173/255, 216/255, 230/255};
        local i = 1;
        while i <= 5 and connections[connectionsPage * 5 + i] do
            if connections[connectionsPage * 5 + i] then
                buttons[8 + (i - 1) * 4] = {
                    x = 2 * buttonWidth,
                    y = 40 + (i - 1) * 20,
                    w = buttonWidth * 0.6,
                    h = 20,
                    bg = colour,
                    txt = "R" .. connections[connectionsPage * 5 + i].r1 .. " - R" .. connections[connectionsPage * 5 + i].r2
                };
                buttons[9 + (i - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w,
                    y = 40 + (i - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "+"
                };
                buttons[10 + (i - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w + buttons[9].w,
                    y = 40 + (i - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "-"
                };
                buttons[11 + (i - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w + buttons[9].w + buttons[10].w,
                    y = 40 + (i - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "X"
                };
            end
            i = i + 1;
        end
        local j = #buttons + 1;
        buttons[j] = {
            x = 2 * buttonWidth,
            y = 40 + (i - 1) * 20,
            w = buttonWidth * 0.15,
            h = 20,
            bg = colour,
            txt = "<"
        };
        buttons[j + 1] = {
            x = 2 * buttonWidth + buttons[j].w,
            y = 40 + (i - 1) * 20,
            w = buttonWidth * 0.7,
            h = 20,
            bg = colour,
            txt = "Page: " .. connectionsPage + 1
        };
        buttons[j + 2] = {
            x = 2 * buttonWidth + buttons[j].w + buttons[j + 1].w,
            y = 40 + (i - 1) * 20,
            w = buttonWidth * 0.15,
            h = 20,
            bg = colour,
            txt = ">"
        };
        connectionsTabOpen = true;
    else
        for i = 8, #buttons, 1 do
            buttons[i] = nil;
        end
        connectionsTabOpen = false;
    end
end

function Calculate()
    if origin < 1 or destination < 1 then
        return;
    end

    function Calculate()

        if origin < 1 and destination < 1 then
            return;
        end
    
        usedRouters = {};
        route = {};
        SearchRoute(origin); 
    
        --[[
        local o, d = origin, destination; -- these store where we are
        local originRoute, destinationRoute = {o}, {d}; -- these store the route we've already calculated
        --local origin
    
        local found = false;
        local i = 1; -- from origin: odd, from destination: even
        while not found and i <= #routers do
            if i % 2 == 1 then
                local c = SearchForConnections(o);
    
                if #c == 0 then
                    return;
                end
    
                c = Sort(c);
    
                local added = false;
                local j = 1;
                while j <= #c and not added do
                    if true then
                    --innen
                    end
                end
            else
    
            end
    
            for k, v in pairs(originRoute) do
                for l, w in pairs(destinationRoute) do
                    if w == v then
                        found = true;
                    end
                end
            end
            i = i + 1;
        end
        print("found a pair :3");
        ]]
    end
    
    function SearchRoute(router)
        table.insert(route, router);
        table.insert(usedRouters, router);
    
        local t = SearchForConnections(router);
        t = Sort(t);
    
        for i, connection in pairs(t) do
            local otherRouter = 0;
            if connections[connection].r1 == router then
                otherRouter = connections[connection].r2;
            else
                otherRouter = connections[connection].r1;
            end
    
            if otherRouter == destination then
                table.insert(nextToDestination, router);
            end
        end
    
        local finished = false;
    
        for i, connection in pairs(t) do
            local otherRouter = 0;
            if connections[connection].r1 == router then
                otherRouter = connections[connection].r2;
            else
                otherRouter = connections[connection].r1;
            end
    
            print(otherRouter, not Contains(usedRouters, otherRouter));
    
            if not Contains(usedRouters, otherRouter) then
                SearchRoute(otherRouter);
                return;
            elseif i == #t then
                finished = true;
            end
        end
    
        if finished then
            Check();
        end
    end
    
    function Check()
        --[[
        --is the last router in the route table the destination? if not, go back the the router before it and add the faulty connection to the usedRouters table
        if not route[#route] == destination then
            table.insert(usedRouters, route[#route]);
            route[#route] = nil;
            SearchRoute(route[#route]);
            return;
        end
        --]]
    
        if #nextToDestination == 1 then
            return;
        end
    
        local costs = {};
    
        for i = 1, #nextToDestination, 1 do
            costs[i] = {i, 0};
    
            local j = 1;
            while route[j] ~= nextToDestination do
                j = j + 1;
            end
    
            for i = 2, j, 1 do
                costs[i][2] = costs[i][2] + connections[SearchForConnection(route[i - 1], route[i])].cost;
            end
    
            costs[i][2] = costs[i][2] + connections[SearchForConnection(nextToDestination[i], destination)].cost;
        end
    
        costs = Sort(costs);
    
        route = {};
    
        local j = 1;
        while route[j] ~= costs[1][1] do
            j = j + 1;
        end
    
        for i = 1, j, 1 do
            table.insert(route, costs[1][i]);
        end
    
        table.insert(route, destination); 
    
        nextToDestination = {};
        --[[
        local j = 1;
        while route[j] ~= nextToDestination do
            j = j + 1;
        end
    
        local route1cost = 0;
        local temp = {route[1]};
    
        for i = 2, j, 1 do
            route1cost = route1cost + connections[SearchForConnection(route[i - 1], route[i])].cost;
            table.insert(temp, route[i]);
        end
    
        local route2cost = route1cost;
    
        for i = j + 1, #route, 1 do
            route1cost = route1cost + connections[SearchForConnection(route[i - 1], route[i])].cost;
        end
    
        print(nextToDestination, destination);
        route2cost = route2cost + connections[SearchForConnection(route[nextToDestination], route[destination])].cost;
    
        if route1cost < route2cost then
            for i = j + 1, #route, 1 do
                table.insert(temp, route[i]);
            end
        else
            table.insert(temp, destination);
        end
    
        route = temp;
        --]]
    end
end

function SearchForConnections(router)
    local t = {};
    for i, connection in pairs(connections) do
        if connection.r1 == router or connection.r2 == router then
            table.insert(t, i);
        end
    end
    return t;
end

function SearchForConnection(r1, r2)
    for i, connection in ipairs(connections) do
        if (connection.r1 == r1 and connection.r2 == r2) or (connection.r1 == r2 and connection.r2 == r1) then
            return i;
        end
    end
end

function Sort(t)
    if #t == 1 then
        return t;
    end

    if type(t[1]) == "number" then
        local n = #t;
        local swapped;

        repeat
            swapped = false;
            for i=2, n do
                if connections[t[i-1]].cost > connections[t[i]].cost then
                    t[i], t[i-1] = t[i-1], t[i];
                    swapped = true;
                end
            end
        until not swapped;

        return t;
    else
        local n = #t;
        local swapped;

        repeat
            swapped = false;
            for i=2, n do
                if t[i - 1][2] > t[i][2] then
                    t[i], t[i-1] = t[i-1], t[i];
                    swapped = true;
                end
            end
        until not swapped;

        return t;
    end

    
end

function Contains(t, searched)
    for i, v in pairs(t) do
        if v == searched then
            return true;
        end
    end
    return false;
end

function Pack(t)
    local i = 1;
    local temp = {};
    for j, v in pairs(t) do
        temp[i] = v;
        i = i + 1;
    end
    return temp;
end