local Vector3 = require("types.vector3");
local Direction = require("types.direction");

TurtleState = {};
TurtleState.__index = TurtleState;

function TurtleState.new(pos, lookDir, digRight)
    local self = setmetatable({}, TurtleState);
    self.pos = pos;
    self.returnPos = Vector3.new(0,0,0);
    self.lookDir = lookDir;
    self.digDir = lookDir;
    self.digRight = digRight;
    return self;
end

function TurtleState:tostring()
    return "Pos: " .. (self.pos:tostring() or "nil") ..  "\n" ..
           "Facing: " .. (Direction.reverse[self.lookDir] or "nil") .. "\n" ..
           "Last Digging Pos: " .. (self.returnPos:tostring() or "nil") .. "\n" ..
           "Digging Direction: " .. (self.digRight == true and "Right" or "Left") .. " | " .. (Direction.reverse[self.digDir] or "nil") .. "\n";
end

return TurtleState;