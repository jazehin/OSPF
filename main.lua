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
local font;

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

function love.draw()
    DrawButtons();
    love.graphics.setBackgroundColor(0, 0, 0);
    love.graphics.setColor(1, 1, 1);
    --love.graphics.print("Number of routers: " .. #routers);

    for _, router in pairs(routers) do
        if router.visible then
            love.graphics.draw(routerImage, router.x - routerImage:getWidth()/2, router.y - routerImage:getHeight()/2);
            love.graphics.printf(router.name, router.x - routerImage:getWidth()/2, router.y + routerImage:getHeight()/2, routerImage:getWidth(), "center");
        end
    end

    if placingRouter then
        love.graphics.draw(routerImage, mousex - routerImage:getWidth()/2, mousey - routerImage:getHeight()/2);
    end

    if relocatingRouter ~= 0 then
        love.graphics.draw(routerImage, mousex - routerImage:getWidth()/2, mousey - routerImage:getHeight()/2);
        love.graphics.printf(routers[relocatingRouter].name, mousex - routerImage:getWidth()/2, mousey + routerImage:getHeight()/2, routerImage:getWidth(), "center");
    end
end

function love.keypressed(key)
    
end



function love.mousepressed(x, y, button, istouch, presses)
    

    if button == 2 then
        local routerIndex = PressedRouter(x, y);
        if routerIndex ~= 0 and routers[routerIndex] then
            routers[routerIndex] = nil;
        end
        print(routerIndex);
    end

    if relocatingRouter ~= 0 then
        routers[relocatingRouter].x, routers[relocatingRouter].y = mousex, mousey;
        routers[relocatingRouter].visible = true;
        relocatingRouter = 0;
    end

    if presses == 2 and button == 1 then
        local routerIndex = PressedRouter(x, y);
        if routerIndex ~= 0 then
            relocatingRouter = routerIndex;
            routers[routerIndex].visible = false;
        end
    end

    if placingRouter then
        local i = #routers+1;
        routers[i] = Router(x, y, i);
        placingRouter = false;
    end

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
    end
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
    local routers = {};
    for str in string.gmatch(connecting, "([^|]+)") do
        table.insert(routers, str)
    end

    -- deal with existing connections and connections the originate from and head towards the same router

    local i = #connections + 1;

    connections[i] = Connection()
end