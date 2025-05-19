-- Placeholder for snort_defaults.lua
-- You can copy the default from the Snort source (snort3/etc/snort_defaults.lua)
-- or build your own.

-- This file typically contains default settings for various Snort components.
-- For example, default preprocessor configurations, etc.

-- setup the path for rules and configs
RULE_PATH = RULE_PATH or '/usr/local/etc/snort/rules'
BUILTIN_RULE_PATH = BUILTIN_RULE_PATH or '/usr/local/etc/snort/builtin_rules'
PREPROC_RULE_PATH = PREPROC_RULE_PATH or '/usr/local/etc/snort/preproc_rules'
LUA_PATH = LUA_PATH or '/usr/local/etc/snort'

-- HOME_NET and EXTERNAL_NET should be defined globally in snort.lua before this file is included.
-- This section ensures they are available and populates default_variables.

if HOME_NET == nil then
    print("Warning: HOME_NET was not defined globally in snort.lua before including snort_defaults.lua. Defaulting to 'any'.")
    HOME_NET = 'any'
end

if EXTERNAL_NET == nil then
    print("Warning: EXTERNAL_NET was not defined globally in snort.lua before including snort_defaults.lua. Defaulting to '!$HOME_NET'.")
    EXTERNAL_NET = '!$HOME_NET' -- This will use the HOME_NET defined above or globally
end

-- Define default_variables table, which snort.lua can use for ips.variables
default_variables = {
    HOME_NET = HOME_NET,
    EXTERNAL_NET = EXTERNAL_NET,

    -- You can add other common variables here if needed, e.g.:
    -- AIM_SERVERS = '$HOME_NET',
    -- DNS_SERVERS = '$HOME_NET',
    -- SMTP_SERVERS = '$HOME_NET',
    -- HTTP_SERVERS = '$HOME_NET',
    -- SQL_SERVERS = '$HOME_NET',
    -- TELNET_SERVERS = '$HOME_NET',
    -- SNMP_SERVERS = '$HOME_NET',
    -- FTP_SERVERS = '$HOME_NET',
    -- SSH_SERVERS = '$HOME_NET',
    -- SIP_SERVERS = '$HOME_NET',
    -- FILE_DATA_PORTS = '$HTTP_PORTS',
    -- HTTP_PORTS = '{ 80, 8080 }', -- Example, adjust as needed
    -- SHELLCODE_PORTS = '!80',
    -- ORACLE_PORTS = '1521',
    -- MSSQL_PORTS = '1433',
}

-- default is to run as an ids
ips = ips or {}
ips.mode = ips.mode or 'tap' -- Changed default to 'tap' for IDS-only behavior unless overridden

-- file_api configuration (example, ensure paths and files are correct if used)
-- file_api = file_api or {
--     magic_files = { LUA_PATH .. '/file_magic.data' }, -- Ensure this file exists if uncommented
--     log_types = true,
--     log_sigs = true,
-- }

-- Placeholder message to confirm this file is loaded
print("snort_defaults.lua loaded and default_variables populated.")
