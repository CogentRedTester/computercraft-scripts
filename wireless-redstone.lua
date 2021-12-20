shell.execute("rm", "startup.lua")
shell.execute("wget", "https://raw.githubusercontent.com/CogentRedTester/computercraft-scripts/master/wireless-redstone.lua", "startup.lua")

local opts = {
    id = "",
    role = 0,
    mode = 0,
    side = ""
}

local PROTOCOL_SRING = "RedTester_wireless_redstone_protocol/"
local STATUS = ""

local ROLE = {
    SENDING = 1,
    RECEIVING = 2
}

local MODE = {
    ANALOGUE = 1,
    DIGITAL = 2
}

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function configuration()
    local id, role, mode, side
    clearScreen()

    print("Welcome to RedTester's Wireless Redstone Protocol!")
    print("First time setup...")
    print()
    print("Press ENTER to continue...")
    local _ = io.read()

    clearScreen()
    print("Enter frequency ID:")
    print()
    id = io.read()

    repeat
        clearScreen()
        print("Will this computer be:")
        print(ROLE.SENDING, "sending")
        print(ROLE.RECEIVING, "receiving")
        print()
        pcall( function() role = tonumber(io.read()) end)
    until role == ROLE.SENDING or role == ROLE.RECEIVING

    clearScreen()
    local sides = redstone.getSides()
    repeat
        print("Select side to input/output redstone:")
        for index, value in ipairs(sides) do
            print(index, value)
        end
        print()
        pcall( function() side = tonumber(io.read()) end)
    until sides[side]
    side = sides[side]

    if role == ROLE.RECEIVING then
        repeat
            clearScreen()
            print("Select output mode:")
            print(MODE.ANALOGUE, "analogue - redstone signal strength is maintained")
            print(MODE.DIGITAL, "digital - redstone signal strength is reset")
            print()
            pcall( function() mode = tonumber(io.read()) end)
        until mode == MODE.ANALOGUE or mode == MODE.DIGITAL
    end

    clearScreen()
    print("Your settings are:")
    print()
    print("ID:", id)
    print("ROLE:", role == ROLE.SENDING and "sender" or "receiver")
    print("SIDE:", side)
    if role == ROLE.RECEIVING then print("MODE:", mode == MODE.ANALOGUE and "analogue" or "digital") end

    print()
    print("Press ENTER to finish setup")
    _ = io.read()

    settings.set("id", id)
    settings.set("role", role)
    settings.set("mode", mode or 0)
    settings.set("side", side)
    settings.set("first_run", true)
end

local function drawStatus(status)
    if not rednet.isOpen() then status = "No Modem" end

    clearScreen()
    print("RedTester's Wireless Redstone Protocol")
    print("--------------------------------------")
    print()
    print("ID:", opts.id)
    print("ROLE:", opts.role == ROLE.SENDING and "sender" or "receiver")
    print("SIDE:", opts.side)
    if opts.role == ROLE.RECEIVING then print("MODE:", opts.mode == MODE.ANALOGUE and "analogue" or "digital") end
    print()
    print("STATUS:", status)
end

local function handleInput()

end

--sending computers will respond with the redstone level if queried by a receiver
local function queryDriver()
    while true do
        local source = rednet.receive(PROTOCOL_SRING..opts.id.."/query")
        rednet.send(source, redstone.getAnalogueInput(opts.side))
    end
end

local function sendingDriver()
    local function sendUpdate()
        local signal = redstone.getAnalogueInput(opts.side)
        rednet.broadcast(signal, PROTOCOL_SRING..opts.id)

        drawStatus("broadcasting - strength "..signal)
        os.pullEvent("redstone")
    end

    local function timeout()
        sleep(10)
    end

    while true do
        parallel.waitForAny(sendUpdate, timeout)
    end
end

--the receiving computer waits to receive update messages
--the current assumption is that there is only a single sender
local function receivingDriver()
    rednet.broadcast("", PROTOCOL_SRING..opts.id.."/query")

    while true do
        local source, signal_strength = rednet.receive(PROTOCOL_SRING..opts.id, 11)
        if not source then
            signal_strength = 0
            drawStatus("no senders found")
        else
            if opts.mode == MODE.ANALOGUE then
                drawStatus("receiving - strength "..signal_strength)
            else
                drawStatus("receiving - signal "..(signal_strength == 0 and "off" or "on"))
            end
        end

        if opts.mode == MODE.ANALOGUE then
            redstone.setAnalogueOutput(opts.side, signal_strength)
        else
            redstone.setAnalogueOutput(opts.side, signal_strength == 0 and 0 or 15)
        end
    end
end

--reconnects to any modems connected during runtime
local function modemDriver()
    while true do
        os.pullEvent("peripheral")
        peripheral.find("modem", rednet.open)
        drawStatus("modem connected")
    end
end

local function driver()
    for key, _ in pairs(opts) do
        opts[key] = settings.get(key)
    end
    peripheral.find("modem", rednet.open)

    local threads = {modemDriver}

    if opts.role == ROLE.SENDING then
        table.insert(threads, sendingDriver)
        table.insert(threads, queryDriver)
    elseif opts.role == ROLE.RECEIVING then
        table.insert(threads, receivingDriver)
    end

    parallel.waitForAny(unpack(threads))
end

settings.load(".wireless_settings")
if settings.get("first_run") == nil then
    configuration()
    settings.save(".wireless_settings")
end

driver()
