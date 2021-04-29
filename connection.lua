Connection = Object.extend(Object)

function Connection:new(r1, r2)
    self.r1 = tonumber(string.sub(r1, 2));
    self.r2 = tonumber(string.sub(r2, 2));
    self.value = 1;
    self.valueContainer = {
        x, y, w = 20, h = font:getHeight()
    };
end