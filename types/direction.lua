local Direction = {
    Forward = 0,
    Right = 1,
    Backward = 2,
    Left = 3
}

-- Reverse lookup table for printing
Direction.reverse = {
    [0] = "Forward",
    [1] = "Right",
    [2] = "Backward",
    [3] = "Left"
};


return Direction;