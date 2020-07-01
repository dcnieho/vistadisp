function displayID = openScreen(displayID, hideCursorFlag)
% openScreen - open screen for psychtoolbox
% 
% Usage: displayID = openScreen(displayID, [hideCursorFlag=true])
% 
% openScreen takes a displayID structure (e.g., from running
% loadDisplayParams), and does the following:
% 1. opens a PTB window with a background color (defaults to 1/2 of
% maxRgbValue) (using Screen in PTB)
% 2. draws a fixation dot (using drawFixation in exptTools)
% 3. hides the cursor
% 4. store the original gamma table in the displayID structure
% 
% After you are done with the opened PTB window, use closeScreen to revert
% back to the original state.
% 
% History:
% ##/##/## rfd & sod wrote it.
% 04/12/06 shc (shcheung@stanford.edu) cleaned it and added the help
% comments.

if(~exist('hideCursorFlag','var')||isempty(hideCursorFlag))
    hideCursorFlag = true;
end

if(~isfield(displayID,'bitsPerPixel'))
	displayID.bitsPerPixel = 8;
	disp('Using default pixel depth of 8 bits');
end

if(~isfield(displayID,'pixelSize'))
    if(isfield(displayID,'numPixels') && isfield(displayID,'dimensions') && ...
            ~isempty(displayID.numPixels) && ~isempty(displayID.dimensions) && ...
            length(displayID.numPixels) == length(displayID.dimensions))
        displayID.pixelSize = mean(displayID.dimensions./displayID.numPixels);
        disp('Using number of pixels and dimension information to calculate pixel size');
    else
        displayID.pixelSize = 0.0691;
        disp('Using default pixel size of 0.0691 cm');
    end
end

if(~isfield(displayID,'gammaTable'))
	displayID.gammaTable = linspace(0,2^displayID.cmapDepth-1,2^displayID.cmapDepth)';
	disp('Using default linear gamma table');
end

if(~isfield(displayID,'backColorRgb'))
    displayID.backColorRgb = [repmat(round(displayID.maxRgbValue/2),1,3) displayID.maxRgbValue];
	disp(['Setting backColorRgb to ',num2str(displayID.backColorRgb),'.']);
end

% Skip the annoying blue flickering warning
% Screen('Preference','SkipSyncTests',1);

% check screen is at right resolution and refresh rate
rect                = Screen('Rect',displayID.screenNumber);
frate               = Screen('NominalFrameRate',displayID.screenNumber);
assert(isequal(rect(3:4),displayID.numPixels),'expected resolution of [%s], but got [%s]',num2str(displayID.numPixels),num2str(rect(3:4)));
if frate==59 && expt.scr.framerate==60
    % see http://support.microsoft.com/kb/2006076, 59 Hz == 59.94Hz
    % (and thus == 60 Hz)
    warning('WARNING: Windows reported 59Hz again, ignoring it and pretending its 60 Hz...'); %#ok<WNTAG>
    frate=60;
end
assert(frate==displayID.frameRate,'expected framerate of %d, but got %d',displayID.frameRate,frate);


% Open the screen and save the window pointer and rect
fprintf('opening on screen %d\n',displayID.screenNumber);
[displayID.windowPtr,displayID.rect] = Screen('OpenWindow',displayID.screenNumber,displayID.backColorRgb);

if(hideCursorFlag), HideCursor; end

return;
