Router = Object.extend(Object)

function Router:new(x, y, id)
    self.x = x;
    self.y = y;
    self.name = "R"..id;
    self.visible = true;
end