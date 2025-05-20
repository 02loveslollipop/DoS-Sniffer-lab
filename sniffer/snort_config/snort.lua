-- Snort 3 configuration file (snort.lua)

-- Define network and path variables globally, as per official Snort 3 examples
HOME_NET = 'any'
EXTERNAL_NET = '!$HOME_NET' -- Changed to reference HOME_NET for standard practice
RULE_PATH = '/usr/local/etc/snort/rules'
PREPROC_RULE_PATH = '/usr/local/etc/snort/preproc_rules'
BUILTIN_RULE_PATH = '/usr/local/etc/snort/builtin_rules'
PLUGIN_PATH = '/usr/local/lib/snort_dynamicrules'

-- Include default configurations. This is crucial.
-- snort_defaults.lua is expected to define 'default_variables'
include 'snort_defaults.lua'

-- Function to detect LAND attack
land_detector = {}
function land_detector.check()
    local p = snort.get_packet()
    -- Ensure packet data is available and all necessary fields are present
    if p and p.ip_src and p.ip_dst and p.src_port and p.dst_port then
        -- Compare IP addresses as strings and ports as numbers
        if tostring(p.ip_src) == tostring(p.ip_dst) and p.src_port == p.dst_port then
            return true -- LAND attack condition met
        end
    end
    return false -- LAND attack condition not met
end

-- Main configuration table to be returned
return {
    -- It's good practice to include these in the returned table
    -- as some modules might expect them here.
    HOME_NET = HOME_NET, -- Global HOME_NET
    EXTERNAL_NET = EXTERNAL_NET, -- Global EXTERNAL_NET
    RULE_PATH = RULE_PATH, -- Global RULE_PATH
    PREPROC_RULE_PATH = PREPROC_RULE_PATH,
    BUILTIN_RULE_PATH = BUILTIN_RULE_PATH,
    PLUGIN_PATH = PLUGIN_PATH,

    -- Configure IPS mode
    ips = {
        mode = 'inline', -- or 'tap' for passive IDS mode
        rules = "include " .. RULE_PATH .. "/custom.rules",
        -- Configure variables in a flat structure
        variables = {
            HOME_NET = HOME_NET,        -- Reference global HOME_NET
            EXTERNAL_NET = EXTERNAL_NET   -- Reference global EXTERNAL_NET
            -- If you had port variables, they would go here directly, e.g.:
            -- HTTP_PORTS = '80,8080'
        }
    },

    -- Configure DAQ (Data Acquisition)
    daq = {
        module = 'pcap',    -- Default DAQ module
        -- interface = 'eth0', -- This is typically overridden by the -i command-line option
        snaplen = 1518,     -- Maximum packet capture size (default)
        promisc = true,     -- Run in promiscuous mode (default)
        -- buffer_size = 128,  -- DAQ buffer size in MB (optional)
    },

    -- Example for logging (adjust as needed)
    -- alerts = {
    --     { type = 'alert_fast', file = 'alert_fast.txt' },
    --     { type = 'unified2', file = 'snort.u2', limit = 128 },
    -- },

    -- Configure preprocessors as needed here
    -- stream = {}, -- Enable stream preprocessor with defaults
    -- http_inspect = {}, -- Enable http_inspect with defaults
}