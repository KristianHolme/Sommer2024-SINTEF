% Get the full path of the currently running script
fullpath = mfilename('fullpath');

% Extract the directory part of the full path
[currentScriptDir, ~, ~] = fileparts(fullpath);

addpath(genpath(currentScriptDir))