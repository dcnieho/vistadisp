function [response,timing] = doRetinotopyScan(params)
% doRetinotopyScan - runs retinotopy scans
%
% doRetinotopyScan(params)
%
% Runs any of several retinotopy scans
%
% 99.08.12 RFD wrote it, consolidating several variants of retinotopy scan code.
% 05.06.09 SOD modified for OSX, lots of changes.
% 11.09.15 JW added a check for modality. If modality is ECoG, then call
%           ShowScanStimulus with the argument timeFromT0 == false. See
%           ShowScanStimulus for details. 

% defaults
if ~exist('params', 'var'), error('No parameters specified!'); end
if ~isfield(params, 'skipSyncTests'), skipSyncTests = 1;
else                                  skipSyncTests = params.skipSyncTests; end

if isempty(params.saveMatrix),  removeImages = true; 
else                            removeImages = false; end


% make/load stimulus
stimulus = retLoadStimulus(params);

% loading mex functions for the first time can be
% extremely slow (seconds!), so we want to make sure that
% the ones we are using are loaded.
KbCheck;GetSecs;WaitSecs(0.001);

try
    % check for OpenGL
    AssertOpenGL;
    
    % to skip annoying warning message on display (but not terminal)
    Screen('Preference','SkipSyncTests', skipSyncTests);
    
    % Open the screen
    params.display                = openScreen(params.display);
    params.display.devices        = params.devices;
    
    % to allow blending
    Screen('BlendFunction', params.display.windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % find out where on screen grating should be displayed
    destRect = positionOnScreen(params);
    [params.display.fixX,params.display.fixY] = RectCenterd(destRect);
    
    % setup EL
    if isfield(params,'useEL') && params.useEL
        Eyelink('SetAddress',params.EL.ip);
        el                              = EyelinkInitDefaults(wpnt);
        el.backgroundcolour             = params.backRGB.dir.*params.backRGB.scale;
        el.foregroundcolour             = params.stimLMS.dir.*params.stimLMS.scale;
        el.calibrationtargetcolour      = [255 0 0];
        el.msgfontcolour                = GrayIndex(wpnt);
        el.calibrationtargetsize        = 20/params.display.numPixels(1)*100;  % in percentage of screen size
        el.calibrationtargetwidth       = 6/params.display.numPixels(1)*100;
        % switch off sounds (set to 0) as they are annoying and i've had issues with them crashing
        el.targetbeep                   = 0;
        el.feedbackbeep                 = 0;
        EyelinkUpdateDefaults(el);
        if ~EyelinkInit(params.el.useDummy)
            error('Eyelink Init failed.\n');
        end
        Eyelink('Command', 'sample_rate = 1000');
        Eyelink('Command', 'calibration_type = HV9');
        Eyelink('Command', 'aux_mouse_simulation = NO');
        Eyelink('Command', 'active_eye = RIGHT');
        
        % set display geometry
        Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, params.display.numPixels(1)-1, params.display.numPixels(2)-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, params.display.numPixels(1)-1, params.display.numPixels(2)-1);
        Eyelink('command','screen_phys_coords = %ld %ld %ld %ld', -params.display.dimensions(1)/2*10, -params.display.dimensions(2)/2*10, params.display.dimensions(1)/2*10, params.display.dimensions(2)/2*10);
        Eyelink('command','screen_distance = %ld %ld', params.display.distance*10, params.display.distance*10);
        % set calibrated/used part of screen, based on per-subject
        % positioning
        Eyelink('command','generate_default_targets = NO');
        calTargets = bsxfun(@plus,bsxfun(@minus,params.EL.basePointPositions,params.EL.basePointPositions(1,:))*params.EL.calScale, [params.display.fixX params.display.fixY]);
        fmt = repmat('%.0f,%.0f ',1,size(calTargets,1)); fmt(end) = [];
        EyeLink('command',sprintf(['calibration_targets = ' fmt],calTargets.'));
        valTargets = bsxfun(@plus,bsxfun(@minus,params.EL.basePointPositions,params.EL.basePointPositions(1,:))*params.EL.valScale, [params.display.fixX params.display.fixY]);
        EyeLink('command',sprintf(['validation_targets = ' fmt],valTargets.'));
        
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HREF,PUPIL,STATUS,INPUT,HMARKER,HTARGET');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,HTARGET');
        Eyelink('command', 'file_event_data  = LEFT,RIGHT,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'link_event_data  = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        [v, vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a "%s" tracker.\n', vs);
        Eyelink('Openfile', params.EL.filenm);
        % Do camera setup and calibrate the eye tracker
        Eyelink('Command', 'sticky_mode_data_enable DATA = 1 1 1 1'); % request to store data samples and events during calibration and validation to file
        EyelinkDoTrackerSetup(el);
        Eyelink('Command', 'sticky_mode_data_enable'); % stop sending samples, events to data file
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.1); % short wait so that the tracker can finish the mode transition
        Eyelink('Command', 'setup_menu_mode');  % sticky_mode_data_enable is only switched off when there is an actual mode change. the above set_idle_mode is a no-op as the tracker is already offline at that point. If sticky mode is not switched off properly, we end up with junk samples in a small bit of the edf file, overwriting part of the next trial
        WaitSecs(0.1); % short wait so that the tracker can finish the mode transition
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.1); % short wait so that the tracker can finish the mode transition
    end
    
    % Store the images in textures
    stimulus = createTextures(params.display,stimulus, removeImages);
    
    % override positioning of stimuli on screen
    [stimulus.destRect] = deal(destRect);
    
    % If necessary, flip the screen LR or UD  to account for mirrors
    % We now do a single screen flip before the experiment starts (instead
    % of flipping each image). This ensures that everything, including
    % fixation, stimulus, countdown text, etc, all get flipped.
    retScreenReverse(params, stimulus);
            
    for n = 1:params.repetitions,
        % set priority
        Priority(params.runPriority);
        
        % reset colormap?
        retResetColorMap(params);
        
        % prep EL for recording
        if isfield(params,'useEL') && params.useEL
            Eyelink('Command', 'set_idle_mode');
            WaitSecs(0.1); % short wait so that the tracker can finish the mode transition
            Eyelink('Message', 'TRIALID %d', n);
            Eyelink('message', 'repetition %d', n);
            Eyelink('StartRecording', 1, 1, 1, 1);
            % record a few samples before we actually start displaying
            % otherwise you may lose a few msec of data
            WaitSecs(0.1);
        end
        
        % wait for go signal
        onlyWaitKb = false;
        pressKey2Begin(params.display, onlyWaitKb, [], [], params.triggerKey);


        % If we are doing ECoG/MEG/EEG, then initialize the experiment with
        % a patterned flash to the photodiode
        stimulus.flashTimes = retInitDiode(params);
        
        % countdown + get start time (time0)
        [time0] = countDown(params.display,params.countdown,params.startScan, params.trigger);
        time0   = time0 + params.startScan; % we know we should be behind by that amount
                        
        [response, timing, quitProg] = showScanStimulus(params.display,stimulus,time0,params);
                
        % reset priority
        Priority(0);
        
        % get performance
        [pc,rc] = getFixationPerformance(params.fix,stimulus,response);
        fprintf('[%s]: percent correct: %.1f %%, reaction time: %.1f secs',mfilename,pc,rc);
        
        % save
        if params.savestimparams,
            filename = fullfile(params.homeDir,'data',sprintf('%s_%s.mat',params.subject,datestr(now,30)));
            save(filename);                % save parameters
            fprintf('[%s]:Saving in %s.',mfilename,filename);
        end;
        
        % don't keep going if quit signal is given
        if quitProg, break; end;
        
    end;
    
    % Close the one on-screen and many off-screen windows
    closeScreen(params.display);

catch ME
    % clean up if error occurred
    Screen('CloseAll'); 
    setGamma(0); Priority(0); ShowCursor;
    %warning(ME.identifier, ME.message);
    rethrow(ME)
end;


return;








