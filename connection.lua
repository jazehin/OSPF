Connection = Object.extend(Object)

function Connection:new(r1name, r1x, r1y, r2name, r2x, r2y)
    self.r1name = r1name;
    self.r1x = r1x;
    self.r1y = r1y;
    self.r2name = r2name;
    self.r2x = r2x;
    self.r2y = r2y;
    self.value = 1;
end