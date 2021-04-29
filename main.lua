--LÖVE2D 11.3

local routers = {};
local routerImage = love.graphics.newImage("res/router.png");
local connections = {};
local buttons = {
    addRouter = {
        x = 0,
        y = 0,
        w = 150,
        h = 40,
        bg = {0, 1, 0},
        txt = "Add router"
    },
    addConnection = {
        x = 150,
        y = 0,
        w = 150,
        h = 40,
        bg = {0, 1, 0},
        txt = "Add connection"
    },
    connections = {
        x = 300,
        y = 0,
        w = 150,
        h = 40,
        bg = {0, 0, 1},
        txt = "Connections"
    },
    reset = {
        x = 450,
        y = 0,
        w = 150,
        h = 40,
        bg = {1, 0, 0},
        txt = "Reset"
    },
    calculate = {
        x = 600,
        y = 0,
        w = 150,
        h = 40,
        bg = {0, 0, 1},
        txt = "Calculate"
    },
};

font = nil;

local placingRouter = false;
local relocatingRouter = 0;
local connecting = "";

local mousex, mousey = 0, 0;

Object = require "classic";
require "router"
require "connection"

function love.load()
    love.window.setTitle("OSPF");
    font = love.graphics.newFont();
    love.graphics.setFont(font);
end

function love.update(dt)
end

function love.draw()
    DrawButtons();
    love.graphics.setBackgroundColor(0, 0, 0);
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
        love.graphics.rectangle("fill", avgx - font:getHeight()/2, avgy - font:getHeight()/2, 20, font:getHeight());
        love.graphics.setColor(0, 0, 0);
        love.graphics.printf(connection.value, math.floor(avgx - font:getHeight()/2), math.floor(avgy - font:getHeight()/2), 20, "center"); --rendering text at non-integer intervals may make them blurry
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

    if buttonIndex == "addRouter" then
        placingRouter = not placingRouter;
    elseif buttonIndex == "addConnection" then
        if connecting == "choose" then
            connecting = "";
        else
            connecting = "choose";
        end
        connecting = "choose"
    elseif buttonIndex == "connections" then
    elseif buttonIndex == "reset" then
        for i, _ in pairs(routers) do
            routers[i] = nil;
        end
        for i, _ in pairs(connections) do
            connections[i] = nil;
        end
    end
    --#endregion
end

function love.mousemoved(x, y)
    mousex, mousey = x, y;
end

function DrawButtons()
    for _, button in pairs(buttons) do
        love.graphics.setColor(button.bg);
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h);
        love.graphics.reset();
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h);
        love.graphics.setColor(0, 0, 0);
        love.graphics.printf(button.txt, button.x, ((button.y + button.h) / 2) - (font:getHeight() / 2), button.w, "center");
        love.graphics.reset();
    end
end

function PressedButton(x, y)
    for _, button in pairs(buttons) do
        if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
            return _;
        end
    end
    return "";
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
        table.insert(routersConnected, "R"..str)
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