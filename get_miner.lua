-- Enable HTTP API (make sure HTTP is enabled in ComputerCraft);
-- Turtle needs fuel if it moves (not required for stationary operations);

local githubBaseURL = "https://api.github.com/repos/Eth1et/miner-turtle/contents/code";

-- Ensure HTTP is enabled;
if not http then
    error("HTTP API is not enabled. Please enable it in the ComputerCraft configuration.");
    return;
end

-- Function to download a file from GitHub and save it locally;
local function downloadFile(fileName, downloadURL)
    print("Downloading: " .. fileName);

    local response = http.get(downloadURL);
    if response then
        local content = response.readAll();
        response.close();

        local file = fs.open(fileName, "w");
        file.write(content);
        file.close();

        print("Downloaded and saved: " .. fileName);
    else
        error("Failed to download: " .. fileName);
    end
end

-- Fetch the list of files from the GitHub API;
local function fetchFileList()
    print("Fetching file list from GitHub...");
    local response = http.get(githubBaseURL);
    if not response then
        print("Failed to fetch file list.");
        return {};
    end

    local content = response.readAll();
    response.close();

    local fileList = textutils.unserializeJSON(content) or {};
    return fileList;
end

-- Download each file directly into the current directory;
local fileList = fetchFileList();
for _, fileData in ipairs(fileList) do
    if fileData.type == "file" then
        downloadFile(fileData.name, fileData.download_url);
    end
end

print("All files downloaded.");
