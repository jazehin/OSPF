--LÖVE2D 11.3

local routers = {};
local routerImage = love.graphics.newImage("res/router.png");
local connections = {};
local buttons = {};
local buttonWidth;

Font = nil;

local placingRouter = false;
local relocatingRouter = 0;
local connecting = "";
local connectionsPage = 0;

local mousex, mousey = 0, 0;

Object = require "classic";
require "router"
require "connection"

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
    buttons[7] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {1, 99/255, 71/255},
        txt = "Reset"
    };
    buttons[6] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {240/255, 230/255, 140/255},
        txt = "Calculate"
    };
    buttons[4] = {
        x = 0,
        y = 0,
        w = 0,
        h = 40,
        bg = {1, 182/255, 193/255},
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
    DrawButtons();
    love.graphics.setBackgroundColor(0, 0, 0);
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
        love.graphics.rectangle("fill", avgx - Font:getHeight()/2, avgy - Font:getHeight()/2, 20, Font:getHeight());
        love.graphics.setColor(0, 0, 0);
        love.graphics.printf(connection.value, math.floor(avgx - Font:getHeight()/2), math.floor(avgy - Font:getHeight()/2), 20, "center"); --rendering text at non-integer intervals may make them blurry
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
        local routerIndex = PressedRouter(x, y);

        for i, connection in pairs(connections) do
            if connection.r1 == routerIndex or connection.r2 == routerIndex then
                connections[i] = nil;
            end
        end

        if routerIndex ~= 0 and routers[routerIndex] then
            routers[routerIndex] = nil;
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
        local i = #routers+1;
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

    --#region button press
    local buttonIndex = PressedButton(x, y);

    if buttonIndex == 1 then
        placingRouter = not placingRouter;
    elseif buttonIndex == 2 then
        if connecting == "choose" then
            connecting = "";
        else
            connecting = "choose";
        end
        connecting = "choose"
    elseif buttonIndex == 3 then
        ConnectionsTable();
    elseif buttonIndex == 4 then
    elseif buttonIndex == 5 then
    elseif buttonIndex == 6 then
    elseif buttonIndex == 7 then
        for i, _ in pairs(routers) do
            routers[i] = nil;
        end
        for i, _ in pairs(connections) do
            connections[i] = nil;
        end
    elseif buttonIndex == 7 then
    elseif buttonIndex == 7 then
    elseif buttonIndex == 7 then
    elseif buttonIndex == 28 then
        if connectionsPage > 0 then
            connectionsPage = connectionsPage - 1;
            ConnectionsTable(true);
        end
    elseif buttonIndex == 30 then
        connectionsPage = connectionsPage + 1;
        ConnectionsTable(true);
    end
    --#endregion
end

function love.mousemoved(x, y)
    mousex, mousey = x, y;
end

function DrawButtons()
    for i, button in ipairs(buttons) do
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
end

function ConnectionsTable(keepOpen)

    -- known problems:
    -- > switching to different pages does virtually nothing
    -- > unable to reopen the tab after closing it
    -- > etc?

    if #buttons == 7 or keepOpen then
        local colour = {173/255, 216/255, 230/255};
        local i = connectionsPage * 5 + 1;
        local j = 1
        while i <= connectionsPage * 5 + 5 and connections[connectionsPage * 5 + i] do
            if connections[connectionsPage + 1] then
                buttons[8 + (j - 1) * 4] = {
                    x = 2 * buttonWidth,
                    y = 40 + (j - 1) * 20,
                    w = buttonWidth * 0.6,
                    h = 20,
                    bg = colour,
                    txt = "R" .. connections[i].r1 .. " - R" .. connections[i].r2
                };
                buttons[9 + (j - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w,
                    y = 40 + (j - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "+"
                };
                buttons[10 + (j - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w + buttons[9].w,
                    y = 40 + (j - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "-"
                };
                buttons[11 + (j - 1) * 4] = {
                    x = 2 * buttonWidth + buttons[8].w + buttons[9].w + buttons[10].w,
                    y = 40 + (j - 1) * 20,
                    w = buttonWidth * 0.4 / 3,
                    h = 20,
                    bg = colour,
                    txt = "X"
                };
            end
            i = i + 1;
            j = j + 1;
        end
        buttons[28] = {
            x = 2 * buttonWidth,
            y = 140,
            w = buttonWidth * 0.15,
            h = 20,
            bg = colour,
            txt = "<"
        };
        buttons[29] = {
            x = 2 * buttonWidth + buttons[28].w,
            y = 140,
            w = buttonWidth * 0.7,
            h = 20,
            bg = colour,
            txt = "Page: " .. connectionsPage + 1
        };
        buttons[30] = {
            x = 2 * buttonWidth + buttons[28].w + buttons[29].w,
            y = 140,
            w = buttonWidth * 0.15,
            h = 20,
            bg = colour,
            txt = ">"
        };
        
        
    else
        for i = 8, #buttons, 1 do
            buttons[i] = nil;
        end
    end
end