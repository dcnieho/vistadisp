homeDir = fullfile(fileparts(mfilename('fullpath')),'..','..','..');
addpath(genpath(homeDir))
try
    params.calibration = 'demo';
    params.subject = 'demo';
    params.useEL = true;
    params = retCreateDefaultEyeLinkParams(params);
    
    params.display = loadDisplayParams('displayName',params.calibration);
    fprintf('[%s]:loading calibration from: %s.\n',mfilename,params.calibration);
    
    Screen('Preference','SkipSyncTests', 1);
    params.display = openScreen(params.display);
    
    %Eyelink('SetAddress','');
    el                              = EyelinkInitDefaults(params.display.windowPtr);
    el.backgroundcolour             = [.5 .5 .5]*255;
    el.foregroundcolour             = [0 0 0];
    el.calibrationtargetcolour      = [255 0 0];
    el.msgfontcolour                = [0 0 0];
    el.calibrationtargetsize        = 20/params.display.numPixels(1)*100;  % in percentage of screen size
    el.calibrationtargetwidth       = 6/params.display.numPixels(1)*100;
    % switch off sounds (set to 0) as they are annoying and i've had issues with them crashing
    el.targetbeep                   = 0;
    el.feedbackbeep                 = 0;
    EyelinkUpdateDefaults(el);
    if ~EyelinkInit(false)
        error('Eyelink Init failed.\n');
    end
    Eyelink('Command', 'sample_rate = 1000');
    Eyelink('Command', 'calibration_type = HV9');
    Eyelink('Command', 'aux_mouse_simulation = NO');
    Eyelink('Command', 'active_eye = RIGHT');
    % set display geometry
    Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, params.display.numPixels(1)-1, params.display.numPixels(2)-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, params.display.numPixels(1)-1, params.display.numPixels(2)-1);
    Eyelink('command', 'screen_phys_coords = %ld %ld %ld %ld', -params.display.dimensions(1)/2*10, -params.display.dimensions(2)/2*10, params.display.dimensions(1)/2*10, params.display.dimensions(2)/2*10);
    Eyelink('command', 'screen_distance = %ld %ld', params.display.distance*10, params.display.distance*10);
    % set calibrated/used part of screen
    Eyelink('command', 'generate_default_targets = NO');
    calTargets = bsxfun(@plus,bsxfun(@minus,params.EL.basePointPositions,params.EL.basePointPositions(1,:))*params.EL.calScale,params.EL.basePointPositions(1,:));
    fmt = repmat('%.0f,%.0f ',1,size(calTargets,1)); fmt(end) = [];
    Eyelink('command', sprintf(['calibration_targets = ' fmt],calTargets.'));
    valTargets = bsxfun(@plus,bsxfun(@minus,params.EL.basePointPositions,params.EL.basePointPositions(1,:))*params.EL.valScale,params.EL.basePointPositions(1,:));
    Eyelink('command', sprintf(['validation_targets = ' fmt],valTargets.'));
    
    [v, vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a "%s" tracker.\n', vs);
    Eyelink('Openfile', 'tempdump');
    EyelinkDoTrackerSetup(el);
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.1); % short wait so that the tracker can finish the mode transition
    Eyelink('Shutdown');
catch me
    sca
    rethrow(me)
end
sca
rmpath(genpath(homeDir))
