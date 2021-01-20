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

homeDir = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
addpath(genpath(homeDir))

% make directories
dataDir = fullfile(homeDir,'data');
if ~isdir(dataDir)
    mkdir(dataDir);
end
posDir = fullfile(homeDir,'stimulusPositioning');
if ~isdir(posDir)
    mkdir(posDir);
end

setenv('PTB_SKIPSPLASH','1')                % stop 10s long splashscreen...

subject = input('Enter Subject Initials: ','s');
assert(~isempty(subject),'provide a subject name');
useET = input('Use EyeLink? (y/n): ','s');
assert(any(strcmpi(useET,{'y','n'})))


% get some parameters from graphical interface
params = retCreateDefaultGUIParams([]);
params.triggerKey = 's';
params.prescanDuration = 12;
params.stimSize = 4.5;
params.runPriority = 1;

% these are somehow set in the GUI automatically:
params.interleaves = [];
params.loadMatrix = [];
% params.saveMatrix = []; % set below
params.calibration = 'demo';
params.skipSyncTests = 1;

% add info about subject and script
params.homeDir = homeDir;
params.subject = subject;

% filenames
params.paramsFileName = fullfile(params.homeDir,'data',sprintf('%s_%s_params.mat',params.subject,datestr(now,30)));
params.saveMatrix     = fullfile(params.homeDir,'data',sprintf('%s_%s_images.mat',params.subject,datestr(now,30)));

% now set rest of the params
params = setRetinotopyParams(params.experiment, params);

% set response device
params = setRetinotopyDevices(params);

% some ET setup
params.useEL = strcmpi(useET,'y');
params = retCreateDefaultEyeLinkParams(params);

% go
[response,timing] = doRetinotopyScan(params);

% get EL data file
if params.useEL
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    edfFile = fullfile(params.homeDir,'data',sprintf('%s.edf',params.subject));
    try
        fprintf('Receiving data file ''%s''\n', edfFile);
        warning('make sure data file ends up in right place')
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile);
    end
    Eyelink('Shutdown');
end

rmpath(genpath(homeDir))
