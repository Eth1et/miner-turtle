--Big dick creators: Ethiet, utp
---@diagnostic disable: lowercase-global, undefined-global, undefined-field

-- CONFIG {
    GARBAGE_BLOCKS = {
        "minecraft:cobblestone",
        "minecraft:stone",
        "minecraft:dirt",
        "minecraft:gravel",
        "chisel:marble2",
        "chisel:limestone2",
        "minecraft:netherrack",
        "minecraft:cobbled_deepslate",
        "natura:nether_tainted_soil",
        "minecraft:tuff",
        "minecraft:clay",
        "minecraft:clay_ball",
        "minecraft:andesite",
        "minecraft:granite",
        "minecraft:diorite"
    }
    FUEL_ITEMS = {
        "minecraft:coal",
        "minecraft:charcoal",
        "minecraft:coal_block",
        "modern_industrialization:lignite_coal",
        "modern_industrialization:lignite_coal_block"
    }
    WORLD_Y_BOTTOM = -60
    -- } CONFIG
    
    Directions = {
        Forward = 0,
        Right = 1,
        Backward = 2,
        Left = 3
    }
    
    -- func: check if number
    local function is_numeric(x)
        if tonumber(x) ~= nil then
            return true
        end
        return false
    end
    
    -- func: if not number, exit
    local function die_if_not_num(a)
        if not is_numeric(a) then
            io.write("\nError: not a number\n")
            return 1
        end
    end
    
    -- initialization
    term.clear()
    term.setCursorPos(1,1)
    
    print("Facing forward, place a container towards yourself next to the turtle!")
    
    -- getting parameters
    io.write("Forward: ")
    forward = io.read()
    die_if_not_num(forward)
    forward = tonumber(forward)
    
    io.write("Sideways (to the right): ")
    sideways = io.read()
    die_if_not_num(sideways)
    sideways = tonumber(sideways)
    
    io.write("How much to dig dow? from here ")
    depth = io.read()
    die_if_not_num(depth)
    depth = tonumber(depth)
    
    io.write("Toss garbage? (y/n): ")
    input = io.read()
    toss_garbage = input == "y" or input == "Y" or input == "z" or input == "Z"
    if toss_garbage then
        io.write("Garbage WILL be tossed.\n")
    else
        io.write("Garbage will NOT be tossed.\n")
    end
    
    io.write("Stop while storage is full? (y/n): ")
    input = io.read()
    freeze = input == "y" or input == "Y" or input == "z" or input == "Z"
    if freeze then
        io.write("Turtle WILL stop if external storage full.\n")
    else
        io.write("Turtle will NOT stop if external storage full.\n")
    end
    
    io.write("!! Starting !!")
    os.sleep(2.5)
    
    term.clear()
    term.setCursorPos(1,1)
    io.write("Toss garbage: " .. (toss_garbage == true and "yes" or "no") .. ",\n forward: " .. forward .. ", right: " .. sideways .. "\n")
    term.setCursorPos(1,2)
    
    -- properties
    x_position, y_position, z_position = 0, 0, 0  -- rel pos from start (and chest behind)
    look_direction = Directions.Forward  -- actual
    bedrock_reached = false
    last_x, last_y, last_z = 0, 0, 0
    last_direction = Directions.Forward  -- mining direction
    digging_right = true
    
    -- functions
    local function is_full()
        local free_slots = 16
    
        for slot = 1, 16, 1 do
            local item_detail = turtle.getItemDetail(slot)
    
            if item_detail ~= nil then
                free_slots = free_slots - 1
                for _,block in ipairs(GARBAGE_BLOCKS) do
                    if item_detail.name == block then
                        free_slots = free_slots + 1
                        turtle.select(slot)
                        turtle.drop()
                        break
                    end
                end
            end
        end
    
        turtle.select(1)
        -- "<= 1" and not "== 0" because it would get stuck on cobblestone/other garbage when at corner
        return free_slots <= 1
    end
    
    local function set_direction(direction)
        local diff = (direction - look_direction) % 4
    
        if diff == 1 then
            turtle.turnRight()
        elseif diff == 2 then
            turtle.turnRight()
            turtle.turnRight()
        elseif diff == 3 then
            turtle.turnLeft()
        end
    
        look_direction = direction % 4
    end
    
    local function move_down()
        if turtle.down() then
            y_position = y_position - 1
            return true
        end
        return false
    end
    
    local function move_up()
        if turtle.up() then
            y_position = y_position + 1
            return true
        end
        return false
    end
    
    local function move_forward()
        if turtle.forward() then
            if look_direction == Directions.Forward then
                x_position = x_position + 1
            elseif look_direction == Directions.Backward then
                x_position = x_position - 1
            elseif look_direction == Directions.Left then
                z_position = z_position - 1
            else 
                z_position = z_position + 1
            end
            return true
        end
        return false
    end
    
    local function descend()  -- enters a layer below, at start and for all levels
        local target_y = y_position - 2
        if y_position < 0 then
            target_y = target_y - 1
        end
    
        while y_position > target_y do
            if turtle.digDown() == true then
                move_down()
            else
                if turtle.detectDown() == false then
                    move_down()
                else
                    bedrock_reached = true
                    break
                end
            end
        end
        while turtle.digDown() do
            -- repeating digging down until there is nothing
        end
    end
    
    local function store_loot()
        set_direction(Directions.Backward)
        for slot = 1, 16, 1 do
            turtle.select(slot)
            if turtle.getItemDetail() ~= nil then
                if turtle.drop() == false then
                    if freeze then
                        io.write("Make some space in the external inventory, and press enter..")
                        io.read()
                    end
                end
            end
        end
        turtle.select(1)
    end
    
    local function go_home(is_complete)
        -- save position
        last_x = x_position
        last_y = y_position
        last_z = z_position
        last_direction = look_direction
        -- up
        while y_position < 0 do
            if not move_up() then
                turtle.digUp()
            end
        end
        -- to the chest
        set_direction(Directions.Backward)
        while x_position > 0 do
            if not move_forward() then
                turtle.dig()
            end
        end
        set_direction(Directions.Left)
        while z_position > 0 do
            if not move_forward() then
                turtle.dig()
            end
        end
        set_direction(Directions.Backward)  -- look at chest
        store_loot()
        if is_complete == true then
            term.setCursorPos(1,5)
            io.write("Program has finished, stopping..")
            while true do
                os.sleep(30)
            end
        end
    end
    
    local function try_dig_move_forward()
        -- if move_forward() == false then
        --     if turtle.dig() then
        --         if move_forward() then
        --             return true
        --         end
        --     end
        -- else
        --     return true
        -- end
        -- return false
    
        while move_forward() == false do
            if turtle.dig() == false then
                local success, forward_block = turtle.inspect()
                if success and forward_block.name == "minecarft:bedrock" then
                    return false
                end
            end
        end
        return true
    end
    
    local function dig_fail()
        print("dig fail")
        set_direction(look_direction - 2)
                
        if try_dig_move_forward() == false then
            while true do
                term.setCursorPos(1,4)
                io.write("!!! Stuck, program stopped. !!!")
                os.sleep(30)
            end
        else
            go_home(true)  -- full exit
        end
    end
    
    local function dig()
        if try_dig_move_forward() == false then
            go_home(true)  -- full exit
        end
    
        if turtle.digUp() == false then
            if turtle.detectUp() == true then
                dig_fail()
            end
        end
    
        if turtle.digDown() == false then
            if turtle.detectDown() == true and bedrock_reached == false then
                dig_fail()
            end
        end
    end
    
    local function refuel()
        for slot = 1, 16, 1 do
            local item_detail = turtle.getItemDetail(slot)
            if item_detail ~= nil  then
                for _,a in ipairs(FUEL_ITEMS) do
                    if a == item_detail.name then
                        turtle.select(slot)
                        return turtle.refuel()  -- true/false, dep. on success
                    end
                end
            end
        end
    end
    
    local function has_enough_fuel()
        return turtle.getFuelLevel() >= math.abs(x_position + y_position + z_position) + 16  -- paranoid
    end
    
    local function turn(turn_right)
        local last_dir = look_direction
        if turn_right then
            set_direction(Directions.Right)
        else
            set_direction(Directions.Left)
        end
        dig()
    
        if last_dir == Directions.Forward then
            set_direction(Directions.Backward)
        else -- looking backward
            set_direction(Directions.Forward)
        end
    end
    
    local function go_back()
        -- zx
        set_direction(Directions.Right)
        while z_position < last_z do
            if not move_forward() then
                turtle.dig()
            end
        end
        set_direction(Directions.Forward)
        while x_position < last_x do
            if not move_forward() then
                turtle.dig()
            end
        end
        -- down
        set_direction(last_direction)
        while y_position > last_y do
            if not move_down() then
                turtle.digDown()
            end
        end
    end
    
    local function dig_column()
        while (look_direction == Directions.Forward and x_position < forward-1) or
                (look_direction == Directions.Backward and x_position > 0) do
            print(", x pos: " .. tostring(x_position) .. ", z pos: " .. tostring(z_position))
            dig()
        end
    end
    
    local function dig_level()
        local digged_columns = 0
    
        while (digging_right and z_position < sideways) or (not digging_right and z_position >= 0) do
            --refueling if necessary
            local full_inventory = is_full()
            if not full_inventory and has_enough_fuel() == false then
                refuel()
                turtle.select(1)
            end
    
            --going home if inventory is full or out of fuel
            local needs_fuel = not has_enough_fuel()
            if full_inventory or needs_fuel then
                last_x, last_direction, last_z = x_position, y_position, z_position
                last_direction = look_direction
                go_home(false)
                if needs_fuel then
                    term.setCursorPos(1, 1)
                    io.read("Waiting for refuel, press enter to continue.")
                end
                go_back()
            end
    
            dig_column()
            digged_columns = digged_columns + 1
            
            if digged_columns >= sideways then
                break;
            end
            turn(digging_right)
        end
    end
    
    local function main()
        if turtle.getFuelLevel() < forward * sideways then
            refuel()
            turtle.select(1)
        end
    
        level_count = math.ceil(depth / 3)
        print("level count: " .. tostring(level_count))
        for level = 1, level_count, 1 do
            print("level: " .. level)
            descend()
            dig_level()
            digging_right = not digging_right
            set_direction(look_direction + 2)
        end
    end
    
    main()
    