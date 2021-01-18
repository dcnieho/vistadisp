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

subject = input('Enter Subject Initials: ','s');
assert(~isempty(subject),'provide a subject name');
useET = input('Use EyeLink? (y/n): ','s');
assert(any(strcmpi(useET,{'y','n'})))


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

% add info about subject and script
params.homeDir = homeDir;
params.subject = subject;

% now set rest of the params
params = setRetinotopyParams(params.experiment, params);

% set response device
params = setRetinotopyDevices(params);

% some ET setup
params.useEL = strcmpi(useET,'y');
if params.useEL
    % eyelink only does 8.3 filenames, shorten subject name based
    % on that. We'll store on expt system using full name of
    % course, this is just for the host system, filename.
    eyesub_short     = params.subject(1:min(end,8));
    params.EL.filenm = [eyesub_short '.edf'];
    
    params.EL.ip        = '';       % empty: default. if non-standard, put ip, e.g. '192.168.10.13'
    params.el.useDummy  = false;    % if true dummy mode is used, i.e., no actual EL has to be connected
    params.EL.calScale  = .8;
    params.EL.valScale  = .7;
    params.EL.basePointPositions = [
         960, 540
         960,   0
         960,1080
           0, 540
        1920, 540
         192, 108
        1728, 108
         192, 972
        1728, 972
        ];
end

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
