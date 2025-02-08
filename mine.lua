local iou = require("io_utils");
local TurtleState = require("types.turtle_state");
local Vector3 = require("types.vector3");
local Direction = require("types.direction");
local cfg = require("config");

iou.clear();
term.setTextColour(colors.orange);
print("Place a Chest Behind the turtle");

-- getting parameters
term.setTextColour(colors.blue);
FORWARD = iou.requireInt("Forward: ")
SIDEWAYS = iou.requireInt("Sideways: ")
DEPTH = iou.requireInt("Downwards: ")

GO_RIGHT = iou.requireBool("Go Right (Left otherwise)? (y/n): ");
TOSS_GARBAGE = iou.requireBool("Toss garbage? (y/n): ");
WAIT_STORAGE = iou.requireBool("Wait for Empty storage? (y/n): ");
RETURN_ON_FINISH = iou.requireBool("Return to storage when done? (y/n): ");
GO_DOWN_UNTIL_BLOCK = iou.requireBool("Go down until Block is found? (y/n): ");

-- Init Routine
iou.clear();
term.setTextColour(colors.cyan);
STATE = TurtleState.new(Vector3.new(0,0,0), Direction.Forward, GO_RIGHT);



-- DISPLAY

--- display current state
local function displayState()
    iou.clear();
    print(STATE:tostring());
end



-- MOVEMENT

--- turns towards direction with minimal turns
local function turnTowards(direction)
    if STATE.lookDir == direction then
        return;
    else 
        local diff = (direction - STATE.lookDir) % 4;

        if diff == 1 then
            turtle.turnRight();
        elseif math.abs(diff) == 2 then
            turtle.turnRight();
            turtle.turnRight();
        elseif diff == 3 or diff == -1 then
            turtle.turnLeft();
        end
    end
    STATE.lookDir = direction % 4;
    displayState();
end

--- tries to move down 1 block
local function moveDown()
    if turtle.down() then
        STATE.pos.y = STATE.pos.y - 1;
        displayState();
        return true;
    end
    return false;
end

--- tries to move up 1 block
local function moveUp()
    if turtle.up() then
        STATE.pos.y = STATE.pos.y + 1;
        displayState();
        return true;
    end
    return false;
end

--- tries to move forward one block
local function moveForward()
    if turtle.forward() then
        if STATE.lookDir == Direction.Forward then
            STATE.pos.x = STATE.pos.x + 1;
        elseif STATE.lookDir == Direction.Backward then
            STATE.pos.x = STATE.pos.x - 1;
        elseif STATE.lookDir == Direction.Left then
            STATE.pos.z = STATE.pos.z - 1;
        else 
            STATE.pos.z = STATE.pos.z + 1;
        end
        displayState();
        return true;
    end
    return false;
end



-- FORCED/CHECKED MOVEMENT

--- digs down until it can move 1
--- or gives up when unbreakable block is met
--- returns if succeeds = true or gives up = false
local function digMoveDown()
    while true do
        if moveDown() then
            return true;
        elseif not turtle.digDown() then
            return false;
        end
    end
end

--- digs up until it can move 1
--- or gives up when unbreakable block is met
--- returns if succeeds = true or gives up = false
local function digMoveUp()
    while true do
        if moveUp() then
            return true;
        elseif not turtle.digUp() then
            return false;
        end
    end
end

--- digs up until it can move 1
--- or gives up when unbreakable block is met
--- returns if succeeds = true or gives up = false
local function digMoveForward()
    while true do
        if moveForward() then
            return true;
        elseif not turtle.dig() then
            return false;
        end
    end
end



-- HOMING

--- checks if the inventory is full
--- merges block types, throws out garbage
local function isFull()
    local stacks = {};

    -- Grouping Stacks
    for slot = 1, cfg.INVENTORY_SIZE, 1 do
        local itemDetail = turtle.getItemDetail(slot)
        if itemDetail ~= nil then
            if stacks[itemDetail.name] ~= nil then
               table.insert(stacks[itemDetail.name], slot);
            else
                stacks[itemDetail.name] = {slot};
            end
        end
    end

    -- Merge Stacks
    for _, slots in pairs(stacks) do
        if #slots > 1 then
            for mergeIndex = 1, #slots - 1, 1 do
                local freeSpace = turtle.getItemSpace(slots[mergeIndex]);
    
                for index = mergeIndex + 1, #slots, 1 do
                    if freeSpace <= 0 then
                        break;
                    end
    
                    turtle.select(slots[index]);
                    local itemCount = turtle.getItemCount();
                    local movedAmount = math.min(freeSpace, itemCount);
                    turtle.transferTo(slots[mergeIndex], movedAmount);
                end
            end
        end
    end

    -- Drop Garbage And Count Free Slots
    local freeSlots = cfg.INVENTORY_SIZE;
    for slot = 1, cfg.INVENTORY_SIZE, 1 do
        local itemDetail = turtle.getItemDetail(slot);

        if itemDetail ~= nil then
            freeSlots = freeSlots - 1;

            if TOSS_GARBAGE then
                for _, block in ipairs(cfg.GARBAGE_BLOCKS) do
                    if item_detail.name == block then
                        freeSlots = freeSlots + 1;
                        turtle.select(slot);
                        turtle.drop();
                        break;
                    end
                end
            end
        end
    end

    turtle.select(1)
    -- "<= 1" and not "== 0" because it would get stuck on cobblestone/other garbage when at corner
    return freeSlots <= 1
end

--- stores the loot into the chest
local function storeLoot()
    turnTowards(Direction.Backward)
    for slot = 1, cfg.INVENTORY_SIZE, 1 do
        turtle.select(slot)
        if turtle.getItemDetail() ~= nil then
            while turtle.drop() == false do
                if not WAIT_STORAGE then
                    break;
                end
                iou.waitTillInput("The Chest is full, make some space!");
            end
        end
    end

    turnTowards(Direction.Forward)
    turtle.select(1)
end

--- goes back to the starting position
local function goHome(isComplete)
    -- save position
    STATE.returnPos.x = STATE.pos.x;
    STATE.returnPos.y = STATE.pos.y;
    STATE.returnPos.z = STATE.pos.z;
    STATE.digDir = STATE.lookDir;
    displayState();

    -- up
    while STATE.pos.y < 0 do
        digMoveUp();
    end

    -- to the chest
    turnTowards(Direction.Backward);
    while STATE.pos.x > 0 do
        digMoveForward();
    end
    turnTowards(Direction.Left)
    while STATE.pos.z > 0 do
        digMoveForward();
    end

    -- look at chest
    turnTowards(Direction.Backward);
    storeLoot();

    if isComplete then
        term.setTextColor(colors.green);
        print("Succesfully Finished Program!");
        os.exit(0);
    end
end



-- FUEL MANAGEMENT

--- refuels from every possible source that it has
local function refuel()
    for slot = 1, cfg.INVENTORY_SIZE, 1 do
        local itemDetail = turtle.getItemDetail(slot);
        if itemDetail ~= nil  then
            for _, a in ipairs(cfg.FUEL_ITEMS) do
                if a == itemDetail.name then
                    turtle.select(slot)
                    turtle.refuel()
                    break;
                end
            end
        end
    end
end

--- checks if the fuel level is greater than the sum of coordinate differences compared to (0,0,0)
--- plus utp's paranoid "+ 16"
local function hasEnoughFuel()
    return turtle.getFuelLevel() >= math.abs(STATE.pos.x) + math.abs(STATE.pos.y) + math.abs(STATE.pos.z) + 16;
end



-- LAYERING

--- digs -> moves forward -> digs up -> digs down
local function dig()
    if digMoveForward() == false then
        go_home(true);  -- full exit
    end

    while turtle.digUp() == false and turtle.detectUp() do
        -- repeatedly digs until it noone fucks with it anymore
    end

    while turtle.digDown() == false and turtle.detectDown() do
        -- repeatedly digs until it noone fucks with it anymore
    end
end

--- does a U turn
local function uTurn()
    STATE.digDir = STATE.lookDir;
    if STATE.digRight then
        turnTowards(Direction.Right);
    else
        turnTowards(Direction.Left);
    end
    dig();

    if STATE.digDir == Direction.Forward then
        turnTowards(Direction.Backward);
    else
        turnTowards(Direction.Forward);
    end
end

--- returns to the last digging position, rotation
local function returnAfterStash()
    -- z axis
    turnTowards(Direction.Right);
    while STATE.pos.z < STATE.returnPos.z do
        if not digMoveForward() then
            goHome(true);  -- full exit
            break;
        end
    end

    -- x axis
    turnTowards(Direction.Forward);
    while STATE.pos.x < STATE.returnPos.x do
        if not digMoveForward() then
            goHome(true); -- full exit
            break;
        end
    end

    -- y axis
    turnTowards(STATE.digDir);
    while STATE.pos.y > STATE.returnPos.y do
        if not digMoveDown() then
            goHome(true);  -- full exit
            break;
        end
    end
end

--- descends to the next layer
local function descend(layer)
    local targetY = STATE.pos.y - 3;

    if layer == 1 then
        targetY = targetY + 1;
    end

    while STATE.pos.y ~= targetY do
        if not digMoveDown() then
            goHome(true);
            break;
        end
    end

    while turtle.digDown() do
        -- repeating digging down until there is nothing
    end
end

--- digs a row forwards or backwards
local function digRow()
    while (STATE.lookDir == Direction.Forward and STATE.pos.x < FORWARD-1) or
            (STATE.lookDir == Direction.Backward and STATE.pos.x > 0) do
        dig();
    end
end

--- digs one layer of rows and columns
local function dig_level()
    local first = true;
    while (GO_RIGHT and STATE.digRight and STATE.pos.z < SIDEWAYS -1) or 
          (GO_RIGHT and not STATE.digRight and STATE.pos.z >= 0) or 
          (not GO_RIGHT and STATE.digRight and STATE.pos.z <= 0) or
          (not GO_RIGHT and  not STATE.digRight and STATE.pos.z > - SIDEWAYS + 1) do
        refuel();
        turtle.select(1);

        STATE.returnPos.x, STATE.returnPos.y, STATE.returnPos.z = STATE.pos.x, STATE.pos.y, STATE.pos.z;
        STATE.digDir = STATE.lookDir;
        displayState();

        if not first then
            uTurn();
        end
        first = false;

        if not hasEnoughFuel() then
            goHome(false);
            iou.waitTillInput("Need More Fuel, Please Give!");
        end

        if isFull() then
            goHome(false);
            returnAfterStash();
        end

        digRow();
    end
end



local function main()
    refuel();
    turtle.select(1);

    local layerCount = math.ceil(DEPTH / 3);

    term.setTextColour(colors.orange);
    local estTime = layerCount / 25.0 * math.abs(SIDEWAYS) * math.abs(FORWARD) * cfg.LAYER_TIME_FOR_5X5_IN_MINUTES;
    print("Gonna do " .. tostring(layerCount) .. " layers, est. time: " .. math.floor(estTime) .. "m");
    os.sleep(2.5);
    term.setTextColour(colors.cyan);
    
    for layer = 1, layerCount, 1 do
        displayState();
        descend(layer);
        dig_level();
        STATE.digRight = not STATE.digRight;
        turnTowards(STATE.lookDir + 2);
    end
end

main();