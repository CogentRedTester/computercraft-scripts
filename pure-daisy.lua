local input = "right"
local output = "left"

local rock = colors.white
local wood = colors.brown
local breakers = colors.red
local rockDropper = rock
local woodDropper = wood

local numPulses = 15
local blockPlaceDelay = 10

local setBundled = redstone.setBundledOutput
local getBundled = redstone.getBundledInput

local function printCommand(text)
    print("Sending command: " .. text)
end

local function daisy(colour)
    for i = 1, numPulses do
        setBundled(output, colour)
        sleep(0.2)
        setBundled(output, 0)
        sleep(0.2)
    end

    print('Waiting for blocks to be placed')
    sleep(blockPlaceDelay)
    print('Waiting 60 seconds for infusion')
    sleep(60)

    printCommand('break blocks')
    setBundled(output, breakers)
    sleep(0.2)
    setBundled(output, 0)
end

local function main()
    local colour = getBundled(input)

    if colour == rock then
        printCommand('livingrock')
        daisy(rockDropper)
    elseif colour == wood then
        printCommand('livingwood')
        daisy(woodDropper)
    elseif colour == rock + wood then
        printCommand('livingrock')
        daisy(rockDropper)
        printCommand('livingwood')
        daisy(woodDropper)
    else
        print('unknown redstone signal recieved')
    end
end

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("Pure Daisy Auto-Farm")
    print("---------------------------------------")
    print()
end

printHeader()

while true do
    printHeader()
    if getBundled(input) ~= 0 then
        main()
    else
        print('no input recieved, will check again in 10 seconds...')
        sleep(10)
    end
end