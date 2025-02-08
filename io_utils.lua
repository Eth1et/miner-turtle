local options = {
    yes = true,
    y = true,
    ye = true,
    ya = true,
    zes = true,
    z = true,
    ze = true,
    za = true,
    n = false,
    no = false,
    noo = false
};

local function termUp()
    local x, y = term.getCursorPos();
    term.setCursorPos(x, y-1);
end

local function termStart()
    local _, y = term.getCursorPos();
    term.setCursorPos(1, y);
end

local function clear()
    term.clear();
    term.setCursorPos(1,1);
end


local function requireInt(prompt)
    while true do
        io.write(prompt);
        local input = io.read();
        local num = tonumber(input);

        if num == nil then
            term.clearLine();
            termUp();
            term.clearLine();
            io.write("The given input is not a number!");
            os.sleep(1.5);
            term.clearLine();
            termStart();
        else
            return math.floor(num);
        end
    end
end

local function requireBool(prompt)
    while true do
        io.write(prompt);
        local input = io.read():lower();

        if options[input] == nil then
            term.clearLine();
            termUp();
            term.clearLine();
            io.write("Invalid option!");
            os.sleep(1.5);
            term.clearLine();
            termStart();
        else
            return options[input];
        end
    end
end

local function waitTillInput(message)
    local color = term.getTextColor();
    term.setTextColor(colors.red);
    print(message);
    print("Press any key to Continue operation");
    read();
    term.setTextColor(color);
end



return {
    requireInt = requireInt,
    clear = clear,
    requireBool = requireBool,
    termUp = termUp,
    termStart = termStart,
    waitTillInput = waitTillInput
}