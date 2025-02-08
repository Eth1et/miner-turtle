Vector3 = {};
Vector3.__index = Vector3;

function Vector3.new(x, y, z)
    local self = setmetatable({}, Vector3);
    self.x = x;
    self.y = y;
    self.z = z;
    return self;
end

function Vector3:tostring()
    return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.z) .. ")";
end

function Vector3:sub(other)
    return Vector3.new(self.x - other.x, self.y - other.y, self.z - other.z);
end

return Vector3;