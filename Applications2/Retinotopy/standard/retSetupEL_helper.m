function retSetupEL_helper
try
    params.calibration = 'demo';
    
    params.display = loadDisplayParams('displayName',params.calibration);
    fprintf('[%s]:loading calibration from: %s.\n',mfilename,params.calibration);
    
    Screen('Preference','SkipSyncTests', 1);
    params.display = openScreen(params.display);
    sca
    
    Eyelink('SetAddress','');
    el                              = EyelinkInitDefaults(wpnt);
    el.backgroundcolour             = [.5 .5 .5];
    el.foregroundcolour             = [1 1 1];
    el.calibrationtargetcolour      = [255 0 0];
    el.msgfontcolour                = GrayIndex(wpnt);
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
    % TODO: set calibrated/used part of screen, based on positioning.
    % perhaps:
    %         Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    %         Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % TODO: also set display geometry
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
rmpath(genpath(homeDir))
