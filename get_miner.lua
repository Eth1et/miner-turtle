-- Base URL points to the 'code' folder in the repo;
-- we will download its contents (files and subdirectories) into the current directory.
local githubBaseURL = "https://api.github.com/repos/Eth1et/miner-turtle/contents/code"

-- Ensure HTTP API is enabled;
if not http then
    error("HTTP API is not enabled. Please enable it in the ComputerCraft configuration.")
    return
end

-- Function to download a single file and save it locally;
local function downloadFile(filePath, downloadURL)
    print("Downloading: " .. filePath)
    local response = http.get(downloadURL)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(filePath, "w")
        file.write(content)
        file.close()
        
        print("Downloaded and saved: " .. filePath)
    else
        error("Failed to download: " .. filePath)
    end
end

-- Recursive function to download directories and files.
-- localPath: The local destination path relative to the current directory.
-- apiURL: The GitHub API URL to fetch the contents of this directory.
local function downloadDirectory(localPath, apiURL)
    print("Fetching directory: " .. (localPath == "" and "root" or localPath))
    local response = http.get(apiURL)
    if not response then
        error("Failed to fetch: " .. apiURL)
    end

    local content = response.readAll()
    response.close()

    local fileList = textutils.unserializeJSON(content) or {}
    for _, fileData in ipairs(fileList) do
        if fileData.type == "file" then
            -- Determine the local path for the file.
            local filePath = (localPath == "" and fileData.name) or (localPath .. "/" .. fileData.name)
            downloadFile(filePath, fileData.download_url)
        elseif fileData.type == "dir" then
            -- Build the new local directory path.
            local dirPath = (localPath == "" and fileData.name) or (localPath .. "/" .. fileData.name)
            if not fs.exists(dirPath) then
                fs.makeDir(dirPath)
            end
            -- Recursively download the directory contents.
            downloadDirectory(dirPath, fileData.url)
        end
    end
end

-- Start the recursive download.
-- We pass an empty string for localPath so that the contents of the "code" folder
-- are saved directly into the current directory (i.e. without creating a top-level "code" folder).
downloadDirectory("", githubBaseURL)

print("All files downloaded.")
