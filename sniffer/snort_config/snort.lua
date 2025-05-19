-- Basic snort.lua - A starting point, you'll need to customize this significantly.
-- This is a very minimal configuration for Snort 3.
-- Refer to official Snort 3 documentation for a full configuration.

-- Setup the home network. This is a REQUIRED setting.
-- Configure to your network addresses.
home_net = 'any'  -- IMPORTANT: Replace with your actual home network, e.g., '192.168.1.0/24' for a lab.
external_net = '!$home_net'

-- Path for rules, builtin_rules, and preprocessor rules
-- These paths are relative to where snort is run or can be absolute.
-- In Docker, these will be mapped from the host.
ips = {
    -- enable_builtin_rules = true, -- Disable to focus on custom rules for now
    rules = [[
        include $RULE_PATH/custom.rules
    ]],
    -- Add other rule files or configurations here
}

-- Configure DAQ
-- The DAQ module and mode will depend on how you capture packets.
-- For sniffing a specific interface:
daq = {
    module = 'pcap',
    interface = 'eth0', -- This will be the interface inside the container (e.g., mirrored port)
    snaplen = 1518,
    promisc = true, -- Promiscuous mode is essential for IDS
    -- buffer_size = 8388608, -- 8MB, example value, adjust if needed
}

-- Outputters
-- Configure how and where Snort logs alerts.
-- alert_fast = { file = 'alert_fast.txt', limit = '10m' } -- Simple, one-line alerts
alert_full = { file = 'alert_full.txt', limit = '10m' } -- Full alerts, more detail
-- log_pcap = { file = 'snort.pcap', limit = '10m', max_size = '100m' } -- Log captured packets

-- Preprocessor Configurations
-- These are crucial for proper detection of many attacks.
-- Refer to snort_defaults.lua and official documentation for detailed options.

stream = {
    -- max_sessions = 1048576, -- Default is 262144
    -- memcap = 2147483648, -- Default is 67108864 (64MB)
    -- timeout = 30, -- Default TCP session timeout
    -- log_stats = true,
}

stream_tcp = {
    -- policy = 'bsd', -- or 'first', 'last', 'linux', 'old', 'solaris', 'windows'
    -- require_3whs = false, -- Set to true to only track sessions with a full 3-way handshake
    -- overlap_limit = 0, -- How many overlapping bytes to allow
    -- small_segments = 0, -- Max number of small segments before alerting
}

-- Snort 3's host inspector handles IP defragmentation.
-- Ensure it's not disabled if you have specific host inspector settings.
-- Default behavior should be sufficient for basic teardrop detection.

-- http_inspect = {
--     -- Add HTTP specific configurations here if needed
-- }

-- Make sure the LUA_PATH is set correctly if you have custom Lua modules
-- package.path = package.path .. ';/usr/local/etc/snort/?.lua'

-- Include other specific configurations if needed
include 'snort_defaults.lua' -- Contains many default preprocessor settings
-- include 'file_magic.lua' -- For file identification, less critical for these DoS attacks
include 'file_magic.rules' -- For file identification

-- Print a message to confirm loading (optional)
print('Snort.lua configuration loaded with custom settings for DoS detection.')
