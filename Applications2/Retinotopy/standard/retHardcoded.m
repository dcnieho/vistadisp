function [params,response,timing] = retHardcoded
% [params] = ret([params])
%
% ret - program to start retinotopic mapping experiments (under OSX)
%     params: optional input argument to specify experiment parameters. if
%             omitted, GUI is opened to set parameters
%
% 06/2005 SOD Ported to OSX. If the mouse is invisible,
%             moving it to the Dock usually make s it reappear.
% 10/2005 SOD Several changes, including adding gui.
% 1/2009 JW   Added optional input arg 'params'. This allows you to
%             specify your parameters in advance so that the GUI loads up
%             with the values you want. 
% 
% Examples:
%
% 1. open the GUI, specify your expt, and click OK:
%
%   ret
%
% 2. Specify your experimental params in advance, open the GUI, and then
%    click OK:
%   
%   params = retCreateDefaultGUIParams
%   % modify fields as you like, e.g.
%   params.fixation = 'dot';
%   ret(params)

% TODO:
% - stimulus moving
% - get rid of resolution changing on open and close
% - 

homeDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(homeDir,'..','..','..')))


% get some parameters from graphical interface
params = retCreateDefaultGUIParams([]);
params.triggerKey = 's';
params.prescanDuration = 0;
params.stimSize = 4.5;
params.runPriority = 1;

% these are somehow set in the GUI automatically:
params.interleaves = [];
params.loadMatrix = [];
params.saveMatrix = [];
params.calibration = 'demo';
params.skipSyncTests = 1;

% now set rest of the params
params = setRetinotopyParams(params.experiment, params);

% set response device
params = setRetinotopyDevices(params);

% go
[response,timing] = doRetinotopyScan(params);

rmpath(genpath(fullfile(homeDir,'..','..','..')))
